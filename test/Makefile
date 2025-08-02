# Testing Master Makefile

# =============== SETUP ================= #

# Simulator setup
SIM 		   ?= icarus
TOPLEVEL_LANG  ?= verilog
# Directory setup
CURRENT_DIR    :=  $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC_DIR         =  $(CURRENT_DIR)../src
TEST_DIR        =  $(CURRENT_DIR)unit
$(info TEST_ROOT = $(TEST_DIR))

# Test Disccdovery 
PATTERN := Makefile               # file that marks a test folder 

# Define and Export Sources  (UPDATE WHEN A NEW FILE IS ADDED!)
PROJECT_SOURCES = tt_um_Enjimneering_TTS.v ControlInterface.v Player.v DragonHead.v DragonBody.v PPU.v SpriteROM.v Sync.v CollisionDetector.v DragonTarget.v Heart.v Sheep.v APU.v
VERILOG_SOURCES = $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

export SIM
export TOPLEVEL_LANG
export SRC_DIR
export TEST_DIR
export PROJECT_SOURCES

# ──────────────────────────────────────── #
# ============== Testing ================= #

# if NOT a Gate Level Test
ifneq ($(GATES), yes) 

# RTL Unit test simulation

SIM_BUILD		    = sim_build/rtl
COMPILE_ARGS 		+= -I$(SRC_DIR)

export SIM_BUILD
export VERILOG_SOURCES
export COMPILE_ARGS

# if the unit test flag is set
ifneq ($(UNIT), no)

# DISCOVER TESTS #

# 1:  Find every Makefile below $(TEST_DIR)
TEST_MAKEFILES := $(shell find $(TEST_DIR) -type f -name $(PATTERN))
$(info TEST_MAKEFILES = '$(TEST_MAKEFILES)')

# 2: Exclude any Makefiles that explicitly say RUN = no, false, n (case-insensitive)
MAKEFILES_WITH_RUN_FALSE := $(shell grep -iE '^[[:space:]]*RUN[[:space:]]*\??=[[:space:]]*(no|false|n)$$' $(TEST_MAKEFILES))

# 3: Subtract false Makefiles from all Makefiles
MAKEFILES_TO_RUN := $(filter-out $(MAKEFILES_WITH_RUN_FALSE), $(TEST_MAKEFILES))

#  3: Extract unique directories
RUN_DIRS := $(sort $(dir $(MAKEFILES_TO_RUN)))

# 4:  Strip the root path  e.g. (sync ppu apu player)
TEST_DIRS := $(sort $(patsubst %/,%,$(patsubst $(TEST_DIR)/%,%,$(dir $(MAKEFILES_TO_RUN)))))

TESTS ?= $(TEST_DIRS)
$(info TEST LOCATIONS = '$(TESTS)')

#  RUN TESTS  #

run_all_tests:
	@$(foreach dir, $(TEST_DIRS), \
		echo "Running tests in $(dir)" && \
			$(MAKE) -C /$(TEST_DIR)/$(dir) || echo "Test failed in $(dir)."; \
	)

# .PHONY: $(TEST_DIRS) all

# # Run all tests (ignore errors)
# $(TEST_DIRS):\
# 	-$(MAKE) -C $(TEST_DIR)/$@ || true

# Default target = run all chosen tests
all: $(TESTS) 

# clean all tests
.PHONY: clean
clean:
	@for d in $(TESTS); do \
	$(MAKE) -C $(TEST_DIR)/$$d clean || true; \
	done

endif

else

# Gate level simulation:
SIM_BUILD		= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

.PHONY: all
all:
	$(MAKE) run_all_tests GATES=yes UNIT=yes

endif

