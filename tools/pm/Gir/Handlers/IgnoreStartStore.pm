package Gir::Handlers::IgnoreStartStore;

use strict;
use warnings;

use parent qw(Gir::Handlers::Store);

use Gir::Handlers::Common;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::IgnoreStartStore');
  my $self = $class->SUPER->new ({});

  return bless ($self, $class);
}

sub has_method_for ($$)
{
  return 1;
}

sub get_method_for ($$)
{
  return \&Gir::Handlers::Common::start_ignore;
}

1;
