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

sub _get_wrap_parser ($)
{
  my ($self) = @_;

  return $self->{'wrap_parser'};
}

sub _c_type_from_name ($$)
{
  my ($self, $name) = @_;
  my $wrap_parser = $self->_get_wrap_parser;

  if ($name eq 'utf8' or $name eq 'filename')
  {
    return 'gchar*';
  }
  else
  {
    my $namespace = undef;
    my $stuff = undef;

    if ($name =~ /^(\w)\.(\w)$/)
    {
      $namespace = $1;
      $stuff = $2;
    }
    elsif ($name =~ /^[A-Z]/)
    {
      $namespace = $wrap_parser->get_module;
      $stuff = $name;
    }
    else # probably something like gint or gboolean
    {
      return $name;
    }

    my $repositories = $wrap_parser->get_repositories;
    my $gir_repository = $repositories->get_repository ($namespace);
    my $gir_namespace = $gir_repository->get_g_namespace_by_name ($namespace);
    my @gir_symbol_prefixes = split ',', $gir_namespace->get_a_c_symbol_prefixes;
    my @gir_namespace_methods =
    (
      \&Gir::Api::Namespace::get_g_alias_by_name,
      \&Gir::Api::Namespace::get_g_class_by_name,
      \&Gir::Api::Namespace::get_g_interface_by_name,
      \&Gir::Api::Namespace::get_g_glib_boxed_by_name,
      \&Gir::Api::Namespace::get_g_record_by_name,
      \&Gir::Api::Namespace::get_g_enumeration_by_name,
      \&Gir::Api::Namespace::get_g_bitfield_by_name,
      \&Gir::Api::Namespace::get_g_union_by_name
    );

    foreach my $symbol_prefix (@gir_symbol_prefixes)
    {
      my $maybe_c_name = $symbol_prefix . $stuff;

      foreach my $method (@gir_namespace_methods)
      {
        my $gir_stuff = $gir_namespace->$method ($maybe_c_name);

        if (defined ($gir_stuff))
        {
          # Meh, glib:boxed is special
          if ($gir_stuff->isa ('Gir::Api::GlibBoxed'))
          {
            return $gir_stuff->get_a_glib_type_name;
          }
          else
          {
            return $gir_stuff->get_a_c_type;
          }
        }
      }
    }
# Argh, probably our guess at C name was just wrong.
# Taking longer route at guessing the C type.
    @gir_namespace_methods =
    (
      [
        \&Gir::Api::Namespace::get_g_alias_count,
        \&Gir::Api::Namespace::get_g_alias_by_index,
      ],
      [
        \&Gir::Api::Namespace::get_g_class_count,
        \&Gir::Api::Namespace::get_g_class_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_interface_count,
        \&Gir::Api::Namespace::get_g_interface_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_glib_boxed_count,
        \&Gir::Api::Namespace::get_g_glib_boxed_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_record_count,
        \&Gir::Api::Namespace::get_g_record_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_enumeration_count,
        \&Gir::Api::Namespace::get_g_enumeration_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_bitfield_count,
        \&Gir::Api::Namespace::get_g_bitfield_by_index
      ],
      [
        \&Gir::Api::Namespace::get_g_union_count,
        \&Gir::Api::Namespace::get_g_union_by_index
      ]
    );

    foreach my $method_pair (@gir_namespace_methods)
    {
      my $count_method = $method_pair->[0];
      my $index_method = $method_pair->[1];
      my $count = $gir_namespace->$count_method;

      for (my $iter = 0; $iter < $count; ++$iter)
      {
        my $gir_stuff = $gir_namespace->$index_method ($iter);

        if (defined ($gir_stuff))
        {
          # Meh, glib:boxed is special
          if ($gir_stuff->isa('Gir::Api::GlibBoxed'))
          {
            my $gir_name = $gir_stuff->get_a_glib_name;

            if ($gir_name eq $stuff)
            {
              return $gir_stuff->get_a_glib_type_name;
            }
          }
          else
          {
            my $gir_name = $gir_stuff->get_a_name;

            if ($gir_name eq $stuff)
            {
              return $gir_stuff->get_a_c_type;
            }
          }
        }
      }
    }
  }
  return undef;
}

sub _get_imbue_type ($$)
{
  my ($self, $gir_type) = @_;
  my $sub_type_count = $gir_type->get_g_type_count;
  my $imbue_type = undef;

  # sub_type_count is greater than 0 only for container types
  # like GList, GSList and else.
  if ($sub_type_count > 0)
  {
    my @sub_types = ();
    my $incorrect = 0;
    my $wrap_parser = $self->_get_wrap_parser;

    for (my $index = 0; $index < $sub_type_count; ++$index)
    {
      my $gir_sub_type = $gir_type->get_g_type_by_index ($index);
      my $gir_sub_c_type = $gir_sub_type->get_a_c_type;

      if (defined ($gir_sub_c_type))
      {
        push @sub_types, $gir_sub_c_type;
      }
      else
      {
        my $gir_sub_name = $gir_sub_type->get_a_name;
        my @gir_sub_name_parts = split /\./, $gir_sub_name;
        my $sub_c_type = $self->_c_type_from_name ($gir_sub_name);

        if (defined ($sub_c_type))
        {
          push @sub_types, $sub_c_type;
        }
        else
        {
          $incorrect = 1;
          last;
        }
      }
    }

    unless ($incorrect)
    {
      $imbue_type = '`' . join (', ', @sub_types) . '\'';
    }
  }

  return $imbue_type;
}

sub _parse_typed ($$)
{
  my ($self, $gir_typed) = @_;

  if ($gir_typed->get_g_type_count > 0)
  {
    my $gir_type = $gir_typed->get_g_type_by_index (0);
    my $c_type = $gir_type->get_a_c_type;

    if (defined $c_type and $c_type =~ /^(\w+)/)
    {
      my $pure_c_type = $1;
      my $sub_type_count = $gir_type->get_g_type_count;
      my $imbue_type = $self->_get_imbue_type ($gir_type);

      if (defined ($imbue_type))
      {
        my $imbued_c_type = $pure_c_type . $imbue_type;

        $c_type =~ s/$pure_c_type/$imbued_c_type/;
      }
    }
    return $c_type;
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
      my $transfer = Common::TypeInfo::Common::transfer_from_string ($gir_transfer);
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

sub new_from_gir ($$$)
{
  my ($type, $gir_callable, $wrap_parser) = @_;
  my $class = (ref $type or $type or 'Common::CallableInfo');
  # Bless now, so we can use virtual methods.
  my $self = bless {'wrap_parser' => $wrap_parser}, $class;
  my $gir_return = $gir_callable->get_g_return_value_by_index (0);
  my $ret = $self->_parse_return_value ($gir_return);
  my $gir_ret_transfer = $gir_return->get_a_transfer_ownership;
  my $ret_transfer = Common::TypeInfo::Common::transfer_from_string ($gir_ret_transfer);
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
