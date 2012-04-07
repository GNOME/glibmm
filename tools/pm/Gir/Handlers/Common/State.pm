# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
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

package Gir::Handlers::Common::State;

use strict;
use warnings;

use Gir::Api::TopLevel;

##
## public:
##
sub new ($$$)
{
  my $type = shift;
  my $class = (ref $type or $type or 'Gir::Handlers::Common::State');
  my $self =
  {
    'object_stack' => [Gir::Api::TopLevel->new]
  };

  return bless $self, $class;
}

sub push_object ($$)
{
  my ($self, $object) = @_;
  my $object_stack = $self->{'object_stack'};

  push @{$object_stack}, $object;
}

sub pop_object ($)
{
  my $self = shift;
  my $object_stack = $self->{'object_stack'};

  pop @{$object_stack};
}

sub get_current_object ($)
{
  my $self = shift;
  my $object_stack = $self->{'object_stack'};

  return ${object_stack}->[-1];
}

1; # indicate proper module load.
