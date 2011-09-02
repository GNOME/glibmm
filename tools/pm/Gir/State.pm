package Gir::State;

use strict;
use warnings;
use Gir::Handlers::TopLevel;

##
## public:
##
sub new ($$$)
{
  my ($type, $parsed_file, $xml_parser) = @_;
  my $class = (ref ($type) or $type or 'Gir::State');
  my $self =
  {
    'handlers_stack' => [Gir::Handlers::TopLevel->new ()],
    'current_namespace' => undef,
    'parsed_file' => $parsed_file,
    'xml_parser' => $xml_parser
  };

  return bless ($self, $class);
}

sub push_handlers ($$)
{
  my ($self, $handlers) = @_;
  my $handlers_stack = $self->{'handlers_stack'};

  push (@{$handlers_stack}, $handlers);
}

sub pop_handlers ($)
{
  my $self = shift;
  my $handlers_stack = $self->{'handlers_stack'};

  pop (@{$handlers_stack});
}

sub get_current_handlers ($)
{
  my $self = shift;
  my $handlers_stack = $self->{'handlers_stack'};

  return ${handlers_stack}->[-1];
}

sub get_current_namespace ($)
{
  my $self = shift;

  return $self->{'current_namespace'};
}

sub set_current_namespace ($$)
{
  my ($self, $namespace) = @_;

  $self->{'current_namespace'} = $namespace;
}

sub get_parsed_file ($)
{
  my $self = shift;

  return $self->{'parsed_file'};
}

sub get_xml_parser ($)
{
  my $self = shift;

  return $self->{'xml_parser'};
}

1;
