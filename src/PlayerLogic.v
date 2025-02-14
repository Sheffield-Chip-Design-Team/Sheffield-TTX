
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
  localparam ATTACK_DURATION = 3'b010;

  reg [5:0] player_anim_counter;
  reg [5:0] sword_duration;  // how long the sword stays visible - (SET BY ATTACK DURATION)

  // player state register
  reg [1:0] current_state;
  reg [1:0] next_state;
  reg action_complete;  // flag to indicate that the action has been completed

  // sword direction logic register
  reg [1:0] last_direction;
  reg direction_stored;

  reg [9:0] input_buffer;  // keeps input till there is a release

  always @(posedge clk) begin // Movement Input FSM
    if (~reset) begin
      if (input_data[9:5] != 4'b0000) begin
        input_buffer <= input_data;
      end else if (input_data[4:0] != 5'b00000) begin
        // reset input buffer when buttons are released
        input_buffer <= 0;
        action_complete <= 0;
        direction_stored <= 0;
      end
      if (trigger) begin
        // switch between states on trigger
        current_state <= next_state;  // Update state
      end
    end else begin
      input_buffer  <= 0;
      current_state <= 0;
      action_complete <= 0;
      direction_stored <= 0;
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
      end


    end else begin  // reset attack
      sword_duration <= 0;
      player_anim_counter <= 0;
    end
  end

  always @(posedge clk) begin  // Player State FSM

    if (~reset) begin

      case (current_state)

        IDLE_STATE: begin

          sword_position <= 0;

          case (input_buffer[9])
            1: begin  // attack
              if(~action_complete) begin
                next_state <= ATTACK_STATE;
              end
            end

            0: begin  // no attack
              // Can't access a switch to MOVE_STATE until action_complete is reset to 0
              if (input_buffer[8:5] != 0 && ~action_complete) begin
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
            if (input_buffer[5] == 1 && player_pos[3:0] > 4'b0001) begin
              player_pos <= player_pos - 1;  // Move up
              player_direction <= 2'b00;
              action_complete <= 1;
            end

            // Check boundary for down movement
            if (input_buffer[6] == 1 && player_pos[3:0] < 4'b1011) begin
              player_pos <= player_pos + 1;  // Move down
              player_direction <= 2'b10;
              action_complete <= 1;
            end

            // Check boundary for left movement
            if (input_buffer[7] == 1 && player_pos[7:4] > 4'b0000) begin
              player_pos <= player_pos - 16;  // Move left
              player_orientation <= 2'b11;
              player_direction <= 2'b11;
              action_complete <= 1;
            end

            // Check boundary for right movement
            if (input_buffer[8] == 1 && player_pos[7:4] < 4'b1111) begin
              player_pos <= player_pos + 16;  // Move right
              player_orientation <= 2'b01;
              player_direction <= 2'b01;
              action_complete <= 1;
            end
          end else begin
            next_state <= IDLE_STATE;  // Return to IDLE after moving
            // player_anim_counter <= 0;
          end
        end

        ATTACK_STATE: begin
          if(~action_complete && input_buffer[9]!=0) begin
            // Check if the sword direction is specified by the player
            if(input_buffer[8:5] != 0) begin
              if (input_buffer[5] == 1) begin
                last_direction   <= 2'b00;
                player_direction <= 2'b00;
                direction_stored <= 1;
              end

              if (input_buffer[6] == 1) begin
                last_direction   <= 2'b10;
                player_direction <= 2'b10;
                direction_stored <= 1;
              end

              if (input_buffer[7] == 1) begin
                last_direction   <= 2'b11;
                player_direction <= 2'b11;
                direction_stored <= 1;
              end

              if (input_buffer[8] == 1) begin
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
            sword_visible  <= 4'b1111; // Make sword invisible
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
    end
  end

endmodule
//================================================

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
            
            if(pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movement_counter < 6'd10) begin
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
//================================================

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
    input [1:0] lengthUpdate,           // MUST be a PULSE
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
            case(lengthUpdate) 
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

//================================================

// Module : Sheep Logic

// coordinate system  
// location [7:0]
// location [7:4] - the x coordinates
// location [3:0] - the y coordinates
// the limits for the screen are (0,0) - > (15,11)

module sheepLogic (
    input clk,
    input reset,
    input trigger,
    input wire read_enable, // When high, generate random position for the sheep
    input wire [7:0] dragon_pos, // using as seed value to ensure no overlap
    input wire [7:0] player_pos, // using as seed value to ensure no overlap
    output reg [7:0] sheep_pos, // 8-bit position (4 bits for X, 4 bits for Y)
    output reg [3:0] sheep_visible
);

    wire [7:0] random_value; // 8-bit random value: first 4 bits -> X, last 4 bits -> Y

    // Instantiate the random number generator with seeded initial value
    rand_num rng (
        .clk(clk),
        .reset(reset),
        .seed((player_pos ^ dragon_pos) + 1'b1), // Seed with XOR of player and dragon positions +1
        .rdm_num(random_value)                // Random value generated by the RNG

    );

    always @(posedge clk) begin
        if (reset) begin
            // Reset condition: sheep is not visible and position off-screen
            sheep_visible <= 0;
            // sheep_pos <= 8'b0; // Initialize to 0 during reset
        end else if (read_enable) begin
            // Sheep becomes visible
            sheep_visible <= 1; 
            // Generate a valid position
            // add masks to enforce limit
            sheep_pos[7:4] <= random_value[7:4]; 
            
            // enforce limit 
            if (random_value[3:0] > 11) begin // can probably be minimised
                sheep_pos[3:0] <= ~random_value[3:0];
            end else begin
                sheep_pos[3:0] <= random_value[3:0];
            end

        end
    end
    /*

        y position  correction
            0000       - 
            0001       -
            0010       -
            0011       -
            0100       -
            0101       -
            0110       -
            0111       -
            1000       -
            1001       -
            1010       -
            1011       -
            1100       0011
            1101       0010
            1110       0001  
            1111       0000
    */

    endmodule

    module rand_num (
        input wire clk,
        input wire reset,
        input wire [7:0] seed, // Seed input for initializing randomness
        output reg [7:0] rdm_num
    );

    reg [2:0] counter;

    always @(posedge clk or posedge reset) begin
        
        if (reset) begin // for when we need a new random immediately
            rdm_num <= seed;  // Initialize value using the trigger
            counter <= 7;     // Reset counter
        
        end else if (counter > 0) begin
            // Shift and apply feedback for randomness
            rdm_num[6:0] <= rdm_num[7:1];  // Shift all bits
            rdm_num[7] <= rdm_num[6] ^ rdm_num[5] ^ rdm_num[4]; // Feedback XOR for randomness
            counter <= counter - 1;        // Decrement counter

        end else begin
            counter <= 7;  // Reset counter for next random number
            rdm_num <= seed;
        end
    end

endmodule




//================================================
// Module - Sync Unit Ouput Module 

/*
    Description: 
            Generates sync pulses for VGA monitor, (H-SYNC ,V-SYNC) targeted to 640 * 480 output, 
            Pixel coordinates for the graphics controller,
            and sync signals for the game logic units.

    Build Arguments
        
*/

module sync_generator (  

    input              clk,
    input              reset,
    output reg         hsync,
    output reg         vsync,
    output wire        display_on,
    output wire [9:0]  screen_hpos,
    output wire [9:0]  screen_vpos,
    output wire        frame_end,
    output wire        input_enable
);
    
    reg [9:0] hpos = 0;
    reg [9:0] vpos = 0;


    // declarations for TV-simulator sync parameters

    // horizontal constants

    parameter H_DISPLAY = 640;  // horizontal display width
    parameter H_BACK = 48;  // horizontal left border (back porch)
    parameter H_FRONT = 16;  // horizontal right border (front porch)
    parameter H_SYNC = 96;  // horizontal sync width

    // vertical constants

    parameter V_DISPLAY = 480;  // vertical display height
    parameter V_TOP = 33;  // vertical top border
    parameter V_BOTTOM = 10;  // vertical bottom border
    parameter V_SYNC = 2;  // vertical sync # lines

    // derived constants

    parameter H_SYNC_START = H_DISPLAY + H_FRONT;
    parameter H_SYNC_END = H_DISPLAY + H_FRONT + H_SYNC - 1;
    parameter H_MAX = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
    parameter V_SYNC_START = V_DISPLAY + V_BOTTOM;
    parameter V_SYNC_END = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
    parameter V_MAX = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

    wire hmaxxed = (hpos == H_MAX) || reset;  // set when hpos is maximum
    wire vmaxxed = (vpos == V_MAX) || reset;  // set when vpos is maximum
    
    wire hblanked = (hpos == H_DISPLAY);
    wire vblanked = (vpos == V_DISPLAY);

    assign screen_hpos = (hpos < H_DISPLAY)? hpos : 0; 
    assign screen_vpos = (vpos < V_DISPLAY)? vpos : 0;

    // horizontal position counter

    always @(posedge clk) begin
        hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
        if (hmaxxed) begin
        hpos <= 0;
        end else begin
        hpos <= hpos + 1;
        end
    end

    // vertical position counter

    always @(posedge clk) begin
        vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
        if (hmaxxed)
        if (vmaxxed) begin
        vpos <= 0;
        end else begin
            vpos <= vpos + 1;
        end
    end

    // display_on is set when beam is in "safe" visible frame
    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);
    assign frame_end = hblanked && vblanked;
    assign input_enable = (hblanked && vpos < V_DISPLAY);

endmodule