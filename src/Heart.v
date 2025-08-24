// Module: Hearts Controller
// Author: Rupert Bowen

module Hearts #(parameter [6:0] PlayerTolerance = 60)
 ( 
    input clk,
    input reset,
    input vsync,
    input PlayerDragonCollision,
    output reg PlayerHurt,
    output reg [1:0] playerLives
    );
    reg [6:0] buffer = 0;
    reg prev_vsync = 0;
    
    initial begin
        playerLives <= 3;
    end
    
    always @(posedge clk) begin
        
        PlayerHurt = 0;

        if (reset) begin //When reset goes high, set player lives to 3
            playerLives <= 3;
        end

        else begin
            if (vsync != prev_vsync) begin
                if (vsync) begin //Posedge Vsync
                    if(PlayerDragonCollision) begin
                        if (PlayerTolerance > buffer) begin //Increments buffer until reaches defined value - Provides tolerance to the player
                            buffer <= buffer +1;
                        end
                        else begin
                            if (playerLives > 0) begin  // Player is damaged
                                playerLives <= playerLives -1;
                                PlayerHurt = 1;
                            end
                        buffer <= 0;
                        end
                    end
                    else begin
                        buffer <=0;
                    end 
                end
                prev_vsync <= vsync;
            end 
        end
    end
endmodule
