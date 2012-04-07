# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Sections::Entries module
#
# Copyright 2011 glibmm development team
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#

package Common::Sections::Entries;

use strict;
use warnings;
use constant
{
  'STRING' => 0,
  'SECTION' => 1,
  'CONDITIONAL' => 2
};

sub new ($)
{
  my ($type) = @_;
  my $class = (ref $type or $type or 'Common::Sections::Entries');
  my $self = [];

  return bless $self, $class;
}

sub append_string ($$)
{
  my ($self, $string) = @_;

  push @{$self}, [STRING, $string];
}

sub append_section ($$)
{
  my ($self, $section) = @_;

  push @{$self}, [SECTION, $section];
}

sub append_conditional ($$)
{
  my ($self, $conditional) = @_;

  push @{$self}, [CONDITIONAL, $conditional];
}

sub get_copy ($)
{
  my ($self) = @_;
  my @copy = (@{$self});

  return \@copy;
}

1; # indicate proper module load.
