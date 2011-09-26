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

1; # indicate proper module load.
