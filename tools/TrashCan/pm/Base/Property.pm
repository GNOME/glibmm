# gmmproc - Base::Property module
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

package Base::Property;

use strict;
use warnings;
use parent qw (Base::Entity);

# class Base::Property : public Base::Entity
# {
#   string class;
#   string type;
#   bool   readable;
#   bool   writable;
#   bool   construct_only;
# }

my $g_t = 'type';
my $g_c = 'class';
my $g_r = 'readable';
my $g_w = 'writable';
my $g_c_o = 'construct_only';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Base::Property");
  my $self = $class->SUPER->new ();

  $self->{$g_t} = '';
  $self->{$g_c} = '';
  $self->{$g_r} = 0;
  $self->{$g_w} = 0;
  $self->{$g_c_o} = 0;

  bless ($self, $class);
  return $self;
}

sub get_type ($)
{
  my $self = shift;

  return $self->{$g_t};
}

sub set_type ($$)
{
  my $self = shift;
  my $type = shift;

  $self->{$g_t} = $type;
}

sub get_class ($)
{
  my $self = shift;

  return $self->{$g_c};
}

sub set_class ($$)
{
  my $self = shift;
  my $class = shift;

  $self->{$g_c} = ($class ? 1 : 0);
}

sub get_readable ($)
{
  my $self = shift;

  return $self->{$g_r};
}

sub set_readable ($$)
{
  my $self = shift;
  my $readable = shift;

  $self->{$g_r} = ($readable ? 1 : 0);
}

sub get_writable ($)
{
  my $self = shift;

  return $self->{$g_w};
}

sub set_writable ($$)
{
  my $self = shift;
  my $writable = shift;

  $self->{$g_w} = ($writable ? 1 : 0);
}

sub get_construct_only ($)
{
  my $self = shift;

  return $self->{$g_c_o};
}

sub set_construct_only ($$)
{
  my $self = shift;
  my $construct_only = shift;

  $self->{$g_c_o} = ($construct_only ? 1 : 0);
}

1; # indicate proper module load.
