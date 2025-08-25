# ====================== SETUP ======================

SIM            ?= icarus
TOPLEVEL_LANG  ?= verilog
CURRENT_DIR    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC_DIR        := $(CURRENT_DIR)../src
TEST_DIR       := $(CURRENT_DIR)unit
PATTERN        := Makefile

# Project Sources .. Add new modules here!
PROJECT_SOURCES = tt_um_Enjimneering_TTS.v ControlInterface.v Player.v DragonHead.v DragonBody.v PPU.v SpriteROM.v Sync.v CollisionDetector.v DragonTarget.v Heart.v Sheep.v APU.v Input/GamepadReceiver.v

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
VERILOG_SOURCES = $(addprefix $(SRC_DIR)/, $(PROJECT_SOURCES))
endif
export SIM_BUILD COMPILE_ARGS
export GATES

export SIM TOPLEVEL_LANG SRC_DIR TEST_DIR PROJECT_SOURCES VERILOG_SOURCES
# =================== TEST DISCOVERY ====================

ROOT_DIR := $(shell git rev-parse --show-toplevel)
export ROOT_DIR

TEST_MAKEFILES := $(shell find $(TEST_DIR) -type f -name $(PATTERN))
MAKEFILES_WITH_RUN_FALSE := $(shell grep -iE '^[[:space:]]*RUN[[:space:]]*\??=[[:space:]]*(no|false|n)$$' $(TEST_MAKEFILES))
MAKEFILES_TO_RUN := $(filter-out $(MAKEFILES_WITH_RUN_FALSE), $(TEST_MAKEFILES))
RUN_DIRS := $(sort $(dir $(MAKEFILES_TO_RUN)))
TEST_DIRS := $(sort $(patsubst %/,%,$(patsubst $(TEST_DIR)/%,%,$(RUN_DIRS))))
TESTS ?= $(TEST_DIRS)

# If user specified TESTBENCH, only run that
ifdef TESTBENCH
TESTBENCH_DIR := $(TESTBENCH)
endif

# =================== RUN TEST FUNCTIONS ====================
SHELL := /bin/bash

define run_top_tests
	@mkdir -p $(ROOT_DIR)/test/top/sim; \
	echo "Running top level tests"; \
	script -q -c "make -C $(ROOT_DIR)/test/top" /dev/null \
		| tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" > $(ROOT_DIR)/test/top/sim/latest.log); \
	EXIT_CODE=$$?; \
	if [ $$EXIT_CODE -ne 0 ]; then \
		echo "Top-level tests FAILED!"; \
	fi
	echo "Finished running top level tests!"
endef

define run_unit_test
	@mkdir -p $(ROOT_DIR)/test/unit/$(TESTBENCH_DIR)/sim; \
	echo "Running unit tests in: $(TESTBENCH_DIR)"; \
	script -q -c "make -C $(TEST_DIR)/$(TESTBENCH_DIR)" /dev/null \
		| tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" > $(ROOT_DIR)/test/unit/$(TESTBENCH_DIR)/sim/latest.log); \
	EXIT_CODE=$$?; \
	if [ $$EXIT_CODE -ne 0 ]; then \
		echo "Unit test FAILED in: $(TESTBENCH_DIR)"; \
	fi
endef

define run_all_unit_tests
	@for dir in $(TEST_DIRS); do \
		echo "Running unit tests in: $$dir"; \
		mkdir -p $(ROOT_DIR)/test/unit/$$dir/sim; \
		set -o pipefail; \
		script -q -c "make -C $(TEST_DIR)/$$dir" /dev/null \
			| tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" > $(ROOT_DIR)/test/unit/$$dir/sim/latest.log); \
		EXIT_CODE=$$?; \
		if [ $$EXIT_CODE -ne 0 ]; then \
			echo "Unit test FAILED in: $$dir"; \
		fi; \
	done; \
	echo "Finished all unit tests!"
endef

define run_all_tests
	echo "running all tests!"
	$(call run_all_unit_tests)
	$(call run_top_tests)
endef

# =================== TARGETS ====================

# =================== PHONY ====================
.PHONY: run_top_tests_target run_unit_test_target run_all_unit_tests_target run_all_tests_target clean all

# =================== DEFAULT ====================

all:
ifeq ($(GATES),yes)
	$(call run_top_tests)
else ifeq ($(TESTBENCH),top)
	$(call run_top_tests)
else ifdef TESTBENCH
	$(call run_unit_test)
else
	$(call run_all_tests)
endif

# =================== CLEAN ====================
clean:
	@echo "Cleaning all test directories..."
	@for d in $(TESTS); do \
		echo "Cleaning... $$d"; \
		$(MAKE) -C $(TEST_DIR)/$$d clean || true; \
		echo "Finished cleaning: $$d"; \
	done
	@echo "Cleaning top-level test..."
	@$(MAKE) -C $(ROOT_DIR)/test/top clean || true

