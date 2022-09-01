use strict;
use warnings;
package Camellia::Glue::Inst;

use Camellia::Glue::Bundle;
use Camellia::Glue::Timing;

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
  my $debug = $args->{debug};           # Debug information

  # TODO: support parameters

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

  my $bundle_array = [];
  for my $bundle (@{$config->{bundle}}) {
    defined $bundle->{name} or die "$debug: Bundle name not defined";

    my $group = [];

    for my $port (@{$bundle->{group}}) {
      push @$group, {
        name => $port->{name},
        direction => $port->{direction},
        width => $port->{width},
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
  my ($objref) = @_;

  my $ret = "// $objref->{debug}\n";
  for my $bundle (@{$objref->{bundle}}) {
    for my $port (@{$bundle->{group}}) {
      if ($port->{gen}) {
        $ret .= "wire ";
        $ret .= "[@{[$port->{width}-1]}:0] " if ($port->{width} > 1);
        $ret .= "$port->{wire};\n";
      }
    }
  }

  return $ret;
}

sub gen_inst {
  my ($objref) = @_;
  my $ret = "";
  my $is_first = 1;

  # TODO: parameter support
  $ret .= "\n// $objref->{debug}\n";
  $ret .= "$objref->{mod_name} $objref->{name} (";
  # Generate timing ports first
  for my $timing (@{$objref->{timing}}) {
    if ($is_first) {
      $ret .= "\n";
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
        $ret .= "\n";
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
