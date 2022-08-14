use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  load_module
  init_top push_top write_top
  create_port add_port
  );

my $module = {};

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
  for my $elem (@_) {
    push @elem_array, $elem;
  }
}

sub write_top {
  open TARGET, ">", $meta->{file};

  # generate top-level ports
  print TARGET "module $meta->{top} (";
  my $is_first = 1;
  for my $elem (@port_array) {
    if (defined $elem->{name}) {
      if (!$is_first) {
        print TARGET ",";
        $is_first = 1;
      }
      print TARGET "\n  // $elem->{name}";
    }
    for my $port (@{$elem->{group}}) {
      if ($is_first) {
        print TARGET "\n  ";
        $is_first = 0;
      } else {
        print TARGET ",\n  ";
      }
      # direction
      print TARGET "$port->{direction} ";
      # width
      if ($port->{width} > 1) {
        my $width = $port->{width} - 1;
        print TARGET "[${width}:0] ";
      }
      # port name
      print TARGET "$port->{name}";
    }
  }
  print TARGET "\n);\n\n";

  # TODO: init all wires

  # TODO: init all module instances

  # TODO: generate assign statements for top-level ports

  print TARGET "endmodule\n";

  close TARGET;
}

use Camellia::Glue::Port;

# Provide an safer way to create Port object. It hides low-level implementation,
# avoiding users using "Camellia::Glue::Port" directly.
sub create_port {
  my ($name, $group) = @_;

  # sanity check
  for my $port (@$group) {
    defined $port->{name} or die "Port $name: undefined name";
    defined $port->{direction} or die "Port $name: undefined direction";
    die "Port $name: invalid direction \"$port->{direction}\"" if (
      ("input" cmp $port->{direction}) &&
      ("output" cmp $port->{direction}) &&
      ("inout" cmp $port->{direction})
    );
    defined $port->{width} or die "Port $name: undefined width";
    defined $port->{tag} or $port->{tag} = $port->{name};
  }

  return Camellia::Glue::Port->new({
    name => $name,
    group => $group
  });
}

sub add_port {
  for my $port (@_) {
    push @port_array, $port;
  }
}

use JSON::PP;

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

1;
