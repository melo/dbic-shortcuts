#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use S1;

my $schema = S1->schema;
isa_ok($schema, 'DBIx::Class::Schema', 'Got a valid DBIx::Class::Schema');
is(ref($schema), 'Schema', '... and of the expected type');

can_ok('S1', qw( authors my_books ));
ok(!S1->can('printings'));

is(S1->schema, $schema, 'Second call to schema, same object returned');

done_testing();