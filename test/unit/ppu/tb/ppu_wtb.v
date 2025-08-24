`default_nettype none
`timescale 1ns / 1ns

module ppu_tb();

// PictureProcessingUnit
  reg clk_in;
  reg reset;
  reg [17:0] entity_1;
  reg [17:0] entity_2;
  reg [17:0] entity_3;
  reg [17:0] entity_4;
  reg [17:0] entity_5;
  reg [17:0] entity_6;
  reg [17:0] entity_7;
  reg [17:0] entity_8;
  reg [17:0] dragon_1;
  reg [17:0] dragon_2;
  reg [17:0] dragon_3;
  reg [17:0] dragon_4;
  reg [17:0] dragon_5;
  reg [17:0] dragon_6;
  reg [17:0] dragon_7;
  reg [9:0] counter_V;
  reg [9:0] counter_H;
  wire colour;

  PictureProcessingUnit u_PictureProcessingUnit (
    .clk_in(clk_in),
    .reset(reset),
    .entity_1(entity_1),
    .entity_2(entity_2),
    .entity_3(entity_3),
    .entity_4(entity_4),
    .entity_5(entity_5),
    .entity_6(entity_6),
    .entity_7(entity_7),
    .entity_8(entity_8),
    .dragon_1(dragon_1),
    .dragon_2(dragon_2),
    .dragon_3(dragon_3),
    .dragon_4(dragon_4),
    .dragon_5(dragon_5),
    .dragon_6(dragon_6),
    .dragon_7(dragon_7),
    .counter_V(counter_V),
    .counter_H(counter_H),
    .colour(colour)
  );
 
// SpriteROM
  reg clk;
  reg [1:0] orientation;
  reg [3:0] sprite_ID;
  reg [2:0] line_index;
  wire [7:0] data;

  SpriteROM u_SpriteROM (
    .clk(clk),
    .reset(reset),
    .orientation(orientation),
    .sprite_ID(sprite_ID),
    .line_index(line_index),
    .data(data)
  );
 

  initial begin
    $dumpfile("ppu.vcd");
    $dumpvars(0, ppu_tb);
    #1;
  end
endmodule
