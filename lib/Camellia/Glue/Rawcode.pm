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
  my ($objref) = @_;
  return "\n// $objref->{debug}\n$objref->{code}"
}

1;
