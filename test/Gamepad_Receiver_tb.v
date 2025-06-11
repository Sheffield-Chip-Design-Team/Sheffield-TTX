`include "src/input_modules/Gamepad_Receiver.v"
`timescale 1ns/1ps

module Gamepad_Receiver_tb;

  reg clk_50;
  reg reset;
  reg data;
  reg is_snes;

  wire controller_latch;
  wire controller_clk;
  wire A, B, select, start;
  wire d_pad_up, d_pad_down, d_pad_left, d_pad_right;
  wire X, Y, left, right;

  // Instantiate the DUT
  Gamepad_Receiver dut (
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

  // Clock generation
  initial clk_50 = 0;
  always #10 clk_50 = ~clk_50; // 50 MHz clock (period = 20ns)

  initial begin
    // Initialize
    reset = 1;
    data = 1;
    is_snes = 0;

    // Hold reset for a few cycles
    #100;
    reset = 0;

    // NES mode test: send 8 bits (A, B, select, start, up, down, left, right)
    // Example: all buttons pressed (active low, so data = 0)
    repeat (8) begin
      @(posedge controller_latch);
      repeat (2) @(posedge clk_50); // Wait a couple cycles
      data = 0;
      repeat (600) @(posedge clk_50); // Hold data for 12us
      data = 1;
    end

    // Wait a bit
    #1000;

    // SNES mode test: send 12 bits (A, B, select, start, up, down, left, right, X, Y, left, right)
    is_snes = 1;
    reset = 1;
    #100;
    reset = 0;

    // Wait a bit
    #2000;

    $finish;
  end

endmodule