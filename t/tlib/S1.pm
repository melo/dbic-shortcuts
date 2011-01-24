package S1;
use parent 'DBICx::Shortcuts';

__PACKAGE__->setup('Schema', 'txn_do', 'storage');

sub connect_info { }

1;
