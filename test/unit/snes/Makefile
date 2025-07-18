# (!) - CHANGE THESE WHEN CREATING A NEW TEST 

# =============

UUT_SRCS 	?= Sync			#(!) Source File(s) [add .v to the end of each filename]
WRAPPER_TB 	?= sync_wtb		#(!) Wrapper-Testbench Name		
TOPLEVEL 	?= sync_tb	    #(!) Toplevel Module (Wrapper module)
TEST_MODULE ?= test_sync	#(!) Python Test Module Filename

# =============

# Input Santisation

UUT_SRCS := $(strip $(UUT_SRCS))
WRAPPER_TB := $(strip $(WRAPPER_TB))
TOPLEVEL := $(strip $(TOPLEVEL))
TEST_MODULE := $(strip $(TEST_MODULE))

# Add .v suffix to any list item where it not already present
UUT_SRCS := $(foreach f,$(UUT_SRCS),$(if $(filter .v,$(suffix $(f))),$(f),$(f).v))

# Add .v  to WTB name if not already present
ifneq ($(suffix $(WRAPPER_TB)),.v)
WRAPPER_TB := $(WRAPPER_TB).v
endif

# Directory variable
TEST_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# RUN TESTS

# Allow direct test run from test folder - setup environment variables.
ifeq ($(MAKELEVEL),0)
# $(info Including Project Sources Manually...)

ROOT_DIR := $(dir $(abspath $(TEST_DIR)/../../))
# $(info ROOT_DIR Directory: $(ROOT_DIR))

PROJECT_SOURCES = $(addprefix $(ROOT_DIR)/src/,$(UUT_SRCS))
# $(info Project Sources: $(PROJECT_SOURCES) )

# INCLUDE UUT SOURCES 
VERILOG_SOURCES += $(PROJECT_SOURCES)
export SRC_DIR PROJECT_SOURCES VERILOG_SOURCES   # export sources so they save in recursion
endif

# INCLUDE WRAPPER TB  
VERILOG_SOURCES += $(TEST_DIR)$(WRAPPER_TB) 	 
VERILOG_SOURCES := $(sort $(VERILOG_SOURCES))    # Sanitise sorce list (remove duplicates)
MODULE=$(TEST_MODULE)  

# $(info VERILOG_SOURCES: $(VERILOG_SOURCES))

# name the results file
export COCOTB_RESULTS_FILE=$(TOPLEVEL)_results.xml

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
