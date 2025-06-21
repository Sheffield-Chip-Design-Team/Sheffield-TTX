
module DragonTarget(
      input wire clk,
      input wire reset,
      input wire trigger,
      input wire dragon_hurt,
      input wire target_reached,
      input wire [7:0] player_pos, 
      input wire [7:0] sheep_pos,
      output wire [7:0] target_pos
);
    
    reg [7:0] target_pos_reg;
    reg [2:0] DragonBehaviourState = 0;
    reg [2:0] NextDragonBehaviourState = 0;

    always @(posedge clk) begin
      if (~reset) begin

        if (trigger) begin
          DragonBehaviourState <= NextDragonBehaviourState;
        end

      end else begin
        DragonBehaviourState <= 0;
      end

    end

    always @(posedge clk) begin

      case (DragonBehaviourState)
        0: begin //chase the player
          target_pos_reg <= player_pos;
          if (dragon_hurt | target_reached)  NextDragonBehaviourState <= 1; 
        end

        1: begin // chase the sheep
          target_pos_reg <= 8'b1111_1100;
          if (dragon_hurt | target_reached) NextDragonBehaviourState <= 2;
        end

        2: begin // retreat to the corner
          target_pos_reg <= 8'b0000_0000;
           if (target_reached) NextDragonBehaviourState <= 0;
        end

        default : begin 
          target_pos_reg <= player_pos;
        end
      endcase

    end

    assign target_pos = player_pos;
endmodule
