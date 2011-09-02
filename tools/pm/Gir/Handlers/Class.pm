package Gir::Handlers::Class;

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
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'class/constructor');
}

sub _field_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['bits', 'private', 'readable', 'writable'], \@atts_vals, 'class/field');
}

sub _function_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'moved-to', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'class/function');
}

sub _glib_signal_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['action', 'deprecated', 'deprecated-version', 'detailed', 'introspectable', 'no-hooks', 'no-recurse', 'version', 'when'], \@atts_vals, 'class/glib:signal');
}

sub _implements_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], [], \@atts_vals, 'class/implements');
}

sub _method_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'class/method');
}

sub _property_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name', 'transfer-ownership'], ['construct-only', 'construct', 'deprecated', 'deprecated-version', 'introspectable', 'readable', 'version', 'writable'], \@atts_vals, 'class/property');
}

sub _virtual_method_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['deprecated', 'deprecated-version', 'introspectable', 'invoker', 'throws', 'version'], \@atts_vals, 'class/virtual-method');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Class');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::DocStartStore->new
    ({
      'constructor' => \&_constructor_start,
      'field' => \& _field_start,
      'function' => \&_function_start,
      'glib:signal' => \&_glib_signal_start,
      'implements' => \&_implements_start,
      'method' => \&_method_start,
      'property' => \& _property_start,
      'virtual-method' => \&_virtual_method_start
    }),
    Gir::Handlers::Stores::DocEndStore->new
    ({
      'constructor' => \&Gir::Handlers::Common::end_ignore,
      'field' => \&Gir::Handlers::Common::end_ignore,
      'function' => \&Gir::Handlers::Common::end_ignore,
      'glib:signal' => \&Gir::Handlers::Common::end_ignore,
      'implements' => \&Gir::Handlers::Common::end_ignore,
      'method' => \&Gir::Handlers::Common::end_ignore,
      'property' => \&Gir::Handlers::Common::end_ignore,
      'virtual-method' => \&Gir::Handlers::Common::end_ignore
    })
  );
  $self->_set_subhandlers
  ({
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
