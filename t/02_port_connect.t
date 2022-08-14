# Test if ports can be connected correctly

use strict;
use warnings;

use Test::Simple tests => 6;

use Camellia::Glue;

my $master = create_port "master", [
  {
    name => "port1",
    direction => "input",
    width => 64
    # use default tag (the name)
  },
  {
    name => "port_same_tag",
    direction => "input",
    width => 64,
    tag => "port2"
  },
  {
    name => "port_same_dir",
    direction => "output",
    width => 32,
    tag => "port3"
  },
  {
    name => "port_wrong_width",
    direction => "output",
    width => 32,
    tag => "port4"
  }
];

my $slave = create_port "slave", [
  {
    name => "port_default_tag",
    direction => "output",
    width => 64,
    tag => "port1"
  },
  {
    name => "port_same_tag",
    direction => "output",
    width => 64,
    tag => "port2"
  },
  {
    name => "port_same_dir",
    direction => "output",
    width => 32,
    tag => "port3"
  },
  {
    name => "port_wrong_width",
    direction => "input",
    width => 64,
    tag => "port4"
  }
];

$master->connect($slave, {
  prefix => "m2s"
});

ok(0 == (@{$master->{group}}[0]->{wire} cmp "m2s_port1"));
ok(defined @{$master->{group}}[0]->{wire});
ok(0 == (@{$slave->{group}}[1]->{wire} cmp "m2s_port2"));
ok(defined @{$slave->{group}}[1]->{wire});
ok(!(defined @{$master->{group}}[2]->{wire}));
ok(!(defined @{$master->{group}}[3]->{wire}));
