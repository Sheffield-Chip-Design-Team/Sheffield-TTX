
// Module: Player Logic

/*
   Author: Anubhav Avinaash, James Ashie Kotey, Bowen Shi
   Description:    
               Player Logic FSM.
   Last Updated:
*/

module PlayerLogic(
    input clk,
    input reset,
    input wire [4:0] input_data,
    input wire frame_end,

    output reg [7:0] player_pos,
    output reg [1:0] player_orientation,   // player orientation 
    output reg [1:0] player_direction,   // player direction
    output reg [3:0] player_sprite,

    output reg [7:0] sword_position, // sword position xxxx_yyyy
    output reg [3:0] sword_visible,
    output reg [1:0] sword_orientation   // sword orientation 
    
);

    // State definitions
    localparam IDLE_STATE   = 2'b00;  // Move when there is input from the controller
    localparam ATTACK_STATE = 2'b01;  // Sword appears where the player is facing
    localparam MOVE_STATE   = 2'b10;  // Wait for input and stay idle

    reg [5:0] player_anim_counter;
    reg [5:0] sword_duration; // how long the sword stays visible

    // player state register
    reg [1:0] current_state;
    reg [1:0] next_state;


    reg sword_duration_flag;
    reg sword_duration_flag_local;


    always @(negedge clk) begin //<<<<<IMPORTANT<<<<<< negedge is aviable in vga playground and FPGA. Probably some timing issue but not sure
        if(~reset)begin           

            if(frame_end)begin
                    // Update state
                current_state <= next_state;

                sword_duration_flag_local <= sword_duration_flag; 
                if(sword_duration_flag != sword_duration_flag_local)begin
                    sword_duration<=0;
                end else begin
                    sword_duration <= sword_duration + 1;
                end

                // player_anim_counter <= player_anim_counter + 1;
                if (player_anim_counter == 20) begin
                    player_anim_counter <= 0;
                    player_sprite <= 4'b0011;
                end else if (player_anim_counter == 7) begin
                    player_sprite <= 4'b0010;
                    player_anim_counter <= player_anim_counter +1;
                end else begin
                    player_anim_counter <= player_anim_counter +1;  
                end
            end
        end else begin
            current_state <= 0;
            sword_duration <= 0;
            player_anim_counter <= 0;
        end
    end

    always @(posedge clk) begin
        if(~reset)begin
            case (current_state)

                IDLE_STATE: begin
                    sword_position <= 0;
                    sword_visible <= 4'b1111;

                    case (input_data[4]) 
                        1 : begin // attack
                            next_state <= ATTACK_STATE;
                            sword_duration_flag <= sword_duration_flag + 1;
                        end

                        0: begin // no attack

                        if (input_data[3:0] != 0 ) // directional buttons
                            next_state <= MOVE_STATE;  // Default case, stay in IDLE state
                        end

                        default: begin
                            next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                        end

                    endcase               
                end

                MOVE_STATE: begin
                    // Move player based on direction inputs and update orientation
                    if (input_data[0] == 1 && player_pos[3:0] > 4'b0001) begin   // Check boundary for up movement
                        player_pos <= player_pos - 1;  // Move up
                        player_direction <= 2'b00;
                    end

                    if (input_data[1] == 1 && player_pos[3:0] < 4'b1011) begin  // Check boundary for down movement
                        player_pos <= player_pos + 1;  // Move down
                        player_direction <= 2'b10;
                    end 

                    if (input_data[2] == 1 && player_pos[7:4] > 4'b0000) begin  // Check boundary for left movement
                        player_pos <= player_pos - 16;  // Move left
                        player_orientation <= 2'b11;
                        player_direction <= 2'b11;
                    end

                    if (input_data[3] == 1 && player_pos[7:4] < 4'b1111) begin  // Check boundary for right movement
                        player_pos <= player_pos + 16;  // Move right
                        player_orientation <= 2'b01;
                        player_direction <= 2'b01;
                    end

                    next_state <= IDLE_STATE;  // Return to IDLE after moving
                    // player_anim_counter <= 0;
                end

                ATTACK_STATE: begin
                    sword_visible <= 4'b0001;
                    if (player_direction == 2'b00 ) begin // player facing up
                        sword_position <= player_pos - 1;
                        sword_orientation <= 2'b00;
                    end if (player_direction == 2'b10 ) begin // player facing down
                        sword_position <= player_pos + 1;
                        sword_orientation <= 2'b10;
                    end if (player_direction == 2'b11) begin // player facing left
                        sword_position <= player_pos - 16;
                        sword_orientation <= 2'b11;
                    end if (player_direction == 2'b01) begin // player facing right
                        sword_position <= player_pos + 16;
                        sword_orientation <= 2'b01;
                    end

                    if (sword_duration == 10)
                        next_state <= IDLE_STATE;  // Return to IDLE after attacking
                        // player_anim_counter <= 0;
                end

                default: begin
                    next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                end
            endcase
        end else begin
        sword_duration_flag <= 0;
        next_state <= 0;
        player_orientation <= 2'b01;
        player_direction <= 2'b01;
        end
    end

    endmodule
