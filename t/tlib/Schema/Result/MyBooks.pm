package Schema::Result::MyBooks;
use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('my_books');
__PACKAGE__->add_columns(qw(id));
__PACKAGE__->set_primary_key(qw(id));

1;
