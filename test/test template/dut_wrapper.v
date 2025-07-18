`default_nettype none
`timescale 1ns / 1ns

/* 
  Note:
    This wrapper 'testbench' just instantiates the module and makes some
    convenient wires that can be driven/tested by the cocotb python testbench.
*/

module dut_wrapper(); // replace 'dut' with the DUT name

  // 1. define module interface signals for I/O

  // example signals

  reg clk;
  reg rst_n;
  wire out;

  // 2. Instantiate DUT

  dut dut (
    .clk(clk),
    .reset(~rst_n),
    .out(out)
  );

  // 3. Dump the signals to a VCD file so it can be viewed in surfer/GTKWAVE

  initial begin
    $dumpfile("dut.vcd");        // call this whatever you want (output file name
    $dumpvars(0, dut_wrapper);   // replace duut_wrapper with the mame of your wrapper
    #1;
  end

endmodule
