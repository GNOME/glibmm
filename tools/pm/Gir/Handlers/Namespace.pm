package Gir::Handlers::Namespace;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Alias;
use Gir::Handlers::Bitfield;
use Gir::Handlers::Common;
use Gir::Handlers::Callback;
use Gir::Handlers::Class;
use Gir::Handlers::Constant;
use Gir::Handlers::Enumeration;
use Gir::Handlers::Function;
use Gir::Handlers::Interface;
use Gir::Handlers::Record;
use Gir::Handlers::Stores::Store;
use Gir::Parser;

##
## private:
##
sub _alias_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], [], \@atts_vals, 'alias');
}

sub _bitfield_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], ['glib:get-type', 'glib:type-name', 'version'], \@atts_vals, 'bitfield');
}

sub _callback_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name'], ['c:type', 'introspectable', 'throws', 'version'], \@atts_vals, 'callback');
}

sub _class_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['glib:get-type', 'glib:type-name', 'name'], ['abstract', 'c:symbol-prefix', 'c:type', 'glib:fundamental', 'glib:type-struct', 'parent', 'version'], \@atts_vals, 'class');
}

sub _constant_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['name', 'value'], [], \@atts_vals, 'constant');
}

sub _enumeration_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], ['deprecated', 'deprecated-version', 'glib:error-domain', 'glib:get-type', 'glib:type-name', 'version'], \@atts_vals, 'enumeration');
}

sub _function_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:identifier', 'name'], ['deprecated', 'deprecated-version', 'introspectable', 'moved-to', 'shadowed-by', 'shadows', 'throws', 'version'], \@atts_vals, 'function');
}

sub _interface_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:symbol-prefix', 'c:type', 'glib:get-type', 'glib:type-name', 'name'], ['glib:type-struct', 'version'], \@atts_vals, 'interface');
}

sub _record_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], ['c:symbol-prefix', 'deprecated', 'deprecated-version', 'disguised', 'foreign', 'glib:get-type', 'glib:is-gtype-struct-for', 'glib:type-name', 'introspectable', 'version'], \@atts_vals, 'record');
}

sub _union_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values_warn (['c:type', 'name'], ['c:symbol-prefix', 'glib:get-type', 'glib:type-name'], \@atts_vals, 'union');
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Namespace');
  my $self = $class->SUPER::new ();

  $self->_set_handlers
  (
    Gir::Handlers::Stores::Store->new
    ({
      'class' => \&_class_start,
      'interface' => \&_interface_start,
      'enumeration' => \&_enumeration_start,
      'bitfield' => \&_bitfield_start,
      'record' => \&_record_start,
      'function' => \&_function_start,
      'callback' => \&_callback_start,
      'alias' => \&_alias_start,
      'constant' => \&_constant_start,
      'union' => \&_union_start
    }),
    Gir::Handlers::Stores::Store->new
    ({
      'class' => \&Gir::Handlers::Common::end_ignore,
      'interface' => \&Gir::Handlers::Common::end_ignore,
      'enumeration' => \&Gir::Handlers::Common::end_ignore,
      'bitfield' => \&Gir::Handlers::Common::end_ignore,
      'record' => \&Gir::Handlers::Common::end_ignore,
      'function' => \&Gir::Handlers::Common::end_ignore,
      'callback' => \&Gir::Handlers::Common::end_ignore,
      'alias' => \&Gir::Handlers::Common::end_ignore,
      'constant' => \&Gir::Handlers::Common::end_ignore,
      'union' => \&Gir::Handlers::Common::end_ignore
    })
  );
  $self->_set_subhandlers
  ({
    'alias' => "Gir::Handlers::Alias",
    'bitfield' => "Gir::Handlers::Bitfield",
    'callback' => "Gir::Handlers::Callback",
    'class' => "Gir::Handlers::Class",
    'constant' => "Gir::Handlers::Constant",
    'enumeration' => "Gir::Handlers::Enumeration",
    'function' => "Gir::Handlers::Function",
    'interface' => "Gir::Handlers::Interface",
    'record' => "Gir::Handlers::Record",
    '*' => "Gir::Handlers::Ignore"
  });

  return bless ($self, $class);
}

1;
