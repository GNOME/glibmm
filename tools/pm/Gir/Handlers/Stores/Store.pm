package Gir::Handlers::Stores::Store;

use strict;
use warnings;

##
## public:
##
sub new ($$)
{
  my ($type, $methods) = @_;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Stores::Store');
  my $self =
  {
    'methods' => $methods
  };

  return bless ($self, $class);
}

sub has_method_for ($$)
{
  my ($self, $elem) = @_;
  my $methods = $self->{'methods'};

  return exists ($methods->{$elem});
}

sub get_method_for ($$)
{
  my ($self, $elem) = @_;

  if ($self->has_method_for ($elem))
  {
    my $methods = $self->{'methods'};

    return $methods->{$elem};
  }
  # TODO: error.
}

1;
