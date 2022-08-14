# This test demonstrate a simple use case of Camellia::Glue.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module.
init_top {top => "test", file => "test.v"};

# Add top-level ports
my $clk = create_bundle "clock", [
  {name => "clk", direction => "input", width => 1}
];
my $reset = create_bundle "reset", [
  {name => "rst_n", direction => "input", width => 1}
];
my $data = create_bundle "data", [
  {name => "d", direction => "input", width => 64},
  {name => "q", direction => "output", width => 64}
];

# Currently, assign q with a register reg_q, which is defined in raw code.
$data->except("q", "reg_q");

add_bundle $clk, $reset, $data;

# TODO add rawcode that generates reg_q

# TODO: create and connect instances

# Finally, write it to a given file.
write_top;

# Compare if the generated file is wanted
ok(0 == (compare "test.v", "example/test.v"));

# Remove generated file
ok(unlink "test.v");
