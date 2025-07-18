# TinyTapestaton CI Test Flow

This project uses an automating testing flow powered by [cocotb](https://docs.cocotb.org/en/stable/) to drive the modules and check their outputs.

See below to get started or for more information, check the [website](https://tinytapeout.com/hdl/testing/).

## Writing Unit Tests

1. Copy the test teamplate folder nito the unit folder
2. Edit the filenames, and module names to fit the module you are testing
3. Populate the wrapper
4. Write your tests in the python module.

## How to run

To run the RTL Top level tests simulation:

```sh
make -B 
```

To run the RTL Unit test simulation:

```sh
make -B UNIT=yes
```
To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

## How to view the VCD file

```sh
gtkwave tb.vcd tb.gtkw
```
Or ... open the file in the Surfer VSCode Extension.