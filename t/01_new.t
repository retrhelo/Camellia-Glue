use strict;
use warnings;

use Test::Simple tests => 2;

# Create a Glue object
use Camellia::Glue;
my $handle = Camellia::Glue->new({name => "hello"});
ok(0 == ($handle->{name} cmp "hello"));

# Create a Rawcode object
use Camellia::Glue::Rawcode;
my $code = <<EOL;
  always @(posedge clk) begin
    \$display("posedge!\n");
  end
EOL
my $rawcode = Camellia::Glue::Rawcode->new({code => $code});
ok(0 == ($code cmp $rawcode->{code}))
