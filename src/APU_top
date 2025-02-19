module PWM(
    input clk,       // System clock
    input rst,       // Reset signal
    output reg buzzer // PWM output for buzzer
);
    
    parameter PWM_PERIOD = 12500; // Define period directly (50 MHz clk and 4kHz pwm)
    parameter NOTE_PERIOD = 250000000; // 5 seconds assuming 50MHz clock (50M * 5)
    
    reg [7:0] duty_cycle1 = 128/256; // Original duty cycle
    reg [7:0] duty_cycle2 = 64/256; // Quarter duty cycle
    reg [7:0] duty_cycle3 = 32/256; // Half duty cycle
    reg [7:0] duty_cycle4 = 16/256; // Eighth duty cycle
    
    reg [7:0] current_duty_cycle;
    reg [31:0] counter;
    reg [31:0] note_counter;
    reg [1:0] note_index; // 2-bit index to cycle through 4 notes
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            note_counter <= 0;
            buzzer <= 0;
            note_index <= 0;
            current_duty_cycle <= duty_cycle1;

        end else begin
            // PWM Logic
            if (counter < PWM_PERIOD - 1)
                counter <= counter + 1;
            else
                counter <= 0;

            buzzer <= (counter < (current_duty_cycle * PWM_PERIOD)) ? 1 : 0;
            
            // Note Alternation Logic
            if (note_counter < NOTE_PERIOD - 1)
                note_counter <= note_counter + 1;
            else begin
                note_counter <= 0;
                note_index <= note_index + 1;
                case (note_index)
                    2'b00: current_duty_cycle <= duty_cycle1;
                    2'b01: current_duty_cycle <= duty_cycle2;
                    2'b10: current_duty_cycle <= duty_cycle3;
                    2'b11: current_duty_cycle <= duty_cycle4;
                endcase
            end
        end
    end
endmodule
