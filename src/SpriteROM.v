
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
    /*

        romData[0] = 8'b1_111111_1; // 0000 Heart (6x6)
        romData[1] = 8'b1_111111_1;
        romData[2] = 8'b1_101011_1;
        romData[3] = 8'b1_000101_1;
        romData[4] = 8'b1_000001_1;
        romData[5] = 8'b1_100011_1;
        romData[6] = 8'b1_110111_1;
        romData[7] = 8'b1_111111_1;



    */
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
