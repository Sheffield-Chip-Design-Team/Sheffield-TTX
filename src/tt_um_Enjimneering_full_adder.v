/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
// `include "full_adder.v"- THIS MAKES IT INCLUDE TWICE, DONT DO THAT

module tt_um_Enjimneering_full_adder (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

//using full adder
  FullAdder fa (.a(ui_in[0]), .b(ui_in[1]), .c(ui_in[2]), .carry(uo_out[1]), .sum(uo_out[0]));

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;
  assign uo_out[7:2] = 0;
    
endmodule
