package Schema::Result::MyBooks;
use parent 'DBIx::Class::ResultSource';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('my_books');
__PACKAGE__->add_columns(
  id => {
    data_type         => 'INT',
    is_nullable       => 0,
    is_auto_increment => 1,
  },
  title => {
    data_type   => 'VARCHAR',
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key(qw(id));

1;
