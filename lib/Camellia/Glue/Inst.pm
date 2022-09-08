use strict;
use warnings;
package Camellia::Glue::Inst;

use Camellia::Glue::Bundle;
use Camellia::Glue::Timing;
use Camellia::Glue::Param;

use constant {
  DATA_SRC => 0x1,
  DATA_DST => 0x2
};

sub new {
  my ($class, $args) = @_;

  my $name = $args->{name};             # Instance's name
  my $mod_name = $args->{mod_name};     # Module's name
  my $config = $args->{config};         # Module's bundles (and parameters)
  my $default_timing = $args->{timing}; # Default timing domain
  my $param_hash = $args->{param_hash}; # Parameter hash table
  my $debug = $args->{debug};           # Debug information

  # Deep copy all configurations from `config`

  my $timing_array = [];
  for my $timing (@{$config->{timing}}) {
    my $tmp_timing = Camellia::Glue::Timing->new({
      name => $timing->{name},
      clock => {
        name => $timing->{clock}->{name}
      },
      reset => {
        name => $timing->{reset}->{name},
        edge => $timing->{reset}->{edge}
      },
      debug => $debug
    });

    defined $default_timing and $tmp_timing->set_timing($default_timing);

    push @$timing_array, $tmp_timing;
  }

  # Parameter
  my $param = Camellia::Glue::Param->new({
    param => $config->{param},
    init => $param_hash
  });

  my $param_array = [];
  for my $p (@{$config->{param}}) {
    if (defined $param_hash->{$p->{name}}) {
      push @$param_array, {
        name => $p->{name},
        value => $param_hash->{$p->{name}}
      };
    }
  }

  my $bundle_array = [];
  for my $bundle (@{$config->{bundle}}) {
    my $group = [];

    for my $port (@{$bundle->{group}}) {
      push @$group, {
        name => $port->{name},
        direction => $port->{direction},
        width => $param->map($port->{width}),
        tag => $port->{tag} // $port->{name}
      }
    }

    push @$bundle_array, Camellia::Glue::Bundle->new({
      group => $group,
      name => $bundle->{name},
      debug => $debug,
      is_top => 0
    });
  }

  return bless {
    name => $name,
    mod_name => $mod_name,
    timing => $timing_array,
    bundle => $bundle_array,
    param => $param_array,
    debug => $debug
  }, $class;
}

# Get bundle of the given name
sub get_bundle {
  my ($objref, $name) = @_;

  for my $bundle (@{$objref->{bundle}}) {
    if (0 == ($name cmp $bundle->{name})) {
      return $bundle;
    }
  }

  die "Bundle \"$name\" not found";
}

# Get timing of the given name
sub get_timing {
  my ($objref, $name) = @_;

  for my $timing (@{$objref->{timing}}) {
    if (0 == ($name cmp $timing->{name})) {
      return $timing;
    }
  }

  die "Timing \"$name\" not found";
}

# Be noticed! Connection check for each bundle should be performed before
# generating any wires or the instance itself.

sub check {
  my ($objref) = @_;

  for my $timing (@{$objref->{timing}}) {
    $timing->check();
  }

  for my $bundle (@{$objref->{bundle}}) {
    $bundle->check();
  }
}

sub gen_wire {
  my ($objref, $is_debug) = @_;
  my $ret = "";

  $ret .= "// $objref->{debug}\n" if ($is_debug);
  for my $bundle (@{$objref->{bundle}}) {
    for my $port (@{$bundle->{group}}) {
      if ($port->{gen}) {
        $ret .= "wire ";

        # Calculate port's bit width
        if ($port->{width} =~ m/[^a-zA-z_]/) {
          # If the port's width is composed by pure numeric, then perform
          # calculation to get its Verilog width, which results in code more
          # readable and reasonable.
          my $calc_width = eval "$port->{width}-1";
          $ret .= "[$calc_width:0] " if ($calc_width > 0);
        } else {
          # Otherwise generate directly
          $ret .= "[($port->{width})-1:0] ";
        }

        $ret .= "$port->{wire};\n";
      }
    }
  }

  return $ret;
}

sub gen_inst {
  my ($objref, $is_debug) = @_;
  my $ret = "";
  my $is_first;

  $ret .= "\n// $objref->{debug}" if ($is_debug);
  $ret .= "\n$objref->{mod_name} ";

  # Parameter initialization
  $is_first = 1;
  for my $param (@{$objref->{param}}) {
    if ($is_first) {
      $ret .= "#(\n";
      $is_first = 0;
    } else {
      $ret .= ",\n";
    }
    $ret .= "  .$param->{name}($param->{value})";
  }

  if (!$is_first) {
    $ret .= "\n) ";
    $is_first = 1;
  }

  $ret .= "$objref->{name} ";

  # Generate timing ports first
  for my $timing (@{$objref->{timing}}) {
    if ($is_first) {
      $ret .= "(\n";
      $is_first = 0;
    } else {
      $ret .= ",\n";
    }

    $ret .= "  .$timing->{clock}->{name}($timing->{clock}->{wire}),\n";
    $ret .= "  .$timing->{reset}->{name}($timing->{reset}->{wire})";
  }
  # Then normal bundles
  for my $bundle (@{$objref->{bundle}}) {
    for my $port (@{$bundle->{group}}) {
      if ($is_first) {
        $ret .= "(\n";
        $is_first = 0;
      } else {
        $ret .= ",\n";
      }

      $ret .= "  .$port->{name}(";
      $ret .= $port->{wire} // "/* not used */";
      $ret .= ")";
    }
  }
  $ret .= "\n);\n";

  return $ret;
}

1;
