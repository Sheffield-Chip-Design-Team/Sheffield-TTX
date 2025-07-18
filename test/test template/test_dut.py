# SPDX-FileCopyrightText: © 2025 SHaRC - James Ashie Kotey
# SPDX-License-Identifier: Apache-2.0

# Change this filename to sometihing more sensible !

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge, FallingEdge, Timer, First
from random import randint

# Helper functions - keep and reuse these !
async def init_module(uut):
    """ Initialise the module to known clock and reset state
    """
    global clock_running
    
    uut.rst_n.value = 1

    start_clock(uut)
   
def start_clock(uut, period_ns=40):
    """ Start the module clock. 
    """
    global clock_running
    clock_running = True
    uut._log.info(f"Starting clock with period {period_ns} ns")
    clock = Clock(uut.clk, period_ns, units="ns")
    cocotb.start_soon(clock.start())
    uut._log.info(f"clock already running! with period {period_ns} ns")

async def reset(uut, reset_duration=1):
    """  Reset the module. 
    """
    uut._log.info("Resetting Module")
    uut.rst_n.value = 0
    await ClockCycles(uut.clk,reset_duration)
    uut.rst_n.value = 1

def get_state(uut) -> list[int]:
    """ Capture the current state of the module and return it as a list. 
    """
    return [
        uut.hsync.value.integer,
        uut.vsync.value.integer,
        uut.video_active.value.integer,
        uut.pix_x.value.integer,
        uut.pix_y.value.integer,
        uut.frame_end.value.integer
    ]

# Reset Tests
@cocotb.test()
async def test_reset(uut):
    
    uut._log.info("Starting Sync Generator Reset Test")

    # initialise module and start clock
    await init_module(uut)
    await ClockCycles(uut.clk, 1)

    # reset module
    await reset(uut,1)
    uut._log.info("Module Reset Complete")

    # capture module state after the next positive edge
    await RisingEdge(uut.clk)
    state = get_state(uut)
    expected_state = [0, 0, 1, 0, 0, 0]  # Expected state after reset
    assert state == expected_state, (
        f"Sync generator reset state  incorrect: expected {expected_state}, got {state}"
    )

     # resample the state after some 1 cycle
    await ClockCycles(uut.clk, 1)
    state = get_state(uut)
    assert state == [0,0,1,1,0,0], "module did not continue counting as expected!"

    uut._log.info("Reset Condition Test Passed!")
