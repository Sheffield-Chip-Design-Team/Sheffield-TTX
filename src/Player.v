// Module: Player Logic

/*
   Last Updated: 04:27 18/09/2025 
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
    output reg [1:0] player_orientation,  // player orientation
    output reg [1:0] player_direction,    // player direction
    output reg [3:0] player_sprite,

    output reg [7:0] sword_position,    // sword position xxxx_yyyy
    output reg [3:0] sword_visible,
    output reg [1:0] sword_orientation  // sword orientation
);

  // State definitions
  localparam IDLE_STATE = 2'b00;  // Move when there is input from the controller
  localparam ATTACK_STATE = 2'b01;  // Sword appears where the player is facing
  localparam MOVE_STATE = 2'b10;  // Wait for input and stay idle
  localparam ATTACK_DURATION = 6'b000_100;

  wire [4:0] pressed_buttons;
  wire [4:0] released_buttons;
  assign pressed_buttons  = input_data[9:5];  // up, down, left, right, attack
  assign released_buttons = input_data[4:0];  

  reg [5:0] player_anim_counter;
  reg [5:0] sword_duration;  // how long the sword stays visible - (SET BY ATTACK DURATION)

  // player state register
  reg [1:0] current_state;
  reg [1:0] next_state;
  reg action_complete;  // flag to indicate that the action has been completed

  // sword direction logic register
  reg [1:0] last_direction;
  reg direction_stored;

  reg [4:0] input_buffer;  // keeps input till there is a release

  always @(posedge clk) begin // Movement Input FSM
    if (~reset) begin

      if (pressed_buttons != 5'b00000) begin
        input_buffer <= input_data[9:5];
      end
      
      else if (released_buttons != 5'b00000) begin
          // reset input buffer when buttons are released
          input_buffer <= 0;
      end

      if (trigger) begin
        // switch between states on trigger
        current_state <= next_state;  // Update state
      end

    end else begin
        input_buffer  <= 0;
        current_state <= 0;
      end
  end


  always @(posedge clk) begin  // animation FSM
    if (~reset) begin

      if (trigger) begin

        if (sword_visible == 4'b0001) begin
          sword_duration <= sword_duration + 1;
        end else begin
          sword_duration <= 0;
        end

        if (player_anim_counter == 20) begin
          player_anim_counter <= 0;
          player_sprite <= 4'b0011;
        end else if (player_anim_counter == 7) begin
          player_sprite <= 4'b0010;
          player_anim_counter <= player_anim_counter + 1;
        end else begin
          player_anim_counter <= player_anim_counter + 1;

        end
      end end else begin  // reset attack
        sword_duration <= 0;
        player_sprite <= 4'b0011;
        player_anim_counter <= 0;
    end
  end

  always @(posedge clk) begin  // Player State FSM

    if (~reset) begin

      // Reset the action_complete flag when buttons are released
      if (pressed_buttons != 5'b00000) begin
        action_complete <= 0;
        direction_stored <= 0;
      end

      case (current_state)

        IDLE_STATE: begin

          sword_position <= 0;

          case (input_buffer[4])
            1: begin  // attack
              if(~action_complete) begin
                next_state <= ATTACK_STATE;
              end
            end

            0: begin  // no attack
              // Can't access a switch to MOVE_STATE until action_complete is reset to 0
              if (input_buffer[3:0] != 0 && ~action_complete) begin
                next_state <= MOVE_STATE;
              end
            end

            default: begin
              next_state <= IDLE_STATE;  // Default case, stay in IDLE state
            end
          endcase
        end

        MOVE_STATE: begin
          // Can't move if action is already complete
          if (~action_complete) begin
            // Move player based on direction inputs and update orientation
            // Check boundary for up movement
            if (input_buffer[0] == 1 && player_pos[3:0] > 4'b0001) begin
              player_pos <= player_pos - 1;  // Move up
              player_direction <= 2'b00;
              action_complete <= 1;
            end

            // Check boundary for down movement
            if (input_buffer[1] == 1 && player_pos[3:0] < 4'b1011) begin
              player_pos <= player_pos + 1;  // Move down
              player_direction <= 2'b10;
              action_complete <= 1;
            end

            // Check boundary for left movement
            if (input_buffer[2] == 1 && player_pos[7:4] > 4'b0000) begin
              player_pos <= player_pos - 16;  // Move left
              player_orientation <= 2'b11;
              player_direction <= 2'b11;
              action_complete <= 1;
            end

            // Check boundary for right movement
            if (input_buffer[3] == 1 && player_pos[7:4] < 4'b1111) begin
              player_pos <= player_pos + 16;  // Move right
              player_orientation <= 2'b01;
              player_direction <= 2'b01;
              action_complete <= 1;
            end

          end else begin
            next_state <= IDLE_STATE;  // Return to IDLE after moving
          end

        end

        ATTACK_STATE: begin
          if(~action_complete && input_buffer[4]!=0) begin
            // Check if the sword direction is specified by the player
            if(input_buffer[3:0] != 0) begin
              if (input_buffer[0] == 1) begin
                last_direction   <= 2'b00;
                player_direction <= 2'b00;
                direction_stored <= 1;
              end

              if (input_buffer[1] == 1) begin
                last_direction   <= 2'b10;
                player_direction <= 2'b10;
                direction_stored <= 1;
              end

              if (input_buffer[2] == 1) begin
                last_direction   <= 2'b11;
                player_direction <= 2'b11;
                direction_stored <= 1;
              end

              if (input_buffer[3] == 1) begin
                last_direction   <= 2'b01;
                player_direction <= 2'b01;
                direction_stored <= 1;
              end
            end
            
            // if not, use the last direction
            else begin
              last_direction <= player_direction;
              direction_stored <= 1;
            end
          end

          if (direction_stored) begin
            // Set sword orientation
            sword_orientation <= last_direction;

            // Set sword location
            if (last_direction == 2'b00) begin  // player facing up
              sword_position <= player_pos - 1;
            end

            if (last_direction == 2'b10) begin  // player facing down
              sword_position <= player_pos + 1;
            end

            if (last_direction == 2'b11) begin  // player facing left
              sword_position <= player_pos - 16;
            end

            if (last_direction == 2'b01) begin  // player facing right
              sword_position <= player_pos + 16;
            end

            sword_visible <= 4'b0001; // Make sword visible
            // reset
            action_complete <= 1; // Set action complete flag
            direction_stored <= 0; // reset direction_stored flag
          end

          if (sword_duration == ATTACK_DURATION) begin // Attack State duration
            sword_visible  <= 4'b0000; // Make sword invisible
            next_state <= IDLE_STATE;  // Return to IDLE after attacking
          end
        end


        default: begin
          next_state <= IDLE_STATE;  // Default case, stay in IDLE state
        end
      endcase

    end else begin
      next_state <= 0;
      player_pos <= 8'b0001_0011;
      player_orientation <= 2'b01;
      player_direction <= 2'b01;
      action_complete <= 0;
      direction_stored <= 0;
    end
  end

endmodule
