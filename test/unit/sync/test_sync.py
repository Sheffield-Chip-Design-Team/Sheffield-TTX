# SPDX-FileCopyrightText: © 2025 SHaRC - James Ashie Kotey
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge, FallingEdge, Timer, First
from random import randint

# 640 X 480 Timing Constants

# Horizontal
H_DISPLAY = 640  # Horizontal display width
H_BACK = 48      # Horizontal left border (back porch)
H_FRONT = 16     # Horizontal right border (front porch)
H_SYNC = 96      # Horizontal sync width

# Derrived Values
H_MAX =  799        # H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1
H_SYNC_START = 656  # H_DISPLAY + H_FRONT
H_SYNC_END = 751    # H_DISPLAY + H_FRONT + H_SYNC - 1

# Vertical 
V_DISPLAY = 480  # Vertical display height
V_TOP = 33       # Vertical top border
V_BOTTOM = 10    # Vertical bottom border
V_SYNC = 2       # Vertical sync width (number of lines)

# Derrived Values
V_MAX = 524     # V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1
V_SYNC_START = 490  # V_DISPLAY + V_BOTTOM
V_SYNC_END = 491    # V_DISPLAY + V_BOTTOM + V_SYNC - 1

clock_running = False

# Helper functions 
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

# @cocotb.test()
# async def test_reset_random(uut):
    
#     uut._log.info("Starting Sync Generator Randomized Reset Test")

#     pre_reset_duration  = randint(1, H_MAX-1)
#     reset_duration      = randint(1, H_MAX-1)
#     post_reset_duration = randint(1, H_MAX-1)

#     # initialise module and start clock
#     await init_module(uut)
#     await ClockCycles(uut.clk, pre_reset_duration)
    
#     # reset module
#     await reset(uut,reset_duration)
#     uut._log.info("Module Reset Complete")

#     # capture module state after the next positive edge
#     await RisingEdge(uut.clk)
#     state = get_state(uut)
#     assert state == [0,0,1,0,0,0], "module reset incorrectly!"

#      # resample the state after some more cycles
#     await ClockCycles(uut.clk, post_reset_duration)
#     state = get_state(uut)
#     expected_state = [
#                 1 if H_SYNC_START <= state[3] < H_SYNC_END else 0,  # hsync
#                 1 if V_SYNC_START <= state[4] < V_SYNC_END else 0,  # vsync
#                 1 if (0 <= state[3] < H_DISPLAY and 0 <= state[4] < V_DISPLAY) else 0,  # video_active
#                 state[3],  # pix_x
#                 state[4],  # pix_y
#                 1 if (state[3] == 0 and state[4] == 0) else 0  # frame_end
#     ]
#     assert state == expected_state, f"State mismatch! Expected: {expected_state}, Got: {state}"


#     assert state == [0,0, 1, post_reset_duration ,0,0], "module did not continue counting as expected!"

#     uut._log.info("Reset Condition Test Passed!")

# Pixel Counters

# @cocotb.test()
# async def test_horizontal_counter_random(uut):
#     """
#     Constrained random test for the horizontal pixel counter (pix_x).
#     Randomly waits for a number of clock cycles and verifies pix_x behavior.
#     """
#     uut._log.info("Starting Constrained Random Pixel X Counter Test")

#     await init_module(uut)
#     # Reset the module
#     await reset(uut)
#     uut._log.info("Module Reset Complete")

#     # Generate a random number of clock cycles to wait
#     random_cycles = randint(1, H_MAX * 2)  # Constrain to 2 horizontal line periods
#     uut._log.info(f"Waiting for {random_cycles} clock cycles before checking pix_x")

#     # Wait for the random number of clock cycles
#     await ClockCycles(uut.clk, random_cycles)

#     # Capture the current pix_x value
#     pix_x_value = uut.pix_x.value.integer
#     uut._log.info(f"Pixel X value after {random_cycles} cycles: {pix_x_value}")

#     # Calculate the expected pix_x value 

#     if random_cycles % H_MAX  < H_DISPLAY:
#         expected_pix_x = random_cycles % (H_DISPLAY- 1)
#     else:
#         expected_pix_x = 0

#     # Assert that pix_x matches the expected value
#     assert pix_x_value == expected_pix_x, (
#         f"Pixel X counter incorrect: expected {expected_pix_x}, got {pix_x_value}"
#     )

#     uut._log.info("Constrained Random Pixel X Counter Test Passed!")

@cocotb.test()
async def test_vertical_counter_random(uut):
    """
    Constrained random test for the vertical pixel counter (pix_y).
    Randomly waits for a number of clock cycles and verifies pix_y behavior.
    """
    uut._log.info("Starting Constrained Random Pixel Y Counter Test")

    await init_module(uut)
    
    # Reset the module
    await reset(uut)
    uut._log.info("Module Reset Complete")

    # Generate a random number of clock cycles to wait
    random_cycles = randint(1, H_MAX * 50)  # Constrain to 50 vertical line periods
    uut._log.info(f"Waiting for {random_cycles} clock cycles before checking pix_y")

    # Wait for the random number of clock cycles
    await ClockCycles(uut.clk, random_cycles)

    # Capture the current pix_x value
    pix_y_value = uut.pix_y.value.integer
    uut._log.info(f"Pixel X value after {random_cycles} cycles: {pix_y_value}")

    # Calculate the expected pix_x value (sticks to the end)
    expected_pix_y = min((random_cycles // (H_MAX + 1)) % (V_MAX + 1), V_DISPLAY - 1)

    # Assert that pix_x matches the expected value
    assert pix_y_value == expected_pix_y, (
        f"Pixel X counter incorrect: expected {expected_pix_y}, got {pix_y_value}"
    )

    uut._log.info("Constrained Random Pixel X Counter Test Passed!")

# H-sync Tests

# @cocotb.test()
# async def test_hsync_start(uut):
#     """
#     Test that the hsync signal starts at the correct horizontal position (H_SYNC_START).
#     """
#     uut._log.info("Starting HSync Start Time Test")

#     # Initialize the module
#     await init_module(uut)

#     # Reset the module
#     await reset(uut)
#     uut._log.info("Module Reset Complete")

#     # Wait for the horizontal position (pix_x) to reach H_SYNC_START with a timeout
#     timeout = Timer(0.1, units="ms")  # 0.5 ms timeout to prevent infinite loops
#     while uut.sync_gen.hpos.value.integer != H_SYNC_START:
#         await First(RisingEdge(uut.clk), timeout)

#     # Verify that hsync is asserted (high) at H_SYNC_START
#     hsync_value = uut.hsync.value
#     assert hsync_value == 1, f"HSync should be high at H_SYNC_START={H_SYNC_START}, but got {hsync_value}"

#     uut._log.info(f"HSync correctly started at H_SYNC_START={H_SYNC_START}")

#     # Verify that hsync remains high for the duration of the sync pulse
#     for _ in range(H_SYNC):
#         await RisingEdge(uut.clk)
#         assert uut.hsync.value == 1, f"HSync should remain high during sync pulse, but got {uut.hsync.value}"

#     uut._log.info("HSync Start Time Test Passed!")

# @cocotb.test()
# async def test_hsync_duration(uut):
#     """
#     Test that the hsync signal lasts for exactly 1 clock cycle.
#     """
#     uut._log.info("Starting HSync Duration Test")

#     await init_module(uut)

#     # Reset the module
#     await reset(uut)
#     uut._log.info("Module Reset Complete")

#     # Wait until the start of the vsync pulse
#     while uut.hsync.value != 1:
#         await RisingEdge(uut.clk)

#     uut._log.info("HSync pulse started")

#     # Count the number of clk cycles pulses during the hsync pulse
#     clk_count = 0
#     while uut.hsync.value == 1:
#         await RisingEdge(uut.clk)
#         clk_count += 1

#     uut._log.info(f"VSync pulse ended after {clk_count} hsync pulses")

#     # Assert that vsync lasted for exactly one hsync pulses
#     assert clk_count == 1, f"VSync duration incorrect: expected 1 hsync pulses, got {clk_count}"

#     uut._log.info("HSync Duration Test Passed!")

@cocotb.test() 
async def test_hsync_random(uut):
    """
    Constrained random test for hsync signal timing.
    Randomly waits for a number of clock cycles and checks hsync behavior.
    """
    uut._log.info("Starting Constrained Random HSync Test")

    await init_module(uut)

    # Reset the module
    await reset(uut)
    uut._log.info("Module Reset Complete")

    # Generate a random number of clock cycles to wait (constrained range)
    random_cycles = randint(1, H_MAX * 2)  # Constrain to 2 horizontal line periods
    uut._log.info(f"Waiting for {random_cycles} clock cycles before checking hsync")

    # Wait for the random number of clock cycles
    await ClockCycles(uut.clk, random_cycles)

    # Capture the hsync signal value
    hsync_value = uut.hsync.value
    hpos = uut.sync_gen.hpos.value.integer  # Current horizontal position
    uut._log.info(f"HSync value after {random_cycles} cycles: {hsync_value}, hpos: {hpos}")

    # Assert that hsync behaves as expected
    # Check if hsync is high during the sync pulse
    if H_SYNC_START <= hpos <= H_SYNC_END:
        assert hsync_value == 1, f"HSync should be high during sync pulse at hpos={hpos}, but got {hsync_value}"
    else:
        assert hsync_value == 0, f"HSync should be low outside sync pulse at hpos={hpos}, but got {hsync_value}"

    uut._log.info("Constrained Random HSync Test Passed!")

# # V-sync Tests
# @cocotb.test()
# async def test_vsync_start(uut):
#     """
#     Test that the vsync signal starts at the correct vertical position (V_SYNC_START).
#     """
#     uut._log.info("Starting VSync Start Time Test")

#     # Initialize the module
#     await init_module(uut)

#     # Reset the module
#     await reset(uut)
#     uut._log.info("Module Reset Complete")

#     # Wait for the vertical position (pix_y) to reach V_SYNC_START with a timeout
#     timeout = Timer(0.1, units="ms")  # 0.5 ms timeout to prevent infinite loops
#     while uut.sync_gen.vpos.value.integer != V_SYNC_START:
#         await First(RisingEdge(uut.clk), timeout)

#     # Verify that vsync is asserted (high) at V_SYNC_START
#     vsync_value = uut.vsync.value
#     assert vsync_value == 1, f"VSync should be high at V_SYNC_START={V_SYNC_START}, but got {vsync_value}"

#     uut._log.info(f"VSync correctly started at V_SYNC_START={V_SYNC_START}")

#     # Verify that vsync remains high for the duration of the sync pulse
#     for _ in range(V_SYNC):
#         await RisingEdge(uut.clk)
#         assert uut.vsync.value == 1, f"VSync should remain high during sync pulse, but got {uut.vsync.value}"

#     uut._log.info("VSync Start Time Test Passed!")

# @cocotb.test()
# async def test_vsync_duration(uut):
#     """
#     Test that the vsync signal lasts for exactly two hsync pulses.
#     """
#     uut._log.info("Starting VSync Duration Test")

#     await init_module(uut)

#     # Reset the module
#     await reset(uut)
#     uut._log.info("Module Reset Complete")

#     # Wait until the start of the vsync pulse
#     while uut.vsync.value != 1:
#         await RisingEdge(uut.clk)

#     uut._log.info("VSync pulse started")

#     # Count the number of hsync pulses during the vsync pulse
#     hsync_count = 0
#     while uut.vsync.value == 1:
#         await RisingEdge(uut.hsync)
#         hsync_count += 1

#     uut._log.info(f"VSync pulse ended after {hsync_count} hsync pulses")

#     # Assert that vsync lasted for exactly two hsync pulses
#     assert hsync_count == 2, f"VSync duration incorrect: expected 2 hsync pulses, got {hsync_count}"

#     uut._log.info("VSync Duration Test Passed!")

@cocotb.test()
async def test_vsync_random(uut):
    """ Constrained random test for vsync signal.
    Randomly waits for a number of clock cycles and checks vsync behavior.
    """

    CYCLE_LIMIT = V_MAX * H_MAX  # Number of cycles in a complete frame

    uut._log.info("Starting Constrained Random VSync Test")
    
    await init_module(uut)
    # Reset the module
    await reset(uut)
    uut._log.info("Module Reset Complete")

    # Generate a random number of clock cycles to wait (constrained range)
    random_cycles = randint(1, CYCLE_LIMIT)  # Constrain to 2 vertical frame periods
    uut._log.info(f"Waiting for {random_cycles} clock cycles before checking vsync")

    # Wait for the random number of clock cycles
    await ClockCycles(uut.clk, random_cycles)

    # Capture the vsync signal value
    vsync_value = uut.vsync.value
    uut._log.info(f"VSync value after {random_cycles} cycles: {vsync_value}")

    # Assert that vsync behaves as expected
    # For example, check if vsync is high during the sync pulse
    if random_cycles % V_MAX >= V_SYNC_START and random_cycles % V_MAX <= V_SYNC_END:
        assert vsync_value == 1, f"VSync should be high during sync pulse, but got {vsync_value}"
    else:
        assert vsync_value == 0, f"VSync should be low outside sync pulse, but got {vsync_value}"

    uut._log.info("Constrained Random VSync Test Passed!")
