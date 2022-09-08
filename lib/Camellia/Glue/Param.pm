# A bunch of Verilog parameters, that would be useful in parameterized design.

use strict;
use warnings;
package Camellia::Glue::Param;

sub __substitute {
  my ($str, $param_hash) = @_;

  use constant {
    STATE_ERR => -1,
    STATE_IDLE => 0,
    STATE_IDENT => 1
  };

  my $ret = "";
  my $ident = "";
  my $state = STATE_IDLE;
  for my $ch (split '', $str) {
    if (STATE_IDLE == $state) {
      if ('{' eq $ch) {
        $state = STATE_IDENT;
      } else {
        $ret .= $ch;
      }
    } elsif (STATE_IDENT == $state) {
      if ('}' eq $ch) {
        $state = STATE_IDLE;
        # Identity match over, try substituting it
        defined $param_hash->{$ident} or die "Unknown parameter \"$ident\"";
        $ret .= "($param_hash->{$ident})";
        $ident = "";
      } else {
        $ident .= $ch;
      }
    }
  }

  STATE_IDLE == $state or die "Missing } with unfinished ident \"$ident\"";
  return $ret;
}

# Resolve given list of parameters, to make sure that every parameter is able
# to be mapped in one step.
sub new {
  my ($class, $args) = @_;
  my $param_array = $args->{param};
  my $init = $args->{init};

  my $mapped = {};
  for my $param (@$param_array) {
    if (defined $init->{$param->{name}}) {
      # It's in initialization list
      $mapped->{$param->{name}} = $init->{$param->{name}};
    } else {
      $mapped->{$param->{name}} = __substitute $param->{value}, $mapped;
    }
  }

  return bless $mapped, $class;
}

sub map {
  my ($objref, $str) = @_;
  return __substitute $str, $objref;
}

1;
