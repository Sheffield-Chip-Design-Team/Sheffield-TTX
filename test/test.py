# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

expected = [0,1,1,2,1,2,2,3]

@cocotb.test()
async def test_project(dut):
    
    dut._log.info("Full Adder Test")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 1, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    
   # await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    for i in range(8):
        dut.ui_in.value = i
        await ClockCycles(dut.clk, 2)
        dut._log.info(i)
        dut._log.info("Test Vector Accepted.")
        assert dut.uo_out.value == expected[i]
        
    dut._log.info("Test Complete")
  
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
   
    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
