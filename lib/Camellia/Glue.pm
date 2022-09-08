use strict;
use warnings;
package Camellia::Glue;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  load_module
  init_top write_top
  create_timing enter_timing
  create_bundle create_raw create_inst
  );

my $module = {};

my $meta;

my ($port_buf, $assign_buf);
my ($wire_buf, $elem_buf);

sub init_top {
  my ($top, $file, $info) = @_;

  # clear buf
  $port_buf = $assign_buf = $wire_buf = $elem_buf = "";
  # assign top module name
  $meta = $info // {};
  $meta->{top} = $top;
  $meta->{file} = $file;
  $meta->{debug} //= 0;
  $meta->{elem_array} = [];
}

sub write_top {
  open TARGET, ">", $meta->{file};

  # Print generating information
  my $header = "";
  $header .= " * Author: $meta->{author}\n" if (defined $meta->{author});
  $header .= " * License: $meta->{license}\n" if (defined $meta->{license});
  $header .= " *\n" if ($header);

  print TARGET <<EOL_HEAD;
/*
$header * Generated by Camellia-Glue.
 */

EOL_HEAD

  # Generate every elements into Verilog codes
  for my $elem (@{$meta->{elem_array}}) {
    if ($elem->isa("Camellia::Glue::Bundle")) {
      # Connection check
      $elem->check();

      $port_buf .= $elem->gen_port($meta->{debug}, 0 == ("" cmp $port_buf));
      $assign_buf .= $elem->gen_assign($meta->{debug});
    } elsif ($elem->isa("Camellia::Glue::Rawcode")) {
      $elem_buf .= $elem->gen_code($meta->{debug});
    } elsif ($elem->isa("Camellia::Glue::Inst")) {
      # Connection check
      $elem->check();

      $wire_buf .= $elem->gen_wire($meta->{debug});
      $elem_buf .= $elem->gen_inst($meta->{debug});
    } elsif ($elem->isa("Camellia::Glue::Timing")) {
      $port_buf .= $elem->gen_port($meta->{debug}, 0 == ("" cmp $port_buf));
    } else {
      my ($package, $filename, $line) = caller;
      die "&$filename \@$line: Unknown type signed";
    }
  }

  print TARGET "module $meta->{top} ($port_buf\n);\n";
  print TARGET "\n$wire_buf\n" if ($wire_buf);
  print TARGET "$elem_buf\n" if ($elem_buf);
  print TARGET "$assign_buf\n" if ($assign_buf);
  print TARGET "endmodule\n";

  close TARGET;
}

use File::Basename;
use Camellia::Glue::Timing;
use Camellia::Glue::Bundle;

sub create_timing {
  my ($name, $args) = @_;
  $name //= "";

  my ($package, $filename, $line) = caller;
  my $ret = Camellia::Glue::Timing->new({
    name => $name,
    clock => {name => $args->{clock}},
    reset => {name => $args->{reset}, edge => $args->{edge}},
    debug => "&" . basename($filename) . "; \@$line"
  });

  push @{$meta->{elem_array}}, $ret;
  return $ret;
}

sub enter_timing {
  my ($timing) = @_;
  $meta->{timing} = $timing;
}

# Provide an safer way to create Bundle object. It hides low-level
# implementation, avoiding users using "Camellia::Glue::Bundle" directly.
sub create_bundle {
  my ($name, $group) = @_;

  # Preprocess of input arguments
  $name //= "bd";

  my ($package, $filename, $line) = caller;
  my $ret = Camellia::Glue::Bundle->new({
    name => $name,
    group => $group,
    debug => "&" . basename($filename) . "; \@$line",
    is_top => 1
  });

  push @{$meta->{elem_array}}, $ret;
  return $ret;
}

use JSON::PP;

# load module definition from file
sub load_module {
  for my $path (@_) {
    open MODULE_FILE, "<$path" or die "Fail to open $path";
    my $content;
    while (<MODULE_FILE>) {
      $content .= $_;
    }
    close MODULE_FILE;

    my $config = decode_json $content;
    my $name = $config->{name};
    (defined $module->{$name}) and die "Multi-load of module \"$name\"";
    $module->{$name} = $config;
  }
}

use Camellia::Glue::Rawcode;
use Camellia::Glue::Inst;

sub create_raw {
  my ($code) = @_;
  my ($package, $filename, $line) = caller;

  my $ret = Camellia::Glue::Rawcode->new({
    code => $code,
    debug => "&" . basename($filename) . "; \@$line"
  });

  push @{$meta->{elem_array}}, $ret;
  return $ret;
}

sub create_inst {
  my ($mod_name, $name, $con_bundle, $param_hash) = @_;
  my ($package, $filename, $line) = caller;

  my $config = $module->{$mod_name};
  die "Unknown module \"$mod_name\"" if !(defined $config);

  # Add the counter
  $config->{count} = (defined $config->{count}) ? $config->{count} + 1 : 0;

  my $ret = Camellia::Glue::Inst->new({
    name => $name // "u$config->{count}_$mod_name",
    mod_name => $mod_name,
    config => $config,
    timing => $meta->{timing},
    param_hash => $param_hash,
    debug => "&" . basename($filename) . "; \@$line"
  });

  # `con_bundle` binds instance's bundles with existing bundles
  if (defined $con_bundle) {
    for my $bundle_name (keys %$con_bundle) {
      my $src_bd = $ret->get_bundle($bundle_name);
      my ($dst_bd, $prefix, $suffix) = $con_bundle->{$bundle_name};

      $suffix //= "$src_bd->{name}_$dst_bd->{name}_$line";

      $src_bd->connect($dst_bd, {
        prefix => $prefix,
        suffix => $suffix
      });
    }
  }

  push @{$meta->{elem_array}}, $ret;
  return $ret;
}

1;
