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
    input wire nes_latch,         // Latch signal
    input wire nes_clk,       // Clock signal for NES controller
    output reg data           // Serial data output
);
    reg [2:0] state;

    localparam A_STATE      = 3'd0;
    localparam B_STATE      = 3'd1;
    localparam SELECT_STATE = 3'd2;
    localparam START_STATE  = 3'd3;
    localparam UP_STATE     = 3'd4;
    localparam DOWN_STATE   = 3'd5;
    localparam LEFT_STATE   = 3'd6;
    localparam RIGHT_STATE  = 3'd7;

    always@(posedge clk) begin
        if(reset)begin
            data = 1;
            state <= A_STATE;
        end
    end

    always@(posedge nes_latch) begin
        state <= A_STATE;
    end

    always @(posedge nes_clk) begin
        if(!reset)begin
            case (state)
                A_STATE: begin
                    // data = ~a_button;
                    state <= B_STATE;
                end
                B_STATE: begin
                    // data = ~b_button;
                    state <= SELECT_STATE;
                end
                SELECT_STATE: begin
                    // data = ~select_button;
                    state <= START_STATE;
                end
                START_STATE: begin
                    // data = ~start_button;
                    state <= UP_STATE;
                end
                UP_STATE: begin
                    // data = ~up_button;
                    state <= DOWN_STATE;
                end
                DOWN_STATE: begin
                    // data = ~down_button;
                    state <= LEFT_STATE;
                end
                LEFT_STATE: begin
                    // data = ~left_button;
                    state <= RIGHT_STATE;
                end
                RIGHT_STATE: begin
                    state <= A_STATE;
                end
                default: begin
                    state <= A_STATE;
                end
            endcase
        end
    end


    always @(clk) begin
        case (state)
            A_STATE: data = ~a_button;
            B_STATE: data = ~b_button;
            SELECT_STATE: data = ~select_button;
            START_STATE: data = ~start_button;
            UP_STATE: data = ~up_button;
            DOWN_STATE: data = ~down_button;
            LEFT_STATE: data = ~left_button;
            RIGHT_STATE: data = ~right_button;
            default: data = 1;
        endcase
    end

endmodule


