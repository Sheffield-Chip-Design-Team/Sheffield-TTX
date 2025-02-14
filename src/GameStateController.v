// Game control Unit
// Last Updated: 31/01/2025 @ 16:23:52

module GameStateControlUnit (
    input wire        clk,
    input wire        reset,
    input wire [7:0]  playerPos,
    input wire [7:0]  swordPos,
    input wire [7:0]  sheepPos,
    input wire [55:0] dragonSegmentPositions,
    input wire [6:0]  activeDragonSegments,
    output reg        playerDragonCollision,
    output reg        swordDragonCollision,
    output reg        sheepDragonCollision
);

    reg       checksegment;
    reg [2:0] segmentCounter = 0;
    reg [7:0] dragonSegment;

    wire PlayerDragonCollisionFlag;
    wire SwordDragonCollisionFlag;
    wire SheepDragonCollisionFlag;
    
    // make comparison to determine if there is a collision.

    Comparator dragonPlayer(
        .inA(playerPos),
        .inB(dragonSegment),
        .out(PlayerDragonCollisionFlag)
    );

    Comparator dragonSword(
        .inA(swordPos),
        .inB(dragonSegment),
        .out(SwordDragonCollisionFlag)
    );

    Comparator dragonSheep(
        .inA(sheepPos),
        .inB(dragonSegment),
        .out(SheepDragonCollisionFlag)
    );

    always@(posedge clk) begin

        if (!reset) begin
            
            //check that current dragon segement is active
            checksegment <= ((8'b0000_0001 << segmentCounter) & (activeDragonSegments[segmentCounter]) != 0);

            playerDragonCollision <= playerDragonCollision | PlayerDragonCollisionFlag;
            swordDragonCollision  <= swordDragonCollision  | SwordDragonCollisionFlag;
            sheepDragonCollision  <= sheepDragonCollision  | SheepDragonCollisionFlag;

            case(segmentCounter) // check against each active dragon segment.
                    
                    0: begin
                        if (checksegment) begin   // read from the first dragon segment
                            dragonSegment <= dragonSegmentPositions[7:0];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    1: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[15:8];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    2: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[23:16];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    3: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[31:24];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    4: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[39:32];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    5: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[47:40];
                        end segmentCounter <= segmentCounter + 1;
                    end

                    6: begin
                        if (checksegment) begin 
                            dragonSegment <= dragonSegmentPositions[55:48];
                        end
                    end

            endcase

        end else begin              // reset any collision data after each frame.
             segmentCounter <= 0;
             playerDragonCollision <= 0;
             swordDragonCollision <= 0;
             sheepDragonCollision <= 0;
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