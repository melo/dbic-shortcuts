package DBICx::Shortcuts;

use strict;
use warnings;
use Carp qw( croak );

my %schemas;

sub setup {
  my ($class, $schema_class) = @_;

  eval "require $schema_class";
  die if $@;
  my $schema = $schema_class->connect;
  
  SOURCE: for my $source ($schema->sources) {
    my $info = $schema->source($source)->source_info;
    next SOURCE if exists $info->{skip_shortcut} && $info->{skip_shortcut};

    my $method = $info->{shortcut};
    if (!$method) {
      $method = $source;
      $method =~ s/.+::(.+)$/$1/; ## deal with nested sources
      $method =~ s/([a-z])([A-Z])/${1}_$2/g;
      $method = lc($method);
    }
    
    croak("Shortcut failed, '$method' already defined in '$class', ")
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
  my ($class) = @_;
  
  croak("Class '$class' did not call 'setup()'")
    unless exists $schemas{$class};

  my $info = $schemas{$class};
  my $schema = $info->{schema};
  return $schema if $schema;

  my @connect_args = $class->connect_info();
  return $info->{schema} = $info->{class}->connect(@connect_args);
}

sub connect_info {
  croak("Class '$_[0]' needs to override 'connect_info()', ");
}

1;

__END__

=encoding utf8

=head1 NAME

DBICx::Shortcuts - Setup a class with shortcut methods to the sources of a DBIx::Class-based schema


=head1 SYNOPSIS

  package S;
  use parent 'DBICx::Shortcuts';
  
  __PACKAGE__->setup('Class::Of::Your::Schema');
  
  sub connect_info {
    ## return DBIx::Class::Schema::connect() arguments
    return ('dbi:SQLite:test.db', undef, undef, {AutoCommit => 1});
  }
  
  1;


  # And on your code, assuming you had a Books source
  
  # Without arguments, returns ResultSet
  $book = S->books->create({ ... });
  
  # With first argument as a defined non-ref, passes @_ to find()
  $book = S->books(42);  ## 42 is the ID of the book
  
  # All other cases, calls search()
  $rs = S->books({title => { like => '%Perl%' }});


=head1 DESCRIPTION

If you use L<DBIx::Class> a lot, you soon get tired of writting:

    $schema->resultset('Books')->create({...});

All that L<resultset($source_name')|DBIx::Class::Schema/resultset>
bussiness is a lot of code to write.

The L<DBICx::Shortcuts> class provides you with a shorter alternative.
First you must create a new class, C<S> for example, and connect it to
the real Schema class using the L<"setup()"> method.

For each source defined in your schema class, a method will be created
in the shortcut class.

This method can be used in three ways.

If called without parameters, the shortcut method will return a
ResultSet for the source. Usefull to call create().

If called with parameters where the first is not a reference, it calls
find(). Usefull to fetch a row based on the primary key.

In all other cases, it calls search() and returns the resultset.


=head2 Connection information

But to do this, your shortcuts class needs to connect your schema to the
database. To do that, you must override the L<"connect_info()"> method
and have it return all the required connect() parameters.


=head1 METHODS

=head2 setup()

    package MyShortcutsClass;
    __PACKAGE__->setup('MySchemaClass');

The L</setup()> accepts your schema class as a parameter, loads it, and
creates a shortcut method for each source found inside.

You can control some aspects of the shortcut creation using the
<source_info()|DBIx::Class::ResultSource/source_info> ResultSource metadata hashref.
The following keys are supported:

=over 4

=item shortcut

Defines the name of the shortcut to create for this source.

=item skip_shortcut

If true, disables the creation of a shortcut key for this source.

=back


=head2 schema()

Returns a connected and ready to use schema object. Uses the
L<"connect_info()"> information to connect.


=head2 connect_info()

This method is not to be called directly, but to be defined by your own shortcut class.

It must return the parameters that L<DBIx::Shortcuts> must use in the call to L<connect()|DBIx::Class::Schema/connect> to create the schema object.


=head1 DIAGNOSTICS

The following exceptions might be thrown:


=over 4

=item Shortcut failed, '$method' already defined in '$class'

If two sources use the same shortcut, or if you define an adition method
on your shortcuts class that conflits with a source method, you will get
this exception in the call to L<"setup()">.


=item Class '$class' did not call 'setup()'

If you forgot to call L<"setup()"> and start calling L<"schema()">, this is
the result.


=item Class '$shortcuts_class' needs to override 'connect_info()'

You forgot to override the L<"connect_info()"> method.

=back


Also, the L<"setup()"> method calls L<perlfunc/require> to load your schema class,
and propagates any exception that you might get from that call.


=head1 SEE ALSO

L<DBIx::Class>


=head1 AUTHOR

Pedro Melo, C<< <melo@simplicidade.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2010 Pedro Melo

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
