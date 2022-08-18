use strict;
use warnings;
package Camellia::Glue::Bundle;

sub new {
  my ($class, $args) = @_;

  return bless {
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
# gen: if the wire is auto generated

sub connect {
  my ($obj, $dst_obj, $args) = @_;

  my ($prefix, $suffix);
  if (defined $args) {
    $prefix = (defined $args->{prefix}) ? "$args->{prefix}_" : "";
    $suffix = (defined $args->{suffix}) ? "_$args->{suffix}" : "";
  }

  for my $src (@{$obj->{group}}) {
    for my $dst (@{$dst_obj->{group}}) {
      # if the tags match
      if (0 == ($src->{tag} cmp $dst->{tag})) {
        if (0 == ($src->{direction} cmp $dst->{direction}) &&
            $src->{direction} cmp "inout")
        {
          warn "$obj->{name}::$src->{name} -> $dst_obj->{name}::$dst->{name}: "
              . "same direction";
        } elsif ($src->{width} != $dst->{width}) {
          warn "$obj->{name}::$src->{name} -> $dst_obj->{name}::$dst->{name}: "
              . "unmatched width ($src->{width}, $dst->{width})";
        } else {
          # create the connection
          $src->{wire} = $dst->{wire} = "$prefix$src->{tag}$suffix";
          # only mark source port as "generated"
          $src->{gen} = 1;
        }
        last;
      }
    }
  }

  return $obj;
}

# Assign connection manually
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

# Connection check for bundle
sub check {
  my ($obj) = @_;

  for my $port (@{$obj->{group}}) {
    if (!(defined $port->{wire})) {
      ("output" cmp $port->{direction}) or die "$port->{name}: "
          . "undriven input port";
      warn "$port->{name}: output not used";
    }
  }
}

1;
