package Gir::Handlers::TopLevel;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Common;
use Gir::Handlers::Repository;
use Gir::Handlers::Stores::Store;

sub _repository_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['version', 'xmlns', 'xmlns:c'], ['c:identifier-prefixes', 'c:symbol-prefixes', 'xmlns:glib'], \@atts_vals, 'repository');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::TopLevel');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::Store->new ({ 'repository' => \&_repository_start }),
    Gir::Handlers::Stores::Store->new ({ 'repository' => \&Gir::Handlers::Common::end_ignore })
  );
  $self->_set_subhandlers
  ({
    'repository' => "Gir::Handlers::Repository",
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
