/*
    Project: TinyTapeStation
    Module: FPGA NES Reciever Module
    Original Author :
    Adapted by Kwashie Andoh

    Summary: The NES input receiever module takes input from the NES 7-pin output port and
    and inputs the individual button states.

    Description =============================================

*/

module NESTest_Top (

    // system
    input wire system_clk_100MHz, // E3 - CLK pin
    input wire reset,             // Switch

    // controller interface [GPIO]
    input wire NES_Data,
    output wire NES_Latch,
    output wire NES_Clk,

    // button states [LEDs]
    output wire A_out,
    output wire B_out,
    output wire select_out,
    output wire start_out,
    output wire up_out,
    output wire down_out,
    output wire left_out,
    output wire right_out

);

    wire system_clk_50MHz;

    // 100MHz -> 50MHz Clock Divider
    clk_div clk_div_100to50
    (
        .clk_in(system_clk_100MHz),
        .reset(reset),
        .clk_50MHz(system_clk_50MHz)
    );

    NES_Reciever nesRec (
        .clk(system_clk_50MHz),
        .reset(reset),
        .data(NES_Data),
        .latch(NES_Latch),
        .nes_clk(NES_Clk),
        .A(A_out),
        .B(B_out),
        .select(select_out),
        .start(start_out),
        .up(up_out),
        .down(down_out),
        .left(left_out),
        .right(right_out)
    );

endmodule


module NES_Reciever (

    input wire clk,
    input wire reset,
    input wire data,   // input data from nes controller to FPGA
    output reg latch,
    output reg nes_clk,  // outputs from FPGA to nes controller
    output wire A,
    output wire B,
    output wire select,
    output wire start,
    output wire up,
    output wire down,
    output wire left,
    output wire right  // output states of nes controller buttons
);

    // FSM symbolic states
    localparam [3:0] latch_en = 4'h0;  // assert latch for 12 us
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
        nes_clk    <= latch_next;
        latch      <= nes_clk_next;
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
                latch_next = 1;

                nes_clk_next = 0;  // nes_clk state

                // count 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // once 12 us passed
                else if (count_reg == 600) begin
                latch_next = 0;  // deassert latch pin
                count_next = 0;  // reset latch_count
                state_next = read_A_wait;  // go to read_A_wait state
                end
            end

            read_A_wait: begin
                if (count_reg == 0) A_next = data;  // read A

                nes_clk_next = 0;  // nes_clk state

                if (count_reg < 300)  // count clk cycles for 6 us
                count_next = count_reg + 1;

                // once 6 us passed
                else if (count_reg == 300) begin
                count_next = 0;  // reset latch_count
                state_next = read_B;  // go to read_B state
                end
            end

            read_B: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read B
                if (count_reg == 300) B_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_select;  // go to read_select state
                end
            end

            read_select: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read select
                if (count_reg == 300) select_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_start;  // go to read_start state
                end
            end

            read_start: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read start
                if (count_reg == 300) start_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_up;  // go to read_up state
                end
            end

            read_up: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read up
                if (count_reg == 300) up_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_down;  // go to read_down state
                end
            end

            read_down: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read down
                if (count_reg == 300) down_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_left;  // go to read_left state
                end
            end

            read_left: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read left
                if (count_reg == 300) left_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = read_right;  // go to read_right state
                end
            end

            read_right: begin
                // count clk cycles for 12 us
                if (count_reg < 600) count_next = count_reg + 1;

                // nes_clk state
                if (count_reg <= 300) nes_clk_next = 1;
                else if (count_reg > 300) nes_clk_next = 0;

                // read right
                if (count_reg == 300) right_next = data;

                // state over
                if (count_reg == 600) begin
                count_next = 0;  // reset latch_count
                state_next = latch_en;  // go to latch_en state
                end
            end

            default: state_next = latch_en;  // default state
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
