/*
 * Author: retrhelo <artyomliu@foxmail.com>
 *
 * Generated by Camellia-Glue. Seed: 3735928559
 */

module gen_module_seq_mix (
  // slow &05_module_seq_mix.t; @20
  input clk_slow,
  input rst_slow,
  // fast &05_module_seq_mix.t; @25
  input clk_fast,
  input rst_n_fast,
  //  &05_module_seq_mix.t; @31
  input [31:0] din,
  // after_add1 &05_module_seq_mix.t; @34
  output [31:0] dout_add,
  // after_minus1 &05_module_seq_mix.t; @37
  output [31:0] dout_minus
);

// &05_module_seq_mix.t; @46
wire [31:0] data_845239;
// &05_module_seq_mix.t; @47
wire [31:0] data_7808ca;
// &05_module_seq_mix.t; @53
wire [31:0] data_ecdae7;
// &05_module_seq_mix.t; @54
wire [31:0] data_82ddc2;


// &05_module_seq_mix.t; @46
add1 u0_add1 (
  .din(data_5b9468),
  .dout(data_845239)
);

// &05_module_seq_mix.t; @47
register u0_register (
  .clk(clk_slow),
  .rst_n(~(rst_slow)),
  .d(data_845239),
  .q(data_7808ca)
);

// &05_module_seq_mix.t; @53
minus1 u0_minus1 (
  .din(data_5b9468),
  .dout(data_ecdae7)
);

// &05_module_seq_mix.t; @54
register u1_register (
  .clk(clk_fast),
  .rst_n(rst_n_fast),
  .d(data_ecdae7),
  .q(data_82ddc2)
);

//  &05_module_seq_mix.t; @31
assign data_5b9468 = din;
// after_add1 &05_module_seq_mix.t; @34
assign dout_add = data_7808ca;
// after_minus1 &05_module_seq_mix.t; @37
assign dout_minus = data_82ddc2;

endmodule
