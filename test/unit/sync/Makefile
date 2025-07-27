# (!) - CHANGE THESE WHEN CREATING A NEW TEST 

# =============

UUT_SRCS 	?= Sync				#(!) Source File(s) [add .v to the end of each filename]
WRAPPER_TB 	?= sync_wtb			#(!) Wrapper-Testbench Name		
TOPLEVEL 	?= sync_tb	    	#(!) Toplevel Module (Wrapper module)
TEST_MODULE ?= test_sync		#(!) Python Test Module Filename
RUN 		?= false			
# =============

# Directory Setup for file placement
CURRENT_DIR :=  $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
POST_SIM_DIR := sim

# Set the build directory for Cocotb
#export COCOTB_BUILD_DIR := $(CURRENT_DIR)/sim

# Input Santisation

UUT_SRCS    := $(strip $(UUT_SRCS))
WRAPPER_TB  := tb/$(strip $(WRAPPER_TB))
TOPLEVEL    := $(strip $(TOPLEVEL))
TEST_MODULE := $(strip $(TEST_MODULE))

# Add .v suffix to any list item where it not already present
UUT_SRCS := $(foreach f,$(UUT_SRCS),$(if $(filter .v,$(suffix $(f))),$(f),$(f).v))

# Add .v  to WTB name if not already present
ifneq ($(suffix $(WRAPPER_TB)),.v)
WRAPPER_TB := $(WRAPPER_TB).v
endif

# remove .py from the test module name if present
TEST_MODULE := $(patsubst %.py,%,$(TEST_MODULE))

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

export PYTHONPATH := $(abspath tb)

# INCLUDE WRAPPER TB  
VERILOG_SOURCES += $(TEST_DIR)$(WRAPPER_TB) 	 
VERILOG_SOURCES := $(sort $(VERILOG_SOURCES))    # Sanitise sorce list (remove duplicates)
MODULE =$(TEST_MODULE)

# $(info VERILOG_SOURCES: $(VERILOG_SOURCES))
# name the results file
export COCOTB_RESULTS_FILE=$(TOPLEVEL)_results.xml
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: cleanup 

# Run cocotb test, then clean up artifacts
all: cleanup

# Move artifacts to sim/ folder
cleanup:
	@mkdir -p $(POST_SIM_DIR)
	@echo "[CLEANUP] Cleaning up..."

# deletes pycache

	@if [ -d "tb/__pycache__" ]; then \
		echo "[INFO] Deleting __pycache__"; \
		rm -rf tb/__pycache__; \
		echo "[INFO] Removed __pycache__ directory."; \
	fi

	@if [ -d "$(POST_SIM_DIR)/sim_build" ]; then \
		echo "[INFO] Deleting existing sim_build in $(POST_SIM_DIR)"; \
		rm -rf $(POST_SIM_DIR)/sim_build; \
		echo "[INFO] Deleted sim_build in $(POST_SIM_DIR)."; \
	fi

	@if [ -d "sim_build" ]; then \
		echo "[INFO] Moving new sim_build to $(POST_SIM_DIR)"; \
		mv sim_build $(POST_SIM_DIR)/; \
		echo "[INFO] Moved sim_build to $(POST_SIM_DIR)."; \
	fi

	@echo "[INFO] Moving simulation outputs to $(POST_SIM_DIR)..."
	@if ls *.vcd 1>/dev/null 2>&1; then mv -f *.vcd $(POST_SIM_DIR)/; fi
	@if ls *_results.xml 1>/dev/null 2>&1; then mv -f *_results.xml $(POST_SIM_DIR)/; fi
	@echo "[CLEANUP] Cleanup complete!"