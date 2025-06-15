
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland, Rupert Bowen
 * Last Updated: 01/12/2024 @ 21:26:37
*/

module tt_um_tinytapestation ( 

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset   
);
  
   // Clock Divider to generate 50 MHz and 25 MHz clocks from 100 MHz input clock
   wire CLK_50MHZ, CLK_25MHZ;

   clk_div clk_div_inst (
    .clk_in(clk),                   // input clk_in (100 MHZ)
    .reset(~rst_n), 
    .clk_out_25MHz(CLK_25MHZ),      // output clk_out_25MHz
    .clk_out_50MHz(CLK_50MHZ)       // output clk_out_50MHz
   );
   
    // Controller input signals
    
    wire NES_Clk;
    wire NES_Latch;
    wire NES_Data;
    
    wire Up_button;  
    wire Down_button;
    wire Left_button;
    wire Right_button;
    wire A_button;
    wire B_button;
    wire Start_button;
    wire Select_button;
    
    // NES/SNES Reciever Module
    InputReceiver gamepadInput (
        .clk(CLK_25MHZ),
        .reset(~rst_n),
        .data(NES_Data),    // input data from nes controller to FPGA
        .latch(NES_Latch),  // parallel -> serial switch for gamepad shift register
        .nes_clk(NES_Clk),  // outputs from FPGA to nes controller
        .A(A_button),
        .B(B_button),
        .select(Select_button),
        .start(Start_button),
        .up(Up_button),
        .down(Down_button),
        .left(Left_button),
        .right(Right_button)  
    );
    
    
    // Dummy Dragon Display
    reg [6:0] VisibleSegments = 0; // 7 segments for dragon parts visibility
    reg Dragon_1 = 0;
    reg Dragon_2 = 0;   
    reg Dragon_3 = 0;
    reg Dragon_4 = 0;
    reg Dragon_5 = 0;
    reg Dragon_6 = 0;
    reg Dragon_7 = 0;
   
    // Hearts Display 
    reg [1:0] player_lives = 2'b11; // 2 bits for player lives (max 3)

    // Dummy Player Display
    reg [3:0] player_sprite = 4'b0010;    // 4 bits for player sprite
    reg [1:0] player_orientation = 2'b01; // 2 bits for player orientation
    reg [7:0] player_pos = 8'b0001_0001;  // 8 bits for player position (x,y)

    // Dummy Sword Display
    reg sword_position = 0; // sword position
    reg sword_visible = 0;  // sword visibility

    // Dummy Sheep Display
    reg [3:0] sheep_sprite = 4'b1000;     // sheep sprite (3'd7)
    reg [1:0] sheep_orientation = 2'b11;  // left facing
    reg [7:0] sheep_pos = 8'b1001_0010;   // 8 bits for sheep position (x,y)
  
  
    PictureProcessingUnit ppu (

        .clk_in         (CLK_25MHZ),
        .reset          (~rst_n), 
        
        .entity_1       ({4'b0000, 2'b00, 8'b1111_0000, {2'b00, playerLives} }),           // heart
        .entity_2       ({player_sprite, player_orientation , player_pos,  4'b0001}),      // player
        .entity_3       ({sword_visible, sword_orientation, sword_position, 4'b0001}),     // sword
        .entity_4       ({sheep_sprite, sheep_orientation , sheep_pos,  4'b0001}),         // sheep 
        .entity_5       (18'b1111_11_1111_1111_0001),                                      // sheep 2 - ADD LATER?
        .entity_6       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_7       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_8       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_9       ({4'b0110,Dragon_1,3'b000,VisibleSegments[0]}),                    // dragon parts
        .entity_10      ({4'b0100,Dragon_2,3'b000,VisibleSegments[1]}),  
        .entity_11      ({4'b0100,Dragon_3,3'b000,VisibleSegments[2]}),  
        .entity_12      ({4'b0100,Dragon_4,3'b000,VisibleSegments[3]}),
        .entity_13      ({4'b0100,Dragon_5,3'b000,VisibleSegments[4]}),
        .entity_14      ({4'b0100,Dragon_6,3'b000,VisibleSegments[5]}), 
        .entity_15      ({4'b0100,Dragon_7,3'b000,VisibleSegments[6]}),        
        
        .counter_V      (pix_y),
        .counter_H      (pix_x),

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
    
    sync_generator sync_gen (
        .clk(CLK_25MHZ),
        .reset(~rst_n),
        .hsync(hsync),              // horizontal sync signal (active low)
        .vsync(vsync),              // vertical sync signal   (active low)
        .display_on(video_active),  // active video area
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end)
    );

    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

   //  VGA display logic
    always @(posedge CLK_25MHZ) begin
       if (~rst_n) begin
            R <= 2'b00;
            G <= 2'b00;
            B <= 2'b00;
        end else if (video_active) begin
            // show sprites
            R <= pixel_value ? 2'b11 : 0;
            G <= pixel_value ? 2'b11 : 2'b11;
            B <= pixel_value ? 2'b11 : 0;
        end else begin
            R <= 2'b00;
            G <= 2'b00;
            B <= 2'b00;
       end
    end
    
    // Audio signals
    wire sound;

    APU apu( 
      .clk(CLK_25MHZ),
      .reset(~rst_n),
      .frame_end(frame_end),
      .snare_trigger(Start_button),
      .x(pix_x),
      .y(pix_y),
      .sound(sound)
    );

    // System IO Connections
    assign ui_in   = {7'b000_0000, NES_Data};
    assign uio_oe  = 8'b1000_0011;
    assign uio_out = {sound, 5'b00000, NES_Latch, NES_Clk};
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    wire _unused_ok = &{ena, uio_in}; 

endmodule

module InputCollector (
    input wire clk,
    input wire reset,
    input wire up,            
    input wire down,
    input wire left,
    input wire right,
    input wire attack,
    output reg [9:0] control_state  // 10 bits to store pressed AND released buttons
);
 
    integer i;
    
    initial begin
        control_state = 0;
    end

    reg [4:0] previous_state  = 5'b0;
    reg [4:0] current_state   = 5'b0;
    reg [4:0] pressed_buttons = 5'b0 ;
    reg [4:0] released_buttons = 5'b0 ;

    always @(posedge clk) begin
        previous_state <= current_state;
        current_state <= {attack, right, left , down , up};
    end

   always @(posedge clk) begin
        if (reset) begin
            pressed_buttons  <= 5'b0;
            released_buttons <= 5'b0;
        end else begin
            for (i = 0; i < 5; i = i + 1) begin
                pressed_buttons[i]  <= (current_state[i]  & ~previous_state[i]);
                released_buttons[i] <= (~current_state[i] & previous_state[i]);
            end
        end
    end

   always @(posedge clk) begin
        if (reset) begin
          control_state <= 0;
        end else control_state <= control_state | {pressed_buttons, released_buttons};
   end


endmodule

// PPU
module PictureProcessingUnit(
    input clk_in,
    input reset,    
    input wire [17:0] entity_1,  
    input wire [17:0] entity_2,  //Simultaneously supports up to 9 objects in the scene.
    input wire [17:0] entity_3,  //Set the entity ID to 4'hf for unused channels.
    input wire [17:0] entity_4,
    input wire [17:0] entity_5,
    input wire [17:0] entity_6,
    input wire [17:0] entity_7, 
    input wire [17:0] entity_8,
    input wire [17:0] entity_9,
    input wire [17:0] entity_10,
    input wire [17:0] entity_11,
    input wire [17:0] entity_12,
    input wire [17:0] entity_13,
    input wire [17:0] entity_14,
    input wire [17:0] entity_15,

    input wire [9:0] counter_V,
    input wire [9:0] counter_H,

    output reg colour // 0-black 1-white
    );

    wire clk = clk_in; // needs to be 25MHz!!!

    //internal Special Purpose Registers/Flags
    reg [3:0]  entity_Counter;     // like a Prorgram Counter but for entities instead of instructions
    reg [17:0] general_Entity;     // entity data register - like an MDR

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
                    general_Entity <= entity_8; 
                    end
                4'd1:begin
                    general_Entity <= entity_7;
                end   
                4'd2:begin
                    general_Entity <= entity_6;
                end
                4'd3:begin 
                    general_Entity <= entity_5;
                end
                4'd4:begin 
                    general_Entity <= entity_4;
                end
                4'd5:begin 
                    general_Entity <= entity_3;
                end
                4'd6:begin 
                    general_Entity <= entity_2;
                end
                4'd7:begin 
                    general_Entity <= entity_1;
                end
                4'd8: begin
                    general_Entity <= entity_9;
                end
                4'd9: begin
                    general_Entity <= entity_10;
                end
                4'd10: begin
                    general_Entity <= entity_11;
                end
                4'd11: begin
                    general_Entity <= entity_12;
                end
                4'd12: begin
                    general_Entity <= entity_13;
                end
                4'd13: begin
                    general_Entity <= entity_14;
                end
                4'd14: begin
                    general_Entity <= entity_15;
                end

                default: begin
                    general_Entity <= 18'b111111000000000000;
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
            entity_Counter <= 4'b0000;
            general_Entity <=18'b111111000000000000;
        end 
   
    end

    // Checking whether the Entity in the general entity register should be displayed in the Local tile
   
    wire inRange; // if entity is within the range
    wire range_H; // if entity is within the horizontal range
    wire range_V; // if entity is within vertical range

    // Determine whether the difference between the entity pos and the current block pos is less than the required display length.
    assign range_H = (general_Entity[11:8] - local_Counter_H) < {1'b0,general_Entity[2:0]}; 
    assign range_V = (local_Counter_V - general_Entity[7:4]) == 1'b0;
    assign inRange = range_H && range_V;


    //These registers are used to address the ROM.
    reg [8:0] detector;    // Data Format: [8:6] Row number, [5:2] Entity ID, [1:0] Orientation  
    reg [8:0] out_entity;  
    
    // Send entity data to the ROM depending on the contents of the processed tile and slot type. 
    always @(posedge clk) begin 

        if (!reset) begin
            // depending on the slot type, send the appropriate row to the Sprite ROM

            if (!(column_Counter == 7 && upscale_Counter_H == 3))begin

                out_entity <= out_entity;
                
                if (inRange && (general_Entity[17:14] != 4'b1111)) begin

                    if (general_Entity[3] == 1'b1) begin
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

    wire [7:0] buffer; // ROM output buffer 
    
    // Read From ROM
    SpriteROM Rom ( 
        .clk(clk),
        .reset(reset),
        .orientation(out_entity[1:0]),
        .sprite_ID(out_entity[5:2]),
        .line_index(out_entity[8:6]),
        .data(buffer)
    );

    
    // Send the appropriate pixel value to the VGA output unit 
    always@(posedge clk)begin 
       
        if(!reset)begin
            colour <= buffer[column_Counter];
        end else begin
            colour <= 1'b1;
        end
        
    end

endmodule


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
        romData[0] = 8'b1_111111_1; // 0000 Heart (6x6)
        romData[1] = 8'b1_111111_1;
        romData[2] = 8'b1_101011_1;
        romData[3] = 8'b1_000101_1;
        romData[4] = 8'b1_000001_1;
        romData[5] = 8'b1_100011_1;
        romData[6] = 8'b1_110111_1;
        romData[7] = 8'b1_111111_1;

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
       if (reset) begin
         hsync <= 0;
         hpos <= 0;
       end else begin
            hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
            if (hmaxxed) begin
                hpos <= 0;
            end else begin
                hpos <= hpos + 1;
            end
       end
    end

    // vertical position counter

    always @(posedge clk) begin
       if (reset) begin
           vsync <= 0;
           vpos <= 0;
       end else begin
           vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
           if (hmaxxed) begin
                if (vmaxxed) begin
                    vpos <= 0;
                end else begin
                    vpos <= vpos + 1;
                end
            end
        end
      end

    // display_on is set when beam is in "safe" visible frame
    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);
    assign frame_end = hblanked && vblanked;
    assign input_enable = (hblanked && vpos < V_DISPLAY);

endmodule
  
module APU (
      input wire clk,
      input wire reset,
      input wire snare_trigger,
      input wire frame_end,
      input wire [9:0] x,
      input wire [9:0] y,
      output wire sound
);

  `define MUSIC_SPEED   1'b1;  // for 60 FPS

  reg [11:0] frame_counter;
  wire [12:0] timer = frame_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]
    
  // snare noise - using linear feedback shift register  
  reg noise;
  reg noise_src;
  reg [2:0] noise_counter;
  reg [12:0] lfsr;
  
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  always @(posedge clk) begin
    lfsr <= {lfsr[11:0], feedback};
    noise_src <= lfsr;
  end

  wire snare  = snare_active & noise & x < envelopeB*4;   // noise with half a second envelope

  reg prev_snare_trigger = 0;
  reg snare_start;
  reg snare_active = 0;

  reg [14:0] line_counter = 0;  // Enough bits to count up to ~32k lines
 
  // Triggering SFX
  always @(posedge clk) begin // triggering SFX
        prev_snare_trigger <= snare_trigger & ~snare_active;
        snare_start <= ~prev_snare_trigger & snare_trigger;
        if (snare_start & ~snare_active) begin
            snare_active <= 1;
            line_counter <= 0;
        end
        // Count scanlines only if snare is active
        if (snare_active && x == 0) begin
            line_counter <= line_counter + 1;
            if (line_counter >= 6000) begin
                snare_active <= 0;
            end
        end
  end
  
  // SFX Timers  
  always @(posedge clk) begin
    if (reset) begin
      frame_counter <= 0;
      noise_counter <= 0;
      noise <= 0;
    end else begin
      // frame counter
      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end
      // noise timer
      if (x == 0) begin
        if (noise_counter > 1) begin 
          noise_counter <= 0;
          noise <= noise ^ noise_src;
        end else
          noise_counter <= noise_counter + 1'b1;
      end
    end
  end

  // output
  assign sound = {snare};

endmodule

// NES Reciever Module

module InputReceiver (
    input wire clk,
    input wire reset,
    input wire data,     // input data from nes controller to FPGA
    output reg latch,    // parallel -> serial switch for gamepad switch register
    output reg nes_clk,  // outputs from FPGA to nes controller
    output wire A,        
    output wire B,       
    output wire select,
    output wire start,
    output wire up,
    output wire down,
    output wire left,
    output wire right   // output states of nes controller buttons
);

    // FSM symbolic states
    localparam [3:0] latch_en = 4'h0;       // assert latch for 12 us
    localparam [3:0] read_A_wait = 4'h1;
    localparam [3:0] read_B = 4'h2;
    localparam [3:0] read_select  = 4'h3;
    localparam [3:0] read_start   = 4'h4;
    localparam [3:0] read_up      = 4'h5;
    localparam [3:0] read_down    = 4'h6;
    localparam [3:0] read_left    = 4'h7;
    localparam [3:0] read_right   = 4'h8;

    // register to count clock cycles to time latch assertion, nes_clk state, and FSM state transitions	 
    reg [10:0] count_reg, count_next;

    // FSM state register, and button state regs
    reg [3:0] state_reg, state_next;
    reg A_reg, B_reg, select_reg, start_reg, up_reg, down_reg, left_reg, right_reg;
    reg A_next, B_next, select_next, start_next, up_next, down_next, left_next, right_next;
    reg latch_next, nes_clk_next;

     // infer all the registers
    always @(posedge clk)

    if (reset) begin
        count_reg  <= 0;
        state_reg  <= 0;
        A_reg      <= 0;
        B_reg      <= 0;
        select_reg <= 0;
        start_reg  <= 0;
        up_reg     <= 0;
        down_reg   <= 0;
        left_reg   <= 0;
        right_reg  <= 0;
        nes_clk    <= 0;
        latch      <= 0;

    end else begin
        count_reg  <= count_next;
        state_reg  <= state_next;
        A_reg      <= A_next;
        B_reg      <= B_next;
        select_reg <= select_next;
        start_reg  <= start_next;
        up_reg     <= up_next;
        down_reg   <= down_next;
        left_reg   <= left_next;
        right_reg  <= right_next;
        nes_clk    <= nes_clk_next;
        latch      <= latch_next;
    end

    // FSM next-state logic and data path
    always @(posedge clk) begin

        // defaults
        count_next  <= count_reg;
        A_next      <= A_reg;
        B_next      <= B_reg;
        select_next <= select_reg;
        start_next  <= start_reg;
        up_next     <= up_reg;
        down_next   <= down_reg;
        left_next   <= left_reg;
        right_next  <= right_reg;
        state_next  <= state_reg;

        case (state_reg)

            latch_en: begin
                // assert latch pin
                latch_next <= 1;
                nes_clk_next <= 0;  // nes_clk state

                // count 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // once 12 us passed
                else if (count_reg == 300) begin
                    latch_next <= 0;  // deassert latch pin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_A_wait;  // go to read_A_wait state
                end
            end

            read_A_wait: begin

                nes_clk_next <= 0;  // nes_clk state

                if (count_reg == 0) begin
                    A_next <= data;  // read A
                end

                if (count_reg < 150)  // count clk cycles for 6 us
                count_next <= count_reg + 1;

                // once 6 us passed
                else if (count_reg == 150) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_B;  // go to read_B state
                end
            end

            read_B: begin

                // count clk cycles for 12 us
                if (count_reg < 300) begin
                    count_next <= count_reg + 1;
                end

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next<= 1;

                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read B
                if (count_reg == 150)
                    B_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_select;  // go to read_select state
                end
            end

            read_select: begin

                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read select
                if (count_reg == 150)
                    select_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_start;  // go to read_start state
                end

            end

            read_start: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read start
                if (count_reg == 150)
                    start_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_up;  // go to read_up state
                end
            end

            read_up: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read up
                if (count_reg == 150)
                    up_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_down;  // go to read_down state
                end
            end

            read_down: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read down
                if (count_reg == 150) begin
                    down_next <= data;
                end

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_left;  // go to read_left state
                end
            end

            read_left: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read left
                if (count_reg == 150)
                    left_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_right;  // go to read_right state
                end

            end

            read_right: begin
                // count clk cycles for 12 us
                if (count_reg < 300) begin
                    count_next <= count_reg + 1;
                end

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read right
                if (count_reg == 150)
                    right_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= latch_en;  // go to latch_en state
                end
            end

            default: state_next <= latch_en;  // default state
        endcase
    end

    // assign outputs, *normally asserted when unpressed
    assign A      = ~A_reg;
    assign B      = ~B_reg;
    assign select = ~select_reg;
    assign start  = ~start_reg;
    assign up     = ~up_reg;
    assign down   = ~down_reg;
    assign left   = ~left_reg;
    assign right  = ~right_reg;

endmodule

