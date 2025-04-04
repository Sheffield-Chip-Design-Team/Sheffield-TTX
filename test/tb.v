`default_nettype none
`timescale 1ns / 1ns

/* This testbench just instantiates the module and makes some convenient wires
  that can be driven / tested by the cocotb test.py.
*/
module tb ();

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

  tt_um_Enjimneering_top tts (
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
  
  InputController ic(  // change these mappings to change the controls in the simulator
      .clk(clk),
      .reset(frame_end),
      .up(ui_in[0]),
      .down(ui_in[1]),
      .left(ui_in[2]),
      .right(ui_in[3]),
      .attack(ui_in[4]),
      .control_state(input_data)
  );

  CollisionDetector collisionDetector (
        .clk(clk),
        .reset(vsync),
        .playerPos(player_pos),
        .swordPos(sword_position),
        .sheepPos(sheep_pos),
        .activeDragonSegments(VisibleSegments),
        .dragonSegmentPositions(
            {Dragon_1[7:0],
            Dragon_2[7:0],
            Dragon_3[7:0],
            Dragon_4[7:0],
            Dragon_5[7:0],
            Dragon_6[7:0],
            Dragon_7[7:0]} ),
        .playerDragonCollision(PlayerDragonCollision),
        .swordDragonCollision(SwordDragonCollision),
        .sheepDragonCollision(SheepDragonCollision)
  );
  
  PlayerLogic playlogic(
        .clk(clk),
        .reset(~rst_n),
        .input_data(input_data),
        .trigger(frame_end),

        .player_pos(player_pos),
        .player_orientation(player_orientation),
        .player_direction(player_direction),
        .player_sprite(player_sprite),

        .sword_position(sword_position),
        .sword_visible(sword_visible),
        .sword_orientation(sword_orientation)
  );

  DragonHead dragonHead( 
        .clk(clk),
        .reset(~rst_n),
        .targetPos(player_pos),
        .vsync(vsync),
        .dragon_direction(dragon_direction),
        .dragon_pos(dragon_position),
        .movement_counter(movement_delay_counter)// Counter for delaying dragon's movement otherwise sticks to player
  );

  DragonBody dragonBody(

        .clk(clk),
        .reset(~rst_n),
        .lengthUpdate(2'b01),
        .Dragon_Head({dragon_direction, dragon_position}),
        .movementCounter(movement_delay_counter),
        .vsync(vsync),
        .Dragon_1(Dragon_1),
        .Dragon_2(Dragon_2),
        .Dragon_3(Dragon_3),
        .Dragon_4(Dragon_4),
        .Dragon_5(Dragon_5),
        .Dragon_6(Dragon_6),
        .Dragon_7(Dragon_7),

        .Display_en(VisibleSegments)
  );

  sheepLogic sheep (
        .clk(ui_in[7]), 
        .reset(~rst_n),
        .read_enable(1), 
        .dragon_pos(dragon_position), 
        .player_pos(player_pos),
        .sheep_pos(sheep_pos),
        .sheep_sprite(sheep_sprite)
  );

  PictureProcessingUnit ppu (

        .clk_in         (clk),
        .reset          (~rst_n), 
        .entity_1       ({player_sprite, player_orientation , player_pos,  4'b0001}),      // player
        .entity_2       ({4'b0001, sword_orientation, sword_position, 3'b000,sword_visible[0]}),     // sword
        .entity_3       ({4'b0111, 2'b01, sheep_pos, 4'b0001}) ,                           // sheep
        .entity_4       (18'b1111_11_1110_0000_0001),
        .entity_5       (18'b1111_11_1101_0000_0001),
        .entity_6       (18'b1111_11_1111_1111_0001),
        .entity_7       ({14'b0000_00_1111_0000, 2'b00, playerLives}),                     // heart
        .entity_8       (18'b1111_11_1111_1111_0001),
        .dragon_1       ({4'b0110,Dragon_1,3'b000,VisibleSegments[0]}),                    // dragon parts
        .dragon_2       ({4'b0100,Dragon_2,3'b000,VisibleSegments[1]}),  
        .dragon_3       ({4'b0100,Dragon_3,3'b000,VisibleSegments[2]}),  
        .dragon_4       ({4'b0100,Dragon_4,3'b000,VisibleSegments[3]}),
        .dragon_5       ({4'b0100,Dragon_5,3'b000,VisibleSegments[4]}),
        .dragon_6       ({4'b0100,Dragon_6,3'b000,VisibleSegments[5]}),        
        .counter_V      (pix_y),
        .counter_H      (pix_x),

        .colour         (pixel_value)
  );

  sync_generator sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end),
        .input_enable(enable_input)
    );

  // Dump the signals to a VCD file so it can be viewed in gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

endmodule
