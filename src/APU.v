
module AudioProcessingUnit (
      input wire clk,
      input wire reset,
      input wire snare_trigger,
      input wire frame_end,
      input wire [9:0] x,
      input wire [9:0] y,
      output wire sound
);

  `define MUSIC_SPEED   1'b1;  // for 60 FPS

  reg [11:0] frame_counter;
  wire [12:0] timer = frame_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]
    
  // snare noise - using linear feedback shift register  
  reg noise;
  reg noise_src;
  reg [2:0] noise_counter;
  reg [12:0] lfsr;
  
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  always @(posedge clk) begin
    lfsr <= {lfsr[11:0], feedback};
    noise_src <= lfsr;
  end

  wire snare  = snare_active & noise & x < envelopeB*4;   // noise with half a second envelope

  reg prev_snare_trigger = 0;
  reg snare_start;
  reg snare_active = 0;

  reg [14:0] line_counter = 0;  // Enough bits to count up to ~32k lines
 
  // Triggering SFX
  always @(posedge clk) begin // triggering SFX
        prev_snare_trigger <= snare_trigger & ~snare_active;
        snare_start <= ~prev_snare_trigger & snare_trigger;
        if (snare_start & ~snare_active) begin
            snare_active <= 1;
            line_counter <= 0;
        end
        // Count scanlines only if snare is active
        if (snare_active && x == 0) begin
            line_counter <= line_counter + 1;
            if (line_counter >= 6000) begin
                snare_active <= 0;
            end
        end
  end
  
  // SFX Timers  
  always @(posedge clk) begin
    if (reset) begin
      frame_counter <= 0;
      noise_counter <= 0;
      noise <= 0;
    end else begin
      // frame counter
      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end
      // noise timer
      if (x == 0) begin
        if (noise_counter > 1) begin 
          noise_counter <= 0;
          noise <= noise ^ noise_src;
        end else
          noise_counter <= noise_counter + 1'b1;
      end
    end
  end

  // output
  assign sound = {snare};
endmodule
