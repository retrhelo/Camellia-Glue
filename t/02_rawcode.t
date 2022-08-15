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
my $data = create_bundle "data", [
  {name => "d", direction => "input", width => 64},
  {name => "q", direction => "output", width => 64}
];

# except() will not get signal generated, but they're still necessary for
# connection check. Make sure that every port is connected, especially for
# output ones.
$data->except("d", "reg_q");
$data->except("q", "reg_q");

add_bundle $timing, $data;

# Raw Verilog code that defines timing logic
my $rawcode = create_raw <<EOL;
reg [63:0] reg_q;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) reg_q <= 64'd0;
  else reg_q <= d;
end

assign q = reg_q;
EOL
push_top $rawcode;

# Finally, write it to a given file.
write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
