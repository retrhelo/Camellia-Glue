use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

sub new {
  my ($class, $args) = @_;
  return bless {
    name => $args->{name},    # name of top module
    stack => [],              # contains instances and rawcode
    wire => []                # connecting wires between instances
  }, $class;
}

1;
