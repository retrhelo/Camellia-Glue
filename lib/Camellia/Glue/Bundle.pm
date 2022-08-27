use strict;
use warnings;
package Camellia::Glue::Bundle;

# each element in "group" stands for a single port, and consists of following
# fields:
# name: the name of the port
# direction: the direction of "input" or "output"
# width: width of port
# tag: tag of this port, used for comparison when connecting with another port
# wire: the name of wire used to connect this port
# gen: if the wire is auto generated

# Direction bit layout:
# We use hex integer to represent the direction of certain port.
# 0x1: data source
# 0x2: data_destination

use constant {
  DATA_SRC => 0x1,
  DATA_DST => 0x2
};

sub new {
  my ($class, $args) = @_;

  defined $args->{name} or die "$args->{debug}: bundle without name";

  # Verify bundle port group
  for my $port (@{$args->{group}}) {
    defined $port->{name} or die "$args->{debug}: undefined name";
    defined $port->{direction} or
        die "$args->{debug}: undefined direction";
    die "$args->{debug}: invalid direction \"$port->{direction}\""
        if (
          ("input" cmp $port->{direction}) &&
          ("output" cmp $port->{direction})
        );
    defined $port->{width} or die "$args->{debug}: undefined width";
  }

  for my $port (@{$args->{group}}) {
    # Transform direction into integer format
    if (0 == ("input" cmp $port->{direction})) {
      $port->{direction} = $args->{is_top} ? DATA_SRC : DATA_DST;
    } else {
      $port->{direction} = $args->{is_top} ? DATA_DST : DATA_SRC;
    }

    # Set default tag
    $port->{tag} //= $port->{name};
  }

  return bless {
    group => $args->{group},
    name => $args->{name},
    debug => $args->{debug}
  }, $class;
}

my $hash = {};
sub __gen_random {
  my $rand;
  do {
    $rand = int(rand(0xffffff));
  } until (!(defined $hash->{"$rand"}));

  $hash->{"$rand"} = 1;
  return sprintf "%06x", $rand;
}

sub connect {
  my ($obj, $dst_obj, $args) = @_;

  my ($prefix, $suffix);
  if (defined $args) {
    $prefix = (defined $args->{prefix}) ? "$args->{prefix}_" : "";
    $suffix = (defined $args->{suffix}) ? "_$args->{suffix}" : "";
  } else {
    # TODO: generate random pre/suffix
    $prefix = "";
    $suffix = "_" . __gen_random;
  }

  for my $src (@{$obj->{group}}) {
    for my $dst (@{$dst_obj->{group}}) {
      # if the tags match
      if (0 == ($src->{tag} cmp $dst->{tag})) {
        if ($src->{direction} == $dst->{direction}) {
          warn "$obj->{name}::$src->{name} -> $dst_obj->{name}::$dst->{name}: "
              . "same direction";
        } elsif ($src->{width} != $dst->{width}) {
          warn "$obj->{name}::$src->{name} -> $dst_obj->{name}::$dst->{name}: "
              . "unmatched width ($src->{width}, $dst->{width})";
        } else {
          my ($port_out, $port_in);
          if (DATA_SRC == $src->{direction}) {
            $port_out = $src;
            $port_in = $dst;
          } else {
            $port_out = $dst;
            $port_in = $src;
          }

          if (!(defined $port_out->{wire})) {
            $port_out->{wire} = "$prefix$port_out->{tag}$suffix";
            $port_out->{gen} = 1;
          }
          $port_in->{wire} = $port_out->{wire};
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

sub check {
  my ($objref) = @_;

  for my $port (@{$objref->{group}}) {
    if (!(defined $port->{wire})) {
      (DATA_DST == $port->{direction}) and die "$objref->{debug}: "
          . "$port->{name}: undriven output port";
      warn "$objref->{debug}: $port->{name}: input not used";
    }
  }
}

sub gen_port {
  my ($objref, $is_first) = @_;
  my $ret = $is_first ? "" : ",";

  $ret .= "\n  // $objref->{name} $objref->{debug}";
  for my $port (@{$objref->{group}}) {
    $ret .= "\n  " . (DATA_SRC == $port->{direction} ? "input " : "output ");
    $ret .= "[@{[$port->{width} - 1]}:0] " if ($port->{width} > 1);
    $ret .= $port->{name};
  }

  return $ret;
}

sub gen_assign {
  my ($objref) = @_;
  my $ret = "";

  for my $port (@{$objref->{group}}) {
    $ret .= "assign ";
    if (DATA_DST == $port->{direction}) {
      $ret .= "$port->{name} = $port->{wire};\n";
    } else {
      $ret .= "$port->{wire} = $port->{name};\n";
    }
  }
  $ret = "// $objref->{name} $objref->{debug}\n" . $ret if ($ret);

  return $ret;
}

1;
