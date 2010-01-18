package DBICx::Shortcuts;

use strict;
use warnings;

my %schemas;

sub setup {
  my ($class, $schema_class) = @_;

  eval "require $schema_class";
  die if $@;
  my $schema = $schema_class->connect;
  
  for my $source ($schema->sources) {
    my $method = $source;
    $method =~ s/.+::(.+)$/$1/; ## deal with nested sources
    $method =~ s/([a-z])([A-Z])/${1}_$2/g;
    $method = lc($method);
    
    die "Shortcut failed, '$method' already defined in '$class', "
      if $class->can($method);
    
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub {
      my $rs = shift->schema->resultset($source);
      
      return $rs unless @_;
      return $rs->find(@_) if defined($_[0]) && !ref($_[0]);
      return $rs->search(@_);
    };
  }
  
  $schemas{$class} = { class => $schema_class };
  
  return;
}

sub schema {
  my $class = shift;

  my $info = $schemas{$class};
  my $schema = $info->{schema};
  return $schema if $schema;

  my @connect_args = $class->connect_info(@_);
  return $info->{schema} = $info->{class}->connect(@connect_args);
}

sub connect_info {
  die "Class '$_[0]' needs to override 'connect_info()', ";
}

1;
