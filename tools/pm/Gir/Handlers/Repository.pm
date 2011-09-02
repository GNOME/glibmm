package Gir::Handlers::Repository;

use strict;
use warnings;

use parent qw(Gir::Handlers::Base);

use Gir::Handlers::Common;
use Gir::Handlers::Ignore;
use Gir::Handlers::Namespace;
use Gir::Handlers::Store;
use Gir::Parser;

##
## private:
##
sub _namespace_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = Gir::Handlers::Common::extract_values (['name', 'version', 'shared-library', 'c:identifier-prefixes', 'c:symbol-prefixes'], [], \@atts_vals, 'namespace');
  my $api = $parser->get_api ();
  my $name = $params->{'name'};

  if ($api->has_namespace ($name))
  {
    # TODO: error? every gir probably should have different namespace, right?
  }
  $api->add_namespace ($name);
}

sub _include_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = extract_values_warn (['name', 'version'], [], \@atts_vals, 'include');

  $parser->parse_file ($params->{'name'} . '-' . $params->{'version'});
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Repository');
  my $self = $class->SUPER->new ();

  $self->_set_handlers
  (
    Gir::Handlers::Store->new
    ({
      'c:include' => \&Gir::Handlers::Common::start_ignore,
      'implementation' => \&Gir::Handlers::Common::start_ignore,
      'include' => \&_include_start,
      'namespace' => \&_namespace_start,
      'package' => \&Gir::Handlers::Common::start_ignore
    }),
    Gir::Handlers::Store->new
    ({
      'c:include' => \&Gir::Handlers::Common::end_ignore,
      'implementation' => \&Gir::Handlers::Common::end_ignore,
      'include' => \&Gir::Handlers::Common::end_ignore,
      'namespace' => \&Gir::Handlers::Common::end_ignore,
      'package' => \&Gir::Handlers::Common::end_ignore
    })
  );

  return bless ($self, $class);
}

sub get_subhandlers_for ($$)
{
  my ($self, $elem) = @_;

  if ($elem eq 'namespace')
  {
    return Gir::Handlers::Namespace->new ();
  }
  # rest is either ignored or has no children
  return Gir::Handlers::Ignore->new ();
}

1;
