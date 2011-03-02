package DBICx::Shortcuts;

use strict;
use warnings;
use Sub::Name;
use Package::Stash;
use Carp qw( croak confess );

my %schemas;

sub new {
  my ($class, @connect_info) = @_;

  return bless {connect_info => \@connect_info,}, $class;
}

sub setup {
  my ($class, $schema_class, @methods) = @_;

  eval "require $schema_class";
  die if $@;
  local $ENV{DBIC_NO_VERSION_CHECK} = 1;
  my $schema = $schema_class->connect;

  my $stash = Package::Stash->new($class);

  my %sources;
SOURCE: for my $source_name ($schema->sources) {
    my $source = $schema->source($source_name);
    my $info   = $source->source_info;
    next SOURCE if exists $info->{skip_shortcut} && $info->{skip_shortcut};

    my $method;
    if (exists $info->{shortcut}) {
      $method = $info->{shortcut};
    }
    else {
      $method = $class->build_shortcut_for_source($source);
    }
    next SOURCE unless defined $method;

    croak("Shortcut failed, '$method' already defined in '$class', ")
      if $class->can($method);

    my $full_name = join('::', $class, $method);
    $stash->add_symbol("\&$method", subname $full_name, sub {
      my $self = shift;

      ## Old style singleton support
      $self = $schemas{$self}{instance} unless ref($self);
      my $schema = $self->schema;

      ## No arguments, return empty result set
      ## Returning a cached RS directly to the outside could be
      ## used with side-effects
      return $schema->resultset($source_name) unless @_;

      ## Cache resultset objects
      my $rs = $self->{rs}{$method};
      unless ($rs) {
        $rs = $self->{rs}{$method} = $schema->resultset($source_name);
      }

      ## first argument not a reference, assume find by PK
      return $rs->find(@_) if defined($_[0]) && !ref($_[0]);

      ## first argument is a scalar ref, assume unique constraint name,
      ## use find
      if (defined($_[0]) && ref($_[0]) eq 'SCALAR') {
        my $key = shift;
        my $args = ref($_[-1]) eq 'HASH' ? pop : {};
        $args->{key} = $$key;

        return $rs->find(@_, $args);
      }

      ## otherwise, its a search
      return $rs->search(@_);
    });

    $sources{$method}      = $source_name;
    $sources{$source_name} = $source_name;
  }

  ## Enable set of schema shortcuts
  for my $meth (@methods) {
    no strict 'refs';
    *{__PACKAGE__ . "::$meth"} = sub { return shift->schema->$meth(@_) };
  }

  ## Keep our singleton support alive
  $schemas{$class} = {
    schema_class => $schema_class,
    instance     => $class->new,
    sources      => \%sources,
  };

  return;
}

sub build_shortcut_for_source {
  my ($class, $source) = @_;

  my $method = $source->source_name;
  $method =~ s/.+::(.+)$/$1/;              ## deal with nested sources
  $method =~ s/([a-z])([A-Z])/${1}_$2/g;
  $method = lc($method);

  return $method;
}

sub schema {
  my ($self) = @_;

  ## Make sure it is a proper Shortcut class
  my $class = ref($self) || $self;
  croak("Class '$self' did not call 'setup()'")
    unless exists $schemas{$class};

  ## Our schema information
  my $info = $schemas{$class};

  ## Old style singleton support
  if (!ref($self)) {
    $self = $info->{instance};
  }

  ## Return cached schema
  return $self->{schema} if $self->{schema};

  my $ci = $self->{connect_info};
  return $self->{schema} =
    $info->{schema_class}->connect($self->connect_info(@$ci));
}

sub source {
  my ($self, $source) = @_;
  my $class = ref($self) || $self;

  confess("Source '$source' unknown, ")
    unless exists $schemas{$class}{sources}{$source};

  $self->schema->source($schemas{$class}{sources}{$source});
}

sub connect_info {
  croak("Class '" . ref($_[0]) . "' needs to override 'connect_info()', ");
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
  
  ## Alternate version, this one import txn_do from DBIx::Class::Schema
  ## __PACKAGE__->setup('Class::Of::Your::Schema', 'txn_do');
  
  sub connect_info {
    ## return DBIx::Class::Schema::connect() arguments
    return ('dbi:SQLite:test.db', undef, undef, {AutoCommit => 1});
  }
  
  1;


  # And on your code, assuming you had a Books source
  
  # Without arguments, returns ResultSet
  $book = S->books->create({ ... });
  
  # With first argument as a defined non-ref, passes @_ to find()
  $book = S->books(42);  ## 42 is the PK of the book
  
  # With first argument as a ScalarRef, uses a unique constraint
  $book = S->book(\'isbn_key', '9123123432123');
  
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

This method can be used in four ways.

If called without parameters, the shortcut method will return a
ResultSet for the source. Usefull to call create().

If called with parameters where the first is not a reference, it calls
find(). Usefull to fetch a row based on the primary key.

If called with parameters where the first is a scalarRef, we assume it
to be the name of the unique constraint to use, and the rest of the
arguments to be the required values for that constraint.

In all other cases, it calls search() and returns the resultset.


=head2 Connection information

But to do this, your shortcuts class needs to connect your schema to the
database. To do that, you must override the L<"connect_info()"> method
and have it return all the required connect() parameters.


=head1 METHODS

=head2 setup()

    package MyShortcutsClass;
    __PACKAGE__->setup('MySchemaClass');
    ## or
    __PACKAGE__->setup('MySchemaClass', 'txn_do', 'storage', $other_methods);

The L</setup()> accepts your schema class as a parameter, loads it, and
creates a shortcut method for each source found inside.

Optionally you can follow with a list of methods that you want to create
as shortcuts to the same named method in
L<DBIx::Class::Schema|DBIx::Class::Schema>.

You can control some aspects of the shortcut creation using the
<source_info()|DBIx::Class::ResultSource/source_info> ResultSource metadata hashref.
The following keys are supported:

=over 4

=item shortcut

Defines the name of the shortcut to create for this source.

If the shortcut is declared as C<undef>, no shortcut wil be created for this source.

=item skip_shortcut

If true, disables the creation of a shortcut key for this source.

This is available as a more explicit alternative to setting the C<shortcut> key to C<undef>.

=back


=head2 schema()

Returns a connected and ready to use schema object. Uses the
L<"connect_info()"> information to connect.


=head2 connect_info()

This method is not to be called directly, but to be defined by your own shortcut class.

It must return the parameters that L<DBICx::Shortcuts> must use in the call to L<connect()|DBIx::Class::Schema/connect> to create the schema object.


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
