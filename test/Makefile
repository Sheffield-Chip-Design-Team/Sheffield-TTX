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
ifneq ($(GATES),yes) 

# RTL simulation

SIM_BUILD		    = sim_build/rtl
COMPILE_ARGS 		+= -I$(SRC_DIR)

export SIM_BUILD
export VERILOG_SOURCES
export COMPILE_ARGS

# DISCOVER TESTS #

# 1.  Find every Makefile below $(TEST_DIR)
TEST_MAKEFILES := $(shell find $(TEST_DIR) -type f -name $(PATTERN))
$(info TEST_MAKEFILES = '$(TEST_MAKEFILES)')

# 2.  Strip the root path  e.g. (sync  ppu apu player)
TEST_DIRS := $(sort $(patsubst $(TEST_DIR)/%,%,$(dir $(TEST_MAKEFILES))))

TESTS ?= $(TEST_DIRS)
$(info TEST LOCATIONS = '$(TESTS)')

#  RUN TESTS  #

.PHONY: $(TEST_DIRS) all

# Run all tests (ignore errors)
$(TEST_DIRS):
	-$(MAKE) -C $(TEST_DIR)/$@ 

# Default target = run all chosen tests
all: $(TESTS) 


# clean all tests
.PHONY: clean
clean:
	@for d in $(TESTS); do \
	$(MAKE) -C $(TEST_DIR)/$$d clean || true; \
	done

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

endif

