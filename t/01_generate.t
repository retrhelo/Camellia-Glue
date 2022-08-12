# This test demonstrate a simple use case of Camellia::Glue.

use strict;
use warnings;

use Test::Simple tests => 2;
use File::Compare;

use Camellia::Glue;

# First initialize a top-level module.
init_top {top => "test", file => "test.v"};

# TODO: create and connect instances

# Finally, write it to a given file.
write_top;

ok(0 == (compare "test.v", "example/test.v"));

# Remove generated file
ok(unlink "test.v");
