use strict;
use warnings;
package Camellia::Glue::Rawcode;

sub new {
  my ($class, $args) = @_;
  return bless {
    code => $args->{code}
  }, $class;
}

1;
