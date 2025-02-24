`default_nettype none

// PWM audio output.
// The output is high for sample clocks out of every 255 clocks.
// This means a sample of 0 is always off, a sample of 255 is always on.
module pwm_audio (
    input wire clk,
    input wire rst_n,

    input wire [7:0] sample,

    output reg pwm
);

    reg [7:0] count;

    always @(posedge clk) begin
        if (!rst_n) count <= 0;
        else begin
            // PWM output high for sample clocks out of every 255 clocks
            pwm <= count < sample;

            // Wrap the counter every 255 clocks
            count <= count + 1;
            if (count == 8'hfe) count <= 0;
        end
    end

endmodule