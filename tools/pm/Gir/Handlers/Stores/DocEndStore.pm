package Gir::Handlers::Stores::DocEndStore;

use strict;
use warnings;

use parent qw(Gir::Handlers::Stores::Store);

use Gir::Handlers::Common;

##
## public:
##
sub new ($$)
{
  my ($type, $handlers) = @_;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Stores::DocEndStore');

  unless (exists ($handlers->{'doc'}))
  {
    $handlers->{'doc'} = \&Gir::Handlers::Common::doc_end;
  }

  my $self = $class->SUPER::new ($handlers);

  return bless ($self, $class);
}

1;
