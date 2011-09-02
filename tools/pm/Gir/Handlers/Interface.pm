package Gir::Handlers::Interface;

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
sub _glib_signal_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['action', 'deprecated', 'deprecated-version', 'detailed', 'introspectable', 'no-hooks', 'no-recurse', 'version', 'when'], \@atts_vals, 'interface/glib:signal');
}

sub _function_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'moved-to', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'interface/function');
}

sub _method_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'interface/method');
}

sub _prerequisite_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], [], \@atts_vals, 'interface/prerequisite');
}

sub _property_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name', 'transfer-ownership'], ['construct-only', 'construct', 'deprecated', 'deprecated-version', 'introspectable', 'readable', 'version', 'writable'], \@atts_vals, 'interface/property');
}

sub _virtual_method_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['deprecated', 'deprecated-version', 'introspectable', 'invoker', 'throws', 'version'], \@atts_vals, 'interface/virtual-method');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Interface');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::DocStartStore->new
    ({
      'glib:signal' => \&_glib_signal_start,
      'function' => \&_function_start,
      'method' => \&_method_start,
      'prerequisite' => \&_prerequisite_start,
      'property' => \&_property_start,
      'virtual-method' => \&_virtual_method_start
    }),
    Gir::Handlers::Stores::DocEndStore->new
    ({
      'glib:signal' => \&Gir::Handlers::Common::end_ignore,
      'function' => \&Gir::Handlers::Common::end_ignore,
      'method' => \&Gir::Handlers::Common::end_ignore,
      'prerequisite' => \&Gir::Handlers::Common::end_ignore,
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
