# This test demonstrate a simple use case of Camellia::Glue.
# Top-level ports are declared, and connected to a raw code snippet.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module
my $gen_file = "gen_rawcode.v";
init_top "gen_rawcode", $gen_file;

# Add top-level ports
my $data_in = create_bundle "data_in", [
  {name => "d", direction => "input", width => 64}
];
my $data_out = create_bundle undef, [
  {name => "q", direction => "output", width => 64}
];

$data_in->except("d", "temp");
$data_out->except("q", "temp");

sign $data_in, $data_out;

my $rawcode = create_raw <<EOL;
assign q = d + 1;
EOL

sign $rawcode;

# Finally, write it to a given file
write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
