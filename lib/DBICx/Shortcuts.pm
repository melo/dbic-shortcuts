package DBICx::Shortcuts;

use strict;
use warnings;

my %schemas;

sub schema {
  my $class = shift;

  my $schema = $schemas{$class};
  return $schema if $schema;

  ($schema, my @connect_args) = $class->connect_info(@_);

  return $schemas{$class} = $schema->connect(@connect_args);
}

sub connect_info {
  die "Class '$_[0]' needs to override 'connect_info()', ";
}

1;
