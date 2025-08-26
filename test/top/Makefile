# Makefile for top level tests

WRAPPER_TB   ?= tb/top_wtb.v
TOPLEVEL     ?= top_tb
TEST_MODULE  ?= test_top
RUN          ?= true

CURRENT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ifeq ($(GATES), yes)
POST_SIM_DIR := $(CURRENT_DIR)/../
else
POST_SIM_DIR := sim
endif


TEST_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ifeq ($(MAKELEVEL),0)
ROOT_DIR := $(dir $(abspath $(TEST_DIR)/../))
PROJECT_SOURCES = $(addprefix $(ROOT_DIR)src/,$(UUT_SRCS))
VERILOG_SOURCES += $(PROJECT_SOURCES)
export SRC_DIR PROJECT_SOURCES VERILOG_SOURCES
endif

export PYTHONPATH := $(abspath tb)
VERILOG_SOURCES += $(TEST_DIR)$(WRAPPER_TB)
VERILOG_SOURCES := $(sort $(VERILOG_SOURCES))
MODULE = $(TEST_MODULE)
export COCOTB_RESULTS_FILE=$(TEST_DIR)/../results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: run cleanup sim

all: sim cleanup

cleanup:
	@mkdir -p $(POST_SIM_DIR)
	@echo "[CLEANUP] Cleaning up..."
	@if [ -d "tb/__pycache__" ]; then rm -rf tb/__pycache__; fi
	@if [ -d "$(POST_SIM_DIR)/sim_build" ]; then rm -rf $(POST_SIM_DIR)/sim_build; fi
	@if [ -d "sim_build" ]; then mv sim_build $(POST_SIM_DIR)/; fi
	@if ls *.vcd 1>/dev/null 2>&1; then mv -f *.vcd $(POST_SIM_DIR)/; fi
	@if ls *_results.xml 1>/dev/null 2>&1; then mv -f *_results.xml $(POST_SIM_DIR)/; fi
	@echo "[INFO] Cleanup complete!"
