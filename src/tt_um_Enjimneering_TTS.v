
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


// GDS: https://gds-viewer.tinytapeout.com/?model=https%3A%2F%2Fsheffield-chip-design-team.github.io%2FSheffield-TTX%2F%2Ftinytapeout.gds.gltf

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
        .clk(ui_in[7]), 
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

    //Audio wire
    wire Audio_out;
    //Audio unit
    APU_top apu(
        .clk(clk),
        .rst_n(~rst_n),

        .x(pix_x),
        .y(pix_y),
        .Audio_Output(Audio_out)
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
    assign uio_out[7:6] = {Audio_out, 1'b1}; //Audio output, and a 1 to enable amplifier circuit
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    assign uio_out[7:2] = 0;
    wire _unused_ok = &{ena, uio_in, ui_in[6:5], 
    NES_Data, 
    SwordDragonCollision, 
    SheepDragonCollision, 
    player_direction, 
    sheep_sprite, 
    enable_input, 
    Dragon_7[9:8]}; 

endmodule
