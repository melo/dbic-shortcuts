package S4;
use parent 'DBICx::Shortcuts';

sub build_shortcut_for_source {
  my ($class, $source) = @_;

  return $source->from . '_short';
}

__PACKAGE__->setup('Schema');

sub connect_info { return ("dbi:SQLite::memory:") }

1;
