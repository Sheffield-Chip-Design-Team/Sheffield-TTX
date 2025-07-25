`default_nettype none
`timescale 1ns / 1ns

/* This testbench just instantiates the module and makes some convenient wires
  that can be driven / tested by the cocotb test.py.
*/
module top_tb ();

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  wire VPWR = 1'b1; wire VGND = 1'b0;

  tt_um_Enjimneering_top dut (
    `ifdef GL_TEST     // Include power ports for the Gate Level test:
          .VPWR(VPWR),
          .VGND(VGND),
    `endif
        .ui_in  (ui_in),    // Dedicated inputs
        .uo_out (uo_out),   // Dedicated outputs
        .uio_in (uio_in),   // IOs: Input path
        .uio_out(uio_out),  // IOs: Output path
        .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
        .ena    (ena),      // enable - goes high when design is selected
        .clk    (clk),      // clock
        .rst_n  (rst_n)     // not reset
  );
  
  // Dump the signals to a VCD file so it can be viewed in gtkwave.
  initial begin
    $dumpfile("tts.vcd");
    $dumpvars(0, tb);
    #1;
  end

endmodule
