module gen_rawcode (
  // timing &02_rawcode.t; @17
  input clk,
  input rst_n,
  // data_in &02_rawcode.t; @21
  input [63:0] d,
  //  &02_rawcode.t; @24
  output [63:0] q
);

reg [63:0] reg_q;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) reg_q <= 64'd0;
  else reg_q <= d;
end

assign q = reg_q;

endmodule
