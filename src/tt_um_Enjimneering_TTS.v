
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland
 * Last Updated: 01/12/2024 @ 21:26:37
*/

// === BUILD DEPENDENCIES === 
//   `include "NESReciever.v"
//   `include "ControlInterface.v"
//   `include "GameStateController.v"
//   `include "PlayerLogic.v"
//   `include "DragonHead.v"
//   `include "DragonBody.v"
//   `include "Sheep.v"
//   `include "Sync.v"
//   `include "PPU.v"
//   `include "APU_top.v"


// GDS: https://gds-viewer.tinytapeout.com/?model=https%3A%2F%2Fsheffield-chip-design-team.github.io%2FSheffield-TTX%2F%2Ftinytapeout.gds.gltf

// TT Pinout (standard for TT projects - can't change this)
module tt_um_Enjimneering_top ( 

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
//    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset   
    input  wire       apu_test
);

    //system signals
    wire NES_Clk;
    wire NES_Latch;
    wire NES_Data = 0;

    assign {NES_Latch,NES_Clk} = 2'b0;

    /*
        NES/SNES RECIEVER MODULE
    */

    // input signals
    wire [9:0] input_data; // register to hold the 5 possible player actions

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

    wire PlayerDragonCollision;
    wire SwordDragonCollision;
    wire SheepDragonCollision;
    

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

    //player logic
    reg [1:0] playerLives = 3;
    wire [7:0] player_pos;   // player position xxxx_yyyy
    // orientation and direction: 00 - up, 01 - right, 10 - down, 11 - left  
    wire [1:0] player_orientation;   // player orientation 
    wire [1:0] player_direction;   // player direction
    wire [3:0] player_sprite;

    wire [7:0] sword_position; // sword position xxxx_yyyy
    wire [3:0] sword_visible;
    wire [1:0] sword_orientation;   // sword orientation 

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

    // dragon logic 
    wire [1:0] dragon_direction;
    wire [7:0] dragon_position;
    wire [5:0] movement_delay_counter;
    
    DragonHead dragonHead( 
        .clk(clk),
        .reset(~rst_n),
        .targetPos(player_pos),
        .vsync(vsync),
        .dragon_direction(dragon_direction),
        .dragon_pos(dragon_position),
        .movement_counter(movement_delay_counter)// Counter for delaying dragon's movement otherwise sticks to player
    );

    wire [9:0]   Dragon_1 ;
    wire [9:0]   Dragon_2 ;
    wire [9:0]   Dragon_3 ;
    wire [9:0]   Dragon_4 ;
    wire [9:0]   Dragon_5 ;
    wire [9:0]   Dragon_6 ;
    wire [9:0]   Dragon_7 ;

    wire [6:0] VisibleSegments;

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

    // sheep logic
    wire [7:0] sheep_pos; // 8-bit position (4 bits for X, 4 bits for Y)
    wire [3:0] sheep_sprite;

    sheepLogic sheep (
        .clk(clk), 
        .reset(~rst_n),
        .read_enable(1), 
        .dragon_pos(dragon_position), 
        .player_pos(player_pos),
        .sheep_pos(sheep_pos),
        .sheep_sprite(sheep_sprite)
    );

    // Picture Processing Unit
    // Entity input structure: ([17:14] spriteID, [13:12] Orientation, [11:4] Location(tile), [3] Flip, [2:0] Array(Enable)). 
    // Set the entity ID to 4'1111 for unused channels.
    // Set the array to 3'b000 for temporary disable channels.
    // Sprite ID    -   0: Heart 1: Sword, 2: Gnome_Idle_1, 3: Gnome_Idle_2, 4: Dragon_Wing_Up,
    //                  5: Dragon_Wing_Down, 6: Dragon_Head, 7: Sheep_Idle_1, 8: Sheep_Idle_2
    // Orientation  -   0: Up, 1: right , 2: down, 3: left
    // Location     -   8'bxxxx_yyyyy [xcoord (0-15), ycoord (0-11)]
    // Flip bit     -   0 means not flipped, 1 means flipped.
    // Array        -   repeat the tile x times in the orientation direction.

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

    clk_wiz_0 APU_CLK(
      .clk_in1(clk),
      .reset(rst_n),

      .clk_out1(apu_clk)
    );

    //Audio wire
    wire audio_out;
    //Audio unit
    APU apu (
        .clk(apu_clk),
        .rst_n(~rst_n),

        .SwordDragonCollision(apu_test),

        .x(pix_x),
        .y(pix_y),
        .Audio_Output(audio_out)
    );

    // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire frame_end;
    wire enable_input;
    // sync generator unit 
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

    // outpout colour signals
    wire pixel_value;
    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

    // display logic
    always @(posedge clk) begin
        
        if (~rst_n) begin
        R <= 0;
        G <= 0;
        B <= 0;
        
        end else begin
            if (video_active) begin // display output color from Frame controller unit

                if (PlayerDragonCollision == 0) begin // no collision - green
                    R <= pixel_value ? 2'b11 : 0;
                    G <= pixel_value ? 2'b11 : 2'b11;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 1) begin // collision - red
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 0;
                end

            end else begin
                R <= 0;
                G <= 0;
                B <= 0;
            end
        end
    end

    // System IO Connections
    assign uio_oe  = 8'b0000_0011;
    assign uio_out[1:0] = {NES_Latch, NES_Clk};
    assign uio_out[7:6] = {audio_out, 1'b1}; //Audio output, and a 1 to enable amplifier circuit
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    assign uio_out[5] = apu_test;
    // housekeeping to prevent errors/ warnings in synthesis.
    assign uio_out[4:2] = 0;
    wire _unused_ok = &{ena, uio_in, ui_in[6:5], 
    NES_Data, 
    SheepDragonCollision, 
    player_direction, 
    sheep_sprite, 
    enable_input, 
    Dragon_7[9:8]}; 

endmodule
// `default_nettype none

`define MUSIC_SPEED   1'b1;  // for 60 FPS
// `define MUSIC_SPEED   2'd2;  // for 30 FPS

`define C1  481; // 32.70375 Hz 
`define Cs1 454; // 34.6475 Hz 
`define D1  429; // 36.7075 Hz 
`define Ds1 405; // 38.89125 Hz 
`define E1  382; // 41.20375 Hz 
`define F1  360; // 43.65375 Hz 
`define Fs1 340; // 46.24875 Hz 
`define G1  321; // 49.0 Hz 
`define Gs1 303; // 51.9125 Hz 
`define A1  286; // 55.0 Hz 
`define As1 270; // 58.27 Hz 
`define B1  255; // 61.735 Hz 
`define C2  241; // 65.4075 Hz 
`define Cs2 227; // 69.295 Hz 
`define D2  214; // 73.415 Hz 
`define Ds2 202; // 77.7825 Hz 
`define E2  191; // 82.4075 Hz 
`define F2  180; // 87.3075 Hz 
`define Fs2 170; // 92.4975 Hz 
`define G2  161; // 98.0 Hz 
`define Gs2 152; // 103.825 Hz 
`define A2  143; // 110.0 Hz 
`define As2 135; // 116.54 Hz 
`define B2  127; // 123.47 Hz 
`define C3  120; // 130.815 Hz 
`define Cs3 114; // 138.59 Hz 
`define D3  107; // 146.83 Hz 
`define Ds3 101; // 155.565 Hz 
`define E3  95; // 164.815 Hz 
`define F3  90; // 174.615 Hz 
`define Fs3 85; // 184.995 Hz 
`define G3  80; // 196.0 Hz 
`define Gs3 76; // 207.65 Hz 
`define A3  72; // 220.0 Hz 
`define As3 68; // 233.08 Hz 
`define B3  64; // 246.94 Hz 
`define C4  60; // 261.63 Hz 
`define Cs4 57; // 277.18 Hz 
`define D4  54; // 293.66 Hz 
`define Ds4 51; // 311.13 Hz 
`define E4  48; // 329.63 Hz 
`define F4  45; // 349.23 Hz 
`define Fs4 43; // 369.99 Hz 
`define G4  40; // 392.0 Hz 
`define Gs4 38; // 415.3 Hz 
`define A4  36; // 440.0 Hz 
`define As4 34; // 466.16 Hz 
`define B4  32; // 493.88 Hz 
`define C5  30; // 523.26 Hz 
`define Cs5 28; // 554.36 Hz 
`define D5  27; // 587.32 Hz 
`define Ds5 25; // 622.26 Hz 
`define E5  24; // 659.26 Hz 
`define F5  23; // 698.46 Hz 
`define Fs5 21; // 739.98 Hz 
`define G5  20; // 784.0 Hz 
`define Gs5 19; // 830.6 Hz 
`define A5  18; // 880.0 Hz 
`define As5 17; // 932.32 Hz 
`define B5  16; // 987.76 Hz 

module APU(

  input wire clk,   // clock
  input wire rst_n, // reset_n - high to reset
  input wire SwordDragonCollision,
  // input wire bgm_ena,
  // input wire effect_code,
  input wire [9:0] x,     // hpos
  input wire [9:0] y,     //ypos

  output wire Audio_Output
);

  // VGA signals
  wire sound;

  assign Audio_Output = sound;
  reg [12:0] lfsr;
  wire [2:0] part = frame_counter[10-:3];
  wire [12:0] timer = frame_counter;
  reg noise, noise_src;
  reg [2:0] noise_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]
  wire beats_1_3 = timer[5:4] == 2'b10;

  // kick wave
  wire square60hz =  y < 262;                 // standing 60Hz square wave


  reg prev_SwordDragonCollision ;
 
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;

always @(posedge clk) begin

      lfsr <= {lfsr[11:0], feedback};

end

  // snare noise    
//   reg [12:0] lfsr;
//   wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  // always @(posedge clk) begin
  //   lfsr <= {lfsr[11:0], feedback};
  //   // lfsr <= lfsr[12:0];
  // end

  // lead wave counter
  reg [7:0] note_freq;
  reg [7:0] note_counter;
  reg       note;

  // bass wave counter
  reg [8:0] note2_freq;
  reg [8:0] note2_counter;
  reg       note2;

  // lead notes
  wire [3:0] note_in = timer[7-:4];           // 16 notes, 16 frames per note each. 256 frames total, ~4 seconds
  always @(note_in)
  case(note_in)
      4'd0 : note_freq = `E2
      4'd1 : note_freq = `E3
      4'd2 : note_freq = `D3
      4'd3 : note_freq = `E3
      4'd4 : note_freq = `A2
      4'd5 : note_freq = `B2
      4'd6 : note_freq = `D3
      4'd7 : note_freq = `E3
      4'd8 : note_freq = `E2
      4'd9 : note_freq = `E3
      4'd10: note_freq = `D3
      4'd11: note_freq = `E3
      4'd12: note_freq = `G2
      4'd13: note_freq = `E3
      4'd14: note_freq = `Fs2
      4'd15: note_freq = `E3
  endcase

  // bass notes
  wire [1:0] note2_in = timer[7-:2];           // 8 notes, 32 frames per note each. 256 frames total, ~4 seconds
  always @(note2_in)
  case(note2_in)
      2'd0 : note2_freq = `As4
      // 3'd1 : note2_freq = `As4
      2'd1 : note2_freq = `F5
      // 3'd3 : note2_freq = `F5
      2'd2 : note2_freq = `A5
      // 3'd5 : note2_freq = `A5
      2'd3 : note2_freq = 9'b111111111;
      // 3'd7 : note2_freq = `A5
  endcase

  wire kick   = square60hz & (x < envelopeA*4) & SwordDragonCollision;
  // wire kick   = 0;                   // 60Hz square wave with half second envelope
  wire snare  = noise       & (x >= 128 && x < 128+envelopeB) & SwordDragonCollision;   // noise with half a second envelope
  wire lead   = note       & (x >= 256 && x < 256+envelopeB*8);   // ROM square wave with quarter second envelope
  wire base   = note2      & (x >= 256 && x < ((beats_1_3)?(512+8*4):(512+32*4))); 
    //  wire base   = note2      & (x >= 512 && x < 256+envelopeB*8); 
  // assign sound = { kick | (snare) | (base) | (lead & part > 2) };
assign sound = 1;

  reg [12:0] frame_counter;
  always @(posedge clk) begin
    if (rst_n) begin
      frame_counter <= 0;
      noise_counter <= 0;
      note_counter <= 0;
      note2_counter <= 0;
      noise <= 0;
      note <= 0;
      note2 <= 0;

    end else begin
      noise_src <= ^lfsr;

      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end

      // noise
    if (x == 0) begin
        if (noise_counter > 1) begin 
          noise_counter <= 0;
          noise <= noise ^ noise_src;
        end else begin
          noise_counter <= noise_counter + 1'b1;
        end

      // square wave
      if (x == 0) begin
        if (note_counter > note_freq) begin
          note_counter <= 0;
          note <= ~note;
        end else begin
          note_counter <= note_counter + 1'b1;
        end

        if (note2_counter > note2_freq) begin
          note2_counter <= 0;
          note2 <= ~note2;
        end else begin
          note2_counter <= note2_counter + 1'b1;
        end
        
      end
    end
    end
 end
endmodule



