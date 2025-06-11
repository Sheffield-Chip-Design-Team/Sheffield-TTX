/* * Gamepad_Receiver.v
 *   Project: TinyTapeStation
 *   Author : Kwashie Andoh
 * 
 * This module implements a receiver for NES/SNES gamepad input.
 * It uses a finite state machine (FSM) to read the gamepad data
 * over a serial interface, handling both NES and SNES controllers.
 *
 * The module is designed to work with a 50 MHz clock and
 * includes a reset signal to initialize the state.
 *
 * Inputs:
 * - clk_50: 50 MHz clock signal
 * - reset: Reset signal to initialize the FSM
 * - data: Serial data input from the gamepad
 * - is_snes: Flag to indicate if the controller is SNES (1) or NES (0)
 *
 * Outputs:
 * - controller_latch: Latch signal to initiate reading from the gamepad
 * - controller_clk: Clock signal for the gamepad communication
 * - A, B, select, start: (S)NES buttons
 * - d_pad_up, d_pad_down, d_pad_left, d_pad_right: (S)NES D-pad buttons
 * - X, Y, left, right: SNES buttons (if is_snes is 1)
 *
*/

module Gamepad_Receiver (
    input wire clk_50,
    input wire reset,
    input wire data,
    input wire is_snes, // 1 for SNES, 0 for NES

    output reg  controller_latch,
    output reg  controller_clk,
    // Classic NES buttons
    output wire A,
    output wire B,
    output wire select,
    output wire start,
    output wire d_pad_up,
    output wire d_pad_down,
    output wire d_pad_left,
    output wire d_pad_right,
    // Additional SNES buttons
    output wire X,
    output wire Y,
    output wire left,
    output wire right
);
  // FSM symbolic states
  localparam [3:0] latch_en = 0;

  // register to count clock cycles to time latch assertion, controller_clk state, and FSM state transitions
  reg [10:0] count_reg, count_next;

  // FSM state register, and button state regs
  reg [3:0] state_reg, state_next;
  reg
      A_reg,
      B_reg,
      select_reg,
      start_reg,
      d_pad_up_reg,
      d_pad_down_reg,
      d_pad_left_reg,
      d_pad_right_reg;
  reg X_reg, Y_reg, left_reg, right_reg;
  reg
      A_next,
      B_next,
      select_next,
      start_next,
      d_pad_up_next,
      d_pad_down_next,
      d_pad_left_next,
      d_pad_right_next;
  reg X_next, Y_next, left_next, right_next;
  reg controller_latch_next, controller_clk_next;

  // infer all the registers
  always @(posedge clk_50)

    if (reset) begin
      count_reg        <= 0;
      state_reg        <= 0;
      A_reg            <= 0;
      B_reg            <= 0;
      select_reg       <= 0;
      start_reg        <= 0;
      d_pad_up_reg     <= 0;
      d_pad_down_reg   <= 0;
      d_pad_left_reg   <= 0;
      d_pad_right_reg  <= 0;
      X_reg            <= 0;
      Y_reg            <= 0;
      left_reg         <= 0;
      right_reg        <= 0;
      controller_clk   <= 1;  // default state is high
      controller_latch <= 0;

    end else begin
      count_reg        <= count_next;
      state_reg        <= state_next;
      A_reg            <= A_next;
      B_reg            <= B_next;
      select_reg       <= select_next;
      start_reg        <= start_next;
      d_pad_up_reg     <= d_pad_up_next;
      d_pad_down_reg   <= d_pad_down_next;
      d_pad_left_reg   <= d_pad_left_next;
      d_pad_right_reg  <= d_pad_right_next;
      X_reg            <= X_next;
      Y_reg            <= Y_next;
      left_reg         <= left_next;
      right_reg        <= right_next;
      controller_clk   <= controller_clk_next;
      controller_latch <= controller_latch_next;
    end

  // FSM next-state logic and data path
  always @(posedge clk_50) begin

    // defaults
    count_next       <= count_reg;
    A_next           <= A_reg;
    B_next           <= B_reg;
    select_next      <= select_reg;
    start_next       <= start_reg;
    d_pad_up_next    <= d_pad_up_reg;
    d_pad_down_next  <= d_pad_down_reg;
    d_pad_left_next  <= d_pad_left_reg;
    d_pad_right_next <= d_pad_right_reg;
    X_next           <= X_reg;
    Y_next           <= Y_reg;
    left_next        <= left_reg;
    right_next       <= right_reg;
    state_next       <= state_reg;

    case (state_reg)

      latch_en: begin
        // assert latch pin
        controller_latch_next <= 1;
        controller_clk_next   <= 1;  // controller_clk state

        // count 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // once 12 us passed
        else if (count_reg == 300) begin
          controller_latch_next <= 0;  // deassert latch pin
          count_next <= 0;  // reset latch_count
          state_next <= 1;
        end
      end

      1: begin

        // count clk cycles for 12 us
        if (count_reg < 300) begin
          count_next <= count_reg + 1;
        end

        // toggle controller_clk state every 6 us
        if (count_reg <= 150) controller_clk_next <= 1;

        else if (count_reg > 150) controller_clk_next <= 0;

        if (count_reg == 150) begin
          if (is_snes) begin
            B_next <= data;  // read B
          end else begin
            A_next <= data;  // read A
          end
        end

        // once 12 us passed
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 2;
        end
      end

      2: begin

        // count clk cycles for 12 us
        if (count_reg < 300) begin
          count_next <= count_reg + 1;
        end

        // toggle controller_clk state every 6 us
        if (count_reg <= 150) controller_clk_next <= 1;

        else if (count_reg > 150) controller_clk_next <= 0;

        if (count_reg == 150) begin
          if (is_snes) begin
            Y_next <= data;  // read Y
          end else begin
            B_next <= data;  // read B
          end
        end

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 3;  // go to read_select state
        end
      end

      3: begin

        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) controller_clk_next <= 1;
        else if (count_reg > 150) controller_clk_next <= 0;

        // read select
        if (count_reg == 150) select_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 4;  // go to read_start state
        end

      end

      4: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) controller_clk_next <= 1;
        else if (count_reg > 150) controller_clk_next <= 0;

        // read start
        if (count_reg == 150) start_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 5;  // go to read_d_pad_up state
        end
      end

      5: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) controller_clk_next <= 1;
        else if (count_reg > 150) controller_clk_next <= 0;

        // read d_pad_up
        if (count_reg == 150) d_pad_up_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 6;  // go to read_d_pad_down state
        end
      end

      6: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read d_pad_down
        if (count_reg == 150) d_pad_down_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 7;  // go to read_d_pad_left state
        end
      end

      7: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read d_pad_left
        if (count_reg == 150) d_pad_left_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 8;  // go to read_d_pad_right state
        end

      end

      8: begin
        // count clk cycles for 12 us
        if (count_reg < 300) begin
          count_next <= count_reg + 1;
        end

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read d_pad_right
        if (count_reg == 150) d_pad_right_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          if (is_snes) begin
            state_next <= 9;
          end else begin
            state_next <= latch_en;  // return to latch_en state
          end
        end
      end

      9: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read A
        if (count_reg == 150) A_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 10;
        end

      end

      10: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read X
        if (count_reg == 150) X_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 11;
        end

      end

      11: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read left
        if (count_reg == 150) left_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 12;
        end

      end

      12: begin
        // count clk cycles for 12 us
        if (count_reg < 300) count_next <= count_reg + 1;

        // controller_clk state
        if (count_reg <= 150) begin
          controller_clk_next <= 1;
        end else if (count_reg > 150) begin
          controller_clk_next <= 0;
        end

        // read right
        if (count_reg == 150) right_next <= data;

        // state over
        if (count_reg == 300) begin
          count_next <= 0;  // reset latch_count
          state_next <= 13;
        end

      end

      13: begin
        // count clk cycles for 48 us
        if (count_reg < 1800) count_next <= count_reg + 1;

        // toggle controller_clk state every 6us (150 cycles)
        if ((count_reg % 300) < 150) controller_clk_next <= 1;
        else controller_clk_next <= 0;

        // state over
        if (count_reg == 1800) begin
          count_next <= 0;  // reset latch_count
          state_next <= latch_en;  // return to latch_en state
        end

      end

      default: state_next <= latch_en;  // default state
    endcase
  end

  // assign outputs, *normally asserted when unpressed
  // Classic NES buttons
  assign A           = ~A_reg;
  assign B           = ~B_reg;
  assign select      = ~select_reg;
  assign start       = ~start_reg;
  assign d_pad_up    = ~d_pad_up_reg;
  assign d_pad_down  = ~d_pad_down_reg;
  assign d_pad_left  = ~d_pad_left_reg;
  assign d_pad_right = ~d_pad_right_reg;
  // Additional SNES buttons
  assign X           = ~X_reg;
  assign Y           = ~Y_reg;
  assign left        = ~left_reg;
  assign right       = ~right_reg;

endmodule
