![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# The Tiny Tapestation - Tiny Tapeout 10 

## What is the Tiny Tapestation ?

In Summer 2023, five Electronics Students at the University of Sheffield, embarked on a research and design project: recreating a simple gaming system from the gate level,
building up an understanding of system design, semiconductors,  HDL programming, ASIC implementation and game design.

## How does it work? 

Magic..

## How to test it?

### Cocotb Test Framework

This repository provides a **Cocotb + Icarus Verilog (iverilog)** test environment for verifying hardware designs in Verilog using Python-based testbenches. The run scripts can be used to automatically generate sanity tests for synchronous modules and to 

### Prerequisites

Make sure the following are installed:

- **iverilog** (Icarus Verilog)
- **Python 3.11+**
- **pip packages** from `test/requirements.txt`

### Installation (Ubuntu/Debian)

```bash
sudo apt-get update && sudo apt-get install -y iverilog
pip install -r test/requirements.txt
```

## Test Scripts

There are two main scripts used for creating and running tests.

### 1. run_tests

Runs simulations and regression tests.

Usage：

```bash
./run_tests sim [-tb=<testbench_name>]
```

**sim** → Run a single simulation, optionally specifying a testbench

```bash
./run_tests sim -tb=test_player
```

**regress** → concurrently regression tests with multiple random seeds

```bash
./run_tests regress -runs <number> -width <number> [other options]
```


### Examples
```bash
./run_tests regress -runs 10 -width 5
```
Runs 10 simulations in two batches of 5


--- 
### 2. setup_env.sh

Sets up the test environment, generates Makefiles, and creates wrapper testbenches.

### Usage

```bash
./setup_env.sh [TARGET_DIR] -s <UUT_SRCS> -a <ALIAS> [--regen]
```

### Options

[TARGET_DIR] → Directory where the test environment is created

-s, --src → Verilog source files for the DUT (space-separated)

-w, --wtb → Wrapper testbench name (no .v)

-t, --top → Top-level Verilog module

-m, --module → Python test module name (no .py)

-a, --alias → Base name for auto-generated files

--regen → Regenerate Makefile only

-h, --help → Show usage help

### Example

```bash
./setup_env.sh test/unit/player Player.v -a 'player'
```
This creates a test environment in test/unit/player/ to test the Player.v module.

---

## Credits

SHaRC, Tiny Tapeout 2025