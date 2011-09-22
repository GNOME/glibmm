package Gir::State;

use strict;
use warnings;
use Gir::Handlers::TopLevel;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::State');
  my $self =
  {
    'handlers_stack' => [Gir::Handlers::TopLevel->new ()]
  };

  return bless ($self, $class);
}

sub push_handlers ($$)
{
  my ($self, $handlers) = @_;
  my $handlers_stack = $self->{'handlers_stack'};

  push (@{$handlers_stack}, $handlers);
}

sub pop_handlers ($)
{
  my $self = shift;
  my $handlers_stack = $self->{'handlers_stack'};

  pop (@{$handlers_stack});
}

sub get_current_handlers ($)
{
  my $self = shift;
  my $handlers_stack = $self->{'handlers_stack'};

  return ${handlers_stack}->[-1];
}

1;
