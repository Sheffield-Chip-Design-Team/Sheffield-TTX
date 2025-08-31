`default_nettype none
`timescale 1ns / 1ns

module apu_tb();

  // AudioProcessingUnit
  reg clk;
  reg reset;
  reg SheepDragonCollision;
  reg SwordDragonCollision;
  reg PlayerDragonCollision;
  // reg frame_end;
  reg [9:0] x;
  reg [9:0] y;
  wire sound;

  AudioProcessingUnit audioprocessingunit (
    .clk(clk),
    .reset(reset),
    .SheepDragonCollision(SheepDragonCollision),
    .SwordDragonCollision(SwordDragonCollision),
    .PlayerDragonCollision(PlayerDragonCollision),
    // .frame_end(frame_end),
    .x(x),
    .y(y),
    .sound(sound)
  );
 
  initial begin
    $dumpfile("apu.vcd");
    $dumpvars(0, apu_tb);
    #1;
  end
endmodule
