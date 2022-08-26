module gen_rawcode (
  // data_in &02_rawcode.t; @17
  input [63:0] d,
  //  &02_rawcode.t; @20
  output [63:0] q
);

// &02_rawcode.t; @29
assign q = d + 1;

endmodule
