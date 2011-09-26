## Copyright 2011 Krzesimir Nowak
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
##

package Gir::Parser;

use strict;
use warnings;

use Encode;

use Gir::Config;
use Gir::Handlers::Generated::Common::Store;
use Gir::State;

use IO::File;

use XML::Parser::Expat;

sub _print_error ($$$)
{
  my ($state, $error, $elem) = @_;
  my $xml_parser = $state->get_xml_parser ();
  my $msg = $state->get_parsed_file ()
    . ':'
    . $xml_parser->current_line ()
    . ': '
    . $error
    . "\nTags stack:\n";
  my @context = $xml_parser->context ();

  foreach my $tag (@context)
  {
    $msg .= '  ' . $tag . "\n";
  }
  if (defined ($elem))
  {
    $msg .= '  ' . $elem . "\n";
  }
  print STDERR $msg;
}

sub _get_file_contents_as_utf8 ($)
{
  my $real_filename = shift;
  my $xml = IO::File->new ($real_filename, 'r');

  unless (defined ($xml))
  {
    #TODO: error;
    print STDERR 'Could not open file: ' . $real_filename . ".\n";
    exit (1);
  }

  my $file_size = ($xml->stat ())[7];
  my $contents = undef;

  unless ($xml->binmode (':raw'))
  {
    #TODO: error;
    print STDERR "Calling binmode on " . $real_filename . " failed.\n";
    exit (1);
  }

  my $bytes_read = $xml->read ($contents, $file_size);

  if ($bytes_read != $file_size)
  {
    #TODO: error;
    if (defined ($bytes_read))
    {
      print STDERR 'Read ' . $bytes_read . ' bytes from ' . $real_filename . ', wanted: ' . $file_size . " bytes.\n";
    }
    else
    {
      print STDERR 'Read error from ' . $real_filename . ".\n";
    }
    exit (1);
  }
  unless ($xml->close ())
  {
    print STDERR 'Closing ' . $real_filename . " failed.\n";
    exit (1);
  }
  return decode ('utf-8', $contents);
}

sub _start ($$$@)
{
  my ($self, undef, $elem, @atts_vals) = @_;
  my $state = $self->get_current_state ();
  my $handlers = $state->get_current_handlers ();
  my $start_handlers = $handlers->get_start_handlers ();

  if (defined ($start_handlers))
  {
    if ($start_handlers->has_method_for ($elem))
    {
      my $method = $start_handlers->get_method_for ($elem);
      my $subhandlers = $handlers->get_subhandlers_for ($elem);

      if (defined ($subhandlers))
      {
        $state->push_handlers ($subhandlers);
        return $handlers->$method ($self, @atts_vals);
      }
      # TODO: internal error - wrong implementation of get_subhandlers_for?
      _print_error ($state, 'Internal error - wrong implementation of get_subhandlers_for?', $elem);
      exit (1);
    }
    # TODO: unknown elem?
    _print_error ($state, 'Unknown tag: ' . $elem . '.', $elem);
    exit (1);
  }
  _print_error ($state, 'No start handlers: ' . $elem . '.', $elem);
  exit (1);
}

sub _end ($$$)
{
  my ($self, undef, $elem) = @_;
  my $state = $self->get_current_state ();

  $state->pop_handlers ();

  my $handlers = $state->get_current_handlers ();
  unless (defined $handlers)
  {
    _print_error ($state, 'No handlers for tag: ' . $elem . '.', $elem);
    exit (1);
  }
  my $end_handlers = $handlers->get_end_handlers ();

  if ($end_handlers->has_method_for ($elem))
  {
    my $method = $end_handlers->get_method_for ($elem);

    return $handlers->$method ($self);
  }
  _print_error ($state, 'Unknown tag: ' . $elem . '.', $elem);
  exit (1);
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
    'api' => {}, # TODO: replace with Gir::Api->new () or something like that.
  };

  return bless ($self, $class);
}

sub _create_xml_parser ($)
{
  my $self = shift;
  my $xml_parser = XML::Parser::Expat->new ();

  #TODO: implement commented methods.
  $xml_parser->setHandlers
  (
#    Char => sub { $self->_char (@_); },
#    Comment => sub { $self->_comment (@_); },
#    Default => sub { $self->_default (@_); },
    End => sub { $self->_end (@_); },
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
    my $real_filename = File::Spec->catfile (Gir::Config::get_girdir(), $filename);
    my $xml_parser = $self->_create_xml_parser ();
    my $new_state = Gir::State->new ($real_filename, $xml_parser);
    my $states_stack = $self->{'states_stack'};

    $parsed_girs->{$filename} = undef;
    push (@{$states_stack}, $new_state);

    my $contents = _get_file_contents_as_utf8 ($real_filename);

    $xml_parser->parse ($contents);
    $xml_parser->release ();
    pop (@{$states_stack});
    #print STDOUT 'Parsed ' . $real_filename . "\n";
  }
}

sub get_api ($)
{
  my $self = shift;

  return $self->{'api'};
}

sub get_current_state ($)
{
  my $self = shift;
  my $states_stack = $self->{'states_stack'};

  return $states_stack->[-1];
}

1;
