# gmmproc - Base::Enum module
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

package Base::Enum;

use strict;
use warnings;
use parent qw (Base::Entity);

# class Base::Enum : public Base::Entity
# {
#   bool         flags;
#   string array element_names;o
#   string array element_values;
# }

my $g_f = 'flags';
my $g_e_n = 'element_names';
my $g_e_v = 'element_values';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Enum");
  my $self = $class->SUPER->new ();

  $self->{$g_f} = 0;
  $self->{$g_e_n} = [];
  $self->{$g_e_v} = [];

  return bless ($self, $class);
}

sub is_flags ($)
{
  my $self = shift;

  return $self->{$g_f};
}

sub set_flags ($$)
{
  my $self = shift;
  my $flags = shift;

  $self->{$g_f} = ($flags ? 1 : 0);
}

sub get_element_names ($)
{
  my $self = shift;

  return $self->{$g_e_n};
}

sub set_element_names ($$)
{
  my $self = shift;
  my $element_names = shift;

  $self->{$g_e_n} = $element_names;
}

sub get_element_values ($)
{
  my $self = shift;

  return $self->{$g_e_v};
}

sub set_element_values ($$)
{
  my $self = shift;
  my $element_values = shift;

  $self->{$g_e_v} = $element_values;
}

1; # indicate proper module load.
