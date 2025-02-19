module PWM(
    input clk,       // System clock
    input rst,       // Reset signal
    output reg pwm // PWM output for buzzer
);
    
    parameter PWM_PERIOD = 12500; // Define period directly (50 MHz clk and 4kHz pwm)
    parameter NOTE_PERIOD = 250000000; // 5 seconds assuming 50MHz clock (50M * 5)
   
    parameter FULL_CYCLE = 128; 
    parameter HALF_CYCLE = 64; 
    parameter QUARTER_CYCLE = 32; 
    parameter EIGTH_CYCLE = 16; 
    
    
    reg [7:0] duty_cycle1 = FULL_CYCLE/FULL_CYCLE; // Original duty cycle
    reg [7:0] duty_cycle2 = HALF_CYCLE/FULL_CYCLE; // Half duty cycle
    reg [7:0] duty_cycle3 = QUARTER_CYCLE/FULL_CYCLE; // Quater duty cycle
    reg [7:0] duty_cycle4 = EIGTH_CYCLE/FULL_CYCLE; // Eighth duty cycle
    
    reg [7:0] current_duty_cycle;
    reg [31:0] counter;
    reg [31:0] note_counter;
    reg [1:0] note_index; // 2-bit index to cycle through 4 notes
    
    always @(posedge clk) begin
       
        if (rst) begin
            counter <= 0;
            note_counter <= 0;
            pwm <= 0;
            note_index <= 0;
            current_duty_cycle <= duty_cycle1;

        end else begin
            // PWM Logic
            if (counter < PWM_PERIOD - 1)
                counter <= counter + 1;
            else
                counter <= 0;

            pwm <= (counter < (current_duty_cycle * PWM_PERIOD)) ? 1 : 0; 
            
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
