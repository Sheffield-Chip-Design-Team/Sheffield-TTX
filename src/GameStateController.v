// Game control Unit
// Last Updated: 31/01/2025 @ 16:23:52

module GameStateControlUnit (
    input wire        clk,
    input wire        reset,
    input wire [7:0]  playerPos,
    input wire [55:0] dragonSegmentPositions,
    input wire [6:0]  activeDragonSegments,
    output wire       playerDragonCollisionFlag

);

    reg [2:0] stateReg = 0;
    reg [7:0] currentSegment;
    reg       collsionCollector;
    reg       checksegment;
    
    // make comparison to determine if there is a collision.

    Comparator collisionDetector(
    .inA(playerPos),
    .inB(currentSegment),
    .out(playerDragonCollisionFlag)
    );

    always@(posedge clk) begin

        if (!reset) begin
            
            checksegment <= (stateReg & activeDragonSegments[stateReg]);
            collsionCollector <= collsionCollector | playerDragonCollisionFlag;

            case(stateReg)
                0: begin    // read from the first dragon segment
                    currentSegment <= dragonSegmentPositions[7:0];
                    stateReg = stateReg + 1;
                end

                1: begin
                    currentSegment <= dragonSegmentPositions[15:8];
                    stateReg = stateReg + 1;
                end

                2: begin
                    currentSegment <= dragonSegmentPositions[23:16];
                    stateReg = stateReg + 1;
                end

                3: begin
                    currentSegment <= dragonSegmentPositions[31:24];
                    stateReg = stateReg + 1;
                end

                4: begin
                    currentSegment <= dragonSegmentPositions[39:32];
                    stateReg = stateReg + 1;
                end

                5: begin
                    currentSegment <= dragonSegmentPositions[47:40];
                    stateReg = stateReg + 1;
                end

                6: begin
                    currentSegment <= dragonSegmentPositions[55:48];
                    stateReg = 0;
                end

            endcase

        end else begin
             stateReg = 0;
        end

    end

endmodule

module Comparator (
    input wire [7:0] inA,
    input wire [7:0] inB,
    output wire out
);

    assign out = (inA == inB);

endmodule