package Schema::Result::Mecenas;
use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('mecenas');

__PACKAGE__->source_info({
  shortcut => undef,
});

__PACKAGE__->add_columns(qw(id));
__PACKAGE__->set_primary_key(qw(id));

1;
