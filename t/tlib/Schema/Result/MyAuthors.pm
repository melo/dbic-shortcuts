package Schema::Result::MyAuthors;
use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('my_authors');

__PACKAGE__->source_info({
  shortcut => 'authors',
  skip_shortcut => 0,
});

__PACKAGE__->add_columns(qw(id oid));
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint(oid_un => [qw(oid)]);

1;
