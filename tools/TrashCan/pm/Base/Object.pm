# gmmproc - Base::Object module
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

package Base::Object;

use strict;
use warnings;
use parent qw (Base::Entity);

# class Base::Object : public Base::Entity
# {
#   string       parent;
#   string       gtype_id;
#   string array implemented_interfaces
# }

my $g_p = 'parent';
my $g_g_i = 'gtype_id';
my $g_i_i = 'implemented_interfaces';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Base::Object");
  my $self = $class->SUPER->new ();

  $self->{$g_p} = '';
  $self->{$g_g_i} = '';
  $self->{$g_i_i} = [];

  bless ($self, $class);
  return $self;
}

sub get_parent ($)
{
  my $self = shift;

  return $self->{$g_p};
}

sub set_parent ($$)
{
  my $self = shift;
  my $parent = shift;

  $self->{$g_p} = $parent;
}

sub get_gtype_id ($)
{
  my $self = shift;

  return $self->{$g_g_i};
}

sub set_gtype_id ($$)
{
  my $self = shift;
  my $gtype_id = shift;

  $self->{$g_g_i} = $gtype_id;
}

sub get_implemented_interfaces ($)
{
  my $self = shift;

  return $self->{$g_i_i};
}

sub set_implemented_interfaces ($$)
{
  my $self = shift;
  my $gtype_id = shift;

  $self->{$g_g_i} = $gtype_id;
}

1; # indicate proper module load.
