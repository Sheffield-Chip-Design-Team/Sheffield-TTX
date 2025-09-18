import cocotb
from random import randint
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

async def reset(uut, reset_duration=randint(1,10)):
    # assert reset
    uut._log.info("Resetting Module")
    uut.reset.value = 1
    await ClockCycles(uut.clk, reset_duration)
    uut.reset.value = 0

async def dummy_sync(uut):
    while True:
        await ClockCycles(uut.clk, 10)
        uut.frame_end.value = 1
        await ClockCycles(uut.clk, 1)
        uut.frame_end.value = 0

@cocotb.test() # pyright: ignore[reportCallIssue]
async def test_player_sanity(uut):
    
    uut.attack.value = 0
    uut.up.value = 0
    uut.down.value = 0
    uut.left.value = 0
    uut.right.value = 0
    uut.frame_end.value = 0

    # start clock
    clock = Clock(uut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
   
    # reset the module
    await reset(uut)
    await RisingEdge(uut.clk)

    cocotb.start_soon(dummy_sync(uut))
    await ClockCycles(uut.clk, 25)
    uut.right.value = 1
    await ClockCycles(uut.clk, 20)
    uut.right.value = 0
    
    await ClockCycles(uut.clk, 25)
    uut.down.value = 1
    await ClockCycles(uut.clk, 20)
    uut.down.value = 0

    await ClockCycles(uut.clk, 25)
    uut.right.value = 1
    uut.attack.value = 1
    await ClockCycles(uut.clk, 20)
    uut.attack.value = 0

    # continue test ...
    await ClockCycles(uut.clk, 80)
    uut._log.info("Test Complete!")

