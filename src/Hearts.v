//Hearts Module
//Stores and decrements the value of player lives
//Author: Rupert Bowen, 26/03/2025


module Hearts #(parameter [6:0] PlayerTolerance = 60)( //add reset line
    input clk,
    input reset,
    input vsync,
    input PlayerDragonCollision,
    output reg [1:0] playerLives
    );
    reg [6:0] buffer = 0;
    reg vsyncPrior = 0;
    
    initial begin
        playerLives <= 3;
    end
    always @(posedge clk) begin
        
        if (reset) begin //When reset goes high, set player lives to 3
            playerLives <= 3;
        end
        else begin
            if (vsync != vsyncPrior) begin
                if (vsync) begin //Posedge Vsync
                    if(PlayerDragonCollision) begin
                        if (PlayerTolerance > buffer) begin //Increments buffer until reaches defined value - Provides tolerance to the player
                            buffer <= buffer +1;
                        end
                        else begin
                            if (playerLives > 0) begin  //Player is damaged
                                playerLives <= playerLives -1;
                            end
                        buffer <= 0;
                        end
                    end
                    else begin
                        buffer <=0;
                    end 
                end
                vsyncPrior <= vsync;
            end 
            
        end
     
    end
endmodule
