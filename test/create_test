#!/bin/bash
# Written by JAK - v2.0
# Cocotb Environment Setup Script - Tiny Tapestation Project

show_help() {
    echo " "
    echo "Cocotb Environment Setup Script"
    echo "James Ashie Kotey - SHaRC 2025"
    echo "Usage:"
    echo "  $0 [TARGET_DIR] -s <UUT_SRCS> -w <WRAPPER_TB> -t <TOPLEVEL> -m <TEST_MODULE> [--regen]"
    echo "  $0 [TARGET_DIR] -s <UUT_SRCS> -a <ALIAS> [--regen]"
    echo "  $0 [TARGET_DIR] <UUT_SRCS> <WRAPPER_TB> <TOPLEVEL> <TEST_MODULE>"
    echo ""
    echo "Options:"
    echo "  [TARGET_DIR]    Optional. Directory to create test environment in."
    echo "  -s, --src       Name(s) of UUT Verilog source file(s) (space-separated, no .v)"
    echo "  -w, --wtb       Wrapper testbench name (without .v)"
    echo "  -t, --top       Top-level Verilog module name"
    echo "  -m, --module    Python test module name (without .py)"
    echo "  -a, --alias     Base name for auto-generated files"
    echo "  -h, --help      Show this help message"
    echo "  --regen         Only regenerate Makefile"
    exit 0
}

# Show help if no args
if [ "$#" -eq 0 ] || [[ " $* " == *" -h "* ]] || [[ " $* " == *" --help "* ]]; then
    show_help
fi

# ===== Optional target directory =====
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    TARGET_DIR="$1"
    [ ! -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR" && echo "[SETUP] Created folder: $TARGET_DIR"
    shift
    cd "$TARGET_DIR" || { echo "Failed to enter directory: $TARGET_DIR"; exit 1; }
else
    TARGET_DIR="."
fi

# Initialize variables
UUT_SRCS=""
WRAPPER_TB=""
TOPLEVEL=""
TEST_MODULE=""
ALIAS=""
REGEN_ONLY=false
# ===== Optional target directory =====
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    TARGET_DIR="$1"
    shift
else
    TARGET_DIR="."
fi

# ===== Parse flags =====
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
        -a|--alias) ALIAS="$2"; shift 2 ;;
        --regen) REGEN_ONLY=true; shift ;;
        -h|--help) show_help ;;
        *) 
            # If no flags, treat as positional args only if exactly 4 remain
            if [ "$#" -eq 4 ]; then
                UUT_SRCS="$1"
                WRAPPER_TB="$2"
                TOPLEVEL="$3"
                TEST_MODULE="$4"
                shift 4
                break
            else
                echo "Unknown option or not enough arguments: $1"
                show_help
            fi
            ;;
    esac
done
# ===== Sanity checks =====
if [ -z "$UUT_SRCS" ]; then
    echo "Error: Must provide at least one UUT source (-s)"
    exit 1
fi

# Auto-generate wrapper/top/module if alias is provided
if [ -n "$ALIAS" ]; then
    WRAPPER_TB="${ALIAS}_wtb"
    TOPLEVEL="${ALIAS}_tb"
    TEST_MODULE="test_${ALIAS}"
else
    if [ -z "$WRAPPER_TB" ] || [ -z "$TOPLEVEL" ] || [ -z "$TEST_MODULE" ]; then
        echo "Error: Must provide -w, -t, -m or use -a"
        exit 1
    fi
fi

# ===== Sanitize inputs =====
UUT_SRCS="$(echo "$UUT_SRCS" | xargs)"
WRAPPER_TB="$(echo "$WRAPPER_TB" | xargs)"
TOPLEVEL="$(echo "$TOPLEVEL" | xargs)"
TEST_MODULE="$(echo "$TEST_MODULE" | xargs)"
VCD_NAME="${TOPLEVEL%_tb}"

# Add .v extension to UUT sources
UUT_SRCS_SANITIZED=""
for src in $UUT_SRCS; do
    [[ "$src" != *.v ]] && src="${src}.v"
    UUT_SRCS_SANITIZED+="$src "
done
UUT_SRCS="$UUT_SRCS_SANITIZED"

WRAPPER_TB="tb/${WRAPPER_TB}"
[[ "$WRAPPER_TB" != *.v ]] && WRAPPER_TB="${WRAPPER_TB}.v"
TEST_MODULE="${TEST_MODULE%.py}"

# ===== Makefile generation =====
NEW_ENV=$([ ! -f "Makefile" ] && echo true || echo false)

cat > Makefile <<EOF
# Auto-generated Makefile
UUT_SRCS     ?= ${UUT_SRCS}
WRAPPER_TB   ?= ${WRAPPER_TB}
TOPLEVEL     ?= ${TOPLEVEL}
TEST_MODULE  ?= ${TEST_MODULE}
RUN          ?= true

CURRENT_DIR := \$(dir \$(abspath \$(lastword \$(MAKEFILE_LIST))))
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
	@if [ -d "tb/__pycache__" ]; then rm -rf tb/__pycache__; fi
	@if [ -d "\$(POST_SIM_DIR)/sim_build" ]; then rm -rf \$(POST_SIM_DIR)/sim_build; fi
	@if [ -d "sim_build" ]; then mv sim_build \$(POST_SIM_DIR)/; fi
	@if ls *.vcd 1>/dev/null 2>&1; then mv -f *.vcd \$(POST_SIM_DIR)/; fi
	@if ls *_results.xml 1>/dev/null 2>&1; then mv -f *_results.xml \$(POST_SIM_DIR)/; fi
	@echo "[INFO] Cleanup complete!"
EOF

[ "$NEW_ENV" = true ] && echo "[SETUP] Generated new Makefile" || echo "[INFO] Regenerated Makefile"

$REGEN_ONLY && exit 0

# ===== Create directories =====
[ ! -d "tb" ] && mkdir -p tb && echo "[SETUP] Created /tb folder"

# ===== Wrapper Verilog file =====
if [ ! -f "${WRAPPER_TB}" ]; then
cat > "${WRAPPER_TB}" <<EOF
\`default_nettype none
\`timescale 1ns / 1ns

module ${TOPLEVEL}();
  reg clk;
  reg rst_n;

  wire input_wire;
  wire output_wire;

  // Instantiate UUT here

  initial begin
    \$dumpfile("${VCD_NAME}.vcd");
    \$dumpvars(0, ${TOPLEVEL});
    #1;
  end
endmodule
EOF
echo "[SETUP] Created ${WRAPPER_TB} template"
else
echo "[INFO] ${WRAPPER_TB} already exists, skipping generation."
fi

# ===== Python test file =====
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
echo "[INFO] tb/${TEST_MODULE}.py already exists, skipping generation."
fi

# ===== Gitignore =====
if [ ! -f ".gitignore" ]; then
cat > .gitignore <<EOF
sim_build/
__pycache__/
*.vvp
*.xml
EOF
echo "[SETUP] Created .gitignore"
fi

echo "[DONE] Environment setup complete!"
