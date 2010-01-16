#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use S;

my $schema = S->schema;
isa_ok($schema, 'DBIx::Class::Schema', 'Got a valid DBIx::Class::Schema');
is(ref($schema), 'Schema', '... and of the expected type');

done_testing();