`default_nettype none
`timescale 1ns / 1ns

module player_tb();

  // InputCollector
  reg up;
  reg down;
  reg left;
  reg right;
  reg attack;
  wire [9:0] control_state;

  InputCollector collector (
    .clk(clk),
    .reset(collector_trigger),
    .up(up),
    .down(down),
    .left(left),
    .right(right),
    .attack(attack),
    .control_state(control_state)
  );
 
  // PlayerLogic
  reg clk;
  reg reset;
  reg [9:0] input_data;
  wire [7:0] player_pos;
  wire [1:0] player_orientation;
  wire [1:0] player_direction;
  wire [3:0] player_sprite;
  wire [7:0] sword_position;
  wire [3:0] sword_visible;
  wire [1:0] sword_orientation;

  PlayerLogic player (
    .clk(clk),
    .reset(reset),
    .trigger(player_trigger),
    .input_data(control_state),
    .player_pos(player_pos),
    .player_orientation(player_orientation),
    .player_direction(player_direction),
    .player_sprite(player_sprite),
    .sword_position(sword_position),
    .sword_visible(sword_visible),
    .sword_orientation(sword_orientation)
  );
 
  // sync_generator
  wire hsync;
  wire vsync;
  wire display_on;
  wire [9:0] screen_hpos;
  wire [9:0] screen_vpos;
  wire frame_end;
  wire input_enable;

  reg player_trigger;
  reg collector_trigger;

 always @(posedge clk ) begin
   player_trigger <= frame_end;
   collector_trigger <= player_trigger;
 end

  initial begin
    $dumpfile("player.vcd");
    $dumpvars(0, player_tb);
    #1;
  end
endmodule
