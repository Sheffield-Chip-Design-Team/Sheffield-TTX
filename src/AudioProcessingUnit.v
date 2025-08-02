module AudioProcessingUnit (
    input wire clk,
    input wire reset,
    input wire SheepDragonCollision,
    input wire SwordDragonCollision,
    input wire PlayerDragonCollision,
    input wire frame_end,
    input wire [9:0] x,
    input wire [9:0] y,
    output wire sound
);

//-------------------------------------------//
// Global frame counter (for melody timing)
//-------------------------------------------//
reg [11:0] frame_counter;
always @(posedge clk) begin
    if (reset)
        frame_counter <= 0;
    else if (x == 0 && y == 0)
        frame_counter <= frame_counter + 1;
end

//-------------------------------------------//
// SFX 1: Dragon Eating Sheep (low rumble)
//-------------------------------------------//
reg dragon_active, dragon_cooldown;
reg [15:0] dragon_counter;
reg dragon_square;
reg [30:0] dragon_duration, dragon_cooldown_timer;

always @(posedge clk) begin
    if (reset) begin
        dragon_active <= 0;
        dragon_cooldown <= 0;
        dragon_counter <= 0;
        dragon_square <= 0;
        dragon_duration <= 0;
        dragon_cooldown_timer <= 0;
    end else begin
        if (SheepDragonCollision && !dragon_active && !dragon_cooldown) begin
            dragon_active <= 1;
            dragon_duration <= 3000;
        end

        if (dragon_active) begin
            if (dragon_counter >= 600) begin
                dragon_counter <= 0;
                dragon_square <= ~dragon_square;
            end else
                dragon_counter <= dragon_counter + 1;

            if (dragon_duration == 0) begin
                dragon_active <= 0;
                dragon_cooldown <= 1;
                dragon_cooldown_timer <= 3000000;
            end else
                dragon_duration <= dragon_duration - 1;
        end

        if (dragon_cooldown) begin
            if (dragon_cooldown_timer == 0)
                dragon_cooldown <= 0;
            else
                dragon_cooldown_timer <= dragon_cooldown_timer - 1;
        end
    end
end

wire [3:0] dragon_out = (dragon_square & dragon_active) ? 4'd8 : 4'd0;

//-------------------------------------------//
// SFX 2: Knight Hitting Dragon (noise burst)
//-------------------------------------------//
reg knight_hit_active, knight_hit_cooldown;
reg [11:0] knight_hit_duration, knight_hit_cooldown_timer;
reg [12:0] lfsr;
wire lfsr_feedback = lfsr[12] ^ lfsr[8] ^ lfsr[2] ^ lfsr[0];

always @(posedge clk) begin
    if (reset) begin
        knight_hit_active <= 0;
        knight_hit_cooldown <= 0;
        knight_hit_duration <= 0;
        knight_hit_cooldown_timer <= 0;
        lfsr <= 13'b1;
    end else begin
        lfsr <= {lfsr[11:0], lfsr_feedback};

        if (SwordDragonCollision && !knight_hit_active && !knight_hit_cooldown) begin
            knight_hit_active <= 1;
            knight_hit_duration <= 1800;
        end

        if (knight_hit_active) begin
            if (knight_hit_duration == 0) begin
                knight_hit_active <= 0;
                knight_hit_cooldown <= 1;
                knight_hit_cooldown_timer <= 1800;
            end else
                knight_hit_duration <= knight_hit_duration - 1;
        end

        if (knight_hit_cooldown) begin
            if (knight_hit_cooldown_timer == 0)
                knight_hit_cooldown <= 0;
            else
                knight_hit_cooldown_timer <= knight_hit_cooldown_timer - 1;
        end
    end
end

wire [3:0] knight_hit_out = (lfsr[0] & knight_hit_active) ? 4'd10 : 4'd0;

//-------------------------------------------//
// SFX 3: Knight Taking Damage (high beep)
//-------------------------------------------//
reg knight_hurt_active, knight_hurt_cooldown;
reg [15:0] knight_hurt_counter;
reg knight_hurt_square;
reg [15:0] knight_hurt_duration, knight_hurt_cooldown_timer;

always @(posedge clk) begin
    if (reset) begin
        knight_hurt_active <= 0;
        knight_hurt_cooldown <= 0;
        knight_hurt_counter <= 0;
        knight_hurt_square <= 0;
        knight_hurt_duration <= 0;
        knight_hurt_cooldown_timer <= 0;
    end else begin
        if (PlayerDragonCollision && !knight_hurt_active && !knight_hurt_cooldown) begin
            knight_hurt_active <= 1;
            knight_hurt_duration <= 1500;
        end

        if (knight_hurt_active) begin
            if (knight_hurt_counter >= 200) begin
                knight_hurt_counter <= 0;
                knight_hurt_square <= ~knight_hurt_square;
            end else
                knight_hurt_counter <= knight_hurt_counter + 1;

            if (knight_hurt_duration == 0) begin
                knight_hurt_active <= 0;
                knight_hurt_cooldown <= 1;
                knight_hurt_cooldown_timer <= 1500;
            end else
                knight_hurt_duration <= knight_hurt_duration - 1;
        end

        if (knight_hurt_cooldown) begin
            if (knight_hurt_cooldown_timer == 0)
                knight_hurt_cooldown <= 0;
            else
                knight_hurt_cooldown_timer <= knight_hurt_cooldown_timer - 1;
        end
    end
end

wire [3:0] knight_hurt_out = (knight_hurt_square & knight_hurt_active) ? 4'd12 : 4'd0;

// //-------------------------------------------//
// // SFX 4: Game Win/Loss (melody)
// //-------------------------------------------//
// reg game_active, game_cooldown;
// reg [3:0] melody_step;
// reg [15:0] game_counter, tone_period;
// reg game_square;
// reg [15:0] game_cooldown_timer;

// always @(posedge clk) begin
//     if (reset) begin
//         game_active <= 0;
//         game_cooldown <= 0;
//         melody_step <= 0;
//         game_counter <= 0;
//         tone_period <= 0;
//         game_square <= 0;
//         game_cooldown_timer <= 0;
//     end else begin
//         if (frame_end && !game_active && !game_cooldown && (melody_step == 0)) begin
//             game_active <= 1;
//             melody_step <= 0;
//         end

//         if (game_active) begin
//             if (game_counter >= tone_period) begin
//                 game_counter <= 0;
//                 game_square <= ~game_square;
//             end else
//                 game_counter <= game_counter + 1;

//             if (frame_end) begin
//                 melody_step <= melody_step + 1;
//                 case (melody_step)
//                     0: tone_period <= 600;
//                     1: tone_period <= 400;
//                     2: tone_period <= 500;
//                     3: tone_period <= 700;
//                     4: begin
//                         tone_period <= 0;
//                         game_active <= 0;
//                         game_cooldown <= 1;
//                         game_cooldown_timer <= 3000;
//                     end
//                 endcase
//             end
//         end

//         if (game_cooldown) begin
//             if (game_cooldown_timer == 0)
//                 game_cooldown <= 0;
//             else
//                 game_cooldown_timer <= game_cooldown_timer - 1;
//         end
//     end
// end

// wire [3:0] game_out = (game_square & game_active) ? 4'd14 : 4'd0;

//-------------------------------------------//
// PWM Mixer
//-------------------------------------------//
wire [5:0] mix = dragon_out + knight_hit_out + knight_hurt_out ;

reg [5:0] pwm_counter;
always @(posedge clk) begin
    pwm_counter <= pwm_counter + 1;
end

assign sound = (pwm_counter < mix);

endmodule