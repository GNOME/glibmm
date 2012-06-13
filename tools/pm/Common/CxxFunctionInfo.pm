# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::CxxFunctionInfo module
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

package Common::CxxFunctionInfo;

use strict;
use warnings;

use Common::Shared;

sub new_from_string ($$)
{
  my ($type, $string) = @_;
  my $class = (ref $type or $type or 'Common::CxxFunctionInfo');
  my $cxx_parts = Common::Shared::parse_function_declaration $string;
  my $static = ($cxx_parts->[0] =~ /\bstatic\b/);
  my $ret = $cxx_parts->[1];
  my $name = $cxx_parts->[2];
  my $params = Common::Shared::parse_params $cxx_parts->[3];
  my $param_types = [];
  my $param_names = [];
  my $param_values = [];
  my $param_nullables = [];
  my $param_out_index = -1;
  my $const = ($cxx_parts->[4] =~ /\bconst\b/);
  my $index = 0;

  foreach my $desc (@{$params})
  {
    push @{$param_types}, $desc->{'type'};
    push @{$param_names}, $desc->{'name'};
    push @{$param_values}, $desc->{'value'};
    push (@{$param_nullables}, $desc->{'nullable'});

    if ($desc->{'out'})
    {
      die if ($param_out_index > -1);
      $param_out_index = $index;
    }
    ++$index;
  }

  $params = undef;

  my $self =
  {
    'static' => $static,
    'ret' => $ret,
    'name' => $name,
    'param_types' => $param_types,
    'param_names' => $param_names,
    'param_values' => $param_values,
    'param_nullables' => $param_nullables,
    'param_out_index' => $param_out_index,
    'const' => $const
  };

  return bless $self, $class;
}

sub get_static ($)
{
  my ($self) = @_;

  return $self->{'static'};
}

sub get_return_type ($)
{
  my ($self) = @_;

  return $self->{'ret'};
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

sub get_param_values ($)
{
  my ($self) = @_;

  return $self->{'param_values'};
}

sub get_param_nullables ($)
{
  my ($self) = @_;

  return $self->{'param_nullables'};
}

sub get_param_out_index ($)
{
  my ($self) = @_;

  return $self->{'param_out_index'};
}

sub get_const ($)
{
  my ($self) = @_;

  return $self->{'const'};
}

1; # indicate proper module load.
