# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::CallableInfo module
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

package Common::CallableInfo;

use strict;
use warnings;

sub _parse_typed ($$)
{
  my ($self, $gir_typed) = @_;

  if ($gir_typed->get_g_type_count > 0)
  {
    my $gir_type = $gir_typed->get_g_type_by_index (0);

    return $gir_type->get_a_c_type;
  }
  elsif ($gir_typed->get_g_array_count > 0)
  {
    my $gir_array = $gir_typed->get_g_array_by_index (0);

    return $gir_array->get_a_c_type;
  }
  elsif ($gir_typed->get_g_varargs_count > 0)
  {
    return '...';
  }
  else
  {
    die;
  }
}

sub _parse_parameters ($$)
{
  my ($self, $gir_function) = @_;
  my $param_types = [];
  my $param_names = [];
  my $param_transfers = [];

  if ($gir_function->get_g_parameters_count > 0)
  {
    my $gir_parameters = $gir_function->get_g_parameters_by_index (0);
    my $gir_parameters_count = $gir_parameters->get_g_parameter_count;

    for (my $iter = 0; $iter < $gir_parameters_count; ++$iter)
    {
      my $gir_parameter = $gir_parameters->get_g_parameter_by_index ($iter);
      my $name = $gir_parameter->get_a_name;
      my $gir_transfer = $gir_parameter->get_a_transfer_ownership;
      my $transfer = Common::ConversionsStore::transfer_from_string $gir_transfer;
      my $type = $self->_parse_parameter ($gir_parameter);

# TODO: error.
      die unless ($type);
      push @{$param_types}, $type;
      push @{$param_names}, $name;
      push @{$param_transfers}, $transfer;
    }
  }
  return ($param_types, $param_names, $param_transfers);
}

sub _parse_parameter ($$)
{
  my ($self, $gir_parameter) = @_;

  return $self->_parse_typed ($gir_parameter);
}

sub _parse_return_value ($$)
{
  my ($self, $gir_return_value) = @_;

  return $self->_parse_typed ($gir_return_value);
}

sub new_from_gir ($$)
{
  my ($type, $gir_callable) = @_;
  my $class = (ref $type or $type or 'Common::CallableInfo');
  # Bless now, so we can use virtual methods.
  my $self = bless {}, $class;
  my $gir_return = $gir_callable->get_g_return_value_by_index (0);
  my $ret = $self->_parse_return_value ($gir_return);
  my $gir_ret_transfer = $gir_return->get_a_transfer_ownership;
  my $ret_transfer = Common::ConversionsStore::transfer_from_string $gir_ret_transfer;
  my $name = $self->_get_name_from_gir ($gir_callable);
  my ($param_types, $param_names, $param_transfers) = $self->_parse_parameters ($gir_callable);

  $self->{'ret'} = $ret;
  $self->{'ret_transfer'} = $ret_transfer;
  $self->{'name'} = $name;
  $self->{'param_types'} = $param_types;
  $self->{'param_names'} = $param_names;
  $self->{'param_transfers'} = $param_transfers;

  return $self;
}

sub get_return_type ($)
{
  my ($self) = @_;

  return $self->{'ret'};
}

sub get_return_transfer ($)
{
  my ($self) = @_;

  return $self->{'ret_transfer'};
}

sub get_name ($)
{
  my ($self) = @_;

  return $self->{'name'};
}

sub get_param_types ($)
{
  my ($self) = @_;

  return $self->{'param_types'};
}

sub get_param_names ($)
{
  my ($self) = @_;

  return $self->{'param_names'};
}

sub get_param_transfers ($)
{
  my ($self) = @_;

  return $self->{'param_transfers'};
}

1; # indicate proper module load.
