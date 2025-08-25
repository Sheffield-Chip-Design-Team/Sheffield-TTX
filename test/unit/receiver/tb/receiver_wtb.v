`default_nettype none
`timescale 1ns / 1ns

module receiver_tb();

  // NESTest_Top
  reg clk;
  reg reset;
  reg NES_Data;
  wire NES_Latch;
  wire NES_Clk;
  reg SNES_PMOD_Data;
  reg SNES_PMOD_Clk;
  reg SNES_PMOD_Latch;
  wire A_out;
  wire B_out;
  wire select_out;
  wire start_out;
  wire up_out;
  wire down_out;
  wire left_out;
  wire right_out;
  wire X_out;
  wire Y_out;
  wire L_out;
  wire R_out;
  wire controller_status;

  NESTest_Top nestest_top (
    .system_clk_50MHz(clk),
    .reset(reset),
    .NES_Data(NES_Data),
    .NES_Latch(NES_Latch),
    .NES_Clk(NES_Clk),
    .SNES_PMOD_Data(SNES_PMOD_Data),
    .SNES_PMOD_Clk(SNES_PMOD_Clk),
    .SNES_PMOD_Latch(SNES_PMOD_Latch),
    .A_out(A_out),
    .B_out(B_out),
    .select_out(select_out),
    .start_out(start_out),
    .up_out(up_out),
    .down_out(down_out),
    .left_out(left_out),
    .right_out(right_out),
    .X_out(X_out),
    .Y_out(Y_out),
    .L_out(L_out),
    .R_out(R_out),
    .controller_status(controller_status)
  );
 
 
  initial begin
    $dumpfile("receiver.vcd");
    $dumpvars(0, receiver_tb);
    #1;
  end
endmodule
