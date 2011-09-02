package Gir::Handlers::Common;

use strict;
use warnings;

##
## public:
##
sub start_ignore ($$@)
{}

sub end_ignore ($$)
{}

sub doc_start ($$@)
{
  my ($self, $parser, @atts_vals) = @_;
  my $params = extract_values_warn (['xml:whitespace'], [], \@atts_vals, 'doc');
  my $state = $parser->get_current_state ();
  my $xml_parser = $state->get_xml_parser ();

  $self->{'doc'} = '';
  $xml_parser->setHandlers ('Char' => sub { $self->{'doc'} .= $_[1] });
}

sub doc_end ($$)
{
  my ($self, $parser) = @_;
  my $state = $parser->get_current_state ();
  my $xml_parser = $state->get_xml_parser ();

  $xml_parser->setHandlers ('Char' => undef);
}

sub extract_values($$$$)
{
  my ($keys, $optional_keys, $atts_vals, $tag) = @_;
  my $params = {};
  my $check = {};
  my $leftovers = {};
  my $leftover = undef;
  my $att = undef;

  foreach my $key (@{$keys})
  {
    $params->{$key} = undef;
    $check->{$key} = undef;
  }
  foreach my $key (@{$optional_keys})
  {
    $params->{$key} = undef;
  }

  foreach my $entry (@{$atts_vals})
  {
    if (defined ($leftover))
    {
      $leftovers->{$leftover} = $entry;
      $leftover = undef;
    }
    elsif (not defined ($att))
    {
      if (exists ($params->{$entry}))
      {
        $att = $entry;
        delete ($check->{$att});
      }
      else
      {
        $leftover = $entry;
      }
    }
    else
    {
      $params->{$att} = $entry;
      $att = undef;
    }
  }

  my @check_keys = keys (%{$check});

  if (@check_keys > 0)
  {
    my $message = "Missing attributes in tag '" . $tag . "':\n";

    foreach my $key (@check_keys)
    {
      $message .= "  " . $key . "\n";
    }
    # TODO: change this later maybe to exception and remove $tag parameter.
    #print STDERR $message;
    #exit (1);
  }

  return ($params, $leftovers);
}

sub extract_values_warn ($$$$)
{
  my ($keys, $optional_keys, $atts_vals, $tag) = @_;
  my ($params, $leftovers) = extract_values ($keys, $optional_keys, $atts_vals, $tag);
  my @leftover_keys = keys (%{$leftovers});

  if (@leftover_keys > 0)
  {
    my $message = "Leftover attributes in tag '" . $tag . "':\n";

    foreach my $leftover (@leftover_keys)
    {
      $message .= "  " . $leftover . " => " . $leftovers->{$leftover} . "\n";
    }
    # TODO: change this later maybe to exception and remove $tag parameter.
    #print STDERR $message;
    #exit (1);
  }

  return $params;
}

1;
