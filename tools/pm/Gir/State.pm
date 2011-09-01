package GirParserState;

use strict;
use warnings;
use GirTopLevelHandlers;

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'GirParserState');
  my $self =
  {
    'tags_stack' => [],
    'current_handlers' => GirTopLevelHandlers::get_handlers ()
  };

  return bless ($self, $class);
}

sub push_tag ($$)
{
  my ($self, $name) = @_;
  my $tags_stack = $self->{'tags_stack'};

  push (@{$tags_stack}, $name);
}

sub pop_tag ($)
{
  my $self = shift;
  my $tags_stack = $self->{'tags_stack'};

  pop (@{$tags_stack});
}

1;
