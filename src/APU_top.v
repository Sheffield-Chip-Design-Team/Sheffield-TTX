 module APU (
      input wire clk,
      input wire reset,
      input wire snare_trigger,
      input wire frame_end,
      input wire [9:0] pix_x,
      input wire [9:0] pix_y,
      output reg sound
    );

  `define MUSIC_SPEED   1'b1;  // for 60 FPS

  reg [11:0] frame_counter;
  wire [12:0] timer = frame_counter;
  reg noise, noise_src = ^lfsr;
  reg [2:0] noise_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]

  // snare noise    
  reg [12:0] lfsr;
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  always @(posedge clk) begin
    lfsr <= {lfsr[11:0], feedback};
  end

  wire snare  = snare_active & noise & pix_x< envelopeB*4;   // noise with half a second envelope
  assign sound = {snare};

  reg prev_buttonPress = 0;
  reg snare_start;
  reg snare_active = 0;

reg [14:0] line_counter = 0;  // Enough bits to count up to ~32k lines

always @(posedge clk) begin
    // Detect rising edge of button
    
    prev_buttonPress <= snare_trigger & ~snare_active;
    snare_start <= ~prev_buttonPress & snare_trigger;

    // Begin snare on button press
    if (snare_start) begin
        snare_active <= 1;
        line_counter <= 0;
    end

    // Count scanlines only if snare is active
    if (snare_active && pix_x == 0) begin
        line_counter <= line_counter + 1;
        if (line_counter >= 6000) begin
            snare_active <= 0;
        end
    end
end

  always @(posedge clk) begin
    if (reset) begin
      frame_counter <= 0;
      noise_counter <= 0;
      noise <= 0;
  
    end else begin

      if (pix_x == 0 && pix_y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end

      // noise
      if (pix_x == 0) begin
        if (noise_counter > 1) begin 
          noise_counter <= 0;
          noise <= noise ^ noise_src;
        end else
          noise_counter <= noise_counter + 1'b1;
      end

    end
  end

endmodule
