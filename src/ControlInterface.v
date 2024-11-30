
// Module : Input Collector

/* 
    Description:
                takes input signals from ui_in (GUI) and outputs 1 on each button state when a button has been pressed or released.

    Control State Structure:
                0: UP 
                1: DOWN
                2: LEFT
                3: RIGHT
                4: ACTION
*/

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
    
    initial begin
        control_state = 0;
    end

    reg [4:0] previous_state  = 5'b0;
    reg [4:0] current_state   = 5'b0;
    reg [4:0] pressed_buttons = 5'b0 ;
    reg [4:0] released_buttons = 5'b0 ;
    reg [1:0] ripple_counter = 0;

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
        
        if (!reset) begin
            control_state <= control_state | {pressed_buttons, released_buttons};
        end

        else  control_state <= 0;
    end


endmodule
