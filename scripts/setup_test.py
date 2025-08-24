#!/usr/bin/env python3
import argparse
from parse import *

def generate_cocotb_test(module_name, ports, test_name):
    clk_signal = next((p[2] for p in ports if any(x in p[2].lower() for x in ['clk', 'clock'])), None)
    rst_signal = next((p[2] for p in ports if any(x in p[2].lower() for x in ['rst', 'reset'])), None)
    
    sanity_name = test_name.removeprefix("test_")

    if not clk_signal or not rst_signal:
        return f"#[TESTGEN] Cannot auto-generate cocotb test for {module_name}: clock or reset not found.\n"

    print(f"[TESTGEN] clock and reset found in {module_name}: {clk_signal}, {rst_signal}")

    # Check if reset signal is active-low (ends with '_n')
    active_low_reset = rst_signal.lower().endswith('_n')
    if (active_low_reset):
        start_rst = 0
        end_rst = 1
    else:
        start_rst = 1
        end_rst = 0

    test_file = f"tb/{test_name.lower()}.py"
    template = f"""import cocotb
from random import randint
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

async def reset(uut, reset_duration=randint(1,10)):
    # assert reset
    uut._log.info("Resetting Module")
    uut.{rst_signal}.value = {start_rst}
    await ClockCycles(uut.{clk_signal}, reset_duration)
    uut.{rst_signal}.value = {end_rst}

@cocotb.test()
async def test_{sanity_name}_sanity(uut):
    # start clock
    clock = Clock(uut.{clk_signal}, 40, units="ns")
    cocotb.start_soon(clock.start())
    await ClockCycles(uut.{clk_signal}, 1)
   
    # reset the module
    await reset(uut)
    await RisingEdge(uut.{clk_signal})

    # continue test ...
    await ClockCycles(uut.{clk_signal}, 100)
    uut._log.info("Test Complete!")

"""
    with open(test_file, "w") as f:
        f.write(template)
    return f"# Generated cocotb test template: {test_file}"

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="Generate cocotb test templates.")
    parser.add_argument("verilog_files", nargs="+", help="List of Verilog files")
    parser.add_argument("-name", type=str, default=None, help="Custom test filename")
    args = parser.parse_args()

    if len(sys.argv) < 2:
        print("Usage: python3 instantiate.py <verilog_files> [-name=<test_name>]")
        sys.exit(1)

    all_args = " ".join(sys.argv[1:])
   
    # Filter out any -name argument and its value
    filtered_args = []
    skip_next = False
    for arg in all_args.split():
        if arg.startswith("-name"):
            skip_next = True
            continue
        if skip_next:
            skip_next = False
            continue
        filtered_args.append(arg)
    file_list = [f.strip() for f in " ".join(filtered_args).split("\n") if f.strip()]

    if not file_list:
        print("No Verilog files found")
        sys.exit(1)

    try:
        ast, _ = parse(file_list, debug=False)
    except Exception as e:
        print(f"Error parsing files: {e}")
        sys.exit(1)

    declared_signals = set()
    modules = extract_module_info(ast)
    
    test_filename = args.name
    for module_name, ports in modules:
        if test_filename:
            generate_cocotb_test(module_name, ports, test_filename)
        else:
            generate_cocotb_test(module_name, ports, module_name.lower())
    
    cleanup_pyverilog_artifacts()