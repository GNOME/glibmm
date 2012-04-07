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
  my ($gir_typed, $wrap_parser) = @_;
  my $name = '';

  if ($gir_typed->get_g_type_count > 0)
  {
    my $gir_type = $gir_typed->get_g_type_by_index (0);

    $name = $gir_type->get_a_name;
  }
  elsif ($gir_typed->get_g_array_count > 0)
  {
    return _guess_typed $gir_typed->get_g_array_by_index(0);
  }

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

        if ($gir_stuff)
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

        if ($gir_stuff)
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
    # Huh, got nothing?
    die;
  }
}

sub _guess_parameter ($$)
{
  my ($gir_parameter, $wrap_parser) = @_;
  my $c_type = _guess_typed $gir_parameter, $wrap_parser;
  my $gir_direction = $gir_parameter->get_a_direction;

  # out parameters in C have to be pointers.
  unless ((index $gir_direction, 'out') < 0)
  {
    $c_type .= '*';
  }

  return $c_type;
}

sub _get_wrap_parser ($)
{
  my ($self) = @_;

  return $self->{'wrap_parser'};
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
    $type = _guess_parameter $gir_parameter, $self->_get_wrap_parser;
  }

  return $type;
}

sub _parse_return_value ($$)
{
  my ($self, $gir_return_value) = @_;
  my $type = $self->SUPER::_parse_return_value ($gir_return_value);

  unless ($type)
  {
    $type = _guess_typed $gir_return_value, $self->_get_wrap_parser;
  }

  return $type;
}

sub new_from_gir ($$$)
{
  my ($type, $gir_function, $wrap_parser) = @_;
  my $class = (ref $type or $type or 'Common::SignalInfo');
  my $self = $class->SUPER::new ($gir_function);

  return bless $self, $class;
}

1; # indicate proper module load.
