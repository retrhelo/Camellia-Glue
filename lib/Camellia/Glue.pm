use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  load_module
  init_top write_top sign
  create_bundle create_raw
  );

my $module = {};

my $meta;

my ($port_buf, $assign_buf);
my ($wire_buf, $elem_buf);

sub init_top {
  my ($top, $file) = @_;

  # clear arrays
  $port_buf = $assign_buf = $wire_buf = $elem_buf = "";
  # assign top module name
  $meta = {
    top => $top,
    file => $file
  };
}

sub write_top {
  open TARGET, ">", $meta->{file};

  print TARGET "module $meta->{top} ($port_buf\n);\n";
  # print TARGET "$wire_buf\n$elem_buf\n$assign_buf\n";
  print TARGET "$wire_buf\n" if ($wire_buf);
  print TARGET "$elem_buf\n" if ($elem_buf);
  print TARGET "$assign_buf\n" if ($assign_buf);
  print TARGET "endmodule\n";

  close TARGET;
}

sub sign {
  for my $elem (@_) {
    if ($elem->isa("Camellia::Glue::Bundle")) {
      my $first_port = 1;
      for my $port (@{$elem->{group}}) {
        $port_buf .= "," if ($port_buf);
        if ($first_port) {
          $port_buf .= (defined $elem->{name}) ? "\n  // $elem->{name}" : "\n";
          $first_port = 0;
        }
        $port_buf .= "\n  $port->{direction} ";
        my $width = $port->{width} - 1;
        $port_buf .= "[$width:0] " if ($port->{width} > 1);
        $port_buf .= $port->{name};
      }

      ((defined $elem->{name}) && (0 == ("timing" cmp $elem->{name})))
        and next;

      $elem->check();

      for my $port (@{$elem->{group}}) {
        # if ($first_port) {
        #   $assign_buf .= (defined $elem->{name}) ? "// $elem->{name}\n" : "\n";
        #   $first_port = 0;
        # }
        # $assign_buf .= "assign ";
        # if (0 == ("input" cmp $port->{direction})) {
        #   $assign_buf .= "$port->{wire} = $port->{name};\n";
        # } elsif (0 == ("output" cmp $port->{direction})) {
        #   $assign_buf .= "$port->{name} = $port->{wire};\n";
        # } else {
        #   warn "Direction inout not supported";
        # }
      }
    } elsif ($elem->isa("Camellia::Glue::Rawcode")) {
      $elem_buf .= "\n$elem->{code}";
    } elsif ($elem->isa("Camellia::Glue::Inst")) {
      # TODO: implement this
      die "Not implemented";
    }
  }
}

use Camellia::Glue::Bundle;

# Provide an safer way to create Bundle object. It hides low-level
# implementation, avoiding users using "Camellia::Glue::Bundle" directly.
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
