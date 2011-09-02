package Gir::Handlers::Constant;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Common;
use Gir::Handlers::Ignore;
use Gir::Handlers::Stores::Store;
use Gir::Parser;

##
## private:
##
sub _type_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], [], \@atts_vals, 'constant/type');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Constant');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::Store->new
    ({
      'type' => \&_type_start
    }),
    Gir::Handlers::Stores::Store->new
    ({
      'type' => \&Gir::Handlers::Common::end_ignore
    })
  );
  $self->_set_subhandlers
  ({
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
