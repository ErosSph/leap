module two_clock (
  input wire clk_a,
  input wire clk_b,
  input wire rst_n,
  input wire [7:0] data_a,
  input wire [7:0] data_b,
  output reg [7:0] count_a,
  output reg [7:0] count_b
);
  always @(posedge clk_a or negedge rst_n) begin
    if (!rst_n)
      count_a <= 8'd0;
    else
      count_a <= count_a + data_a;
  end
  always @(posedge clk_b or negedge rst_n) begin
    if (!rst_n)
      count_b <= 8'd0;
    else
      count_b <= count_b + data_b;
  end
endmodule
