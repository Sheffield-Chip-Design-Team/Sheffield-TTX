
// Module: Player Logic

/*
   Last Updated: 27/12/2024 @ 00:15:32
   Authors: Anubhav Avinaash, James Ashie Kotey, Bowen Shi.
   Description:    
        Player Logic FSM - movement and attack control. 
        Collisions, lives and respawns managed centrally in the Game State Controller.
*/

module PlayerLogic (

    input            clk,
    input            reset,
    input wire       trigger,
    input wire [9:0] input_data,

    output reg [7:0] player_pos,
    output reg [1:0] player_orientation, // player orientation 
    output reg [1:0] player_direction,   // player direction
    output reg [3:0] player_sprite,

    output reg [7:0] sword_position,     // sword position xxxx_yyyy
    output reg [3:0] sword_visible,
    output reg [1:0] sword_orientation   // sword orientation   
);

    // State definitions
    localparam IDLE_STATE   = 2'b00;  // Move when there is input from the controller
    localparam ATTACK_STATE = 2'b01;  // Sword appears where the player is facing
    localparam MOVE_STATE   = 2'b10;  // Wait for input and stay idle
    localparam ATTACK_DURATION = 3'b101;

    reg [5:0] player_anim_counter;
    reg [5:0] sword_duration; // how long the sword stays visible - (SET BY ATTACK DURATION)

    // player state register
    reg [1:0] current_state;
    reg [1:0] next_state;

    // sword direction logic register
    reg [1:0] last_direction;

    reg sword_duration_flag;
    reg sword_duration_flag_local;

    //Delay registers - to fix tiiming issues when using all posedge
    reg delayedTrigger;
    reg [9:0] inputDelay;


    always @(posedge clk )begin // transition control fsm
        delayedTrigger <= trigger;
    end

    always @(posedge trigger) begin // store input in delay reg
           inputDelay <= input_data;
    end

    always @(posedge delayedTrigger) begin
            current_state <= next_state; // Update state
    end


    
    always @(posedge trigger) begin  // animation FSM

        if (~reset) begin           

                if (player_anim_counter == 20) begin
                    player_anim_counter <= 0;
                    player_sprite <= 4'b0011;
                end else if (player_anim_counter == 7) begin
                    player_sprite <= 4'b0010;
                    player_anim_counter <= player_anim_counter +1;
                end else begin
                    player_anim_counter <= player_anim_counter +1;  
                end

        end else begin // reset to idle
            current_state <= 0;
        end
    end

    always @(posedge clk) begin  // sword FSM - TODO: refactor to not be dependant on clk

        if (~reset) begin           

            if (delayedTrigger) begin  
                sword_duration_flag_local <= sword_duration_flag; //九曲十八弯，prevents multiple driver issues.   
                if (sword_duration_flag != sword_duration_flag_local) begin
                    sword_duration <= 0;
                end else begin
                    sword_duration <= sword_duration + 1;
                end
            end

        end else begin // reset attack
                player_sprite <= 4'b0011;
                player_anim_counter <= 0;
            end

    end 

    always @(posedge clk) begin // Player State FSM - TODO: refactor to not be dependant on clk

        if(~reset)begin
            case (current_state)
                
                IDLE_STATE: begin
                    
                    sword_position <= 0;
                    sword_visible <= 4'b1111;

                    case (input_data[9]) 
                        1 : begin // attack
                            next_state <= ATTACK_STATE;
                            sword_duration_flag <= sword_duration_flag + 1;
                        end

                        0: begin // no attack
                            if (input_data[8:5] != 0 ) // directional buttons - pressed
                                next_state <= MOVE_STATE;  // Default case, stay in IDLE state
                        end

                        default: begin
                            next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                        end
                    endcase    
      
                end

                MOVE_STATE: begin
                    // Move player based on direction inputs and update orientation
                    if (inputDelay[5] == 1 && player_pos[3:0] > 4'b0010) begin   // Check boundary for up movement
                        player_pos <= player_pos - 1;  // Move up
                        player_direction <= 2'b00;
                    end

                    if (inputDelay[6] == 1 && player_pos[3:0] < 4'b1011) begin  // Check boundary for down movement
                        player_pos <= player_pos + 1;  // Move down
                        player_direction <= 2'b10;
                    end 

                    if (inputDelay[7] == 1 && player_pos[7:4] > 4'b0000) begin  // Check boundary for left movement
                        player_pos <= player_pos - 16;  // Move left
                        player_orientation <= 2'b11;
                        player_direction <= 2'b11;
                    end

                    if (inputDelay[8] == 1 && player_pos[7:4] < 4'b1111) begin  // Check boundary for right movement
                        player_pos <= player_pos + 16;  // Move right
                        player_orientation <= 2'b01;
                        player_direction <= 2'b01;
                    end

                    inputDelay <= 0;            // clear the register to prevent repeat moves
                    next_state <= IDLE_STATE;   // Return to IDLE after moving

                end

                ATTACK_STATE: begin
                    last_direction <= player_direction;

                    // Check if the sword direction is specified by the player - why does it need to set both?
                    if (input_data[5] == 1) begin   
                        last_direction <= 2'b00;
                        player_direction <= 2'b00;
                    end

                    if (input_data[6] == 1) begin  
                        last_direction <= 2'b10;
                        player_direction <= 2'b10;
                    end 

                    if (input_data[7] == 1) begin
                        last_direction <= 2'b11;
                        player_direction <= 2'b11;
                    end

                    if (input_data[8] == 1) begin
                        last_direction <= 2'b01;
                        player_direction <= 2'b01;
                    end

                    if (input_data[4] == 1) begin                    
                        // Set sword orientation
                        sword_orientation <= last_direction;

                        // Set sword location
                        if (last_direction == 2'b00 ) begin // player facing up
                            sword_position <= player_pos - 1;
                        end 

                        if (last_direction == 2'b10 ) begin // player facing down
                            sword_position <= player_pos + 1;
                        end 

                        if (last_direction == 2'b11) begin // player facing left
                            sword_position <= player_pos - 16;
                        end 

                        if (last_direction == 2'b01) begin // player facing right
                            sword_position <= player_pos + 16;
                        end

                        // Make sword visible
                        sword_visible <= 4'b0001;
                    end 

                    if (sword_duration == ATTACK_DURATION) // Attack State duration
                        next_state <= IDLE_STATE;  // Return to IDLE after attacking
                end

                default: begin
                    next_state <= IDLE_STATE;  // Default case, stay in IDLE state
                end
            endcase
        
        end else begin

            sword_duration_flag <= 0;
            next_state <= 0;
            player_pos <= 8'b0001_0011;
            player_orientation <= 2'b01;
            player_direction <= 2'b01;

        end
    end

endmodule