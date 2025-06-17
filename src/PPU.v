// Module: Picture Processing Unit 
// Author: Bowen Shi
// Last Updated: 19:37 16/06/2025 

// NOTE: Version in simulation has different port names (entity slots)

// `include SpriteROM.v

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
//
*/


module PictureProcessingUnit(
    input clk_in,
    input reset,    
    input wire [17:0] entity_1,  
    input wire [17:0] entity_2,  
    input wire [17:0] entity_3,  
    input wire [17:0] entity_4,
    input wire [17:0] entity_5,
    input wire [17:0] entity_6,
    input wire [17:0] entity_7, 
    input wire [17:0] entity_8,
    
    input wire [17:0] dragon_1,
    input wire [17:0] dragon_2,
    input wire [17:0] dragon_3,
    input wire [17:0] dragon_4,
    input wire [17:0] dragon_5,
    input wire [17:0] dragon_6,
    input wire [17:0] dragon_7,

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
                    general_Entity <= dragon_1;
                end
                4'd9: begin
                    general_Entity <= dragon_2;
                end
                4'd10: begin
                    general_Entity <= dragon_3;
                end
                4'd11: begin
                    general_Entity <= dragon_4;
                end
                4'd12: begin
                    general_Entity <= dragon_5;
                end
                4'd13: begin
                    general_Entity <= dragon_6;
                end
                4'd14: begin
                    general_Entity <= dragon_7;
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
    assign range_V = (local_Counter_V - general_Entity[7:4]) == 4'b0000;
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

