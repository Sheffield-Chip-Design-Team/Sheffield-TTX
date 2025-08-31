import cocotb
from random import randint
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer


async def reset(dut, reset_duration=5):
    dut._log.info("Resetting Module")
    dut.reset.value = 1
    await ClockCycles(dut.clk, reset_duration)
    dut.reset.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_behavior(dut):
    """Check that after reset the sound output is 0"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for _ in range(5):
        await RisingEdge(dut.clk)
        assert dut.sound.value == 0, "Sound should be 0 right after reset"


@cocotb.test()
async def test_no_collision_silence(dut):
    """Ensure no sound is produced if no collisions occur"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    dut.SheepDragonCollision.value = 0
    dut.SwordDragonCollision.value = 0
    dut.PlayerDragonCollision.value = 0
    dut.x.value = 0
    dut.y.value = 0

    silent = True
    for _ in range(100):
        await RisingEdge(dut.clk)
        if dut.sound.value:
            silent = False
            break
    assert silent, "Sound was produced without any collision!"


@cocotb.test()
async def test_sheep_collision_duration(dut):
    """Sheep collision should produce sustained sound"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    dut.SheepDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.SheepDragonCollision.value = 0

    active_cycles = 0
    for _ in range(2000):
        await RisingEdge(dut.clk)
        if dut.sound.value:
            active_cycles += 1
    assert active_cycles > 50, f"Sheep sound too short ({active_cycles} cycles)"


@cocotb.test()
async def test_sheep_collision_cooldown(dut):
    """Verify cooldown prevents retrigger of sheep SFX before cooldown expires"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # First trigger
    dut.SheepDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.SheepDragonCollision.value = 0

    # Let sound run its course (dragon_duration ≈ 3000 cycles)
    await ClockCycles(dut.clk, 4000)

    # Now still in cooldown (3,000,000 cycles!)
    dut.SheepDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.SheepDragonCollision.value = 0

    # Watch a window of cycles to check if retrigger happens (should NOT)
    retriggered = False
    for _ in range(5000):  # small window << cooldown length
        await RisingEdge(dut.clk)
        if dut.sound.value:
            retriggered = True
            break

    assert not retriggered, "Cooldown failed: Sheep sound retriggered before cooldown expired"

@cocotb.test()
async def test_sword_collision_cooldown(dut):
    """Verify cooldown prevents retrigger of sword SFX before cooldown expires"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # First trigger
    dut.SwordDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.SwordDragonCollision.value = 0

    # Let sound run its course (duration ≈ 1800 cycles)
    await ClockCycles(dut.clk, 2500)

    # Still in cooldown
    dut.SwordDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.SwordDragonCollision.value = 0

    retriggered = False
    for _ in range(2000):  # shorter window, cooldown ≈ 1800
        await RisingEdge(dut.clk)
        if dut.sound.value:
            retriggered = True
            break

    assert not retriggered, "Cooldown failed: Sword sound retriggered before cooldown expired"


@cocotb.test()
async def test_player_collision_cooldown(dut):
    """Verify cooldown prevents retrigger of player SFX before cooldown expires"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # First trigger
    dut.PlayerDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.PlayerDragonCollision.value = 0

    # Let sound run its course (duration ≈ 1500 cycles)
    await ClockCycles(dut.clk, 2200)

    # Still in cooldown
    dut.PlayerDragonCollision.value = 1
    await RisingEdge(dut.clk)
    dut.PlayerDragonCollision.value = 0

    retriggered = False
    for _ in range(2000):  # cooldown ≈ 1500
        await RisingEdge(dut.clk)
        if dut.sound.value:
            retriggered = True
            break

    assert not retriggered, "Cooldown failed: Player sound retriggered before cooldown expired"
    
@cocotb.test()
async def test_all_triggers_overlap(dut):
    """Trigger all three collisions simultaneously and check sound output"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Turn all collisions on at the same time
    dut.SheepDragonCollision.value = 1
    dut.SwordDragonCollision.value = 1
    dut.PlayerDragonCollision.value = 1
    dut.x.value = 0
    dut.y.value = 0

    await RisingEdge(dut.clk)
    
    # Turn off the collisions immediately after triggering
    dut.SheepDragonCollision.value = 0
    dut.SwordDragonCollision.value = 0
    dut.PlayerDragonCollision.value = 0

    # Check that sound occurs for at least a few cycles
    sound_detected = False
    for _ in range(2000):
        await RisingEdge(dut.clk)
        if dut.sound.value:
            sound_detected = True
            dut._log.info(f"Sound active at cycle {_} when all triggers overlapped")
            break

    assert sound_detected, "Sound did not occur when all triggers were active"

    # Continue clock until sound goes low
    sound_off_detected = False
    for _ in range(5000):
        await RisingEdge(dut.clk)
        if not dut.sound.value:
            sound_off_detected = True
            dut._log.info(f"Sound went low at cycle {_} after collisions ended")
            break

    assert sound_off_detected, "Sound did not turn off after collisions ended"
