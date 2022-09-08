# Sequential logic support

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module
my $gen_mod = "gen_module_seq";
my $gen_file = "$gen_mod.v";

init_top $gen_mod, $gen_file;

# Add top-level ports
my $default_timing = create_timing "default", {
  clock => "clk",
  reset => "rst",
  edge => "pos"
};
my $fast_timing = create_timing "fast", {
  clock => "clk_fast",
  reset => "rst_n",
  edge => "neg"
};

my $data_in = create_bundle undef, [
  {name => "din", direction => "input", width => 32, tag => "data"}
];
my $data_out1 = create_bundle undef, [
  {name => "dout1", direction => "output", width => 32, tag => "data"}
];
my $data_out2 = create_bundle undef, [
  {name => "dout2", direction => "output", width => 32, tag => "data"}
];

enter_timing $default_timing;

load_module "example/json/register.json";

my $reg = create_inst "register";
$data_in->connect($reg->get_bundle("data_in"));
$reg->get_bundle("data_out")->connect($data_out1);

enter_timing $fast_timing;

my $reg2 = create_inst "register";
$data_in->connect($reg2->get_bundle("data_in"));
$reg2->get_bundle("data_out")->connect($data_out2);

write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
