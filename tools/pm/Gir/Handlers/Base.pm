package Gir::Handlers::Base;

use strict;
use warnings;

##
## private:
##
sub _new_impl_ ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Base');
  my $self =
  {
    'start_handlers' => {},
    'end_handlers' => {}
  };

  return bless ($self, $class);
}

##
## protected:
##
sub _set_handlers ($$$)
{
  my ($self, $start_handlers, $end_handlers) = @_;

  $self->{'start_handlers'} = $start_handlers;
  $self->{'end_handlers'} = $end_handlers;
}

##
## public:
##
sub new ($)
{
  return _new_impl_ (shift);
}

sub get_start_handlers ($)
{
  my $self = shift;

  return $self->{'start_handlers'};
}

sub get_end_handlers ($)
{
  my $self = shift;

  return $self->{'end_handlers'};
}

sub get_subhandlers_for ($$)
{
  #TODO: error - not implemented.
}

1;
