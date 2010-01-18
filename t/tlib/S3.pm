package S3;
use parent 'DBICx::Shortcuts';
use File::Temp qw( tmpnam );

__PACKAGE__->setup('Schema');

my $tmpname = tmpnam();
sub connect_info {
  return ("dbi:SQLite:$tmpname");
}

END {
  unlink($tmpname) if $tmpname;
}

1;
