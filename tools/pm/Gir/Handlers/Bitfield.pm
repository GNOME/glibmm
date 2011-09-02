package Gir::Handlers::Bitfield;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Common;
use Gir::Handlers::Ignore;
use Gir::Handlers::Stores::DocStores;
use Gir::Parser;

##
## private:
##
sub _member_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name', 'value'], ['glib:nick'], \@atts_vals, 'bitfield/member');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Bitfield');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::DocStartStore->new
    ({
      'member' => \&_member_start
    }),
    Gir::Handlers::Stores::DocEndStore->new
    ({
      'member' => \&Gir::Handlers::Common::end_ignore
    })
  );
  $self->_set_subhandlers
  ({
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
