use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  load_module
  init_top push_top write_top
  );

use JSON::PP;

my $module = {};

# load module definition from file
sub load_module {
  my ($path, $name) = @_;

  open MODULE_FILE, "<$path" or die "Fail to open $path";   # open JSON file
  my $content;
  while (<MODULE_FILE>) {
    $content .= $_;
  }
  close MODULE_FILE;  # close JSON file

  $module->{$name} = decode_json $content;
}

my $meta;
my @elem_array = ();
my @port_array = ();

sub init_top {
  my ($args) = @_;

  # clear arrays
  @elem_array = ();
  @port_array = ();
  # assign top module name
  $meta = {
    top => $args->{top},
    file => $args->{file}
  };
}

sub push_top {
  my ($elem) = @_;
  push @elem_array, $elem;
}

sub write_top {
  open TARGET, ">", $meta->{file};
  print TARGET "module $meta->{top} (\n";
  # TODO: print top-level ports
  print TARGET ");\n\n";
  # TODO: init all wires
  # TODO: init all module instances
  print TARGET "endmodule\n";

  close TARGET;
}

1;
