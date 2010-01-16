#!perl

package Y;
use parent 'DBICx::Shortcuts';


package X;
use parent 'DBICx::Shortcuts';

sub connect_info { return @_ }
sub connect      { return $_[1] }


package main;

use strict;
use warnings;
use Test::More;
use Test::Exception;

is(X->schema(42), 42, 'Got The Answer schema');
is(X->schema(21), 42, '... and The Answer is persistent');

### Make sure
throws_ok sub { Y->connect_info },
  qr/Class 'Y' needs to override 'connect_info[(][)]'/,
  'The connect_info() method dies by default';

done_testing();
