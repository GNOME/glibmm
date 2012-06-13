# gmmproc - Base::Entity module
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

package Base::Entity;

use strict;
use warnings;

# class Base::Entity
# {
# public:
#   bool is_marked ();
#   void set_marked (bool);
#
#   string get_c_name ();
#   void set_c_name (string);
#
#   string get_entity ();
#   void set_entity ();
#
# private:
#   bool   marked;
#   string entity;
#   string c_name
# }

my $g_m = 'marked';
my $g_e = 'entity';
my $g_c_n = 'c_name';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Base::Entity");
  my $self =
  {
    $g_m => 0,
    $g_e => '',
    $g_c_n => ''
  };

  bless ($self, $class);
  return $self;
}

sub get_entity ($)
{
  my $self = shift;

  return $self->{$g_e};
}

sub set_entity ($$)
{
  my $self = shift;
  my $entity = shift;

  $self->{$g_e} = $entity;
}

sub is_marked ($)
{
  my $self = shift;

  return ($self->{$g_m} ? 1 : 0);
}

sub set_marked ($$)
{
  my $self = shift;
  my $mark = shift;

  $self->{$g_m} = ($mark ? 1 : 0);
}

sub get_c_name ($)
{
  my $self = shift;

  return $self->{$g_c_n};
}

sub set_c_name ($$)
{
  my $self = shift;
  my $c_name = shift;

  $self->{$g_c_n} = $c_name;
}

1; #indicate proper module load.
