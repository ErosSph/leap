module semantic_features (
  input wire clk,
  input wire rst_n,
  input wire sel,
  input wire [7:0] a,
  input wire [7:0] b,
  output reg [15:0] accum,
  output reg [7:0] y
);
  reg [1:0] state;
  always @* begin
    y = 8'd0;
    case (state)
      2'd0: y = sel ? a + b : {a[3:0], b[7:4]};
      2'd1: y = a[7:0];
      default: y = b;
    endcase
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 2'd0;
      accum <= 16'd0;
    end else begin
      state <= state + 2'd1;
      accum <= accum + {8'd0, y};
    end
  end
endmodule
