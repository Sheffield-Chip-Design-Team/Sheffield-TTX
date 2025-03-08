

// `default_nettype none

`define MUSIC_SPEED   1'b1;  // for 60 FPS
// `define MUSIC_SPEED   2'd2;  // for 30 FPS

`define C1  481; // 32.70375 Hz 
`define Cs1 454; // 34.6475 Hz 
`define D1  429; // 36.7075 Hz 
`define Ds1 405; // 38.89125 Hz 
`define E1  382; // 41.20375 Hz 
`define F1  360; // 43.65375 Hz 
`define Fs1 340; // 46.24875 Hz 
`define G1  321; // 49.0 Hz 
`define Gs1 303; // 51.9125 Hz 
`define A1  286; // 55.0 Hz 
`define As1 270; // 58.27 Hz 
`define B1  255; // 61.735 Hz 
`define C2  241; // 65.4075 Hz 
`define Cs2 227; // 69.295 Hz 
`define D2  214; // 73.415 Hz 
`define Ds2 202; // 77.7825 Hz 
`define E2  191; // 82.4075 Hz 
`define F2  180; // 87.3075 Hz 
`define Fs2 170; // 92.4975 Hz 
`define G2  161; // 98.0 Hz 
`define Gs2 152; // 103.825 Hz 
`define A2  143; // 110.0 Hz 
`define As2 135; // 116.54 Hz 
`define B2  127; // 123.47 Hz 
`define C3  120; // 130.815 Hz 
`define Cs3 114; // 138.59 Hz 
`define D3  107; // 146.83 Hz 
`define Ds3 101; // 155.565 Hz 
`define E3  95; // 164.815 Hz 
`define F3  90; // 174.615 Hz 
`define Fs3 85; // 184.995 Hz 
`define G3  80; // 196.0 Hz 
`define Gs3 76; // 207.65 Hz 
`define A3  72; // 220.0 Hz 
`define As3 68; // 233.08 Hz 
`define B3  64; // 246.94 Hz 
`define C4  60; // 261.63 Hz 
`define Cs4 57; // 277.18 Hz 
`define D4  54; // 293.66 Hz 
`define Ds4 51; // 311.13 Hz 
`define E4  48; // 329.63 Hz 
`define F4  45; // 349.23 Hz 
`define Fs4 43; // 369.99 Hz 
`define G4  40; // 392.0 Hz 
`define Gs4 38; // 415.3 Hz 
`define A4  36; // 440.0 Hz 
`define As4 34; // 466.16 Hz 
`define B4  32; // 493.88 Hz 
`define C5  30; // 523.26 Hz 
`define Cs5 28; // 554.36 Hz 
`define D5  27; // 587.32 Hz 
`define Ds5 25; // 622.26 Hz 
`define E5  24; // 659.26 Hz 
`define F5  23; // 698.46 Hz 
`define Fs5 21; // 739.98 Hz 
`define G5  20; // 784.0 Hz 
`define Gs5 19; // 830.6 Hz 
`define A5  18; // 880.0 Hz 
`define As5 17; // 932.32 Hz 
`define B5  16; // 987.76 Hz 

module APU(

  input wire clk,   // clock
  input wire rst_n, // reset_n - high to reset
  // input wire bgm_ena,
  // input wire effect_code,
  input wire [9:0] x,     // hpos
  input wire [9:0] y,     //ypos

  output wire Audio_Output
);

  // VGA signals
  wire sound;

  assign Audio_Output = sound;

  wire [2:0] part = frame_counter[10-:3];
  wire [12:0] timer = frame_counter;
  // reg noise, noise_src = ^lfsr;
  reg [2:0] noise_counter;

  // envelopes
  wire [4:0] envelopeA = 5'd31 - timer[4:0];  // exp(t*-10) decays to 0 approximately in 32 frames  [255 215 181 153 129 109  92  77  65  55  46  39  33  28  23  20  16  14 12  10   8   7   6   5   4   3   3   2   2]
  wire [4:0] envelopeB = 5'd31 - timer[3:0]*2;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]
  wire beats_1_3 = timer[5:4] == 2'b10;

  // kick wave
  wire square60hz =  y < 262;                 // standing 60Hz square wave


  reg prev_SwordDragonCollision ;
  reg [12:0] lfsr;
  wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;

always @(posedge clk) begin
  prev_SwordDragonCollision <= SwordDragonCollision ;  
  if ((SwordDragonCollision != prev_SwordDragonCollision) && (prev_SwordDragonCollision == 0)) begin
      lfsr <= {lfsr[11:0], feedback};
  end
end

  // snare noise    
  // reg [12:0] lfsr;
  // wire feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0] + 1;
  always @(posedge clk) begin
    // lfsr <= {lfsr[11:0], feedback};
    // lfsr <= lfsr[12:0];
  end

  // lead wave counter
  reg [7:0] note_freq;
  reg [7:0] note_counter;
  reg       note;

  // bass wave counter
  reg [8:0] note2_freq;
  reg [8:0] note2_counter;
  reg       note2;

  // lead notes
  wire [3:0] note_in = timer[7-:4];           // 16 notes, 16 frames per note each. 256 frames total, ~4 seconds
  always @(note_in)
  case(note_in)
      4'd0 : note_freq = `E2
      4'd1 : note_freq = `E3
      4'd2 : note_freq = `D3
      4'd3 : note_freq = `E3
      4'd4 : note_freq = `A2
      4'd5 : note_freq = `B2
      4'd6 : note_freq = `D3
      4'd7 : note_freq = `E3
      4'd8 : note_freq = `E2
      4'd9 : note_freq = `E3
      4'd10: note_freq = `D3
      4'd11: note_freq = `E3
      4'd12: note_freq = `G2
      4'd13: note_freq = `E3
      4'd14: note_freq = `Fs2
      4'd15: note_freq = `E3
  endcase

  // bass notes
  wire [1:0] note2_in = timer[7-:2];           // 8 notes, 32 frames per note each. 256 frames total, ~4 seconds
  always @(note2_in)
  case(note2_in)
      2'd0 : note2_freq = `As4
      // 3'd1 : note2_freq = `As4
      2'd1 : note2_freq = `F5
      // 3'd3 : note2_freq = `F5
      2'd2 : note2_freq = `A5
      // 3'd5 : note2_freq = `A5
      2'd3 : note2_freq = 9'b111111111;
      // 3'd7 : note2_freq = `A5
  endcase

  //wire kick   = square60hz & (x < envelopeA*4);
  wire kick   = 0;                   // 60Hz square wave with half second envelope
  wire snare  = noise       & (x >= 128 && x < 128+envelopeB);   // noise with half a second envelope
  wire lead   = note       & (x >= 256 && x < 256+envelopeB*8);   // ROM square wave with quarter second envelope
  wire base   = note2      & (x >= 256 && x < ((beats_1_3)?(512+8*4):(512+32*4))); 
    //  wire base   = note2      & (x >= 512 && x < 256+envelopeB*8); 
  assign sound = { kick | (snare) | (base) | (lead & part > 2) };

  reg [11:0] frame_counter;
  always @(posedge clk) begin
    if (rst_n) begin
      frame_counter <= 0;
      noise_counter <= 0;
      note_counter <= 0;
      note2_counter <= 0;
      noise <= 0;
      note <= 0;
      note2 <= 0;

    end else begin

      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end

      // noise
    if (x == 0) begin
      //   if (noise_counter > 1) begin 
      //     noise_counter <= 0;
      //     noise <= noise ^ noise_src;
      //   end else
      //     noise_counter <= noise_counter + 1'b1;
      // end

      // square wave
      if (x == 0) begin
        if (note_counter > note_freq) begin
          note_counter <= 0;
          note <= ~note;
        end else begin
          note_counter <= note_counter + 1'b1;
        end

        if (note2_counter > note2_freq) begin
          note2_counter <= 0;
          note2 <= ~note2;
        end else begin
          note2_counter <= note2_counter + 1'b1;
        
        end
      end
    end
    end
  end
endmodule