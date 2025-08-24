`default_nettype none
`timescale 1ns / 1ns

module collector_tb();

// InputCollector
  reg clk;
  reg reset;
  reg up;
  reg down;
  reg left;
  reg right;
  reg attack;
  wire [9:0] control_state;

  InputCollector u_InputCollector (
    .clk(clk),
    .reset(reset),
    .up(up),
    .down(down),
    .left(left),
    .right(right),
    .attack(attack),
    .control_state(control_state)
  );
 

  initial begin
    $dumpfile("collector.vcd");
    $dumpvars(0, collector_tb);
    #1;
  end
endmodule
