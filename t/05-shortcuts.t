#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
BEGIN { $ENV{DBIC_NO_VERSION_CHECK} = 42 }
use S1;

eval "require SQL::Translator";
plan skip_all => 'This test requires SQL::Translator' if $@;

my $schema = S1->schema;
isa_ok($schema, 'DBIx::Class::Schema', 'Got a valid DBIx::Class::Schema');
is(ref($schema), 'Schema', '... and of the expected type');

can_ok('S1', qw( authors my_books ));
ok(!S1->can('printings'));

is(S1->schema, $schema, 'Second call to schema, same object returned');

is($ENV{DBIC_NO_VERSION_CHECK},
  42, 'ENV DBIC_NO_VERSION_CHECK is saved in the call to setup');

done_testing();
