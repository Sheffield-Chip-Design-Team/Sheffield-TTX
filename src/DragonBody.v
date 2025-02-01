
// Module : Dragon Body
// Author: Bowen Shi

/* 
    Description:
    The Dragon body segment 
            
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
    