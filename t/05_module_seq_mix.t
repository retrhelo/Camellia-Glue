# Testing the generation of sequential logics with a more complex use case.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module
my $gen_mod = "gen_module_seq_mix";
my $gen_file = "$gen_mod.v";

init_top $gen_mod, $gen_file, {
  author => "retrhelo <artyomliu\@foxmail.com>"
};

# Set two timing domains for slow/fast clocking
my $slow_timing = create_timing "slow", {
  clock => "clk_slow",
  reset => "rst_slow",
  edge => "pos"
};
my $fast_timing = create_timing "fast", {
  clock => "clk_fast",
  reset => "rst_n_fast",
  edge => "neg"
};

my $data_in = create_bundle undef, [
  {name => "din",, direction => "input", width => 32, tag => "data"}
];
my $data_add = create_bundle "after_add1", [
  {name => "dout_add", direction => "output", width => 32, tag => "data"}
];
my $data_minus = create_bundle "after_minus1", [
  {name => "dout_minus", direction => "output", width => 32, tag => "data"}
];

load_module "example/json/register.json";
load_module "example/json/add1.json", "example/json/minus1.json";

enter_timing $slow_timing;

my $add = create_inst "add1";
my $reg_add = create_inst "register";

$add->get_bundle("data_in")->connect($data_in);
$add->get_bundle("data_out")->connect($reg_add->get_bundle("data_in"));
$reg_add->get_bundle("data_out")->connect($data_add);

my $minus = create_inst "minus1";
my $reg_minus = create_inst "register";

$minus->get_bundle("data_in")->connect($data_in);
$minus->get_bundle("data_out")->connect($reg_minus->get_bundle("data_in"));
$reg_minus->get_bundle("data_out")->connect($data_minus);

# Assign timing domain manually
$reg_minus->get_timing("default")->set_timing($fast_timing);

write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
