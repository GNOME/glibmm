package GirParser;

use strict;
use warnings;
use XML::Parser;

sub _extract_values($$)
{
  my ($keys, $attval) = @_;
  my %params = ();
  my %check = ();

  foreach my $key (@keys)
  {
    $params{$key} = undef;
    $check{$key} = undef;
  }

  my $att = undef;

  foreach my $entry (@{$attval})
  {
    unless (defined ($att))
    {
      if (exists ($params{$entry}))
      {
        $att = $entry;
        delete ($check{$att});
      }
      else
      {
        # TODO: unknown attribute, ignored.
      }
    }
    else
    {
      $params{$att} = $entry;
      $att = undef;
    }
  }

  if (keys (%check) > 0)
  {
    # TODO: missing needed attribute.
  }

  return \%params;
}

sub _sub_start_include ($@)
{
  my ($self, @attval) = @_;
  my $params = _extract_values (['name', 'version'], \@attval);

  $self->parse_file ($params->{'name'} . '-' . $params->{'version'});
}

sub _sub_end_include ($)
{
  # NOTHING.
}

sub _sub_start_namespace ($@)
{
  my ($self, @attval) = @_;
  my $params = _extract_values (['name'], @attval);
  my $api = $self->{'api'};
  my $name = $params->{'name'};

  if ($api->has_namespace ($name))
  {
    # TODO: error?
  }
  $api->add_namespace ($name);
}

sub _sub_end_namespace ($)
{
  # NOTHING
}

sub _init ($)
{
  my $self = shift;
  my $new_state = GirParserState->new ();
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

sub _proof_of_concept_start ($$$@)
{
  my ($self, undef, $elem, @attval) = @_;
  my $state = $self->{'current_state'};
  my $handlers = $state->get_current_handlers ();
  my $start_handlers = $handlers->get_start_handlers ();

  if (exists ($start_handlers->{$elem}))
  {
    my $method = $start_handlers->{$elem};

    $state->push_handlers ($handlers->get_subhandlers_for ($elem));
    return $handlers->$method ($self, @attval);
  }
  # TODO: unknown elem?
}

sub _proof_of_concept_end ($$$)
{
  my ($self, undef, $elem) = @_;
  my $state = $self->{'current_state'};

  $state->pop_handlers ();

  my $handlers = $state->get_current_handlers ();
  my $end_handlers = $handlers->get_end_handlers ();

  if (exists ($end_handlers->{$elem}))
  {
    my $method = $end_handlers->{$elem};

    return $handlers->$method ($self);
  }
  # TODO: unknown elem?
}

sub _start ($$$@)
{
  my ($self, undef, $elem, @attval) = @_;
  my $subhandlers = $self->{'start_subhandlers'};
  my $ignored_tags = $self->{'ignored_tags'};

  unless (exists ($ignored_tags->{$elem}))
  {
    if (exists ($subhandlers->{$elem}))
    {
      my $method = $subhandlers->{$elem};
      my $state = $self->{'state'};

      $state->push_tag ($elem);
      return $self->$method (@attval);
    }
    # TODO: error - unknown element.
  }
}

sub _end ($$$)
{
  my ($self, undef, $elem) = @_;
  my $subhandlers = $self->{'end_subhandlers'};

  if (exists ($subhandlers->{$elem}))
  {
    my $method = $subhandlers->{$elem};
    my $state = $self->{'state'};

    $state->pop_tag ();
    return $self->$method ();
  }
}

#
## private functions
#
sub _get_ignored_tags ()
{
  return
  {
    'repository' => 0,
    'package' => 1,
    'c:include' => 1,
    'alias' => 1,
    'constant' => 1,
    'doc' => 1 # TODO: docs are ignored temporarily - remove it later.
    ''
  }
}

sub _get_start_subhandlers ()
{
  return
  {
    'include' => \&_sub_start_include,
    'namespace' => \&_sub_start_namespace
  };
}

sub _get_end_subhandlers ()
{
  return
  {
    'include' => \&_sub_end_include,
    'namespace' => \&_sub_end_namespace
  };
}

sub new($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'GirParser');
  my $self =
  {
    'states_stack' => [],
    'top_level_start_subhandlers' => _get_top_level_start_subhandlers (),
    'top_level_end_subhandlers' => _get_top_level_end_subhandlers (),
    'repository_start_subhandlers' => _get_repository_start_subhandlers (),
    'repository_end_subhandlers' => _get_repository_end_subhandlers (),
    'namespace_start_subhandlers' => _get_namespace_start_subhandlers (),
    'namespace_end_subhandlers' => _get_namespace_end_subhandlers (),
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

  $xml_parser->setHandlers
  (
    Char => sub { $self->_char (@_); },
    Comment => sub { $self->_comment (@_); },
    Default => sub { $self->_default (@_); },
    End => sub { $self->_end (@_); },
    Final => sub { $self->_final (@_); },
    Init => sub { $self->_init (@_); },
    Start => sub { $self ->_start (@_); },
    XMLDecl => sub { $self->_xmldecl (@_); }
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
