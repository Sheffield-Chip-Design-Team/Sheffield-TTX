
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland
 * Last Updated: 30/11/2024 @ 21:46:41
*/

// BUILD TIME: 2024-11-30 22:53:27.732770 

// TT Pinout (standard for TT projects - can't change this)


module tt_um_vga_example ( 

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset   
);
    
    // display signals
    wire hsync;
    wire vsync;
    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire pixel_value;
    wire frame_end;

    // input signals
    wire [4:0] input_data; // register to hold the 5 possible player actions

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

    // Frame Control Unit
    wire [9:0]   Dragon_1 ;
    wire [9:0]   Dragon_2 ;
    wire [9:0]   Dragon_3 ;
    wire [9:0]   Dragon_4 ;
    wire [9:0]   Dragon_5 ;
    wire [9:0]   Dragon_6 ;
    wire [9:0]   Dragon_7 ;

    wire [6:0] Display_en;

    PictureProcessingUnit ppu (

        .clk_in                  (clk),
        .reset                   (~rst_n),
        .entity_1                ({player_sprite, player_orientation , player_pos}),   //player
        .entity_2                ({sword_visible, sword_orientation, sword_position}), //sword
        .entity_3                (14'b1111_11_0101_0000), // entity input form: ([13:10] entity ID, [9:8] Orientation, [7:0] Location(tile)).
        .entity_4                (14'b1111_11_0110_0000),
        .entity_5                (14'b1111_11_0110_0000),
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

    // vga unit 
    sync_generator sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end)
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

    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // housekeeping to prevent errors/ warnings in synthesis.
    assign uio_out = 0;
    assign uio_oe  = 0;
    wire _unused_ok = &{ena, uio_in}; 

endmodule

//================================================

// Module : Input Collector

/* 
    Description:
                takes input signals from ui_in (GUI) and outputs 1 on each button state when a button has been pressed or released.

    Control State Structure:
                0: UP 
                1: DOWN
                2: LEFT
                3: RIGHT
                4: ACTION
*/

module InputController (

    input wire clk,
    input wire reset,
    input wire up,            
    input wire down,
    input wire left,
    input wire right,
    input wire attack,
    output reg [9:0] control_state  
);
    // control state is now  10 bits wide to include whether all buttons have been released
    
    initial begin
        control_state = 0;
    end

    reg [4:0] previous_state  = 5'b0;
    reg [4:0] current_state   = 5'b0;
    reg [4:0] pressed_buttons = 5'b0 ;
    reg [4:0] released_buttons = 5'b0 ;
    reg [1:0] ripple_counter = 0;

    always @(posedge clk) begin
        previous_state <= current_state;
        current_state <= {attack, right, left , down , up};
    end

    always @(posedge clk) begin
            pressed_buttons[0] <= (current_state[0] == 1 & previous_state[0] == 0) ? 1:0;
            pressed_buttons[1] <= (current_state[1] == 1 & previous_state[1] == 0) ? 1:0;
            pressed_buttons[2] <= (current_state[2] == 1 & previous_state[2] == 0) ? 1:0;
            pressed_buttons[3] <= (current_state[3] == 1 & previous_state[3] == 0) ? 1:0;
            pressed_buttons[4] <= (current_state[4] == 1 & previous_state[4] == 0) ? 1:0;
    end

   always @(posedge clk) begin // added check for when buttons are released
            released_buttons[0] <= (current_state[0] == 0 & previous_state[0] == 1) ? 1:0;
            released_buttons[1] <= (current_state[1] == 0 & previous_state[1] == 1) ? 1:0;
            released_buttons[2] <= (current_state[2] == 0 & previous_state[2] == 1) ? 1:0;
            released_buttons[3] <= (current_state[3] == 0 & previous_state[3] == 1) ? 1:0;
            released_buttons[4] <= (current_state[4] == 0 & previous_state[4] == 1) ? 1:0;
    end

    always @(posedge clk) begin
        
        if (!reset) begin
            control_state <= control_state | {pressed_buttons, released_buttons};
        end

        else  control_state <= 0;
    end


endmodule

//================================================

// Module: Player Logic

module PlayerLogic(
    input clk,
    input reset,
    input wire [4:0] input_data,
    input wire frame_end,

    output reg [7:0] player_pos,
    output reg [1:0] player_orientation,   // player orientation 
    output reg [1:0] player_direction,   // player direction
    output reg [3:0] player_sprite,

    output reg [7:0] sword_position, // sword position xxxx_yyyy
    output reg [3:0] sword_visible,
    output reg [1:0] sword_orientation   // sword orientation 
    
);

    // State definitions
    localparam IDLE_STATE   = 2'b00;  // Move when there is input from the controller
    localparam ATTACK_STATE = 2'b01;  // Sword appears where the player is facing
    localparam MOVE_STATE   = 2'b10;  // Wait for input and stay idle

    reg [5:0] player_anim_counter;
    reg [5:0] sword_duration; // how long the sword stays visible

    // player state register
    reg [1:0] current_state;
    reg [1:0] next_state;


    reg sword_duration_flag;
    reg sword_duration_flag_local;


    always @(negedge clk) begin //<<<<<IMPORTANT<<<<<< negedge is aviable in vga playground and FPGA. Probably some timing issue but not sure
        if(~reset)begin           

            if(frame_end)begin
                    // Update state
                current_state <= next_state;

                sword_duration_flag_local <= sword_duration_flag; 
                if(sword_duration_flag != sword_duration_flag_local)begin
                    sword_duration<=0;
                end else begin
                    sword_duration <= sword_duration + 1;
                end

                // player_anim_counter <= player_anim_counter + 1;
                if (player_anim_counter == 20) begin
                    player_anim_counter <= 0;
                    player_sprite <= 4'b0011;
                end else if (player_anim_counter == 7) begin
                    player_sprite <= 4'b0010;
                    player_anim_counter <= player_anim_counter +1;
                end else begin
                    player_anim_counter <= player_anim_counter +1;  
                end
            end
        end else begin
            current_state <= 0;
            sword_duration <= 0;
            player_anim_counter <= 0;
        end
    end

    always @(posedge clk) begin
        if(~reset)begin
            case (current_state)

                IDLE_STATE: begin
                    sword_position <= 0;
                    sword_visible <= 4'b1111;

                    case (input_data[4]) 
                        1 : begin // attack
                            next_state <= ATTACK_STATE;
                            sword_duration_flag <= sword_duration_flag + 1;
                        end

                        0: begin // no attack

                        if (input_data[3:0] != 0 ) // directional buttons
                            next_state <= MOVE_STATE;  // Default case, stay in IDLE state
                        end

                        default: begin
                            next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                        end

                    endcase               
                end

                MOVE_STATE: begin
                    // Move player based on direction inputs and update orientation
                    if (input_data[0] == 1 && player_pos[3:0] > 4'b0001) begin   // Check boundary for up movement
                        player_pos <= player_pos - 1;  // Move up
                        player_direction <= 2'b00;
                    end

                    if (input_data[1] == 1 && player_pos[3:0] < 4'b1011) begin  // Check boundary for down movement
                        player_pos <= player_pos + 1;  // Move down
                        player_direction <= 2'b10;
                    end 

                    if (input_data[2] == 1 && player_pos[7:4] > 4'b0000) begin  // Check boundary for left movement
                        player_pos <= player_pos - 16;  // Move left
                        player_orientation <= 2'b11;
                        player_direction <= 2'b11;
                    end

                    if (input_data[3] == 1 && player_pos[7:4] < 4'b1111) begin  // Check boundary for right movement
                        player_pos <= player_pos + 16;  // Move right
                        player_orientation <= 2'b01;
                        player_direction <= 2'b01;
                    end

                    next_state <= IDLE_STATE;  // Return to IDLE after moving
                    // player_anim_counter <= 0;
                end

                ATTACK_STATE: begin
                    sword_visible <= 4'b0001;
                    if (player_direction == 2'b00 ) begin // player facing up
                        sword_position <= player_pos - 1;
                        sword_orientation <= 2'b00;
                    end if (player_direction == 2'b10 ) begin // player facing down
                        sword_position <= player_pos + 1;
                        sword_orientation <= 2'b10;
                    end if (player_direction == 2'b11) begin // player facing left
                        sword_position <= player_pos - 16;
                        sword_orientation <= 2'b11;
                    end if (player_direction == 2'b01) begin // player facing right
                        sword_position <= player_pos + 16;
                        sword_orientation <= 2'b01;
                    end

                    if (sword_duration == 10)
                        next_state <= IDLE_STATE;  // Return to IDLE after attacking
                        // player_anim_counter <= 0;
                end

                default: begin
                    next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                end
            endcase
        end else begin
        sword_duration_flag <= 0;
        next_state <= 0;
        player_orientation <= 2'b01;
        player_direction <= 2'b01;
        end
    end

    endmodule

//================================================

// Module : Dragon Head
// Author: Abdulatif Babli


/* 
    Description:
          
*/

module DragonHead ( 

    input clk,
    input reset,
    input [7:0] player_pos,
  
    input vsync,

    output reg [1:0] dragon_direction,
    output reg [7:0] dragon_pos,
    output reg [5:0] movement_counter// Counter for delaying dragon's movement otherwise sticks to player
);

    reg [3:0] dragon_x;
    reg [3:0] dragon_y;

    reg [3:0] dx; //difference
    reg [3:0] dy;
    reg [3:0] sx; //figuring out direction in axis
    reg [3:0] sy;

    reg pre_vsync;

    // Movement logic, uses bresenhams line algorithm

    always @(posedge clk) begin
        
        if (~reset)begin
        
            pre_vsync <= vsync;
            
            if(pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movement_counter < 6'd10) begin
                    movement_counter <= movement_counter + 1;
                
                end else begin
                    movement_counter <= 0;
                    // Store the current position before updating , used later
                    dragon_x <= dragon_pos[7:4];
                    dragon_y <= dragon_pos[3:0];

                    // Calculate the differences between dragon and player
                    dx <= player_pos[7:4] - dragon_x;
                    dy <= player_pos[3:0] - dragon_y ;
                    sx <= (dragon_x < player_pos[7:4]) ? 1 : -1; // Direction in axis
                    sy <= (dragon_y < player_pos[3:0]) ? 1 : -1; 

                    // Move the dragon towards the target if it's not adjacent
                    if (dx >= 1 || dy >= 1) begin
                    // Update dragon position only if it actually moves , keeps flickering
                        if (dx >= dy) begin //prioritize movement
                            dragon_x <= dragon_x + sx;
                            dragon_y <= dragon_y;
                        end else begin
                            dragon_x <= dragon_x;
                            dragon_y <= dragon_y + sy;
                        end

                        if (dragon_x > dragon_pos[7:4])
                        dragon_direction <= 2'b01;   // Move right
                        else if (dragon_x < dragon_pos[7:4])
                        dragon_direction <= 2'b11;   // Move left
                        else if (dragon_y > dragon_pos[3:0])
                        dragon_direction <= 2'b10;   // Move down
                        else if (dragon_y < dragon_pos[3:0])
                        dragon_direction <= 2'b00;   // Move up

                        // Update the next location
                        dragon_pos <= {dragon_x, dragon_y};
                    end else begin
                        // stop moving when the dragon is adjacent to the player 
                        dragon_x <= dragon_x; 
                        dragon_y <= dragon_y; 
                    end
                end
            end 

        end else begin
            dragon_x <= 0;
            dragon_y <= 0;
            movement_counter <= 0;
            dragon_pos <= 0;
            dx <= 0; 
            dy <= 0;
            sx <= 0; 
            sy <= 0;
        end
    end

endmodule

//================================================

// Module : Dragon Body

/* 
    Description:
            
*/

module DragonBody(
    input clk,
    input reset,
    input vsync,
    input [1:0] States, // MUST be a PULSE
    input [9:0] OrienAndPositon, 
    input [5:0] movement_counter,

    output reg [9:0] Dragon_1, // Every 10 bit represent a body segment, Maximum of 8 segments, a queue
    output reg [9:0] Dragon_2,
    output reg [9:0] Dragon_3,
    output reg [9:0] Dragon_4,
    output reg [9:0] Dragon_5,
    output reg [9:0] Dragon_6,
    output reg [9:0] Dragon_7,

    output reg [6:0] Display_en
    );

    localparam MOVE = 2'b00;
    localparam HEAL = 2'b01;
    localparam HIT = 2'b10;
    localparam IDLE = 2'b11;
    reg pre_vsync;

    always @(posedge clk)begin
        
        if (~reset) begin
        
            pre_vsync <= vsync;

            if (pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movement_counter == 6'd10) begin
                    Dragon_1 <= OrienAndPositon;
                    Dragon_2 <= Dragon_1;
                    Dragon_3 <= Dragon_2;
                    Dragon_4 <= Dragon_3;
                    Dragon_5 <= Dragon_4;
                    Dragon_6 <= Dragon_5;
                    Dragon_7 <= Dragon_6;
                end

        end end else begin
            Dragon_1 <= 0;
            Dragon_2 <= 0;
            Dragon_3 <= 0;
            Dragon_4 <= 0;
            Dragon_5 <= 0;
            Dragon_6 <= 0;
            Dragon_7 <= 0;
        end
    end

    always @(posedge clk)begin
        if(~reset) begin
            case(States) 
                MOVE: begin
                    Display_en <= Display_en;
                end
                HEAL: begin
                    Display_en <= (Display_en << 1) | 1'b1;
                end
                HIT: begin
                    Display_en <= Display_en >> 1;
                end
                IDLE: begin
                    Display_en <= Display_en;
                end
            endcase
        end else begin
            Display_en <= 0;
        end
    end

    endmodule
    
//================================================
// Module - Sync Unit Ouput Module 

/*
    Description: 
            Generates sync pulses for VGA monitor, (H-SYNC ,V-SYNC) targeted to 640 * 480 output, 
            Pixel coordinates for the graphics controller,
            and sync signals for the game logic units.

    Build Arguments
        
*/

module sync_generator (  

    input              clk,
    input              reset,
    output reg         hsync,
    output reg         vsync,
    output wire        display_on,
    output wire [9:0]  screen_hpos,
    output wire [9:0]  screen_vpos,
    output wire        frame_end,
    output wire        input_enable
);
    
    reg [9:0] hpos = 0;
    reg [9:0] vpos = 0;


    // declarations for TV-simulator sync parameters

    // horizontal constants

    parameter H_DISPLAY = 640;  // horizontal display width
    parameter H_BACK = 48;  // horizontal left border (back porch)
    parameter H_FRONT = 16;  // horizontal right border (front porch)
    parameter H_SYNC = 96;  // horizontal sync width

    // vertical constants

    parameter V_DISPLAY = 480;  // vertical display height
    parameter V_TOP = 33;  // vertical top border
    parameter V_BOTTOM = 10;  // vertical bottom border
    parameter V_SYNC = 2;  // vertical sync # lines

    // derived constants

    parameter H_SYNC_START = H_DISPLAY + H_FRONT;
    parameter H_SYNC_END = H_DISPLAY + H_FRONT + H_SYNC - 1;
    parameter H_MAX = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
    parameter V_SYNC_START = V_DISPLAY + V_BOTTOM;
    parameter V_SYNC_END = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
    parameter V_MAX = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

    wire hmaxxed = (hpos == H_MAX) || reset;  // set when hpos is maximum
    wire vmaxxed = (vpos == V_MAX) || reset;  // set when vpos is maximum
    
    wire hblanked = (hpos == H_DISPLAY);
    wire vblanked = (vpos == V_DISPLAY);

    assign screen_hpos = (hpos < H_DISPLAY)? hpos : 0; 
    assign screen_vpos = (vpos < V_DISPLAY)? vpos : 0;

    // horizontal position counter

    always @(posedge clk) begin
        hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
        if (hmaxxed) begin
        hpos <= 0;
        end else begin
        hpos <= hpos + 1;
        end
    end

    // vertical position counter

    always @(posedge clk) begin
        vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
        if (hmaxxed)
        if (vmaxxed) begin
        vpos <= 0;
        end else begin
            vpos <= vpos + 1;
        end
    end

    // display_on is set when beam is in "safe" visible frame
    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);
    assign frame_end = hblanked && vblanked;
    assign input_enable = (hblanked && vpos < V_DISPLAY);

endmodule

//================================================
// Module: Picture Processing Unit 


/* 
    Description: 
            This module takkes in entity information from the game logic and uses it to display sprites on screen 
            with selected locations, and orientations. It can easily be adapted to provide more slots to store more 
            entities or to repeat or flip tiles using the array or flipped slots.

    General Entity Format: 
            [13:10] Entity ID, 
            [9:8] Orientation, 
            [7:0] Location.

    Array Entity Format:
            [17:4] Same as before,
            [3:0] number of tiles.
    
*/

/*      
    BUILD ARGS: 
        -I SpriteROM.v 
*/

module PictureProcessingUnit(
    input clk_in,  
    input reset,    
    input wire [13:0] entity_1,  //entity input form: ([13:10] entity ID, [9:8] Orientation, [7:0] Location(tile)).
    input wire [13:0] entity_2,  //Simultaneously supports up to 9 objects in the scene.
    input wire [13:0] entity_3,  //Set the entity ID to 4'hf for unused channels.
    input wire [13:0] entity_4,
    input wire [13:0] entity_5,
    input wire [13:0] entity_6,
    input wire [17:0] entity_7_Array, //Array function disable
    input wire [13:0] entity_8_Flip,
    // input wire [13:0] entity_9_Flip,

    input wire [14:0] dragon_1,
    input wire [14:0] dragon_2,
    input wire [14:0] dragon_3,
    input wire [14:0] dragon_4,
    input wire [14:0] dragon_5,
    input wire [14:0] dragon_6,
    input wire [14:0] dragon_7,

    input wire [9:0] counter_V,
    input wire [9:0] counter_H,

    output reg colour // 0-black 1-white
    );

    wire clk = clk_in; // needs to be 25MHz!!!

    //internal Special Purpose Registers/Flags
    reg [3:0]  entity_Counter;     // like a Prorgram Counter but for entities instead of instructions
    reg [17:0] general_Entity;     // entity data register - like an MDR
    
    reg [1:0]  flip_Or_Array_Flag; // like an opcode to specify how to read the ROM and check the range
    // 2'b11: Disable(internal). 2'b10:Array; 2'b01:Flip; 2'b00: Default

    // Pixel Counters (Previous)
    reg [9:0] previous_horizontal_pixel;
    reg [9:0] previous_vertical_pixel;
    // Upscaling Counters
    reg [2:0] upscale_Counter_H;
    reg [2:0] upscale_Counter_V;
    // Sprite Idexing Counters
    reg [2:0] row_Counter;
    reg [2:0] column_Counter;
    // Tile counters are for the tiles that are currently being drawn by the VGA controller
    reg [3:0] horizontal_Tile_Counter;
    reg [3:0] vertical_Tile_Counter;
    // the Local counters are for tiles that are currently being processed (1 tile ahead of the current tile)
    reg [3:0] local_Counter_H;
    reg [3:0] local_Counter_V;
    
    // Updating the current tile, row and column counterscounters using the current pixel position 
    always@(posedge clk) begin 
        
        if(!reset)begin
            
            previous_horizontal_pixel <= counter_H; // record previous x-pixel

            if (previous_horizontal_pixel != counter_H ) begin

                if(upscale_Counter_H != 4)begin
                    upscale_Counter_H <= upscale_Counter_H + 1;
                end else begin
                    upscale_Counter_H <= 0;
                    column_Counter <= column_Counter + 1;
                end 
                                
                if (counter_H >= 40) begin
                    if(column_Counter == 3'b111 && upscale_Counter_H == 4)begin
                        horizontal_Tile_Counter <= horizontal_Tile_Counter + 1; // increment horizontal tile 
                    end else begin
                        horizontal_Tile_Counter <= horizontal_Tile_Counter;
                    end
                    end else begin
                        horizontal_Tile_Counter <= 0;
                    end

            end else begin
                horizontal_Tile_Counter <= horizontal_Tile_Counter;
                upscale_Counter_H <= upscale_Counter_H;
                column_Counter <= column_Counter;
            end

            previous_vertical_pixel <= counter_V;  // record previous y-pixel

            if (previous_vertical_pixel != counter_V ) begin    // if pixel counter has incremented
                if(upscale_Counter_V != 4) begin                // Upscale every pixel 5x
                    upscale_Counter_V <= upscale_Counter_V + 1;
                end else begin
                    upscale_Counter_V <= 0;
                    row_Counter <= row_Counter + 1;
                end

            if (counter_V >= 40) begin // increment the horizontal pixel after 8 upscaled pixels have been drawn in the vertical direction.
                if(row_Counter == 3'b111 && upscale_Counter_V == 4 && vertical_Tile_Counter != 4'd11)begin // row 0-11
                    vertical_Tile_Counter <= vertical_Tile_Counter + 1; // increment vertical tile 
                end else if(row_Counter == 3'b111 && upscale_Counter_V == 4 && vertical_Tile_Counter == 4'd11) begin // final row of tiles
                    vertical_Tile_Counter <= 0;
                end else begin
                    vertical_Tile_Counter <= vertical_Tile_Counter;
                end 
                end else begin
                     vertical_Tile_Counter <= 0;
                end
            end else begin // if the row counter hasn't updated
                    vertical_Tile_Counter <= vertical_Tile_Counter;
                    upscale_Counter_V <= upscale_Counter_V;
                    row_Counter <= row_Counter;
            end

        end else begin // reset all counters on reset

            previous_horizontal_pixel <= 0;
            column_Counter <= 0; 
            upscale_Counter_H <= 0;
            horizontal_Tile_Counter <= 4'b0000;

            previous_vertical_pixel <= 0;
            row_Counter <= 0;
            upscale_Counter_V <= 0;
            vertical_Tile_Counter <= 4'b0000;
        end

    end

    // Setting the Local tile, to the tile ahead of the tile currently being drawn
    always@(posedge clk) begin  
        
        if (!reset) begin
            
            local_Counter_H <= horizontal_Tile_Counter + 1;       // works as the width of the screen is 16 tiles - uses the overflow of 4-bit counrter as the reset.

            if(row_Counter == 3'b111 && upscale_Counter_H == 4 && horizontal_Tile_Counter == 15 && column_Counter == 7 && upscale_Counter_H == 4) begin // if at the end of a row
                if(vertical_Tile_Counter != 4'b1011) begin        // if not on final tile in the column
                    local_Counter_V <= vertical_Tile_Counter + 1; // increment the vertical tile counter
                end else begin
                    local_Counter_V <= 0;                         // wrap round back to the top of the screen 
                end
            end else begin
                local_Counter_V <= vertical_Tile_Counter;
            end
        end 

        else begin 
            local_Counter_H <= 0;
            local_Counter_V <= 0;
        end

    end

    // Detecting if a new tile has been reached - to reset entity counter
    wire [3:0] next_tile = (horizontal_Tile_Counter + 1);
    wire [3:0] current_tile = (local_Counter_H);
    wire new_tile = next_tile != current_tile;

    // Cycling through the entity slots - loading the data into the general entity register 
    always@(posedge clk) begin 
        
        if (!reset) begin
            case (entity_Counter)
                4'd0: begin 
                    general_Entity <= {entity_8_Flip,4'b0000}; 
                    flip_Or_Array_Flag <= 2'b01;
                    end
                4'd1:begin
                    general_Entity <= entity_7_Array;
                    flip_Or_Array_Flag <= 2'b10;
                end   
                4'd2:begin
                    general_Entity <= {entity_6,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd3:begin 
                    general_Entity <= {entity_5,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd4:begin 
                    general_Entity <= {entity_4,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd5:begin 
                    general_Entity <= {entity_3,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd6:begin 
                    general_Entity <= {entity_2,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd7:begin 
                    general_Entity <= {entity_1,4'b0000};
                    flip_Or_Array_Flag <= 2'b00;
                end
                4'd8: begin
                    general_Entity <= {dragon_1[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_1[14],dragon_1[14]};
                end
                4'd9: begin
                    general_Entity <= {dragon_2[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_2[14],dragon_2[14]};
                end
                4'd10: begin
                    general_Entity <= {dragon_3[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_3[14],dragon_3[14]};
                end
                4'd11: begin
                    general_Entity <= {dragon_4[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_4[14],dragon_4[14]};
                end
                4'd12: begin
                    general_Entity <= {dragon_5[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_5[14],dragon_5[14]};
                end
                4'd13: begin
                    general_Entity <= {dragon_6[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_6[14],dragon_6[14]};
                end
                4'd14: begin
                    general_Entity <= {dragon_7[13:0],4'b0000};
                    flip_Or_Array_Flag <= {dragon_7[14],dragon_7[14]};
                end

                default: begin
                    general_Entity <= 18'b111111000000000000;
                    flip_Or_Array_Flag <= 2'b11;
                end

            endcase

            // cycle through all of the entity slots - new slot each clk
            if (entity_Counter != 14 && entity_Counter != 4'd15) begin
                entity_Counter <= entity_Counter + 1;
            end else if (new_tile) begin // reset the EC every time a new tile is reached
                entity_Counter <=0;
            end else begin // Entity counter IDLE
                entity_Counter <= 4'd15;
            end

        end else begin // reset flags and registers
            flip_Or_Array_Flag <= 2'b11;
            entity_Counter <= 4'b0000;
            general_Entity <=18'b111111000000000000;
        end 
   
    end

    // Checking whether the Entity in the general entity register should be displayed in the Local tile
    wire inRange;   
    assign inRange = ((((local_Counter_H - general_Entity[11:8])) == 0) && (((local_Counter_V - general_Entity[7:4])) == 0));
    //These registers are used to address the ROM.
    reg [8:0] detector;    // Data Format: [8:6] Row number, [5:2] Entity ID, [1:0] Orientation  
    reg [8:0] out_entity;  
    
    // Send entity data to the ROM depending on the contents of the processed tile and slot type. 
    always @(posedge clk) begin 

        if (!reset) begin
            // depending on the slot type, send the appropriate row to the Sprite ROM

            if (!(column_Counter == 7 && upscale_Counter_H == 3))begin

                out_entity <= out_entity;
                
                if ((inRange && (general_Entity[17:14] != 4'b1111)) && (flip_Or_Array_Flag != 2'b11)) begin

                    if (flip_Or_Array_Flag == 2'b01) begin
                        detector <= {~(row_Counter), general_Entity[17:12]};
                    end else begin
                        detector <= {(row_Counter), general_Entity[17:12]};
                    end

                end else begin
                    detector <= detector;
                end

            end else begin
                out_entity <= detector;
                detector <= 9'b111111111;  
            end

        end else begin
            detector <= 9'b111111111;
            out_entity <= 9'b111111111;
        end
    
    end

    // Read From ROM
    SpriteROM Rom ( 
        .clk(clk),
        .reset(reset),
        .orientation(out_entity[1:0]),
        .sprite_ID(out_entity[5:2]),
        .line_index(out_entity[8:6]),
        .data(buffer)
    );

    wire [7:0] buffer; // ROM output buffer 
    
    // Send the appropriate pixel value to the VGA output unit 
    always@(posedge clk)begin 
       
        if(!reset)begin
            colour <= buffer[column_Counter];
        end else begin
            colour <= 1'b1;
        end
        
    end

endmodule


//================================================

// Module: SpriteROM 

/*  Description: The Sprite ROM stores all of the graphicval information in the game using a bitmap.
                 it outputs an 1 * 8 cross-sectional slice of the currently displayed sprite that needs to be 
                 displayed on the current tile. Depending on the oriAentation bits it will return a different, 
                 slice, rotating or flipping  the image as appropriate.

    Sprite List:

                0: Heart
                1: Sword
                2: Gnome_Idle_1
                3: Gnome_Idle_2
                4: Dragon_Wing_Up
                5: Dragon_Wing_Down
                6: Dragon_Head
                7: Sheep_Idle_1
                8: Sheep_Idle_2

    Orientation Selection:

                The ROM Can be read from in four differernt ways in order to output the imagine in a different orientations.

                UP    = 0  - No change
                RIGHT = 1  - Rotated 90 Degrees clockwise around the centre.
                DOWN  = 2  - Reflected 180 Degrees.
                LEFT  = 3  - Rotated 90 Degrees clockwise around the centre, then reflected on the line x = 0
                

    Sprite Storage:

                The sprite is stored using an active low binary bitmap.
                0 = Pixel_ON
                1 = Pixel_OFF
    
    Last Updated: 30/11/2024 @ 21:05:21
    
*/


module SpriteROM (
    
    input            clk,
    input            reset,
    // input wire       read_enable,
    input [1:0] orientation,
    input [3:0] sprite_ID,
    input [2:0] line_index,
    
    output reg [7:0] data
);

    localparam UP     = 2'b00;
    localparam RIGHT  = 2'b01;
    localparam DOWN   = 2'b10;
    localparam LEFT   = 2'b11;

    // assign read_enable = 1'b1;

    reg [7:0] romData [71:0];   

    initial begin

        romData[0] = 8'b11111111; // 0000 Heart 
        romData[1] = 8'b10011001;
        romData[2] = 8'b00000000;
        romData[3] = 8'b00100000;
        romData[4] = 8'b00010000;
        romData[5] = 8'b10000001;
        romData[6] = 8'b11000011;
        romData[7] = 8'b11100111;

        romData[8]  = 8'b11101111; // 0001 Sword 0001
        romData[9]  = 8'b11101111;
        romData[10] = 8'b11101111;
        romData[11] = 8'b11101111;
        romData[12] = 8'b11101111;
        romData[13] = 8'b11101111;
        romData[14] = 8'b11000111;
        romData[15] = 8'b11101111;

        romData[16] = 8'b11111111; // 0010 Gnome (Stand)
        romData[17] = 8'b11000011;
        romData[18] = 8'b10110000;
        romData[19] = 8'b00000011;
        romData[20] = 8'b00110001;
        romData[21] = 8'b00000000;
        romData[22] = 8'b01000001;
        romData[23] = 8'b11111111;

        romData[24] = 8'b11111011; // 0011 Gnome (Crouch)
        romData[25] = 8'b11100011;
        romData[26] = 8'b11001000;
        romData[27] = 8'b11000011;
        romData[28] = 8'b10001001;
        romData[29] = 8'b10000000;
        romData[30] = 8'b10010001;
        romData[31] = 8'b11111111;

        romData[32] = 8'b11000011; // 0100 Dragon Body (Wing up)
        romData[33] = 8'b11100001;
        romData[34] = 8'b10000011;
        romData[35] = 8'b10000001;
        romData[36] = 8'b00000001;
        romData[37] = 8'b01000000;
        romData[38] = 8'b11100001;
        romData[39] = 8'b11000001;

        romData[40] = 8'b11000011; // 0101 Dragon Body (Wing Down)
        romData[41] = 8'b11100001;
        romData[42] = 8'b11000011;
        romData[43] = 8'b10000001;
        romData[44] = 8'b10000000;
        romData[45] = 8'b10000000;
        romData[46] = 8'b10000001;
        romData[47] = 8'b11000001;

        romData[48] = 8'b11000111; // 0110  Dragon Head
        romData[49] = 8'b11000011;
        romData[50] = 8'b11000011;
        romData[51] = 8'b10010001;
        romData[52] = 8'b10110001;
        romData[53] = 8'b10100001;
        romData[54] = 8'b01000011;
        romData[55] = 8'b11000111;

        romData[56] = 8'b11001111; // 0111 sheep 1
        romData[57] = 8'b10000011;
        romData[58] = 8'b10011000;
        romData[59] = 8'b01111011;
        romData[60] = 8'b01111011;
        romData[61] = 8'b01111000;
        romData[62] = 8'b10111011;
        romData[63] = 8'b11000111;

        romData[64] = 8'b11100111; // 1000 sheep -2 
        romData[65] = 8'b11000001;
        romData[66] = 8'b11001100;
        romData[67] = 8'b10111101;
        romData[68] = 8'b10111101;
        romData[69] = 8'b10111100;
        romData[70] = 8'b11011101;
        romData[71] = 8'b11100011;
        
        // empty tile = 1111;

    end

    always @(posedge clk) begin // impliment the 4 orientations
            
            if(!reset) begin
                
                if (sprite_ID != 4'b1111)begin

                    if (orientation == UP) begin                              // Normal Operation
                        data[0] <= romData[{sprite_ID,line_index}][7];
                        data[1] <= romData[{sprite_ID,line_index}][6];
                        data[2] <= romData[{sprite_ID,line_index}][5];
                        data[3] <= romData[{sprite_ID,line_index}][4];
                        data[4] <= romData[{sprite_ID,line_index}][3];
                        data[5] <= romData[{sprite_ID,line_index}][2];
                        data[6] <= romData[{sprite_ID,line_index}][1];
                        data[7] <= romData[{sprite_ID,line_index}][0];
                        // data <= romData(sprite_ID,line_index, 1'b0 );
                    end 

                    else if (orientation == RIGHT) begin                        // (Rotate 90 degrees clockwise around the center point)   
                        data[0] <= romData[{sprite_ID,3'b111}][~line_index];    // romdata[bottom to top][left to right]
                        data[1] <= romData[{sprite_ID,3'b110}][~line_index];
                        data[2] <= romData[{sprite_ID,3'b101}][~line_index];
                        data[3] <= romData[{sprite_ID,3'b100}][~line_index];
                        data[4] <= romData[{sprite_ID,3'b011}][~line_index];
                        data[5] <= romData[{sprite_ID,3'b010}][~line_index];
                        data[6] <= romData[{sprite_ID,3'b001}][~line_index];
                        data[7] <= romData[{sprite_ID,3'b000}][~line_index];
                    end

                    else if(orientation == DOWN) begin                           // Top row to bottom row (Reflection on the line y = 0)
                        data <= romData[{sprite_ID,~line_index}];
                    end

                    else if (orientation == LEFT) begin                         //  (Rotate 90 degrees clockwise around the center point and reflect on the line x = 0)
                        data[0] <= romData[{sprite_ID,3'b000}][~line_index];    //  romdata[top to bottom][left to right]
                        data[1] <= romData[{sprite_ID,3'b001}][~line_index];
                        data[2] <= romData[{sprite_ID,3'b010}][~line_index];
                        data[3] <= romData[{sprite_ID,3'b011}][~line_index];
                        data[4] <= romData[{sprite_ID,3'b100}][~line_index];
                        data[5] <= romData[{sprite_ID,3'b101}][~line_index];
                        data[6] <= romData[{sprite_ID,3'b110}][~line_index];
                        data[7] <= romData[{sprite_ID,3'b111}][~line_index];

                    end else begin
                        data <= 8'b11111111;
                    end

                end else begin
                    data <= 8'b11111111;
                end

            end else begin
                data <= 8'b11111111;
            end

        end

    endmodule