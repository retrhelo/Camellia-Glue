use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  load_module
  init_top push_top write_top
  create_bundle add_bundle
  create_raw
  );

my $module = {};

my $meta;
my @elem_array = ();
my @bundle_array = ();

sub init_top {
  my ($top, $file) = @_;

  # clear arrays
  @elem_array = ();
  @bundle_array = ();
  # assign top module name
  $meta = {
    top => $top,
    file => $file
  };
}

sub push_top {
  for my $elem (@_) {
    push @elem_array, $elem;
  }
}

sub write_top {
  open TARGET, ">", $meta->{file};

  # generate top-level bundles
  print TARGET "module $meta->{top} (";
  my $is_first = 1;
  for my $elem (@bundle_array) {
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
  for my $elem (@elem_array) {
    if ($elem->isa("Camellia::Glue::Rawcode")) {
      print TARGET "$elem->{code}\n";
    }
    # TODO: module instance generation
  }

  for my $bundle (@bundle_array) {
    # All timing related signals, like clock and reset, are not involved
    ((defined $bundle->{name}) && 0 == ("timing" cmp $bundle->{name}))
        and next;

    my $str_buf = "";
    for my $port (@{$bundle->{group}}) {
      # connection check
      if (!(defined $port->{wire})) {
        ("output" cmp $port->{direction}) or die "$port->{name}: "
            . "undriven output port";
        warn "$port->{name}: not used";
      }

      if ($port->{gen}) {
        if (0 == ("output" cmp $port->{direction})) {
          $str_buf .= "assign $port->{name} = $port->{wire};\n";
        } elsif (0 == ("input" cmp $port->{direction})) {
          $str_buf .= "assign $port->{wire} = $port->{name};\n";
        } else {
          warn "$port->{name}: inout connection not generated";
        }
      }
    }

    if ($str_buf) {
      if (defined $bundle->{name}) {
        print TARGET "// $bundle->{name}\n";
      }
      print TARGET "$str_buf\n";
    }
  }

  print TARGET "endmodule\n";

  close TARGET;
}

use Camellia::Glue::Bundle;

# Provide an safer way to create Bundle object. It hides low-level implementation,
# avoiding users using "Camellia::Glue::Bundle" directly.
sub create_bundle {
  my ($name, $group) = @_;

  # sanity check
  for my $port (@$group) {
    defined $port->{name} or die "Bundle $name: undefined name";
    defined $port->{direction} or die "Bundle $name: undefined direction";
    die "Bundle $name: invalid direction \"$port->{direction}\"" if (
      ("input" cmp $port->{direction}) &&
      ("output" cmp $port->{direction}) &&
      ("inout" cmp $port->{direction})
    );
    defined $port->{width} or die "Bundle $name: undefined width";
    defined $port->{tag} or $port->{tag} = $port->{name};
  }

  return Camellia::Glue::Bundle->new({
    name => $name,
    group => $group
  });
}

sub add_bundle {
  push @bundle_array, @_;
}

use JSON::PP;

# load module definition from file
sub load_module {
  my ($path, $name) = @_;

  (defined $module->{$name}) and die "Multi-load of module \"$name\"";

  open MODULE_FILE, "<$path" or die "Fail to open $path";   # open JSON file
  my $content;
  while (<MODULE_FILE>) {
    $content .= $_;
  }
  close MODULE_FILE;  # close JSON file

  $module->{$name} = decode_json $content;
}

use Camellia::Glue::Rawcode;

sub create_raw {
  my ($code) = @_;
  return Camellia::Glue::Rawcode->new({
    code => $code
  });
}

1;
