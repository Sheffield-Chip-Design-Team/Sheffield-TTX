
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
    input heal,                         // grow
    input hit,                          // shrink
    input [5:0] movementCounter,
    input [9:0] Dragon_Head,            // [9:8] orientation, [7:0]  position

    output reg [9:0] Dragon_1,          // Every 10 bit represent a body segment, Maximum of 8 segments, works as a queue.
    output reg [9:0] Dragon_2,
    output reg [9:0] Dragon_3,
    output reg [9:0] Dragon_4,
    output reg [9:0] Dragon_5,
    output reg [9:0] Dragon_6,
    output reg [9:0] Dragon_7,

    output reg [6:0] Display_en
    );

    // lengthUpdate states

    localparam MOVE = 2'b00; // do nothing
    localparam IDLE = 2'b11; // do nothing
    localparam HEAL = 2'b01; // grow
    localparam HIT = 2'b10;  // shrink


    reg pre_vsync;

    always @(posedge clk)begin
        
        if (~reset) begin
        
            pre_vsync <= vsync;

            if (pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movementCounter == 6'd10) begin
                    Dragon_1 <= Dragon_Head;
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

    always @( posedge clk )begin
        
        if(~reset) begin
            case(1'b1) 
                heal: begin
                    Display_en <= (Display_en << 1) | 7'b0000001;
                end
                hit: begin
                    Display_en <= Display_en >> 1;
                end
                default: Display_en <= Display_en;
            endcase
        end else begin
            Display_en <= 7'b0000001;
        end
    end

    endmodule