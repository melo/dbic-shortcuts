#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use S4;

for my $package ('DBD::SQLite', 'SQL::Translator') {
  eval "require $package";
  plan skip_all => "API tests require $package, " if $@;
}
ok(S4->can($_), "Shortcut $_ found")
  for qw( authors my_books_short );

done_testing();
