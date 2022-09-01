# Combinational logic with basic module instances.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module
my $gen_mod = "gen_module_comb";
my $gen_file = "$gen_mod.v";

init_top $gen_mod, $gen_file, {
  author => "Artyom Liu <artyomliu\@foxmail.com>",
  license => "MIT"
};

# Add top-level ports
my $data_in = create_bundle "data_in", [
  {name => "din", direction => "input", width => 32, tag => "data"}
];
my $data_out = create_bundle "data_out", [
  {name => "dout", direction => "output", width => 32, tag => "data"}
];

# Load module from JSON configuration file
load_module "example/json/add1.json", "example/json/minus1.json";

my $adder1 = create_inst "add1";
my $adder2 = create_inst "add1", "adder";
my $minus = create_inst "minus1";

# Connect modules and top-level ports
$data_in->connect($adder1->get_bundle("data_in"));
# Assign prefix explicitly
$adder1->get_bundle("data_out")->connect($adder2->get_bundle("data_in"), {prefix => "tmp"});
$adder2->get_bundle("data_out")->connect($minus->get_bundle("data_in"));
$minus->get_bundle("data_out")->connect($data_out);

sign $data_in, $data_out;
sign $adder1, $adder2, $minus;

write_top;

# Compare if the generated file is wanted
ok(0 == (compare $gen_file, "example/verilog/$gen_file"));

# Remove generated file
ok(unlink $gen_file);
