use strict;
use warnings;
package Camellia::Glue::Inst;

use Camellia::Glue::Bundle;

use constant {
  DATA_SRC => 0x1,
  DATA_DST => 0x2
};

sub new {
  my ($class, $args) = @_;

  my $name = $args->{name};           # Instance's name
  my $mod_name = $args->{mod_name};   # Module's name
  my $config = $args->{config};       # Module's bundles (and parameters)
  my $debug = $args->{debug};         # Debug information

  # TODO: support default timing domain

  # TODO: support parameters

  # Deep copy all configurations from `config`
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
    bundle => $bundle_array,
    debug => $debug
  }, $class;
}

# Get bundle of the given name
sub get {
  my ($objref, $name) = @_;

  for my $bundle (@{$objref->{bundle}}) {
    if (0 == ($name cmp $bundle->{name})) {
      return $bundle;
    }
  }

  die "Bundle \"$name\" not found";
}

# Be noticed! Connection check for each bundle should be performed before
# generating any wires or the instance itself.

sub check {
  my ($objref) = @_;

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
