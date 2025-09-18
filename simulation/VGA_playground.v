/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland
 * Last Updated: 01/12/2024 @ 21:26:37
*/

// CHANGELOG -  18/09/25 
// See changes in new player testbench - run make from test/unit/player
// Tweaked external triggering for player logic and input collector modules
// (Input is now refreshed after the player unit state changes - now the player should respond to the changes on the next input)
// Player attack direction may still need some work - but this should be synthesisable + working for now.

// TT Pinout (standard for TT projects - can't change this)
// GDS: https://gds-viewer.tinytapeout.com/?model=https%3A%2F%2Fsheffield-chip-design-team.github.io%2FSheffield-TTX%2F%2Ftinytapeout.gds.gltf

module tt_um_vga_example ( 

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset   
);

    // Controller signals
    wire NES_Clk;
    wire NES_Latch;
    wire NES_Data;

    // NES Input Stub
    assign {NES_Latch,NES_Clk} = 2'b0;

    // Control signals to game logic

    wire [9:0] input_data; // register to hold the 5 possible player actions
    
    // Bypass the reciver module 
    InputController ic(  
        .clk(clk),
        .reset(collector_trigger),
        .up(ui_in[0]),
        .down(ui_in[1]),
        .left(ui_in[2]),
        .right(ui_in[3]),
        .attack(ui_in[4]),
        .control_state(input_data)
    );

    // Global Timer
    reg [31:0] timer;
    always @(posedge clk) if (rst_n) timer <= timer+1; else timer <= 0;

    wire PlayerDragonCollision;
    wire SwordDragonCollision;
    wire SheepDragonCollision;
    
    CollisionDetector collisionDetector (
        .clk(clk),
        .reset(vsync),
        .playerPos(player_pos),
        .swordPos(sword_pos),
        .sheepPos(sheep_pos),
        .activeDragonSegments(VisibleSegments),
        .dragonSegmentPositions(
            {Dragon_1[7:0],
            Dragon_2[7:0],
            Dragon_3[7:0],
            Dragon_4[7:0],
            Dragon_5[7:0],
            Dragon_6[7:0],
            Dragon_7[7:0]} ),
        .playerDragonCollision(PlayerDragonCollision),
        .swordDragonCollision(SwordDragonCollision),
        .sheepDragonCollision(SheepDragonCollision)
    );

    wire playerHurt;

    Hearts #(
        .PlayerTolerance(1)
    ) hearts (
        .clk(clk),
        .vsync(vsync),
        .reset(~rst_n),
        .PlayerDragonCollision(PlayerDragonCollision),
        .PlayerHurt(playerHurt),
        .playerLives(playerLives)
    );

    // player logic
    wire [1:0] playerLives;
    wire [7:0] player_pos;   // player position xxxx_yyyy
    // orientation and direction: 00 - up, 01 - right, 10 - down, 11 - left  
    wire [1:0] player_orientation;   // player orientation 
    wire [1:0] player_direction;   // player direction
    wire [3:0] player_sprite;

    wire [7:0] sword_pos; // sword position xxxx_yyyy
    wire [3:0] sword_sprite;
    wire [1:0] sword_orientation;   // sword orientation 

    PlayerLogic playlogic(
        .clk(clk),
        .reset(~rst_n | playerHurt),
        .input_data(input_data),
        .trigger(player_trigger),

        .player_sprite(player_sprite),
        .player_pos(player_pos),
        .player_orientation(player_orientation),
        .player_direction(player_direction),

        .sword_visible(sword_sprite),
        .sword_position(sword_pos),
        .sword_orientation(sword_orientation)
    );

    // dragon logic 
    wire [1:0] dragon_direction;
    wire [7:0] dragon_position;
    wire [5:0] movement_delay_counter;
    
    DragonHead dragonHead( 
        .clk(clk),
        .reset(~rst_n),
        .targetPos(target_pos),
        .vsync(vsync),
        .dragon_direction(dragon_direction),
        .dragon_pos(dragon_position),
        .movement_counter(movement_delay_counter)// Counter for delaying dragon's movement otherwise sticks to player
    );

    wire [9:0]   Dragon_1 ;
    wire [9:0]   Dragon_2 ;
    wire [9:0]   Dragon_3 ;
    wire [9:0]   Dragon_4 ;
    wire [9:0]   Dragon_5 ;
    wire [9:0]   Dragon_6 ;
    wire [9:0]   Dragon_7 ;

    wire [6:0] VisibleSegments;
    wire [7:0] target_pos;

    DragonTarget dragonBrain(
        .clk(clk),
        .reset(~rst_n),
        .trigger(frame_end),
        .target_reached_player(PlayerDragonCollision),
        .target_reached_sheep(SheepDragonCollision),
        .dragon_pos(dragon_position),
        .dragon_state(VisibleSegments),
        .dragon_hurt(SwordDragonCollision),
        .player_pos(player_pos), 
        .sheep_pos(sheep_pos),
        .target_pos(target_pos)
    );

    reg ShDC_Delay;
    reg SwDc_Delay;
    always@(posedge clk) if(rst_n) ShDC_Delay <= SheepDragonCollision; else ShDC_Delay <= 0;
    always@(posedge clk) if(rst_n) SwDc_Delay <= SwordDragonCollision; else SwDc_Delay <= 0;
    
    DragonBody dragonBody(

        .clk(clk),
        .reset(~rst_n),
        .heal(SheepDragonCollision),
        .hit(SwordDragonCollision),
        .Dragon_Head({dragon_direction, dragon_position}),
        .movementCounter(movement_delay_counter),
        .vsync(vsync),
        .current_time(timer),
        .Dragon_1(Dragon_1),
        .Dragon_2(Dragon_2),
        .Dragon_3(Dragon_3),
        .Dragon_4(Dragon_4),
        .Dragon_5(Dragon_5),
        .Dragon_6(Dragon_6),
        .Dragon_7(Dragon_7),

        .Display_en(VisibleSegments)
    );

    // random number generator for sheep position
    wire [7:0] sheep_pos;
    reg [3:0] sheep_sprite =4'b0111;

    reg SDC_Buffer;

    always@(posedge clk) SDC_Buffer <= SheepDragonCollision;
    wire SDC_pulse = SDC_Buffer & !SheepDragonCollision;

    rng randnum (   // random nuumber generator based on linear feedback + seed
      .clk(clk),
      .reset(~rst_n),
      .trigger(SheepDragonCollision),
      .seed({pix_y[0],playerLives,VisibleSegments[5],pixel_value,pix_x[7:5]}), // Seed input for initializing randomness
      .ready(),
      .rdm_num(sheep_pos)
     );


    // {sheep_sprite, 2'b01 , sheep_pos,  4'b0001}

    // Picture Processing Unit

    PictureProcessingUnit ppu (

        .clk_in         (clk),
        .reset          (~rst_n), 
        .entity_1       ({4'b0000, 2'b00, 8'b1111_0000, {2'b00, playerLives} }),           // heart
        .entity_2       ({player_sprite, player_orientation , player_pos,  4'b0001}),      // player
        .entity_3       ({sword_sprite, sword_orientation, sword_pos, 4'b0001}),           // sword
        .entity_4       ({sheep_sprite, 2'b01 , sheep_pos,  4'b0001}),         // sheep 
        .entity_5       (18'b1111_11_1111_1111_0001),                                      // empty - sheep 2
        .entity_6       (18'b1111_11_1111_1111_0001),                                   // empty
        .entity_7       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_8       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_9       ({4'b0110,Dragon_1,3'b000,VisibleSegments[0]}),                    // dragon parts
        .entity_10      ({4'b0100,Dragon_2,3'b000,VisibleSegments[1]}),  
        .entity_11      ({4'b0100,Dragon_3,3'b000,VisibleSegments[2]}),  
        .entity_12      ({4'b0100,Dragon_4,3'b000,VisibleSegments[3]}),
        .entity_13      ({4'b0100,Dragon_5,3'b000,VisibleSegments[4]}),
        .entity_14      ({4'b0100,Dragon_6,3'b000,VisibleSegments[5]}), 
        .entity_15      ({4'b0100,Dragon_7,3'b000,VisibleSegments[6]}),        
        .counter_V      (pix_y),
        .counter_H      (pix_x),
        
        .colour         (pixel_value)
    );

    // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire frame_end;

    // sync generator unit 
    sync_generator sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end),
        .input_enable()
    );

  reg player_trigger;
  reg collector_trigger;

  always @(posedge clk ) begin
    player_trigger <= frame_end;
    collector_trigger <= player_trigger;
  end

    // outpout colour signals
    wire pixel_value;
    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

  // display logic
    always @(posedge clk) begin
        
        if (~rst_n) begin
        R <= 0;
        G <= 0;
        B <= 0;
        
        end else begin
            
            if (video_active) begin // display output color from Frame controller unit

                if (PlayerDragonCollision == 0 & SwordDragonCollision == 0) begin // no collision - green
                    R <= pixel_value ? 2'b11 : 0;
                    G <= pixel_value ? 2'b11 : 2'b11;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 1 & SwordDragonCollision == 0) begin // dragon hurs playher rtcollision - red
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 0 & SwordDragonCollision == 1) begin // sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b0;
                    G <= pixel_value ? 2'b11 : 2'b0;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

               if (PlayerDragonCollision == 1 & SwordDragonCollision == 1) begin // both collision simultaneouslt  sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 2'b00;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

            end else begin
                R <= 0;
                G <= 0;
                B <= 0;
            end
        end
    end

    // Audio signals
    wire sound;

     APU apu(
      .clk(clk),
      .reset(~rst_n),
      .frame_end(frame_end),
      .PlayerDragonCollision(PlayerDragonCollision),
      .SwordDragonCollision(SwordDragonCollision),
      .SheepDragonCollision(SheepDragonCollision),
      .x(pix_x),
      .y(pix_y),
      .sound(sound)
    );


    
    
    // System IO Connections
    assign NES_Data = ui_in[0];
    assign uio_oe   = 8'b1000_0011;
    assign uio_out  = {sound, 5'b00000, NES_Latch, NES_Clk};
    assign uo_out   = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    wire _unused_ok = &{ena, uio_in[7:1]}; 

endmodule


module InputController (
    input wire clk,
    input wire reset,
    input wire up,            
    input wire down,
    input wire left,
    input wire right,
    input wire attack,
    output reg [9:0] control_state  
);
    initial begin
        control_state = 0;
    end

    reg [4:0] previous_state  = 5'b0;
    reg [4:0] current_state   = 5'b0;
    reg [4:0] pressed_buttons = 5'b0 ;
    reg [4:0] released_buttons = 5'b0 ;

    always @(posedge clk) begin
        previous_state <= current_state;
        current_state <= {attack, right, left , down , up};
    end

    always @(posedge clk) begin
            pressed_buttons[0] <= (current_state[0] == 1 & previous_state[0] == 0) ? 1:0;
            pressed_buttons[1] <= (current_state[1] == 1 & previous_state[1] == 0) ? 1:0;
            pressed_buttons[2] <= (current_state[2] == 1 & previous_state[2] == 0) ? 1:0;
            pressed_buttons[3] <= (current_state[3] == 1 & previous_state[3] == 0) ? 1:0;
            pressed_buttons[4] <= (current_state[4] == 1 & previous_state[4] == 0) ? 1:0;
    end

   always @(posedge clk) begin // added check for when buttons are released
            released_buttons[0] <= (current_state[0] == 0 & previous_state[0] == 1) ? 1:0;
            released_buttons[1] <= (current_state[1] == 0 & previous_state[1] == 1) ? 1:0;
            released_buttons[2] <= (current_state[2] == 0 & previous_state[2] == 1) ? 1:0;
            released_buttons[3] <= (current_state[3] == 0 & previous_state[3] == 1) ? 1:0;
            released_buttons[4] <= (current_state[4] == 0 & previous_state[4] == 1) ? 1:0;
    end

    always @(posedge clk) begin
        if (!reset) control_state <= control_state | {pressed_buttons, released_buttons};
        else control_state <= 0;
    end
endmodule


module CollisionDetector (
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
    
    // make comparison with current dragon segment to determine if there is a collision.

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
            checksegment <= ((7'b000_0001 << segmentCounter) & activeDragonSegments) != 0;

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
                        end // don't increment segment.
                    end

                    default: begin
                            dragonSegment <= 8'b1111_1111; // out of bounds
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


module Hearts #(parameter [6:0] PlayerTolerance = 60)( 
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
      sword_visible <= 4'b1111;
      player_pos <= 8'b0001_0011;
      player_orientation <= 2'b01;
      player_direction <= 2'b01;
      action_complete <= 0;
      direction_stored <= 0;
    end
  end

endmodule














module DragonTarget(
      input wire clk,
      input wire reset,
      input wire trigger,
      input wire dragon_hurt,
      input wire target_reached_player,
      input wire target_reached_sheep,
      input wire [6:0] dragon_state,
      input wire [7:0] dragon_pos,
      input wire [7:0] player_pos, 
      input wire [7:0] sheep_pos,
      output wire [7:0] target_pos
);
    
    reg [7:0] target_pos_reg;
    reg [2:0] DragonBehaviourState=0;
    reg [2:0] NextDragonBehaviourState=0;
    reg dragon_ready;

    always @(posedge clk) begin
      if (~reset) begin
      dragon_ready <= dragon_ready | &dragon_state[2:0] ;
      if (trigger) begin
          DragonBehaviourState <= NextDragonBehaviourState;
      end

      end else begin
        DragonBehaviourState <= 0;
        target_pos_reg <= 0;
        dragon_ready<=0;
      end

    end

    always @(posedge clk) begin

      case (DragonBehaviourState)

        0: begin //chase the player
          target_pos_reg <= player_pos;
          if (dragon_hurt | target_reached_player)  NextDragonBehaviourState <= 1; 
        end

        1: begin // chase the sheep
          target_pos_reg <= sheep_pos;
          if ((dragon_hurt | target_reached_sheep)&dragon_ready) NextDragonBehaviourState <= 2;
        end

        2: begin // retreat to a corner (use two of the bits of the rng）
            target_pos_reg <= 8'b1011_1011;
            if (dragon_pos == 8'b1011_1011) NextDragonBehaviourState <= 0;
        end

        // 3: begin // reset position
        //     target_pos_reg <= 8'b0001_0001;
        //     if (target_reached & ~reset) 
        //         NextDragonBehaviourState <= 0;

        // end

        default : begin 
          target_pos_reg <= target_pos_reg;
        end
      endcase

    end

    assign target_pos = target_pos_reg;


endmodule

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
            dragon_x <= 4'hF;
            dragon_y <= 4'hB;
            movement_counter <= 0;
            dragon_pos <= 8'hFB;
            dx <= 0; 
            dy <= 0;
            sx <= 0; 
            sy <= 0;
        end
    end
endmodule


module DragonBody(

    input clk,
    input reset,
    input vsync,
    input heal,                         // grow
    input hit,                          // shrink
    input [31:0] current_time,
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

    reg pre_vsync;

    reg heal_reg, hit_reg;
    wire heal_pause,hit_pause;
    always @(posedge clk) heal_reg <= heal;
    always @(posedge clk) hit_reg <= hit;

    assign heal_pause = heal & !heal_reg;
    assign hit_pause = hit & !hit_reg;

    reg [31:0] time_1;


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
            Dragon_1 <= {2'b00,8'hFB};
            Dragon_2 <= {2'b00,8'hFB};
            Dragon_3 <= {2'b00,8'hFB};
            Dragon_4 <= {2'b00,8'hFB};
            Dragon_5 <= {2'b00,8'hFB};
            Dragon_6 <= {2'b00,8'hFB};
            Dragon_7 <= {2'b00,8'hFB};
        end
    end

    wire [31:0] interval = current_time - time_1;
    wire colddown = interval > 32'h01000000;

    always @( posedge clk )begin
        
        if(~reset) begin
            case(1'b1) 
                heal_pause&(Dragon_1[7:0]!=8'hFB): begin
                    Display_en <= (Display_en << 1) | 7'b0000001;
                end
                hit_pause&(Dragon_1[7:0]!=8'hFB)&colddown: begin
                    Display_en <= Display_en >> 1;
                    time_1 <= current_time;
                end
                default: Display_en <= Display_en;
            endcase
        end else begin
            Display_en <= 7'b0000111;
        end
    end
endmodule

module rng ( // random nuumber generator based on linear feedback + seed
  input wire clk,
  input wire reset,
  input wire trigger,
  input wire [7:0] seed, // Seed input for initializing randomness
  output wire ready,
  output wire [7:0] rdm_num
);

    localparam [7:0] default_value = 8'b1001_1011;
    reg trigger_reg;
    reg [7:0] rand_buf1;
    reg [7:0] rand_buf2;
    reg ready_reg;
    wire tri_pulse = trigger_reg & !trigger;
    reg tri_pulse_reg;
    reg [7:0] seed_reg;

    // sequential lfsr-based random number generator
    always @(posedge clk) begin
      
      if (reset) begin
        rand_buf1  <= 0;
        rand_buf2  <= 8'b1111_1101;
        trigger_reg <= 0;
        ready_reg  <= 0;
        seed_reg <=0;
      end

      else begin  

        trigger_reg <= trigger;
        tri_pulse_reg <= tri_pulse;

        seed_reg <= seed+seed_reg;

        if (tri_pulse) begin 
          ready_reg <= 0;
          rand_buf1[6:0] <= seed_reg[7:1];  // Shift all bits from the seed
          rand_buf1[7]   <= rand_buf1[6] ^ rand_buf1[5] ^ rand_buf1[4]; // Feedback XOR for randomness
        end
          
        if (tri_pulse_reg) begin
            ready_reg  <= 1;
            rand_buf2  <= (rand_buf1 % 8'b1111_1100);
        end

        

      end 

    end

    assign rdm_num =(rand_buf2[3:0]!=4'h0 )? rand_buf2:{rand_buf2[7:4],rand_buf1[7:4]};
    assign ready = ready_reg;

endmodule
            


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


module PictureProcessingUnit(
    input clk_in,
    input reset,    
    input wire [17:0] entity_1,  
    input wire [17:0] entity_2,  //Simultaneously supports up to 9 objects in the scene.
    input wire [17:0] entity_3,  //Set the entity ID to 4'hf for unused channels.
    input wire [17:0] entity_4,
    input wire [17:0] entity_5,
    input wire [17:0] entity_6,
    input wire [17:0] entity_7, 
    input wire [17:0] entity_8,
    input wire [17:0] entity_9,
    input wire [17:0] entity_10,
    input wire [17:0] entity_11,
    input wire [17:0] entity_12,
    input wire [17:0] entity_13,
    input wire [17:0] entity_14,
    input wire [17:0] entity_15,

    input wire [9:0] counter_V,
    input wire [9:0] counter_H,

    output reg colour // 0-black 1-white
    );

    wire clk = clk_in; // needs to be 25MHz!!!

    //internal Special Purpose Registers/Flags
    reg [3:0]  entity_Counter;     // like a Prorgram Counter but for entities instead of instructions
    reg [17:0] general_Entity;     // entity data register - like an MDR

    // Pixel Counters (Previous)
    reg [9:0] previous_horizontal_pixel;
    reg [9:0] previous_vertical_pixel;
    // Upscaling Counters
    reg [2:0] upscale_Counter_H;
    reg [2:0] upscale_Counter_V;
    // Sprite Idexing Counters
    reg [2:0] row_Counter;
    reg [2:0] column_Counter;
    // Tile counters are for the tiles that are currently being drawn by the VGA controller
    reg [3:0] horizontal_Tile_Counter;
    reg [3:0] vertical_Tile_Counter;
    // the Local counters are for tiles that are currently being processed (1 tile ahead of the current tile)
    reg [3:0] local_Counter_H;
    reg [3:0] local_Counter_V;
    
    // Updating the current tile, row and column counterscounters using the current pixel position 
    always@(posedge clk) begin 
        
        if(!reset)begin
            
            previous_horizontal_pixel <= counter_H; // record previous x-pixel
           
            if (previous_horizontal_pixel != counter_H ) begin
                if (upscale_Counter_H != 4) begin
                    upscale_Counter_H <= upscale_Counter_H + 1;
                end else begin
                    upscale_Counter_H <= 0;
                    column_Counter <= column_Counter + 1;
            end 
                                
            if (counter_H >= 40) begin
                if (column_Counter == 3'b111 && upscale_Counter_H == 4)begin
                    horizontal_Tile_Counter <= horizontal_Tile_Counter + 1; // increment horizontal tile 
                end else begin
                    horizontal_Tile_Counter <= horizontal_Tile_Counter;
                end
            end else begin
                horizontal_Tile_Counter <= 0; // reset horizontal tile counter
            end

            end else begin // keep counters the same
                horizontal_Tile_Counter <= horizontal_Tile_Counter;
                upscale_Counter_H <= upscale_Counter_H;
                column_Counter <= column_Counter;
            end

            previous_vertical_pixel <= counter_V;  // record previous y-pixel

            if (previous_vertical_pixel != counter_V ) begin    // if pixel counter has incremented
                
                if(upscale_Counter_V != 4) begin                // Upscale every pixel 5x
                    upscale_Counter_V <= upscale_Counter_V + 1;
                end else begin
                    upscale_Counter_V <= 0;
                    row_Counter <= row_Counter + 1;
                end

                if (counter_V >= 40) begin // increment the horizontal pixel after 8 upscaled pixels have been drawn in the vertical direction.
                    if(row_Counter == 3'b111 && upscale_Counter_V == 4 && vertical_Tile_Counter != 4'd11)begin // row 0-11
                        vertical_Tile_Counter <= vertical_Tile_Counter + 1; // increment vertical tile 
                    end else if(row_Counter == 3'b111 && upscale_Counter_V == 4 && vertical_Tile_Counter == 4'd11) begin // final row of tiles
                        vertical_Tile_Counter <= 0;
                    end else begin
                        vertical_Tile_Counter <= vertical_Tile_Counter;
                    end          
                end else begin
                    vertical_Tile_Counter <= 0;
                end
                    
            end else begin // keep counters the same
                    vertical_Tile_Counter <= vertical_Tile_Counter;
                    upscale_Counter_V <= upscale_Counter_V;
                    row_Counter <= row_Counter;
            end

        end else begin // reset all counters 
            // horizontal
            previous_horizontal_pixel <= 0;
            column_Counter <= 0; 
            upscale_Counter_H <= 0;
            horizontal_Tile_Counter <= 4'b0000;
            //vertical
            previous_vertical_pixel <= 0;
            row_Counter <= 0;
            upscale_Counter_V <= 0;
            vertical_Tile_Counter <= 4'b0000;
        end

    end

    // Setting the Local tile, to the tile ahead of the tile currently being drawn
    always@(posedge clk) begin  
        
        if (!reset) begin

            local_Counter_H <= horizontal_Tile_Counter + 1;        // works as the width of the screen is 16 tiles - uses the overflow of 4-bit counrter as the reset.

            if (row_Counter == 3'b111 && upscale_Counter_H == 4 && horizontal_Tile_Counter == 15 && column_Counter == 7 && upscale_Counter_H == 4) begin // if at the end of a row
                if (vertical_Tile_Counter != 4'b1011) begin        // if not on final tile in the column
                    local_Counter_V <= vertical_Tile_Counter + 1;  // increment the vertical tile counter
                end else begin
                    local_Counter_V <= 0;                          // wrap round back to the top of the screen 
                end

            end else begin
                local_Counter_V <= vertical_Tile_Counter;
            end

        end 

        else begin  // reset condition
            local_Counter_H <= 0;
            local_Counter_V <= 0;
        end

    end

    // Detecting if a new tile has been reached - to reset entity counter
    wire [3:0] next_tile = (horizontal_Tile_Counter + 1);
    wire [3:0] current_tile = (local_Counter_H);
    wire new_tile = next_tile != current_tile;

    // Cycling through the entity slots - loading the data into the general entity register 
    
    // TODO: Check the order of the enitity assignments
    always@(posedge clk) begin 
        
        if (!reset) begin
             case (entity_Counter)
                4'd0: begin 
                    general_Entity <= entity_8; 
                end
                4'd1:begin
                    general_Entity <= entity_7;
                end   
                4'd2:begin
                    general_Entity <= entity_6;
                end
                4'd3:begin 
                    general_Entity <= entity_5;
                end
                4'd4:begin 
                    general_Entity <= entity_4;
                end
                4'd5:begin 
                    general_Entity <= entity_3;
                end
                4'd6:begin 
                    general_Entity <= entity_2;
                end
                4'd7:begin 
                    general_Entity <= entity_1;
                end
                4'd8: begin
                    general_Entity <= entity_9;
                end
                4'd9: begin
                    general_Entity <= entity_10;
                end
                4'd10: begin
                    general_Entity <= entity_11;
                end
                4'd11: begin
                    general_Entity <= entity_12;
                end
                4'd12: begin
                    general_Entity <= entity_13;
                end
                4'd13: begin
                    general_Entity <= entity_14;
                end
                4'd14: begin
                    general_Entity <= entity_15;
                end

                default: begin
                    general_Entity <= 18'b111111000000000000;
                end

            endcase

            // cycle through all of the entity slots - new slot each clk
            if (entity_Counter != 14 && entity_Counter != 4'd15) begin
                entity_Counter <= entity_Counter + 1;
            end else if (new_tile) begin // reset the EC every time a new tile is reached
                entity_Counter <=0;
            end else begin // Entity counter IDLE
                entity_Counter <= 4'd15;
            end

        end else begin // reset flags and registers
            entity_Counter <= 4'b0000;
            general_Entity <=18'b111111000000000000;
        end 
   
    end

    // Checking whether the Entity in the general entity register should be displayed in the Local tile
   
    wire inRange; // if entity is within the range
    wire range_H; // if entity is within the horizontal range
    wire range_V; // if entity is within vertical range

    // Determine whether the difference between the entity pos and the current block pos is less than the required display length.
    assign range_H = (general_Entity[11:8] - local_Counter_H) < {1'b0,general_Entity[2:0]}; 
    assign range_V = (local_Counter_V - general_Entity[7:4]) == 1'b0;
    assign inRange = range_H && range_V;

    //These registers are used to address the ROM.
    reg [8:0] detector;    // Data Format: [8:6] Row number, [5:2] Entity ID, [1:0] Orientation  
    reg [8:0] out_entity;  
    
    // Send entity data to the ROM depending on the contents of the processed tile and slot type. 
    always @(posedge clk) begin 

        if (!reset) begin
            // depending on the slot type, send the appropriate row to the Sprite ROM

            if (!(column_Counter == 7 && upscale_Counter_H == 3))begin

                out_entity <= out_entity;
        
                if (inRange && (general_Entity[17:14] != 4'b1111)) begin
                    if (general_Entity[3] == 1'b1) begin
                        detector <= {~(row_Counter), general_Entity[17:12]};
                    end else begin
                        detector <= {(row_Counter), general_Entity[17:12]};
                    end
                end else begin
                    detector <= detector;
                end

            end else begin
                out_entity <= detector;
                detector <= 9'b111111111;  
            end

        end else begin
            detector <= 9'b111111111;
            out_entity <= 9'b111111111;
        end
    
    end

    wire [7:0] buffer; // ROM output buffer 
    
    // Read From ROM
    SpriteROM Rom ( 
        .clk(clk),
        .reset(reset),
        .orientation(out_entity[1:0]),
        .sprite_ID(out_entity[5:2]),
        .line_index(out_entity[8:6]),
        .data(buffer)
    );

    // Send the appropriate pixel value to the VGA output unit 
    always@(posedge clk)begin 
       
        if(!reset)begin
            colour <= buffer[column_Counter];
        end else begin
            colour <= 1'b1;
        end
        
    end
endmodule





module SpriteROM ( 
    input            clk,
    input            reset,
    input [1:0] orientation,
    input [3:0] sprite_ID,
    input [2:0] line_index,
    output reg [7:0] data
);

    localparam UP     = 2'b00;
    localparam RIGHT  = 2'b01;
    localparam DOWN   = 2'b10;
    localparam LEFT   = 2'b11;

    // assign read_enable = 1'b1;

    reg [7:0] romData [71:0];   

    initial begin

        romData[0] = 8'b1_111111_1; // 0000 Heart (6x6)
        romData[1] = 8'b1_111111_1;
        romData[2] = 8'b1_101011_1;
        romData[3] = 8'b1_000101_1;
        romData[4] = 8'b1_000001_1;
        romData[5] = 8'b1_100011_1;
        romData[6] = 8'b1_110111_1;
        romData[7] = 8'b1_111111_1;

        romData[8]  = 8'b11101111; // 0001 Sword 0001
        romData[9]  = 8'b11101111;
        romData[10] = 8'b11101111;
        romData[11] = 8'b11101111;
        romData[12] = 8'b11101111;
        romData[13] = 8'b11101111;
        romData[14] = 8'b11000111;
        romData[15] = 8'b11101111;

        romData[16] = 8'b11111111; // 0010 Gnome (Stand)
        romData[17] = 8'b11000011;
        romData[18] = 8'b10110000;
        romData[19] = 8'b00000011;
        romData[20] = 8'b00110001;
        romData[21] = 8'b00000000;
        romData[22] = 8'b01000001;
        romData[23] = 8'b11111111;

        romData[24] = 8'b11111011; // 0011 Gnome (Crouch)
        romData[25] = 8'b11100011;
        romData[26] = 8'b11001000;
        romData[27] = 8'b11000011;
        romData[28] = 8'b10001001;
        romData[29] = 8'b10000000;
        romData[30] = 8'b10010001;
        romData[31] = 8'b11111111;

        romData[32] = 8'b11000011; // 0100 Dragon Body (Wing up)
        romData[33] = 8'b11100001;
        romData[34] = 8'b10000011;
        romData[35] = 8'b10000001;
        romData[36] = 8'b00000001;
        romData[37] = 8'b01000000;
        romData[38] = 8'b11100001;
        romData[39] = 8'b11000001;

        romData[40] = 8'b11000011; // 0101 Dragon Body (Wing Down)
        romData[41] = 8'b11100001;
        romData[42] = 8'b11000011;
        romData[43] = 8'b10000001;
        romData[44] = 8'b10000000;
        romData[45] = 8'b10000000;
        romData[46] = 8'b10000001;
        romData[47] = 8'b11000001;

        romData[48] = 8'b11000111; // 0110  Dragon Head
        romData[49] = 8'b11000011;
        romData[50] = 8'b11000011;
        romData[51] = 8'b10010001;
        romData[52] = 8'b10110001;
        romData[53] = 8'b10100001;
        romData[54] = 8'b01000011;
        romData[55] = 8'b11000111;

        romData[56] = 8'b11001111; // 0111 sheep 1
        romData[57] = 8'b10000011;
        romData[58] = 8'b10011000;
        romData[59] = 8'b01111011;
        romData[60] = 8'b01111011;
        romData[61] = 8'b01111000;
        romData[62] = 8'b10111011;
        romData[63] = 8'b11000111;

        romData[64] = 8'b11100111; // 1000 sheep -2 
        romData[65] = 8'b11000001;
        romData[66] = 8'b11001100;
        romData[67] = 8'b10111101;
        romData[68] = 8'b10111101;
        romData[69] = 8'b10111100;
        romData[70] = 8'b11011101;
        romData[71] = 8'b11100011;
        
        // empty tile = 1111;

    end

    always @(posedge clk) begin // impliment the 4 orientations
            
            if(!reset) begin
                
                if (sprite_ID != 4'b1111)begin

                    if (orientation == UP) begin                              // Normal Operation
                        data[0] <= romData[{sprite_ID,line_index}][7];
                        data[1] <= romData[{sprite_ID,line_index}][6];
                        data[2] <= romData[{sprite_ID,line_index}][5];
                        data[3] <= romData[{sprite_ID,line_index}][4];
                        data[4] <= romData[{sprite_ID,line_index}][3];
                        data[5] <= romData[{sprite_ID,line_index}][2];
                        data[6] <= romData[{sprite_ID,line_index}][1];
                        data[7] <= romData[{sprite_ID,line_index}][0];
                        // data <= romData(sprite_ID,line_index, 1'b0 );
                    end 

                    else if (orientation == RIGHT) begin                        // (Rotate 90 degrees clockwise around the center point)   
                        data[0] <= romData[{sprite_ID,3'b111}][~line_index];    // romdata[bottom to top][left to right]
                        data[1] <= romData[{sprite_ID,3'b110}][~line_index];
                        data[2] <= romData[{sprite_ID,3'b101}][~line_index];
                        data[3] <= romData[{sprite_ID,3'b100}][~line_index];
                        data[4] <= romData[{sprite_ID,3'b011}][~line_index];
                        data[5] <= romData[{sprite_ID,3'b010}][~line_index];
                        data[6] <= romData[{sprite_ID,3'b001}][~line_index];
                        data[7] <= romData[{sprite_ID,3'b000}][~line_index];
                    end

                    else if(orientation == DOWN) begin                           // Top row to bottom row (Reflection on the line y = 0)
                        data <= romData[{sprite_ID,~line_index}];
                    end

                    else if (orientation == LEFT) begin                         //  (Rotate 90 degrees clockwise around the center point and reflect on the line x = 0)
                        data[0] <= romData[{sprite_ID,3'b000}][~line_index];    //  romdata[top to bottom][left to right]
                        data[1] <= romData[{sprite_ID,3'b001}][~line_index];
                        data[2] <= romData[{sprite_ID,3'b010}][~line_index];
                        data[3] <= romData[{sprite_ID,3'b011}][~line_index];
                        data[4] <= romData[{sprite_ID,3'b100}][~line_index];
                        data[5] <= romData[{sprite_ID,3'b101}][~line_index];
                        data[6] <= romData[{sprite_ID,3'b110}][~line_index];
                        data[7] <= romData[{sprite_ID,3'b111}][~line_index];

                    end else begin
                        data <= 8'b11111111;
                    end

                end else begin
                    data <= 8'b11111111;
                end

            end else begin
                data <= 8'b11111111;
            end

        end
endmodule


module APU (
    input wire clk,
    input wire reset,
    input wire SheepDragonCollision,
    input wire SwordDragonCollision,
    input wire PlayerDragonCollision,
    input wire frame_end,
    input wire [9:0] x,
    input wire [9:0] y,
    output wire sound
);

//-------------------------------------------//
// Global frame counter (for melody timing)
//-------------------------------------------//
reg [11:0] frame_counter;
always @(posedge clk) begin
    if (reset)
        frame_counter <= 0;
    else if (x == 0 && y == 0)
        frame_counter <= frame_counter + 1;
end

//-------------------------------------------//
// SFX 1: Dragon Eating Sheep (low rumble)
//-------------------------------------------//
reg dragon_active, dragon_cooldown;
reg [15:0] dragon_counter;
reg dragon_square;
reg [30:0] dragon_duration, dragon_cooldown_timer;

always @(posedge clk) begin
    if (reset) begin
        dragon_active <= 0;
        dragon_cooldown <= 0;
        dragon_counter <= 0;
        dragon_square <= 0;
        dragon_duration <= 0;
        dragon_cooldown_timer <= 0;
    end else begin
        if (SheepDragonCollision && !dragon_active && !dragon_cooldown) begin
            dragon_active <= 1;
            dragon_duration <= 3000;
        end

        if (dragon_active) begin
            if (dragon_counter >= 600) begin
                dragon_counter <= 0;
                dragon_square <= ~dragon_square;
            end else
                dragon_counter <= dragon_counter + 1;

            if (dragon_duration == 0) begin
                dragon_active <= 0;
                dragon_cooldown <= 1;
                dragon_cooldown_timer <= 3000000;
            end else
                dragon_duration <= dragon_duration - 1;
        end

        if (dragon_cooldown) begin
            if (dragon_cooldown_timer == 0)
                dragon_cooldown <= 0;
            else
                dragon_cooldown_timer <= dragon_cooldown_timer - 1;
        end
    end
end

wire [3:0] dragon_out = (dragon_square & dragon_active) ? 4'd8 : 4'd0;

//-------------------------------------------//
// SFX 2: Knight Hitting Dragon (noise burst)
//-------------------------------------------//
reg knight_hit_active, knight_hit_cooldown;
reg [11:0] knight_hit_duration, knight_hit_cooldown_timer;
reg [12:0] lfsr;
wire lfsr_feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0];

always @(posedge clk) begin
    if (reset) begin
        knight_hit_active <= 0;
        knight_hit_cooldown <= 0;
        knight_hit_duration <= 0;
        knight_hit_cooldown_timer <= 0;
        lfsr <= 13'b1;
    end else begin
        lfsr <= {lfsr[11:0], lfsr_feedback};

        if (SwordDragonCollision && !knight_hit_active && !knight_hit_cooldown) begin
            knight_hit_active <= 1;
            knight_hit_duration <= 1800;
        end

        if (knight_hit_active) begin
            if (knight_hit_duration == 0) begin
                knight_hit_active <= 0;
                knight_hit_cooldown <= 1;
                knight_hit_cooldown_timer <= 1800;
            end else
                knight_hit_duration <= knight_hit_duration - 1;
        end

        if (knight_hit_cooldown) begin
            if (knight_hit_cooldown_timer == 0)
                knight_hit_cooldown <= 0;
            else
                knight_hit_cooldown_timer <= knight_hit_cooldown_timer - 1;
        end
    end
end

wire [3:0] knight_hit_out = (lfsr[0] & knight_hit_active) ? 4'd10 : 4'd0;

//-------------------------------------------//
// SFX 3: Knight Taking Damage (high beep)
//-------------------------------------------//
reg knight_hurt_active, knight_hurt_cooldown;
reg [15:0] knight_hurt_counter;
reg knight_hurt_square;
reg [15:0] knight_hurt_duration, knight_hurt_cooldown_timer;

always @(posedge clk) begin
    if (reset) begin
        knight_hurt_active <= 0;
        knight_hurt_cooldown <= 0;
        knight_hurt_counter <= 0;
        knight_hurt_square <= 0;
        knight_hurt_duration <= 0;
        knight_hurt_cooldown_timer <= 0;
    end else begin
        if (PlayerDragonCollision && !knight_hurt_active && !knight_hurt_cooldown) begin
            knight_hurt_active <= 1;
            knight_hurt_duration <= 1500;
        end

        if (knight_hurt_active) begin
            if (knight_hurt_counter >= 200) begin
                knight_hurt_counter <= 0;
                knight_hurt_square <= ~knight_hurt_square;
            end else
                knight_hurt_counter <= knight_hurt_counter + 1;

            if (knight_hurt_duration == 0) begin
                knight_hurt_active <= 0;
                knight_hurt_cooldown <= 1;
                knight_hurt_cooldown_timer <= 1500;
            end else
                knight_hurt_duration <= knight_hurt_duration - 1;
        end

        if (knight_hurt_cooldown) begin
            if (knight_hurt_cooldown_timer == 0)
                knight_hurt_cooldown <= 0;
            else
                knight_hurt_cooldown_timer <= knight_hurt_cooldown_timer - 1;
        end
    end
end

wire [3:0] knight_hurt_out = (knight_hurt_square & knight_hurt_active) ? 4'd12 : 4'd0;


//-------------------------------------------//
// PWM Mixer
//-------------------------------------------//
wire [5:0] mix = dragon_out + knight_hit_out + knight_hurt_out ;

reg [5:0] pwm_counter;
always @(posedge clk) begin
    pwm_counter <= pwm_counter + 1;
end

assign sound = (pwm_counter < mix);

endmodule