
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland
 * Last Updated: 01/12/2024 @ 21:26:37
*/

// === BUILD DEPENDENCIES === 
// `include "NESReciever.v"
// `include "ControlInterface.v"
// `include "PlayerLogic.v"
// `include "DragonHead.v"
// `include "DragonBody.v"
// `include "Sync.v"
// `include "PPU.v"

// TT Pinout (standard for TT projects - can't change this)
// GDS: https://gds-viewer.tinytapeout.com/?model=https%3A%2F%2Fsheffield-chip-design-team.github.io%2FSheffield-TTX%2F%2Ftinytapeout.gds.gltf
// Happy New Year!

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
    wire NES_Data;

    assign {NES_Latch,NES_Clk} = 2'b0;

    /*
        NES RECIEVER MODULE


    */

    // input signals
    wire [9:0] input_data; // register to hold the 5 possible player actions

    InputController ic(  // change these mappings to change the controls in the simulastor
        .clk(clk),
        .reset(frame_end),
        .up(ui_in[0]),
        .down(ui_in[1]),
        .left(ui_in[2]),
        .right(ui_in[3]),
        .attack(ui_in[4]),
        .control_state(input_data)
    );

    //player logic
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
        .frame_end(frame_end),

        .player_pos(player_pos),
        .player_orientation(player_orientation),
        .player_direction(player_direction),
        .player_sprite(player_sprite),

        .sword_position(sword_position),
        .sword_visible(sword_visible),
        .sword_orientation(sword_orientation)
    );

    //dragon logic 
    wire [1:0] dragon_direction;
    wire [7:0] dragon_position;
    wire [5:0] movement_delay_counter;
    
    DragonHead dragonHead( 
        .clk(clk),
        .reset(~rst_n),
        .player_pos(player_pos),
    
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

    wire [6:0] Display_en;

    DragonBody dragonBody(
        .clk(clk),
        .reset(~rst_n),
        .States(2'b01),
        .OrienAndPositon({dragon_direction,dragon_position}),
        .movement_counter(movement_delay_counter),
        .vsync(vsync),

        .Dragon_1(Dragon_1),
        .Dragon_2(Dragon_2),
        .Dragon_3(Dragon_3),
        .Dragon_4(Dragon_4),
        .Dragon_5(Dragon_5),
        .Dragon_6(Dragon_6),
        .Dragon_7(Dragon_7),

        .Display_en(Display_en)
    );

    // Frame Control Unit

    PictureProcessingUnit ppu (

        .clk_in                  (clk),
        .reset                   (~rst_n),
        .entity_1                ({player_sprite, player_orientation , player_pos}),   //player
        .entity_2                ({sword_visible, sword_orientation, sword_position}), //sword
        .entity_3                (14'b0000_11_1111_0000), // heart // entity input form: ([13:10] entity ID, [9:8] Orientation, [7:0] Location(tile)).
        .entity_4                (14'b0000_11_1110_0000),
        .entity_5                (14'b0000_11_1101_0000),
        .entity_6                (14'b1111_11_1111_1111),
        .entity_7_Array          (18'b1111_01_1010_0000_0111),
        .entity_8_Flip           (14'b1111_11_1111_1111),
        .dragon_1({~Display_en[0],4'b0110,Dragon_1}), 
        .dragon_2({~Display_en[1],4'b0100,Dragon_2}),  //Dragon Body entity slot structure: ([15] Enable, [13:10] entity ID, [9:8] Orientation, [7:0] Location(tile)).
        .dragon_3({~Display_en[2],4'b0100,Dragon_3}),  //Set the entity ID to 4'hf for unused channels.
        .dragon_4({~Display_en[3],4'b0100,Dragon_4}),
        .dragon_5({~Display_en[4],4'b0100,Dragon_5}),
        .dragon_6({~Display_en[5],4'b0100,Dragon_6}),
        .dragon_7({~Display_en[6],4'b0100,Dragon_7}),
        .counter_V               (pix_y),
        .counter_H               (pix_x),

        .colour                  (pixel_value)
    );

   // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire frame_end;

    // vga unit 
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

                if (player_direction == 0) begin // up
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (player_direction == 1) begin // right
                    R <= pixel_value ? 2'b11 : 0;
                    G <= pixel_value ? 2'b11 : 2'b11;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (player_direction == 2) begin // down
                    R <= pixel_value ? 2'b11 : 0;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

                if (player_direction == 3) begin // left
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 2'b11;
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
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    assign uio_out[7:2] = 0;
    wire _unused_ok = &{ena, uio_in}; 

endmodule




