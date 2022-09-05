# Timing signals used in sequential logic

use strict;
use warnings;
package Camellia::Glue::Timing;

use constant {
  NEG_EDGE => 0x0,
  POS_EDGE => 0x1
};

sub new {
  my ($class, $args) = @_;

  # Verification
  defined $args->{name} or die "$args->{debug}: timing without name";
  defined $args->{clock}->{name} or die "$args->{debug}: clock without name";
  defined $args->{reset}->{name} or die "$args->{debug}: reset without name";
  die "$args->{debug}: unknown reset edge" if (
    !(defined $args->{reset}->{edge}) ||
    (
      ("pos" cmp $args->{reset}->{edge}) &&
      ("neg" cmp $args->{reset}->{edge})
    )
  );

  # Transform
  $args->{reset}->{edge} = (0 == ("pos" cmp $args->{reset}->{edge})) ?
      POS_EDGE : NEG_EDGE;

  # By default, let's assume that each pair of timing signals contains only
  # one 'clock' and one 'reset' signal.
  return bless {
    name => $args->{name},
    clock => $args->{clock},
    reset => $args->{reset},
    debug => $args->{debug}
  }, $class;
}

# Like what we have in Bundle.pm, both "clock" and "reset" consist of the
# following fields.
# name: the name of the timing port
# wire: the wire connected to this port
# edge (only for reset): be 1 when reacts on positive edge, 0 when negative

sub set_timing {
  my ($objref, $timing) = @_;

  # Connect clock
  $objref->{clock}->{wire} = $timing->{clock}->{name};
  $objref->{reset}->{wire} =
      ($objref->{reset}->{edge} == $timing->{reset}->{edge}) ?
      "$timing->{reset}->{name}" :
      "~($timing->{reset}->{name})";

  # Also marked $timing as connected, if necessary
  $timing->{clock}->{wire} //= $objref->{clock}->{name};
  $timing->{reset}->{wire} //= $objref->{reset}->{name};
}

sub except {
  my ($objref, $name, $wire) = @_;

  die "Unknown timing field \"$name\"" if (
    ("clock" cmp $name) &&
    ("reset" cmp $name)
  );
  $objref->{$name}->{wire} = $wire;
}

sub check {
  my ($objref) = @_;

  defined $objref->{clock}->{wire} or die "$objref->{debug}: "
      . "undriven clock";
  defined $objref->{reset}->{wire} or die "$objref->{debug}: "
      . "undriven reset";
}

sub gen_port {
  my ($objref, $is_debug, $is_first) = @_;
  my $ret = $is_first ? "" : ",";

  $ret .= "\n  // $objref->{name} $objref->{debug}" if ($is_debug);
  $ret .= "\n  input $objref->{clock}->{name},";
  $ret .= "\n  input $objref->{reset}->{name}";

  return $ret;
}

1;
