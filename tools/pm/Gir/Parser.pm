package GirParser;

use strict;
use warnings;

use Gir::Handlers::Store;
use Gir::State;

use XML::Parser;

sub _init ($)
{
  my $self = shift;
  my $new_state = Gir::State->new ();
  my $state_stack = $self->{'states_stack'};

  push (@{$state_stack}, $new_state);
  $self->{'state'} = $new_state;
}

sub _final ($)
{
  my $self = shift;
  my $state_stack = $self->{'states_stack'};

  pop (@{$state_stack});
  $self->{'state'} = $state_stack->[-1];
}

sub _start ($$$@)
{
  my ($self, undef, $elem, @attval) = @_;
  my $state = $self->{'current_state'};
  my $handlers = $state->get_current_handlers ();
  my $start_handlers = $handlers->get_start_handlers ();

  if ($start_handlers->has_method_for ($elem))
  {
    my $method = $start_handlers->get_method_for ($elem);
    my $subhandlers = $handlers->get_subhandlers_for ($elem);

    if (defined ($subhandlers))
    {
      $state->push_handlers ($subhandlers);
      return $handlers->$method ($self, @attval);
    }
    # TODO: internal error - wrong implementation of get_subhandlers_for?
  }
  # TODO: unknown elem?
}

sub _end ($$$)
{
  my ($self, undef, $elem) = @_;
  my $state = $self->{'current_state'};

  $state->pop_handlers ();

  my $handlers = $state->get_current_handlers ();
  my $end_handlers = $handlers->get_end_handlers ();

  if ($end_handlers->has_method_for ($elem))
  {
    my $method = $end_handlers->get_method_for ($elem);

    return $handlers->$method ($self);
  }
  # TODO: unknown elem?
}

#
## private functions
#

sub new($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'GirParser');
  my $self =
  {
    'states_stack' => [],
    'parsed_girs' => {},
    'state' => undef,
    'api' => {} # TODO: replace with Gir::Api->new () or something like that.
  };

  return bless ($self, $class);
}

sub _create_xml_parser ($)
{
  my $self = shift;
  my $xml_parser = XML::Parser->new ();

  #TODO: implement commented methods.
  $xml_parser->setHandlers
  (
#    Char => sub { $self->_char (@_); },
#    Comment => sub { $self->_comment (@_); },
#    Default => sub { $self->_default (@_); },
    End => sub { $self->_end (@_); },
    Final => sub { $self->_final (@_); },
    Init => sub { $self->_init (@_); },
    Start => sub { $self ->_start (@_); },
#    XMLDecl => sub { $self->_xmldecl (@_); }
  );

  return $xml_parser;
}

sub parse_file ($$)
{
  my ($self, $filename) = @_;
  my $parsed_girs = $self->{'parsed_girs'};

  unless (exists ($parsed_girs->{$filename}))
  {
    my $real_filename = File::Spec->catfile (GirConfig::get_girdir(), $filename);
    my $xml_parser = $self->_create_xml_parser ();

    $parsed_girs->{$filename} = undef;
    $xml_parser->parsefile ($real_filename);
  }
}

sub get_api ($)
{
  my $self = shift;

  return $self->{'api'};
}

1;
