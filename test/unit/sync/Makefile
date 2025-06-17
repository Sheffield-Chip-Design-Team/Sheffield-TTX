# ! CHANGE THESE WHEN CREATING A NEW TEST !

UUT_SRCS ?= Sync.v		# Source File
TB ?= sync_tb.v			# Testbench Name
TOPLEVEL ?= sync_tb		# Toplevel module (Testbench)

# =============

TEST_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Allow direct test run
ifeq ($(MAKELEVEL),0)
# $(info Including Project Sources Manually...)

SRC_DIR := $(dir $(abspath $(TEST_DIR)/../../))
# $(info Source Directory: $(SRC_DIR))

PROJECT_SOURCES = $(addprefix $(SRC_DIR)/src/,$(UUT_SRCS))
# $(info Project Sources: $(PROJECT_SOURCES) )

VERILOG_SOURCES += $(PROJECT_SOURCES)
export SRC_DIR PROJECT_SOURCES VERILOG_SOURCES   # export sources so they save in recursion
endif

# if running from master Makefile, these environment variables
VERILOG_SOURCES += $(TEST_DIR)sync_tb.v  	   # Add testbench name here 
VERILOG_SOURCES := $(sort $(VERILOG_SOURCES))
MODULE=test_sync  

# $(info VERILOG_SOURCES: $(VERILOG_SOURCES))

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

