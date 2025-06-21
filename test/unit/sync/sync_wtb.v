`default_nettype none
`timescale 1ns / 1ns

/* 
  Note:
    This wrapper 'testbench' just instantiates the module and makes some
    convenient wires that can be driven/tested by the cocotb python testbench.
*/

module sync_tb();

  // inputs
  reg clk;
  reg rst_n;

  // outputs
  wire hsync;
  wire vsync;
  wire video_active;
  wire frame_end;
  wire [9:0] pix_x, pix_y;

  // unused
  // wire enable_input;

  sync_generator sync_gen (
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .screen_hpos(pix_x),
    .screen_vpos(pix_y),
    .frame_end(frame_end)
    // .input_enable(enable_input)
  );

  // Dump the signals to a VCD file so it can be viewed in surfer/GTKWAVE.
  initial begin
    $dumpfile("sync.vcd");
    $dumpvars(0, sync_tb);
    #1;
  end

endmodule
