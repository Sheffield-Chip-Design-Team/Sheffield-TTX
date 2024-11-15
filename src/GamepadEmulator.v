// --------------------------------------
// module: GamepadEmulator
// Description: This module simulates the NES controller by taking in button inputs from the VGA playground
// and outputting a serial data stream that can be read by the NES controller module.
// Inputs: ui_in[7:0] - Button inputs from VGA playground
// Outputs: data - Serial data output


module GamepadEmulator (
    input wire clk,           // System clock
    input wire reset,         // Reset signal
    input wire a_button,
    input wire b_button,
    input wire select_button,
    input wire start_button,
    input wire up_button,
    input wire down_button,
    input wire left_button,
    input wire right_button,
    output reg data           // Serial data output
);

    // Timing counters (based on 50MHz clock)
    // 18000ns = 900 clock cycles
    // 12000ns = 600 clock cycles
    reg [31:0] timing_counter;
    reg [2:0] state;

    // States for the button sequence
    localparam LATCH_ENABLE = 3'd0;
    localparam A_STATE      = 3'd0;
    localparam B_STATE      = 3'd1;
    localparam SELECT_STATE = 3'd2;
    localparam START_STATE  = 3'd3;
    localparam UP_STATE     = 3'd4;
    localparam DOWN_STATE   = 3'd5;
    localparam LEFT_STATE   = 3'd6;
    localparam RIGHT_STATE  = 3'd7;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data <= 1;              // Data line pulled high when inactive
            state <= A_STATE;
            timing_counter <= 0;
        end
        else begin
            case (state)
                A_STATE: begin
                    data <= ~a_button;
                    if (timing_counter >= 900) begin  // 18000ns / 20ns (50MHz clock)
                        state <= B_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                B_STATE: begin
                    data <= ~b_button;
                    if (timing_counter >= 600) begin  // 12000ns / 20ns
                        state <= SELECT_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                SELECT_STATE: begin
                    data <= ~select_button;
                    if (timing_counter >= 600) begin
                        state <= START_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                START_STATE: begin
                    data <= ~start_button;
                    if (timing_counter >= 600) begin
                        state <= UP_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                UP_STATE: begin
                    data <= ~up_button;
                    if (timing_counter >= 600) begin
                        state <= DOWN_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                DOWN_STATE: begin
                    data <= ~down_button;
                    if (timing_counter >= 600) begin
                        state <= LEFT_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                LEFT_STATE: begin
                    data <= ~left_button;
                    if (timing_counter >= 600) begin
                        state <= RIGHT_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                RIGHT_STATE: begin
                    data <= ~right_button;
                    if (timing_counter >= 600) begin
                        state <= A_STATE;
                        timing_counter <= 0;
                    end else
                        timing_counter <= timing_counter + 1;
                end

                default: state <= A_STATE;
            endcase
        end
    end

endmodule
