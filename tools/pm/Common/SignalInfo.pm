# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::SignalInfo module
#
# Copyright 2012 glibmm development team
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

package Common::SignalInfo;

use strict;
use warnings;

use parent qw (Common::CallableInfo);

sub _guess_typed ($$)
{
  my ($self, $gir_typed) = @_;
  my $name = undef;
  my $imbue_type = undef;

  if ($gir_typed->get_g_type_count > 0)
  {
    my $gir_type = $gir_typed->get_g_type_by_index (0);

    $name = $gir_type->get_a_name;
    $imbue_type = $self->_get_imbue_type ($gir_type);
  }
  elsif ($gir_typed->get_g_array_count > 0)
  {
    return $self->_guess_typed ($gir_typed->get_g_array_by_index (0));
  }

  die unless (defined ($name));

  my $c_type = $self->_c_type_from_name ($name);

  die unless (defined ($c_type));

  if (defined ($imbue_type) and $c_type =~ /^(\w+)/)
  {
    my $pure_c_type = $1;
    my $imbued_c_type = $pure_c_type . $imbue_type;

    $c_type =~ s/$pure_c_type/$imbued_c_type/;
  }

  return $c_type;
}

sub _guess_parameter ($$)
{
  my ($self, $gir_parameter) = @_;
  my $c_type = $self->_guess_typed ($gir_parameter);
  my $gir_direction = $gir_parameter->get_a_direction;

  # out parameters in C have to be pointers.
  unless ((index $gir_direction, 'out') < 0)
  {
    $c_type .= '*';
  }

  return $c_type;
}

sub _get_name_from_gir ($$)
{
  my (undef, $gir_signal) = @_;

  return $gir_signal->get_a_name;
}

sub _parse_parameter ($$)
{
  my ($self, $gir_parameter) = @_;
  my $type = $self->SUPER::_parse_parameter ($gir_parameter);

  unless ($type)
  {
    $type = $self->_guess_parameter ($gir_parameter);
  }

  return $type;
}

sub _parse_return_value ($$)
{
  my ($self, $gir_return_value) = @_;
  my $type = $self->SUPER::_parse_return_value ($gir_return_value);

  unless ($type)
  {
    $type = $self->_guess_typed ($gir_return_value);
  }

  return $type;
}

sub new_from_gir ($$$)
{
  my ($type, $gir_function, $wrap_parser) = @_;
  my $class = (ref $type or $type or 'Common::SignalInfo');
  my $self = $class->SUPER::new ($gir_function, $wrap_parser);

  return bless $self, $class;
}

1; # indicate proper module load.
