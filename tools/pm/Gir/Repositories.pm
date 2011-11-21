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

package Gir::Repositories;

use strict;
use warnings;

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Repositories');
  my $self =
  {
    'repositories' => {}
  };

  return bless ($self, $class);
}

sub add_repository ($$)
{
  my ($self, $repository) = @_;
  my $repositories = $self->{'repositories'};
  my $namespace = $repository->get_g_namespace_by_index (0);
  my $name = $namespace->get_a_name ();

  if (exists $repositories->{$name})
  {
    print STDERR 'Repository for `' . $name . '\' already exists.' . "\n";
    exit 1;
  }

  $repositories->{$name} = $repository;
}

sub get_repository ($$)
{
  my ($self, $name) = @_;
  my $repositories = $self->{'repositories'};

  if (exists $repositories->{$name})
  {
    return $repositories->{$name};
  }
  return undef;
}

1; # indicate proper module load.
