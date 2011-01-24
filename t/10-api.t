#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Exception;
use S3;

for my $package ('DBD::SQLite', 'SQL::Translator') {
  eval "require $package";
  plan skip_all => "API tests require $package, " if $@;
}

for my $db ('S3', S3->new('a'), S3->new('b')) {
  lives_ok sub { $db->schema->deploy }, 'Schema deployed sucessfuly';

  ## Basic API
  my $rs = $db->my_books;
  isa_ok($rs, 'DBIx::Class::ResultSet', 'Got the expected resultset');

  my $not_found = $db->my_books(-1);
  ok(!defined $not_found, 'Find for non-existing ID, undef');

  $rs = $db->my_books({id => 2});
  isa_ok($rs, 'DBIx::Class::ResultSet', 'Got a resultset');


  ## Now with real data
  my $love = $db->my_books->create({title => 'Love your Catalyst'});
  ok($love, 'Got something');
  isa_ok($love, 'Schema::Result::MyBooks', '... and it seems a MyBook');

  my $hate = $db->my_books->create({title => 'Hate ponies'});
  ok($hate, 'Second book ok');
  isa_ok($hate, 'Schema::Result::MyBooks', '... proper class at least');

  is($hate->title, $db->my_books($hate->id)->title, 'Find shortcut works');
  is(
    $hate->title,
    $db->my_books({id => $hate->id})->first->title,
    'Search shortcut works'
  );

  is(
    $love->title,
    $db->my_books(undef, { sort => 'title DESC' })->first->title,
    'Search without contitions shortcut works'
  );

  ## Use unique keys with find
  my $a1 = $db->authors->create({ id => 1, oid => 10});

  is($a1->id, $db->authors(1)->id, 'Find by primary key works');
  is($a1->id, $db->authors(\'oid_un', 10)->id, 'Find by unique key works');
  is($db->authors(\'oid_un', 10, {})->id,
    $a1->id, 'Find by unique key works (extra args)');
  is($db->authors(\'oid_un', 10, {where => {id => 2}}),
    undef, 'Find by unique key works (extra args)');
}

done_testing();
