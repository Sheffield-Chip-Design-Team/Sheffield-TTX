
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Anubhav Avinash, Kwashie Andoh, 
 * Abdulatif Babli, K Arjunav, Cameron Brizland, Rupert Bowen
 * Last Updated: 01/12/2024 @ 21:26:37
*/

module tt_um_tinytapestation ( 

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset   
);
  
   // Clock Divider to generate 50 MHz and 25 MHz clocks from 100 MHz input clock
   wire CLK_50MHZ, CLK_25MHZ;

   clk_div clk_div_inst (
    .clk_in(clk),                   // input clk_in (100 MHZ)
    .reset(~rst_n), 
    .clk_out_25MHz(CLK_25MHZ),      // output clk_out_25MHz
    .clk_out_50MHz(CLK_50MHZ)       // output clk_out_50MHz
   );
   
    // Controller input signals
    
    wire NES_Clk;
    wire NES_Latch;
    wire NES_Data;
    
    wire Up_button;  
    wire Down_button;
    wire Left_button;
    wire Right_button;
    wire A_button;
    wire B_button;
    wire Start_button;
    wire Select_button;
    
    // NES/SNES Reciever Module
    InputReceiver gamepad (
        .clk(CLK_25MHZ),
        .reset(~rst_n),
        .data(NES_Data),    // input data from nes controller to FPGA
        .latch(NES_Latch),  // parallel -> serial switch for gamepad shift register
        .nes_clk(NES_Clk),  // outputs from FPGA to nes controller
        .A(A_button),
        .B(B_button),
        .select(Select_button),
        .start(Start_button),
        .up(Up_button),
        .down(Down_button),
        .left(Left_button),
        .right(Right_button)  
    );
    
    // colour control with the NES Controller buttons (substitute for game logic)
    reg [2:0] color_state = 0;
    
    always @(posedge CLK_25MHZ) begin
        if (!rst_n) // reset condition
            color_state <= 3'b000;
        else if (Up_button)
            color_state <= 3'b001;
        else if (Down_button)
            color_state <= 3'b010;
        else if (Left_button)
            color_state <= 3'b011;
        else if (Right_button)
            color_state <= 3'b100;
        else if (A_button)
            color_state <= 3'b101;
        else if (B_button)
            color_state <= 3'b110;
        else if (Start_button)
            color_state <= 3'b111;
        else if (Select_button)
            color_state <= 3'b000;
    end
    
    // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // timing signals
    wire frame_end;
    
    sync_generator sync_gen (
        .clk(CLK_25MHZ),
        .reset(~rst_n),
        .hsync(hsync),              // horizontal sync signal (active low)
        .vsync(vsync),              // vertical sync signal   (active low)
        .display_on(video_active),  // active video area
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end)
    );

    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

   //  VGA display logic
    always @(posedge CLK_25MHZ) begin
       if (~rst_n) begin
            R <= 2'b00;
            G <= 2'b00;
            B <= 2'b00;
        end else if (video_active) begin
           // update color 
            case (color_state)
                3'b001: begin R <= 2'b11; G <= 2'b00; B <= 2'b00; end // Red
                3'b010: begin R <= 2'b00; G <= 2'b11; B <= 2'b00; end // Green
                3'b011: begin R <= 2'b00; G <= 2'b00; B <= 2'b11; end // Blue
                3'b100: begin R <= 2'b11; G <= 2'b11; B <= 2'b00; end // Yellow
                3'b101: begin R <= 2'b00; G <= 2'b11; B <= 2'b11; end // Cyan
                3'b110: begin R <= 2'b11; G <= 2'b00; B <= 2'b11; end // Magenta
                3'b111: begin R <= 2'b11; G <= 2'b11; B <= 2'b11; end // White
                default: begin R <= 2'b00; G <= 2'b00; B <= 2'b00; end
            endcase
                
        end else begin
            R <= 2'b00;
            G <= 2'b00;
            B <= 2'b00;
       end
    end
    
    // audio signals

    wire sound;

    APU apu( 
      .clk(CLK_25MHZ),
      .reset(~rst_n),
      .frame_end(frame_end),
      .snare_trigger(Start_button),
      .x(pix_x),
      .y(pix_y),
      .sound(sound)
    );

    // System IO Connections
    assign ui_in   = {7'b000_0000, NES_Data};
    assign uio_oe  = 8'b1000_0011;
    assign uio_out = {sound, 5'b00000, NES_Latch, NES_Clk};
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    wire _unused_ok = &{ena, uio_in}; 

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
    // control state is now  10 bits wide to include whether all buttons have been released
    integer i;
    
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
        if (reset) begin
            pressed_buttons  <= 5'b0;
            released_buttons <= 5'b0;
        end else begin
            for (i = 0; i < 5; i = i + 1) begin
                pressed_buttons[i]  <= (current_state[i]  & ~previous_state[i]);
                released_buttons[i] <= (~current_state[i] & previous_state[i]);
            end
        end
    end

   always @(posedge clk) begin
        if (reset) begin
          control_state <= 0;
        end else control_state <= control_state | {pressed_buttons, released_buttons};
   end


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
       if (reset) begin
         hsync <= 0;
         hpos <= 0;
       end else begin
            hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
            if (hmaxxed) begin
                hpos <= 0;
            end else begin
                hpos <= hpos + 1;
            end
       end
    end

    // vertical position counter

    always @(posedge clk) begin
       if (reset) begin
           vsync <= 0;
           vpos <= 0;
       end else begin
           vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
           if (hmaxxed) begin
                if (vmaxxed) begin
                    vpos <= 0;
                end else begin
                    vpos <= vpos + 1;
                end
            end
        end
      end

    // display_on is set when beam is in "safe" visible frame
    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);
    assign frame_end = hblanked && vblanked;
    assign input_enable = (hblanked && vpos < V_DISPLAY);

endmodule
  
module APU (
      input wire clk,
      input wire reset,
      input wire snare_trigger,
      input wire frame_end,
      input wire [9:0] x,
      input wire [9:0] y,
      output wire sound
);

  `define MUSIC_SPEED   1'b1;  // for 60 FPS

  reg [11:0] frame_counter;
  wire [12:0] timer = frame_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]
    
  // snare noise - using linear feedback shift register  
  reg noise;
  reg noise_src;
  reg [2:0] noise_counter;
  reg [12:0] lfsr;
  
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  always @(posedge clk) begin
    lfsr <= {lfsr[11:0], feedback};
    noise_src <= lfsr;
  end

  wire snare  = snare_active & noise & x < envelopeB*4;   // noise with half a second envelope

  reg prev_snare_trigger = 0;
  reg snare_start;
  reg snare_active = 0;

  reg [14:0] line_counter = 0;  // Enough bits to count up to ~32k lines
 
  // Triggering SFX
  always @(posedge clk) begin // triggering SFX
        prev_snare_trigger <= snare_trigger & ~snare_active;
        snare_start <= ~prev_snare_trigger & snare_trigger;
        if (snare_start & ~snare_active) begin
            snare_active <= 1;
            line_counter <= 0;
        end
        // Count scanlines only if snare is active
        if (snare_active && x == 0) begin
            line_counter <= line_counter + 1;
            if (line_counter >= 6000) begin
                snare_active <= 0;
            end
        end
  end
  
  // SFX Timers  
  always @(posedge clk) begin
    if (reset) begin
      frame_counter <= 0;
      noise_counter <= 0;
      noise <= 0;
    end else begin
      // frame counter
      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end
      // noise timer
      if (x == 0) begin
        if (noise_counter > 1) begin 
          noise_counter <= 0;
          noise <= noise ^ noise_src;
        end else
          noise_counter <= noise_counter + 1'b1;
      end
    end
  end

  // output
  assign sound = {snare};

endmodule

// NES Reciever Module

module InputReceiver (
    input wire clk,
    input wire reset,
    input wire data,     // input data from nes controller to FPGA
    output reg latch,    // parallel -> serial switch for gamepad switch register
    output reg nes_clk,  // outputs from FPGA to nes controller
    output wire A,        
    output wire B,       
    output wire select,
    output wire start,
    output wire up,
    output wire down,
    output wire left,
    output wire right   // output states of nes controller buttons
);

    // FSM symbolic states
    localparam [3:0] latch_en = 4'h0;       // assert latch for 12 us
    localparam [3:0] read_A_wait = 4'h1;
    localparam [3:0] read_B = 4'h2;
    localparam [3:0] read_select  = 4'h3;
    localparam [3:0] read_start   = 4'h4;
    localparam [3:0] read_up      = 4'h5;
    localparam [3:0] read_down    = 4'h6;
    localparam [3:0] read_left    = 4'h7;
    localparam [3:0] read_right   = 4'h8;

    // register to count clock cycles to time latch assertion, nes_clk state, and FSM state transitions	 
    reg [10:0] count_reg, count_next;

    // FSM state register, and button state regs
    reg [3:0] state_reg, state_next;
    reg A_reg, B_reg, select_reg, start_reg, up_reg, down_reg, left_reg, right_reg;
    reg A_next, B_next, select_next, start_next, up_next, down_next, left_next, right_next;
    reg latch_next, nes_clk_next;

     // infer all the registers
    always @(posedge clk)

    if (reset) begin
        count_reg  <= 0;
        state_reg  <= 0;
        A_reg      <= 0;
        B_reg      <= 0;
        select_reg <= 0;
        start_reg  <= 0;
        up_reg     <= 0;
        down_reg   <= 0;
        left_reg   <= 0;
        right_reg  <= 0;
        nes_clk    <= 0;
        latch      <= 0;

    end else begin
        count_reg  <= count_next;
        state_reg  <= state_next;
        A_reg      <= A_next;
        B_reg      <= B_next;
        select_reg <= select_next;
        start_reg  <= start_next;
        up_reg     <= up_next;
        down_reg   <= down_next;
        left_reg   <= left_next;
        right_reg  <= right_next;
        nes_clk    <= nes_clk_next;
        latch      <= latch_next;
    end

    // FSM next-state logic and data path
    always @(posedge clk) begin

        // defaults
        count_next  <= count_reg;
        A_next      <= A_reg;
        B_next      <= B_reg;
        select_next <= select_reg;
        start_next  <= start_reg;
        up_next     <= up_reg;
        down_next   <= down_reg;
        left_next   <= left_reg;
        right_next  <= right_reg;
        state_next  <= state_reg;

        case (state_reg)

            latch_en: begin
                // assert latch pin
                latch_next <= 1;
                nes_clk_next <= 0;  // nes_clk state

                // count 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // once 12 us passed
                else if (count_reg == 300) begin
                    latch_next <= 0;  // deassert latch pin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_A_wait;  // go to read_A_wait state
                end
            end

            read_A_wait: begin

                nes_clk_next <= 0;  // nes_clk state

                if (count_reg == 0) begin
                    A_next <= data;  // read A
                end

                if (count_reg < 150)  // count clk cycles for 6 us
                count_next <= count_reg + 1;

                // once 6 us passed
                else if (count_reg == 150) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_B;  // go to read_B state
                end
            end

            read_B: begin

                // count clk cycles for 12 us
                if (count_reg < 300) begin
                    count_next <= count_reg + 1;
                end

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next<= 1;

                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read B
                if (count_reg == 150)
                    B_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_select;  // go to read_select state
                end
            end

            read_select: begin

                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read select
                if (count_reg == 150)
                    select_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_start;  // go to read_start state
                end

            end

            read_start: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read start
                if (count_reg == 150)
                    start_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_up;  // go to read_up state
                end
            end

            read_up: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150)
                    nes_clk_next <= 1;
                else if (count_reg > 150)
                    nes_clk_next <= 0;

                // read up
                if (count_reg == 150)
                    up_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_down;  // go to read_down state
                end
            end

            read_down: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read down
                if (count_reg == 150) begin
                    down_next <= data;
                end

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_left;  // go to read_left state
                end
            end

            read_left: begin
                // count clk cycles for 12 us
                if (count_reg < 300)
                    count_next <= count_reg + 1;

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read left
                if (count_reg == 150)
                    left_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= read_right;  // go to read_right state
                end

            end

            read_right: begin
                // count clk cycles for 12 us
                if (count_reg < 300) begin
                    count_next <= count_reg + 1;
                end

                // nes_clk state
                if (count_reg <= 150) begin
                    nes_clk_next <= 1;
                end else if (count_reg > 150) begin
                    nes_clk_next <= 0;
                end

                // read right
                if (count_reg == 150)
                    right_next <= data;

                // state over
                if (count_reg == 300) begin
                    count_next <= 0;  // reset latch_count
                    state_next <= latch_en;  // go to latch_en state
                end
            end

            default: state_next <= latch_en;  // default state
        endcase
    end

    // assign outputs, *normally asserted when unpressed
    assign A      = ~A_reg;
    assign B      = ~B_reg;
    assign select = ~select_reg;
    assign start  = ~start_reg;
    assign up     = ~up_reg;
    assign down   = ~down_reg;
    assign left   = ~left_reg;
    assign right  = ~right_reg;

endmodule

