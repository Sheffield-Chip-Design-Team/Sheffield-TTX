
# ====================== SETUP ======================

SIM            ?= icarus
TOPLEVEL_LANG  ?= verilog
CURRENT_DIR    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC_DIR        := $(CURRENT_DIR)../src
TEST_DIR       := $(CURRENT_DIR)unit
PATTERN        := Makefile

# Project Sources
PROJECT_SOURCES = tt_um_Enjimneering_TTS.v ControlInterface.v Player.v DragonHead.v DragonBody.v PPU.v SpriteROM.v Sync.v CollisionDetector.v DragonTarget.v Heart.v Sheep.v APU.v
VERILOG_SOURCES = $(addprefix $(SRC_DIR)/, $(PROJECT_SOURCES))

export SIM TOPLEVEL_LANG SRC_DIR TEST_DIR PROJECT_SOURCES VERILOG_SOURCES

# ====================== BUILD MODE ======================

ifeq ($(GATES), yes)
SIM_BUILD       = sim_build/gl
COMPILE_ARGS   += -DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
else
SIM_BUILD       = sim_build/rtl
COMPILE_ARGS   += -I$(SRC_DIR)
endif

export SIM_BUILD COMPILE_ARGS

# =================== TEST DISCOVERY ====================

ifeq ($(UNIT), no)
TESTS :=
else
ROOT_DIR := $(shell git rev-parse --show-toplevel)
export ROOT_DIR
TEST_MAKEFILES := $(shell find $(TEST_DIR) -type f -name $(PATTERN))
MAKEFILES_WITH_RUN_FALSE := $(shell grep -iE '^[[:space:]]*RUN[[:space:]]*\??=[[:space:]]*(no|false|n)$$' $(TEST_MAKEFILES))
MAKEFILES_TO_RUN := $(filter-out $(MAKEFILES_WITH_RUN_FALSE), $(TEST_MAKEFILES))
RUN_DIRS := $(sort $(dir $(MAKEFILES_TO_RUN)))
TEST_DIRS := $(sort $(patsubst %/,%,$(patsubst $(TEST_DIR)/%,%,$(RUN_DIRS))))
TESTS ?= $(TEST_DIRS)
endif

# =================== RUN TESTS ====================
SHELL := /bin/bash

ifdef TESTBENCH

TESTBENCH_DIR := $(filter $(TESTBENCH), $(TESTS))

ifeq ($(TESTBENCH_DIR),)
$(error TESTBENCH '$(TESTBENCH)' not found. Available tests: $(TESTS))
endif

run_testbench:
	@mkdir -p sim
	@echo "Running tests in: $(TESTBENCH_DIR)"
	@script -q -c "make -C $(TEST_DIR)/$(TESTBENCH_DIR)" /dev/null \
		| tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" > $(ROOT_DIR)/test/unit/$(TESTBENCH_DIR)/sim/latest.log); \
	EXIT_CODE=$$?; \
	if [ $$EXIT_CODE -ne 0 ]; then \
		echo "Test failed in: $(TESTBENCH_DIR)"; \
	fi
	
endif

# Run all tests (default)
run_all_tests:
	@for dir in $(TEST_DIRS); do \
		echo "Running tests in: $$dir"; \
		mkdir -p $(ROOT_DIR)/test/unit/$$dir/sim; \
		set -o pipefail; \
		script -q -c "make -C $(TEST_DIR)/$$dir" /dev/null \
			| tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" > $(ROOT_DIR)/test/unit/$$dir/sim/latest.log); \
		EXIT_CODE=$$?; \
		if [ $$EXIT_CODE -ne 0 ]; then \
			echo "Test failed in: $$dir"; \
		fi; \
	done
	@echo "Finished all tests!"

# =================== CLEAN ====================
clean:
	@for d in $(TESTS); do \
		echo "Cleaning... $$d"; \
		$(MAKE) -C $(TEST_DIR)/$$d clean || true; \
		echo "Finished cleaning: $$d"; \
	done

# =================== PHONY & DEFAULT ====================
.PHONY: run_all_tests run_testbench clean all

ifdef TESTBENCH
all: run_testbench clean
else
all: run_all_tests clean
endif
