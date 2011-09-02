package Gir::Handlers::Record;

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
sub _constructor_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'record/constructor');
}

sub _field_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['bits', 'private', 'readable', 'writable'], \@atts_vals, 'record/field');
}

sub _function_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'moved-to', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'record/function');
}

sub _method_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'record/method');
}

sub _union_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], ['c:symbol-prefix', 'glib:get-type', 'glib:type-name'], \@atts_vals, 'record/union');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Record');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::DocStartStore->new
    ({
      'constructor' => \&_constructor_start,
      'field' => \&_field_start,
      'function' => \&_function_start,
      'method' => \&_method_start,
      'union' => \&_union_start
    }),
    Gir::Handlers::Stores::DocEndStore->new
    ({
      'constructor' => \&Gir::Handlers::Common::end_ignore,
      'field' => \&Gir::Handlers::Common::end_ignore,
      'function' => \&Gir::Handlers::Common::end_ignore,
      'method' => \&Gir::Handlers::Common::end_ignore,
      'union' => \&Gir::Handlers::Common::end_ignore
    })
  );
  $self->_set_subhandlers
  ({
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
