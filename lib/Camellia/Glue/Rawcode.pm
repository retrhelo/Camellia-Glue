use strict;
use warnings;
package Camellia::Glue::Rawcode;

sub new {
  my ($class, $args) = @_;
  return bless {
    code => $args->{code},
    debug => $args->{debug}
  }, $class;
}

sub gen_code {
  my ($objref, $is_debug) = @_;
  my $ret = "";

  $ret .= "\n// $objref->{debug}" if ($is_debug);
  $ret .= "\n$objref->{code}";
  return $ret;
}

1;
