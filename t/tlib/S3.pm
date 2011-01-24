package S3;
use parent 'DBICx::Shortcuts';

__PACKAGE__->setup('Schema');

sub connect_info { return ("dbi:SQLite::memory:") }

1;
