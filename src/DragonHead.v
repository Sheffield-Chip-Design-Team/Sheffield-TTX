// Module : Dragon Head
// Author: Abdulatif Babli
/* 
    Description: 
        The dragon head module contains the movement logic for the dragon's head. The body segments then move in turn
        lagging behind the head.
            
*/

module DragonHead (  

    input clk,
    input reset,
    input [7:0] targetPos,
  
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
           
            // todo : dragon location should reset to top left

            if(pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movement_counter < 6'd12) begin
                    movement_counter <= movement_counter + 1;
                
                end else begin
                    movement_counter <= 0;
                    // Store the current position before updating , used later
                    dragon_x <= dragon_pos[7:4];
                    dragon_y <= dragon_pos[3:0];

                    // Calculate the differences between dragon and player
                    dx <= targetPos[7:4] - dragon_x;
                    dy <= targetPos[3:0] - dragon_y ;
                    sx <= (dragon_x < targetPos[7:4]) ? 1 : -1; // Direction in axis
                    sy <= (dragon_y < targetPos[3:0]) ? 1 : -1; 

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