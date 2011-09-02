package Gir::Handlers::Ignore;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Stores::IgnoreStores;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Ignore');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::IgnoreStartStore->new (),
    Gir::Handlers::Stores::IgnoreEndStore->new ()
  );
  $self->_set_subhandlers
  ({
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
