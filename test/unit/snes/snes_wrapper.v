`default_nettype none
`timescale 1ns / 1ns

module snes_wrapper;

  // interface signals
  reg clk_50;
  reg reset;
  reg data;
  reg is_snes;
  
  wire controller_latch;
  wire controller_clk;
  wire A, B, select, start;
  wire d_pad_up, d_pad_down, d_pad_left, d_pad_right;
  wire X, Y, left, right;

  // UUT instantiation

  Gamepad_Receiver snes (
    .clk_50(clk_50),
    .reset(reset),
    .data(data),
    .is_snes(is_snes),
    .controller_latch(controller_latch),
    .controller_clk(controller_clk),
    .A(A),
    .B(B),
    .select(select),
    .start(start),
    .d_pad_up(d_pad_up),
    .d_pad_down(d_pad_down),
    .d_pad_left(d_pad_left),
    .d_pad_right(d_pad_right),
    .X(X),
    .Y(Y),
    .left(left),
    .right(right)
  );

 initial begin
    $dumpfile("snes.vcd");
    $dumpvars(0, snes_wrapper);
    #1;
  end

endmodule