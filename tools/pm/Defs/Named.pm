# gmmproc - Defs::Named module
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

package Defs::Named;

use strict;
use warnings;

my $g_n = 'name';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Defs::Named');
  my $self =
  {
    $g_n = ''
  };

  bless ($self, $class);
  return $self;
}

sub get_name ($)
{
  my $self = shift;

  return $self->{$g_n};
}

sub set_name ($$)
{
  my $self = shift;
  my $name = shift;

  $self->{$g_n} = $name;
}

1; # indicate proper module load.
