package Gir::Handlers::TopLevel;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Common;
use Gir::Handlers::Repository;
use Gir::Handlers::Store;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::TopLevel');
  my $self = $class->SUPER->new ();

  $self->_set_handlers
  (
    Gir::Handlers::Store->new ({ 'repository' => \&Gir::Handlers::Common::start_ignore }),
    Gir::Handlers::Store->new ({ 'repository' => \&Gir::Handlers::Common::end_ignore })
  );

  return bless ($self, $class);
}

sub get_subhandlers_for ($$)
{
  my ($self, $elem) = @_;

  return Gir::Handlers::Repository->new ();
}

1;
