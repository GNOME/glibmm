package Gir::Handlers::Ignore;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::IgnoreEndStore;
use Gir::Handlers::IgnoreStartStore;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Ignore');
  my $self = $class->SUPER->new ();

  $self->_set_handlers
  (
    Gir::Handlers::IgnoreStartStore->new (),
    Gir::Handlers::IgnoreEndStore->new ()
  );

  return bless ($self, $class);
}

sub get_subhandlers_for ($$)
{
  return Gir::Handlers::Ignore->new ();
}

1;
