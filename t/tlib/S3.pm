package S3;
use parent 'DBICx::Shortcuts';
use File::Temp qw( tmpnam );

__PACKAGE__->setup('Schema');

my $tmpname = tmpnam();
sub connect_info {
  my ($self, $extra) = @_;

  my $name = $tmpname;
  $name .= "-$extra" if $extra;
  
  return ("dbi:SQLite:$name") ;
}

# END {
#   unlink($tmpname) if $tmpname;
# }

1;
