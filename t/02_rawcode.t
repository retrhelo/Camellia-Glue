# This test demonstrate a simple use case of Camellia::Glue.
# Top-level ports are declared, and connected to a raw code snippet.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module.
my $gen_file = "gen_rawcode.v";
init_top "gen_rawcode", $gen_file;

# Add top-level ports
my $timing = create_bundle "timing", [
  {name => "clk", direction => "input", width => 1},
  {name => "rst_n", direction => "input", width => 1}
];
my $data_in = create_bundle "data_in", [
  {name => "d", direction => "input", width => 64}
];
my $data_out = create_bundle undef, [
  {name => "q", direction => "output", width => 64}
];

# except() will not get signal generated, but they're still necessary for
# connection check. Make sure that every port is connected, especially for
# output ones.
$data_in->except("d", "reg_q");
$data_out->except("q", "reg_q");

# add_bundle $timing, $data;
sign $timing;
sign $data_in, $data_out;

# Raw Verilog code that defines timing logic
my $rawcode = create_raw <<EOL;
reg [63:0] reg_q;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) reg_q <= 64'd0;
  else reg_q <= d;
end

assign q = reg_q;
EOL

sign $rawcode;

# Finally, write it to a given file.
write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
