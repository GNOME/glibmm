package Gir::Handlers::Stores::IgnoreEndStore;

use strict;
use warnings;

use parent qw(Gir::Handlers::Stores::Store);

use Gir::Handlers::Common;

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Stores::IgnoreEndStore');
  my $self = $class->SUPER::new ({});

  return bless ($self, $class);
}

sub has_method_for ($$)
{
  return 1;
}

sub get_method_for ($$)
{
  return \&Gir::Handlers::Common::end_ignore;
}

1;
