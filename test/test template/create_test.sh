#!/bin/bash

# This script automates the test environment creation for a module in the tiny tapestation project

show_help() {
  echo " "
  echo "Cocotb Environment Setup Script"
  echo "James Ashie Kotey - SHaRC 2025"
  echo "Usage:"
  echo "  $0 [TARGET_DIR] -s <UUT_SRCS> -w <WRAPPER_TB> -t <TOPLEVEL> -m <TEST_MODULE> [--regen]"
  echo "  OR"
  echo "  $0 [TARGET_DIR] <UUT_SRCS> <WRAPPER_TB> <TOPLEVEL> <TEST_MODULE>"
  echo ""
  echo "Options:"
  echo "  [TARGET_DIR]    Optional. Directory to create test environment in."
  echo "  -s, --src       Name(s) of the UUT Verilog source file(s) (space-separated, no .v)"
  echo "  -w, --wtb       Name of the wrapper testbench file (without .v)"
  echo "  -t, --top       Name of the top-level Verilog module (e.g., 'sync_tb')"
  echo "  -m, --module    Name of the Python test module (without .py)"
  echo "  -h, --help      Show this help message and exit"
  echo "  --regen         Only regenerate Makefile (skip testbench/Python file creation)"
  echo ""
  echo "Example:"
  echo "  $0 -s Sync -w sync_wtb -t sync_tb -m test_sync"
  echo "  $0 Sync sync_wtb sync_tb test_sync"
  echo "  $0 my_dir Sync sync_wtb sync_tb test_sync"
  exit 0
}

# Show help if no args or help flag used
if [ "$#" -eq 0 ] || [[ " $* " == *" --help "* ]] || [[ " $* " == *" -h "* ]]; then
  show_help
fi

# ===== Detect optional directory argument =====

# Save and maybe shift into target dir
if [ -n "$1" ] && [[ "$1" != -* ]]; then
  TARGET_DIR="$1"

  if [ ! -d $TARGET_DIR ]; then
    mkdir -p $TARGET_DIR
    echo "[SETUP] Created folder: $TARGET_DIR"
  fi

  shift
  echo "[INFO] Changing to target directory: $TARGET_DIR"
  cd "$TARGET_DIR" || { echo "Failed to enter directory: $TARGET_DIR"; exit 1; }
  
else
  TARGET_DIR="."
fi

# Show help if no args or help flag used
if [ "$#" -eq 0 ] || [[ " $* " == *" --help "* ]] || [[ " $* " == *" -h "* ]]; then
  show_help
fi

# Initialize variables
UUT_SRCS=""
WRAPPER_TB=""
TOPLEVEL=""
TEST_MODULE=""
REGEN_ONLY=false

if [[ "$1" == -* ]]; then
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s|--src)
        shift
        while [[ "$#" -gt 0 && "$1" != -* ]]; do
          UUT_SRCS+="$1 "
          shift
        done
        ;;
      -w|--wtb) WRAPPER_TB="$2"; shift 2 ;;
      -t|--top) TOPLEVEL="$2"; shift 2 ;;
      -m|--module) TEST_MODULE="$2"; shift 2 ;;
      --regen) REGEN_ONLY=true; shift ;;
      -h|--help) show_help ;;
      *) echo "Unknown option: $1"; show_help ;;
    esac
  done
else
  if [ "$#" -lt 4 ]; then
    echo "Error: Expected 4 positional arguments when not using flags."
    echo "Run '$0 --help' for usage."
    exit 1
  fi
  UUT_SRCS="$1"
  WRAPPER_TB="$2"
  TOPLEVEL="$3"
  TEST_MODULE="$4"
fi

# Sanity check
if [[ -z "$UUT_SRCS" || -z "$WRAPPER_TB" || -z "$TOPLEVEL" || -z "$TEST_MODULE" ]]; then
  echo "Error: Missing required arguments."
  echo "Run '$0 --help' for usage."
  exit 1
fi


# Sanitize inputs
UUT_SRCS="$(echo "$UUT_SRCS" | xargs)"
WRAPPER_TB="$(echo "$WRAPPER_TB" | xargs)"
TOPLEVEL="$(echo "$TOPLEVEL" | xargs)"
TEST_MODULE="$(echo "$TEST_MODULE" | xargs)"
VCD_NAME="${TOPLEVEL%_tb}"

# Add .v extension if missing
UUT_SRCS_SANITIZED=""
for src in $UUT_SRCS; do
  [[ "$src" != *.v ]] && src="${src}.v"
  UUT_SRCS_SANITIZED+="$src "
done
UUT_SRCS="$UUT_SRCS_SANITIZED"

WRAPPER_TB="tb/${WRAPPER_TB}"
[[ "$WRAPPER_TB" != *.v ]] && WRAPPER_TB="${WRAPPER_TB}.v"
TEST_MODULE="${TEST_MODULE%.py}"

# ========== Makefile Generation ==========

NEW_ENV=$([ ! -f "Makefile" ] && echo true || echo false)

cat > Makefile <<EOF
# Auto-generated Makefile

UUT_SRCS     ?= ${UUT_SRCS}
WRAPPER_TB   ?= ${WRAPPER_TB}
TOPLEVEL     ?= ${TOPLEVEL}
TEST_MODULE  ?= ${TEST_MODULE}
RUN          ?= true

CURRENT_DIR :=  \$(dir \$(abspath \$(lastword \$(MAKEFILE_LIST))))
POST_SIM_DIR := sim
TEST_DIR := \$(dir \$(abspath \$(lastword \$(MAKEFILE_LIST))))

ifeq (\$(MAKELEVEL),0)
ROOT_DIR := \$(dir \$(abspath \$(TEST_DIR)/../../))
PROJECT_SOURCES = \$(addprefix \$(ROOT_DIR)/src/,\$(UUT_SRCS))
VERILOG_SOURCES += \$(PROJECT_SOURCES)
export SRC_DIR PROJECT_SOURCES VERILOG_SOURCES
endif

export PYTHONPATH := \$(abspath tb)
VERILOG_SOURCES += \$(TEST_DIR)\$(WRAPPER_TB)
VERILOG_SOURCES := \$(sort \$(VERILOG_SOURCES))
MODULE = \$(TEST_MODULE)
export COCOTB_RESULTS_FILE=\$(TOPLEVEL)_results.xml

include \$(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: run cleanup sim

all: sim cleanup

cleanup:
	@mkdir -p \$(POST_SIM_DIR)
	@echo "[CLEANUP] Cleaning up..."
	@if [ -d "tb/__pycache__" ]; then \\
		echo "[INFO] Deleting __pycache__"; \\
		rm -rf tb/__pycache__; \\
		echo "[INFO] Removed __pycache__ directory."; \\
	fi
	@if [ -d "\$(POST_SIM_DIR)/sim_build" ]; then \\
		echo "[INFO] Deleting existing sim_build in \$(POST_SIM_DIR)"; \\
		rm -rf \$(POST_SIM_DIR)/sim_build; \\
		echo "[INFO] Deleted sim_build in \$(POST_SIM_DIR)."; \\
	fi
	@if [ -d "sim_build" ]; then \\
		echo "[INFO] Moving new sim_build to \$(POST_SIM_DIR)"; \\
		mv sim_build \$(POST_SIM_DIR)/; \\
		echo "[INFO] Moved sim_build to \$(POST_SIM_DIR)."; \\
	fi
	@echo "[INFO] Moving simulation outputs to \$(POST_SIM_DIR)..."
	@if ls *.vcd 1>/dev/null 2>&1; then mv -f *.vcd \$(POST_SIM_DIR)/; fi
	@if ls *_results.xml 1>/dev/null 2>&1; then mv -f *_results.xml \$(POST_SIM_DIR)/; fi
	@echo "[INFO] Cleanup complete!"
EOF

if [ "$NEW_ENV" = true ]; then
    echo "[SETUP] Generated new Makefile"
fi

# Exit early if only regenerating
$REGEN_ONLY && exit 0

# Create Gitignore
if [ ! -f ".gitignore" ]; then
cat > .gitignore <<EOF
sim_build/
__pycache__/
*.vvp
*.xml
EOF
echo "[SETUP] Created .gitignore"
fi


# TB Folder
if [ ! -d "tb" ]; then
  mkdir -p "tb"
  echo "[SETUP] Created /tb folder"
fi

# Wrapper Verilog file
if [ ! -f "${WRAPPER_TB}" ]; then
  cat > "${WRAPPER_TB}" <<EOF
\`default_nettype none
\`timescale 1ns / 1ns

module ${TOPLEVEL}();
  reg clk;
  reg rst_n;
  
  // 1. define I/O singals
  
  wire input_wire;
  wire output_wire;

  // 2. instantiate UUT here




  initial begin
    \$dumpfile("${VCD_NAME}.vcd");
    \$dumpvars(0, ${TOPLEVEL});
    #1;
  end
endmodule
EOF
  echo "[SETUP] Created ${WRAPPER_TB} template"
else
  echo "[INFO] t${WRAPPER_TB}.v already exists... skipping generation."
fi

# Python test file
if [ ! -f "tb/${TEST_MODULE}.py" ]; then
  cat > "tb/${TEST_MODULE}.py" <<EOF
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

async def reset(uut, reset_duration=1):
    uut._log.info("Resetting Module")
    uut.rst_n.value = 0
    await ClockCycles(uut.clk, reset_duration)
    uut.rst_n.value = 1

@cocotb.test()
async def sanity_test(uut):
    clock = Clock(uut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    await ClockCycles(uut.clk, 1)
    await reset(uut, 1)
    await RisingEdge(uut.clk)
    uut._log.info("Test Complete!")
EOF
  echo "[SETUP] Created tb/${TEST_MODULE}.py template"
else
  echo "[INFO] tb/${TEST_MODULE}.py already exists... skipping generation."
fi

echo "[DONE] Environment setup complete!"
