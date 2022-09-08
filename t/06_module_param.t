# Simple test for parameterized design

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module
my $gen_mod = "gen_module_param";
my $gen_file = "$gen_mod.v";

init_top $gen_mod, $gen_file, {debug => 1};

my $timing = create_timing undef, {
  clock => "clk",
  reset => "rst_n",
  edge => "neg"
};

my $data_in = create_bundle undef, [
  {name => "din", direction => "input", width => 64, tag => "data"}
];
my $data_out = create_bundle undef, [
  {name => "dout", direction => "output", width => 65, tag => "data"}
];

load_module "example/json/add1_param.json", "example/json/register_param.json";

enter_timing $timing;

my $width = 64;

my $adder = create_inst "add1_param", "adder", {
  data_in => $data_in
}, {
  in_width => $width
};

create_inst "register_param", undef, {
  data_in => $adder->get_bundle("data_out"),
  data_out => $data_out
}, {
  width => $width + 1
};

write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
