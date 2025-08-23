
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland, Rupert Bowen
 * Last Updated: 01/12/2024 @ 21:26:37
*/

// === SIMULATION BUILD DEPENDENCIES === 
//   `include "ControlInterface.v"
//   `include "CollisionDetector.v"
//   `include "Heart.v"
//   `include "PlayerLogic.v"
//   `include "DragonHead.v"
//   `include "DragonBody.v"
//   `include "Sheep.v"
//   `include "Sync.v"
//   `include "PPU.v"
//   `include "APU.v"
// === END ===

// TT Pinout (standard for TT projects - can't change this)
module tt_um_Enjimneering_top ( 
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset   
);

    // Controller signals
    wire NES_Clk;
    wire NES_Latch;
    wire NES_Data;

    // NES Input Stub
    assign {NES_Latch,NES_Clk} = 2'b0;

    // action signal for player logic
    wire [9:0] input_data; 
    
    // Bypass the reciver module (for simulation)
    InputCollector ic(  
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
        .swordPos(sword_pos),
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

    wire playerHurt;

    Hearts #(
        .PlayerTolerance(1)
    ) hearts (
        .clk(clk),
        .vsync(vsync),
        .reset(~rst_n),
        .PlayerDragonCollision(PlayerDragonCollision),
        .PlayerHurt(playerHurt),
        .playerLives(playerLives)
    );

    // player variables
    wire [1:0] playerLives;          // max lives: 3
    wire [7:0] player_pos;           // player position xxxx_yyyy
                                     // orientation and direction: 00 - up, 01 - right, 10 - down, 11 - left  
    wire [1:0] player_orientation;   // player orientation 
    wire [1:0] player_direction;     // player direction
    wire [3:0] player_sprite;

    // sword variables
    wire [7:0] sword_pos;           // sword position xxxx_yyyy
    wire [3:0] sword_sprite;        // used to toggle sword visibility
    wire [1:0] sword_orientation;   // sword orientation 

    // sheep variables
    wire [7:0] sheep_pos;           // 8-bit position (4 bits for X, 4 bits for Y)
    wire [3:0] sheep_sprite;

    sheepLogic sheep (
        .clk(ui_in[7]), 
        .reset(~rst_n),
        .read_enable(1), 
        .dragon_pos(dragon_position), 
        .player_pos(player_pos),
        .sheep_pos(sheep_pos),
        .sheep_sprite(sheep_sprite)
    );

    PlayerLogic playlogic(
        .clk(clk),
        .reset(~rst_n | playerHurt),
        .input_data(input_data),
        .trigger(frame_end),

        .player_sprite(player_sprite),
        .player_pos(player_pos),
        .player_orientation(player_orientation),
        .player_direction(player_direction),

        .sword_visible(sword_sprite),
        .sword_position(sword_pos),
        .sword_orientation(sword_orientation)
    );

    // dragon logic 
    wire [1:0] dragon_direction;
    wire [7:0] dragon_position;
    wire [5:0] movement_delay_counter;
    
    DragonHead dragonHead( 
        .clk(clk),
        .reset(~rst_n),
        .targetPos(target_pos),
        .vsync(vsync),
        .dragon_direction(dragon_direction),
        .dragon_pos(dragon_position),
        .movement_counter(movement_delay_counter)  // Counter for delaying dragon's movement otherwise sticks to player
    );

    wire [9:0]  Dragon_1;
    wire [9:0]  Dragon_2;
    wire [9:0]  Dragon_3;
    wire [9:0]  Dragon_4;
    wire [9:0]  Dragon_5;
    wire [9:0]  Dragon_6;
    wire [9:0]  Dragon_7;

    wire [6:0] VisibleSegments;
    wire [7:0] target_pos;

    DragonTarget dragonBrain(
        .clk(clk),
        .reset(~rst_n),
        .trigger(frame_end),
        .target_reached(Dragon_1[7:0] == target_pos),
        .dragon_hurt(SwordDragonCollision),
        .player_pos(player_pos), 
        .sheep_pos(sheep_pos),
        .target_pos(target_pos)
    );
    
    // delay the heal and hit for the dragon

    reg ShDC_Delay;
    reg SwDc_Delay;

    always@(posedge clk) if(rst_n) ShDC_Delay <= SheepDragonCollision; else ShDC_Delay <= 0;
    always@(posedge clk) if(rst_n) SwDc_Delay <= SwordDragonCollision; else SwDc_Delay <= 0;
    
    DragonBody dragonBody(

        .clk(clk),
        .reset(~rst_n),
        .heal(SheepDragonCollision & ~ShDC_Delay),
        .hit(SwordDragonCollision & ~SwDc_Delay),
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

    // Picture Processing Unit

    PictureProcessingUnit ppu (

        .clk_in         (clk),
        .reset          (~rst_n), 
        // game entitites 
        .entity_1       ({player_sprite, player_orientation , player_pos,  4'b0001}),                // player
        .entity_2       ({sword_sprite, sword_orientation, sword_pos, 4'b0001}),                // sword
        .entity_3       ({4'b0111, 2'b00, sheep_pos, 4'b0001}) ,                                     // sheep
        .entity_4       (18'b1111_11_1110_0000_0001),
        .entity_5       (18'b1111_11_1101_0000_0001),
        .entity_6       (18'b1111_11_1111_1111_0001),
        .entity_7       ({14'b0000_00_1111_0000, 2'b00, playerLives}),                               // heart
        .entity_8       (18'b1111_11_1111_1111_0001),
        // dragon parts 
        .dragon_1       ({4'b0110,Dragon_1,3'b000,VisibleSegments[0]}),                              // dragon parts
        .dragon_2       ({4'b0100,Dragon_2,3'b000,VisibleSegments[1]}),  
        .dragon_3       ({4'b0100,Dragon_3,3'b000,VisibleSegments[2]}),  
        .dragon_4       ({4'b0100,Dragon_4,3'b000,VisibleSegments[3]}),
        .dragon_5       ({4'b0100,Dragon_5,3'b000,VisibleSegments[4]}),
        .dragon_6       ({4'b0100,Dragon_6,3'b000,VisibleSegments[5]}),  
        .dragon_7       ({4'b0100,Dragon_7,3'b000,VisibleSegments[6]}),    
        // counter position
        .counter_V      (pix_y),
        .counter_H      (pix_x),
        // output color (to VGA)
        .colour         (pixel_value)
    );

    // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire frame_end;

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
        .input_enable()
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

                if (PlayerDragonCollision == 0 & SwordDragonCollision == 0) begin // no collision - green
                    R <= pixel_value ? 2'b11 : 0;
                    G <= pixel_value ? 2'b11 : 2'b11;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 1 & SwordDragonCollision == 0) begin // dragon hurs playher rtcollision - red
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 0 & SwordDragonCollision == 1) begin // sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b0;
                    G <= pixel_value ? 2'b11 : 2'b0;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

               if (PlayerDragonCollision == 1 & SwordDragonCollision == 1) begin // both collision simultaneouslt  sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 2'b00;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

            end else begin
                R <= 0;
                G <= 0;
                B <= 0;
            end
        end
    end

    // Audio signals
    wire sound;

    AudioProcessingUnit apu( 
      .clk(clk),
      .reset(~rst_n),
      .frame_end(frame_end),
      .PlayerDragonCollision(PlayerDragonCollision),
      .x(pix_x),
      .y(pix_y),
      .sound(sound)
    );
    
    // System IO Connections
    assign NES_Data = ui_in[0];
    assign uio_oe   = 8'b1000_0011;
    assign uio_out  = {sound, 5'b00000, NES_Latch, NES_Clk};
    assign uo_out   = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    wire _unused_ok = &{ena, uio_in[7:1]}; 

endmodule
   