use strict;
use warnings;
package Camellia::Glue::Port;

sub new {
  my ($class, $args) = @_;

  return bless {
    connected => 0,
    source => 0,
    group => $args->{group},
    name => $args->{name}
  }, $class;
}

# each element in "group" stands for a single port, and consists of following
# fields:
# name: the name of the port
# direction: the direction of "input", "output" or "inout"
# width: width of port
# tag: tag of this port, used for comparison when connecting with another port
# wire: the name of wire used to connect this port
# gen: should the wire the a generated one

sub connect {
  my ($obj, $args) = @_;

  my $prefix = (defined $args->{prefix}) ? "$args->{prefix}_" : "";
  my $suffix = (defined $args->{suffix}) ? "$args->{suffix}_" : "";

  $obj->{connected} = $args->{dst}->{connected} = 1;
  $obj->source = 1;

  # TODO: optimize the searching algorithm
  for my $src (@{$obj->{group}}) {
    for my $dst (@{$args->{dst}->{group}}) {
      if (0 == ($src->{tag} cmp $dst->{tag})) {
        $src->{wire} = $dst->{wire} = "${prefix}$src->{tag}${suffix}";
        # only mark src's port as "generated", to avoid generating twice
        $src->{gen} = 1;
      }
    }
  }

  return $obj;
}

# Handle excepting ports
sub except {
  my ($obj, $port_name, $wire) = @_;
  for my $src (@{$obj->{group}}) {
    if (0 == ($src->{name} cmp $port_name)) {
      $src->{gen} = 0;
      $src->{wire} = $wire;
    }
  }

  return $obj;
}

1;
