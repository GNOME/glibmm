# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Scanner module
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

package Common::Scanner;

use strict;
use warnings;

use Common::Shared;
use constant
{
  'STAGE_HG' => 0,
  'STAGE_CCG' => 1,
  'STAGE_INVALID' => 2
};

sub _get_stages ($)
{
  my ($self) = @_;

  return $self->{'stages'};
}

sub _set_tokens ($$)
{
  my ($self, $tokens) = @_;

  $self->{'tokens'} = $tokens;
}

sub _get_tokens ($)
{
  my ($self) = @_;

  return $self->{'tokens'};
}

sub _get_namespaces ($)
{
  my ($self) = @_;

  return $self->{'namespaces'};
}

sub _get_classes ($)
{
  my ($self) = @_;

  return $self->{'classes'};
}

sub _inc_level ($)
{
  my ($self) = @_;

  ++$self->{'level'};
}

sub _dec_level ($)
{
  my ($self) = @_;

  --$self->{'level'};
}

sub _get_level ($)
{
  my ($self) = @_;

  return $self->{'level'};
}

sub _get_class_levels ($)
{
  my ($self) = @_;

  return $self->{'class_levels'};
}

sub _get_namespace_levels ($)
{
  my ($self) = @_;

  return $self->{'namespace_levels'};
}

sub _get_handlers ($)
{
  my ($self) = @_;

  return $self->{'handlers'};
}

sub _switch_to_stage ($$)
{
  my ($self, $stage) = @_;
  my $stages = $self->_get_stages;

  if (exists $stages->{$stage})
  {
    $self->_set_tokens ($stages->{$stage});
  }
  else
  {
# TODO: throw an internal error
    print STDERR 'Internal error in Scanner - unknown stage: ' . $stage . "\n";
    exit 1;
  }
}

sub _extract_token ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $results = Common::Shared::extract_token $tokens;

  return $results->[0];
}

sub _on_string_with_end ($$)
{
  my ($self, $end) = @_;
  my $tokens = $self->_get_tokens;

  while (@{$tokens})
  {
    my $token = $self->extract_token;

    if ($token eq $end)
    {
      last;
    }
  }
}

sub _extract_bracketed_text ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $result = Common::Shared::extract_bracketed_text $tokens;

  if (defined $result)
  {
    my $string = $result->[0];
    my $add_to_line = $result->[1];

    return $string;
  }
}

sub _make_full_type ($$)
{
  my ($self, $cpp_type) = @_;
  my $namespaces = $self->_get_namespaces;
  my $classes = $self->_get_classes;

  if (defined $cpp_type)
  {
    return join '::', reverse @{$namespaces}, reverse @{$classes}, $cpp_type;
  }
  else
  {
    return join '::', reverse @{$namespaces}, reverse @{$classes};
  }
}

sub _append ($$$)
{
  my ($self, $c_stuff, $cpp_stuff) = @_;
  my $pairs = $self->get_pairs;

  push @{$pairs}, [$c_stuff, $cpp_stuff];
}

sub _get_params ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->extract_bracketed_text;

  if (@args < 2)
  {
    return undef;
  }

  return [$args[0], $args[1]];
}

sub _on_wrap_func_generic ($$)
{
  my ($self, $args) = @_;
  my $cpp_function = Common::Shared::parse_function_declaration ($args->[0])->[2];
  my $c_function = $args->[1];

  $self->_append ($c_function, $self->_make_full_type ($cpp_function));
}

sub _on_wrap_enum_generic ($$)
{
  my ($self, $args) = @_;
  my $cpp_enum = $args->[0];
  my $c_enum = $args->[1];

  $self->_append ($c_enum, $self->_make_full_type ($cpp_enum));
}

sub _on_wrap_class_generic ($$)
{
  my ($self, $args) = @_;
  my $classes = $self->_get_classes;
  my $cpp_class = $args->[0];
  my $c_class = $args->[1];

  if (@{$classes} > 0 and $classes->[-1] eq $cpp_class)
  {
    $self->_append ($c_class, $self->_make_full_type (undef));
  }
}

sub _on_convert_enum ($$)
{
  my ($self, $args) = @_;
  my $cpp_enum = $args->[0];
  my $c_enum = $args->[1];
  my $full_cpp_enum = $self->_make_full_type ($cpp_enum);
  my $sub_types = Common::Shared::split_cpp_type_to_sub_types $full_cpp_enum;

  foreach my $sub_type (@{$sub_types})
  {
    $self->push_conv($c_enum, $sub_type, 'static_cast< ' . $sub_type . ' >(##ARG##)', undef, undef);
    $self->push_conv($sub_type, $c_enum, 'static_cast< ' . $c_enum . ' >(##ARG##)', undef, undef);
  }
}

sub _generate_containers ($$$)
{
  my ($self, $c_class, $all_types) = @_;
  my $arg = '##ARG##';
  my @list_sub_types = ('Glib::ListHandle', 'ListHandle');
  my @slist_sub_types = ('Glib::SListHandle', 'SListHandle');
  my @array_sub_types = ('Glib::ArrayHandle', 'ArrayHandle');
  my @vector_sub_types = ('std::vector', 'vector');
  my @ownerships = ('Glib::OWNERSHIP_NONE', 'Glib::OWNERSHIP_SHALLOW', 'Glib::OWNERSHIP_DEEP');
  my $handle_to_c = '(' . $arg . ').data()';
  my @c_array_types = ($c_class . '**', 'const ' . $c_class . '**', $c_class . '* const*', 'const ' . $c_class . '* const*');

  foreach my $list_sub_type (@list_sub_types)
  {
    my @list_member_types = map { $list_sub_type . '< ' . $_ . ' >'} @{$all_types};

    push @list_member_types, (map { $_ . '&' } @list_member_types);

    my @const_list_member_types = map { 'const ' . $_ } @list_member_types;
    my $glist = 'GList*';
    my $const_glist = 'const ' . $glist;
    my $cc_handle_to_c = 'const_cast< ' . $glist . ' >(' . $handle_to_c . ')';

    foreach my $list_type (@list_member_types)
    {
      my @to_cxx = map { $list_type . '(' . $arg . ', ' . $_ . ')' } @ownerships;
      my @to_cxx_cc = map { $list_type . '(const_cast< ' . $glist . ' >(' . $arg . '), ' . $_ . ')' } @ownerships;

      $self->push_conv ($list_type, $glist, $handle_to_c, undef, undef);
      $self->push_conv ($list_type, $const_glist, $handle_to_c, undef, undef);
      $self->push_conv ($glist, $list_type, @to_cxx[0 .. 2]);
      $self->push_conv ($const_glist, $list_type, @to_cxx_cc[0 .. 2]);
    }
    foreach my $list_type (@const_list_member_types)
    {
      my @to_cxx = map { $list_type . '(' . $arg . ', ' . $_ . ')' } @ownerships;

      $self->push_conv ($list_type, $glist, $cc_handle_to_c, undef, undef);
      $self->push_conv ($list_type, $const_glist, $handle_to_c, undef, undef);
      $self->push_conv ($glist, $list_type, @to_cxx[0 .. 2]);
      $self->push_conv ($const_glist, $list_type, @to_cxx[0 .. 2]);
    }
  }
  foreach my $slist_sub_type (@slist_sub_types)
  {
    my @slist_member_types = map { $slist_sub_type . '< ' . $_ . ' >' } ${all_types};

    push @slist_member_types, (map { $_ . '&' } @slist_member_types);

    my @const_slist_member_types = map { 'const ' . $_ } @slist_member_types;
    my $gslist = 'GSList*';
    my $const_gslist = 'const ' . $gslist;
    my $cc_handle_to_c = 'const_cast< ' . $gslist . ' >(' . $handle_to_c . ')';

    foreach my $slist_type (@slist_member_types)
    {
      my @to_cxx = map { $slist_type . '(' . $arg . ', ' . $_ . ')' } @ownerships;
      my @to_cxx_cc = map { $slist_type . '(const_cast< ' . $gslist . ' >(' . $arg . '), ' . $_ . ')' } @ownerships;

      $self->push_conv ($slist_type, $gslist, $handle_to_c, undef, undef);
      $self->push_conv ($slist_type, $const_gslist, $handle_to_c, undef, undef);
      $self->push_conv ($gslist, $slist_type, @to_cxx[0 .. 2]);
      $self->push_conv ($const_gslist, $slist_type, @to_cxx_cc[0 .. 2]);
    }
    foreach my $slist_type (@const_slist_member_types)
    {
      my @to_cxx = map { $slist_type . '(' . $arg . ', ' . $_ . ')' } @ownerships;

      $self->push_conv ($slist_type, $gslist, $cc_handle_to_c, undef, undef);
      $self->push_conv ($slist_type, $const_gslist, $handle_to_c, undef, undef);
      $self->push_conv ($gslist, $slist_type, @to_cxx[0 .. 2]);
      $self->push_conv ($const_gslist, $slist_type, @to_cxx[0 .. 2]);
    }
  }
  foreach my $array_sub_type (@array_sub_types)
  {
    my @array_member_types = map { $array_sub_type . '< ' . $_ . ' >' } @{$all_types};

    push @array_member_types, (map { $_ . '&' } @array_member_types);
    push @array_member_types, (map { 'const ' . $_ } @array_member_types);
    foreach my $array_type (@array_member_types)
    {
      my @to_cxx_cc = map { $array_type . '(const_cast< const ' . $array_type . '::CType* >(' . $arg . '), ' . $_ . ')' } @ownerships;

      foreach my $c_array_type (@c_array_types)
      {
        my $cc_handle_to_c = 'const_cast< ' . $c_array_type . ' >(' . $handle_to_c . ')';

        $self->push_conv ($array_type, $c_array_type, $cc_handle_to_c, undef, undef);
        $self->push_conv ($c_array_type, $array_type, @to_cxx_cc[0 .. 2]);
      }
    }
  }
  foreach my $member_type (@{$all_types})
  {
    my @array_to_vectors = map { 'Glib::ArrayHandler< ' . $member_type . ' >::array_to_vector(const_cast< const Glib::ArrayHandler< ' . $member_type . ' >::CType* >(' . $arg . '), ' . $_ . ')' } @ownerships;
    my $vector_to_array = 'Glib::ArrayHandler< ' . $member_type . ' >::vector_to_array(' . $arg . ').data()';
    my @glist_to_vectors = map { 'Glib::ListHandler< ' . $member_type . ' >::list_to_vector(const_cast< GList* >(##ARG##), ' . $_ . ')' } @ownerships;
    my $vector_to_glist = 'Glib::ListHandler< ' . $member_type . ' >::vector_to_list(' . $arg . ').data()';
    my @gslist_to_vectors = map { 'Glib::SListHandler< ' . $member_type . ' >::slist_to_vector(const_cast< GSList* >(##ARG##), ' . $_ . ')' } @ownerships;
    my $vector_to_gslist = 'Glib::SListHandler< ' . $member_type . ' >::vector_to_slist(' . $arg . ').data()';

    foreach my $vector_sub_type (@vector_sub_types)
    {
      my $full_vector_type = $vector_sub_type . '< ' . $member_type . ' >';
      my @full_vector_types = ($full_vector_type, $full_vector_type . '&');

      push @full_vector_types, (map { 'const ' . $_ } @full_vector_types);
      foreach my $vector_type (@full_vector_types)
      {
        foreach my $c_array_type (@c_array_types)
        {
          my $cc_vector_to_array = 'const_cast< ' . $c_array_type . ' >(' . $vector_to_array . ')';

          $self->push_conv ($vector_type, $c_array_type, $cc_vector_to_array, undef, undef);
          $self->push_conv ($c_array_type, $vector_type, @array_to_vectors[0 .. 2]);
        }
        foreach my $c_glist_type ('GList*', 'const GList*')
        {
          my $cc_vector_to_glist = 'const_cast< ' . $c_glist_type . ' >(' . $vector_to_glist . ')';

          $self->push_conv ($vector_type, $c_glist_type, $cc_vector_to_glist, undef, undef);
          $self->push_conv ($c_glist_type, $vector_type, @glist_to_vectors[0 .. 2]);
        }
        foreach my $c_gslist_type ('GSList*', 'const GSList*')
        {
          my $cc_vector_to_gslist = 'const_cast< ' . $c_gslist_type . ' >(' . $vector_to_gslist . ')';

          $self->push_conv ($vector_type, $c_gslist_type, $cc_vector_to_gslist, undef, undef);
          $self->push_conv ($c_gslist_type, $vector_type, @gslist_to_vectors[0 .. 2]);
        }
      }
    }
  }
}

sub _on_convert_class ($$)
{
  my ($self, $args) = @_;
  my $c_class = $args->[1];
  my $full_cpp_class = $self->_make_full_type (undef);
  my $sub_types = Common::Shared::split_cpp_type_to_sub_types $full_cpp_class;
  my $c_class_ptr = $c_class . '*';
  my $const_c_class_ptr = 'const ' . $c_class_ptr;
  my $arg = '##ARG##';
  my $glib_unwrap = 'Glib::unwrap(' . $arg . ')';
  my $cc_glib_unwrap = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap . ')';
  my $glib_unwrap_copy = 'Glib::unwrap_copy(' . $arg . ')';
  my $cc_glib_unwrap_copy = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap_copy . ')';
  my $glib_unwrap_ref = 'Glib::unwrap(&' . $arg . ')';
  my $cc_glib_unwrap_ref = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap_ref . ')';
  my $glib_unwrap_ref_copy = 'Glib::unwrap_copy(&' . $arg . ')';
  my $cc_glib_unwrap_ref_copy = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap_ref_copy . ')';
  my $glib_wrap = 'Glib::wrap(' . $arg . ', false)';
  my $glib_wrap_cc = 'Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', false))';
  my $glib_wrap_copy = 'Glib::wrap(' . $arg . ', true)';
  my $glib_wrap_copy_cc = 'Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', true))';
  my $glib_wrap_ref = '*Glib::wrap(' . $arg . ', false)';
  my $glib_wrap_ref_cc = '*Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', false)';
  my $glib_wrap_ref_copy = '*Glib::wrap(' . $arg . ', true)';
  my $glib_wrap_ref_copy_cc = '*Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', true)';

  foreach my $sub_type (@{$sub_types})
  {
    my $const_sub_type = 'const ' . $sub_type;

    foreach my $non_const_cxx_sub_type ($sub_type, $sub_type . '&')
    {
      foreach my $c_class_type ($c_class_ptr, $const_c_class_ptr)
      {
        $self->push_conv ($non_const_cxx_sub_type, $c_class_type, $glib_unwrap_ref, undef, $glib_unwrap_ref_copy);
      }
      $self->push_conv ($c_class_ptr, $non_const_cxx_sub_type, $glib_wrap_ref, undef, $glib_wrap_ref_copy);
      $self->push_conv ($const_c_class_ptr, $non_const_cxx_sub_type, $glib_wrap_ref_cc, undef, $glib_wrap_ref_copy_cc);
    }
    foreach my $const_cxx_sub_type ($const_sub_type, $const_sub_type . '&')
    {
      foreach my $c_class_type ($c_class_ptr, $const_c_class_ptr)
      {
        $self->push_conv ($c_class_type, $const_cxx_sub_type, $glib_wrap_ref, undef, $glib_wrap_ref_copy);
      }
      $self->push_conv ($const_cxx_sub_type, $c_class_ptr, $cc_glib_unwrap_ref, undef, $cc_glib_unwrap_ref_copy);
      $self->push_conv ($const_cxx_sub_type, $const_c_class_ptr, $glib_unwrap_ref, undef, $glib_unwrap_ref_copy);
    }

    my $sub_type_ptr = $sub_type . '*';
    my $const_sub_type_ptr = $const_sub_type . '*';

    foreach my $c_class_type ($c_class_ptr, $const_c_class_ptr)
    {
      $self->push_conf($sub_type_ptr, $c_class_type, $glib_unwrap, undef, $glib_unwrap_copy);
    }
    $self->push_conv($c_class_ptr, $sub_type_ptr, $glib_wrap, undef, $glib_wrap_copy);
    $self->push_conv($const_c_class_ptr, $sub_type_ptr, $glib_wrap_cc, undef, $glib_wrap_copy_cc);

    foreach my $c_class_type ($c_class_ptr, $const_c_class_ptr)
    {
      $self->push_conv ($c_class_type, $const_sub_type_ptr, $glib_wrap, undef, $glib_wrap_copy);
    }
    $self->push_conv ($const_sub_type_ptr, $c_class_ptr, $cc_glib_unwrap, undef, $cc_glib_unwrap_copy);
    $self->push_conv ($const_sub_type_ptr, $const_c_class_ptr, $glib_unwrap, undef, $glib_unwrap_copy);
  }

  my $gen_flags = Common::Shared::GEN_NORMAL | Common::Shared::GEN_REF | Common::Shared::GEN_PTR | Common::Shared::GEN_CONST;
  my $gen_types = Common::Shared::gen_cpp_types ([$full_cpp_class], $gen_flags);

  $self->_generate_containers ($c_class, $gen_types);
}

sub _on_convert_reffed_class ($$)
{
  my ($self, $args) = @_;
  my $c_class = $args->[1];
  my $full_cpp_class = $self->_make_full_type (undef);
  my $sub_types = Common::Shared::split_cpp_type_to_sub_types $full_cpp_class;
  my $glib_ref_ptr_type = 'Glib::RefPtr';
  my $ref_sub_types = Common::Shared::split_cpp_type_to_sub_types $glib_ref_ptr_type;
  my $c_class_ptr = $c_class . '*';
  my $const_c_class_ptr = 'const ' . $c_class_ptr;
  my $arg = '##ARG##';
  my $glib_unwrap = 'Glib::unwrap(' . $arg . ')';
  my $cc_glib_unwrap = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap . ')';
  my $glib_unwrap_copy = 'Glib::unwrap_copy(' . $arg . ')';
  my $cc_glib_unwrap_copy = 'const_cast< ' . $c_class_ptr . ' >(' . $glib_unwrap_copy . ')';
  my $glib_wrap = 'Glib::wrap(' . $arg . ', false)';
  my $glib_wrap_cc = 'Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', false))';
  my $glib_wrap_copy = 'Glib::wrap(' . $arg . ', true)';
  my $glib_wrap_copy_cc = 'Glib::wrap(const_cast< ' . $c_class_ptr . ' >(' . $arg . ', true))';

  foreach my $sub_type (@{$sub_types})
  {
    foreach my $ref_sub_type (@{$ref_sub_types})
    {
      my $refptr_type = $ref_sub_type . '< ' . $sub_type . ' >';
      my $refptr_const_type = $ref_sub_type . '< const ' . $sub_type . ' >';
      my $const_refptr_type = 'const ' . $ref_sub_type . '< ' . $sub_type . ' >';
      my $const_refptr_const_type = 'const ' . $ref_sub_type . '< const ' . $sub_type . ' >';

      foreach my $xxx_refptr_type ($refptr_type, $const_refptr_type, $refptr_type . '&', $const_refptr_type . '&')
      {
        $self->push_conv ($xxx_refptr_type, $c_class_ptr, $glib_unwrap, undef, $glib_unwrap_copy);
        $self->push_conv ($xxx_refptr_type, $const_c_class_ptr, $glib_unwrap, undef, $glib_unwrap_copy);
        $self->push_conv ($c_class_ptr, $xxx_refptr_type, $glib_wrap, undef, $glib_wrap_copy);
        $self->push_conv ($const_c_class_ptr, $xxx_refptr_type, $glib_wrap_cc, undef, $glib_wrap_copy_cc);
      }
      foreach my $xxx_refptr_const_type ($refptr_const_type, $const_refptr_const_type, $refptr_const_type . '&', $const_refptr_const_type . '&')
      {
        $self->push_conv ($xxx_refptr_const_type, $c_class_ptr, $cc_glib_unwrap, undef, $cc_glib_unwrap_copy);
        $self->push_conv ($xxx_refptr_const_type, $const_c_class_ptr, $glib_unwrap, undef, $glib_unwrap_copy);
        $self->push_conv ($c_class_ptr, $xxx_refptr_const_type, $glib_wrap, undef, $glib_wrap_copy);
        $self->push_conv ($const_c_class_ptr, $xxx_refptr_const_type, $glib_wrap, undef, $glib_wrap_copy);
      }
    }
  }

  my $gen_flags = Common::Shared::GEN_NORMAL | Common::Shared::GEN_REF | Common::Shared::GEN_CONST;
  my $gen_types = Common::Shared::gen_cpp_types ([$glib_ref_ptr_type, $full_cpp_class], $gen_flags);

  $self->_generate_containers ($c_class, $gen_types);
}

###
###
###

sub _on_open_brace ($)
{
  my ($self) = @_;

  $self->_inc_level;
}

sub _on_close_brace ($)
{
  my ($self) = @_;
  my $level = $self->_get_level;
  my $classes = $self->_get_classes;
  my $class_levels = $self->_get_class_levels;
  my $namespaces = $self->_get_namespaces;
  my $namespace_levels = $self->_get_namespace_levels;

  if (@{$class_levels} and $class_levels->[-1] == $level)
  {
    pop @{$classes};
    pop @{$class_levels};
  }
  elsif (@{$namespace_levels} and $namespace_levels->[-1] == $level)
  {
    pop @{$namespaces};
    pop @{$namespace_levels};
  }
  $self->_dec_level;
}

sub _on_string_literal ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('"');
}

sub _on_comment_cpp ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ("\n");
}

sub _on_comment_c ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('*/');
}

sub _on_comment_doxygen ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('*/');
}

sub _on_m4_section ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('#m4end');
}

sub _on_m4_line ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ("\n");
}

sub _on_wrap_method ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_func_generic ($args);
  }
}

sub _on_wrap_ctor ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_func_generic ($args);
  }
}

sub _on_wrap_enum ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_enum_generic ($args);
    $self->_on_convert_enum ($args);
  }
}

sub _on_wrap_gerror ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_enum_generic ($args);
    $self->_on_convert_enum ($args);
  }
}

sub _on_class_generic ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    # no conversion generation possible - it have to be provided manually.
  }
}

sub _on_class_g_object ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_reffed_class ($args);
  }
}

sub _on_class_gtk_object ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_class ($args); # Glib::wrap and Glib::unwrap
  }
}

sub _on_class_boxed_type ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_class ($args); # Glib::wrap and Glib::unwrap
  }
}

sub _on_class_boxed_type_static ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_class ($args); # Glib::wrap and Glib::unwrap
  }
}

sub _on_class_interface ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
# TODO: which convert? reffed or not? probably both. probably manual.
  }
}

sub _on_class_opaque_copyable ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_class ($args); # Glib::wrap and Glib::unwrap
  }
}

sub _on_class_opaque_refcounted ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args);
    $self->_on_convert_reffed_class ($args);
  }
}

sub _on_namespace ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $name = '';
  my $in_s_comment = 0;
  my $in_m_comment = 0;

  # we need to peek ahead to figure out what type of namespace
  # declaration this is.
  foreach my $token (@{$tokens})
  {
    next if (not defined $token or $token eq '');

    if ($in_s_comment)
    {
      if ($token eq "\n")
      {
        $in_s_comment = 0;
      }
    }
    elsif ($in_m_comment)
    {
      if ($token eq '*/')
      {
        $in_m_comment = 0;
      }
    }
    elsif ($token =~ m'^//[/!]?$')
    {
      $in_s_comment = 1;
    }
    elsif ($token =~ m'^/*[*!]?$')
    {
      $in_m_comment = 1;
    }
    elsif ($token eq '{')
    {
      my $namespaces = $self->_get_namespaces;
      my $namespace_levels = $self->_get_namespace_levels;

      $name = Util::string_trim ($name);
      push @{$namespaces}, $name;
      push @{$namespace_levels}, $self->_get_level + 1;
      return;
    }
    elsif ($token eq ';')
    {
      return;
    }
    elsif ($token !~ /\s/)
    {
      $name = $token;
    }
  }
}

sub _on_class ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $name = '';
  my $done = 0;
  my $in_s_comment = 0;
  my $in_m_comment = 0;
  my $colon_met = 0;

  # we need to peek ahead to figure out what type of class
  # declaration this is.
  foreach my $token (@{$tokens})
  {
    next if (not defined $token or $token eq '');

    if ($in_s_comment)
    {
      if ($token eq "\n")
      {
        $in_s_comment = 0;
      }
    }
    elsif ($in_m_comment)
    {
      if ($token eq '*/')
      {
        $in_m_comment = 0;
      }
    }
    elsif ($token eq '//' or $token eq '///' or $token eq '//!')
    {
      $in_s_comment = 1;
    }
    elsif ($token eq '/*' or $token eq '/**' or $token eq '/*!')
    {
      $in_m_comment = 1;
    }
    elsif ($token eq '{')
    {
      my $classes = $self->_get_classes;
      my $class_levels = $self->_get_class_levels;

      $name =~ s/\s+//g;
      push @{$classes}, $name;
      push @{$class_levels}, $self->_get_level + 1;
      return;
    }
    elsif ($token eq ';')
    {
      return;
    }
    elsif ($token eq ':')
    {
      $colon_met = 1;
    }
    elsif ($token !~ /\s/)
    {
      unless ($colon_met)
      {
        $name .= $token;
      }
    }
  }
}

sub new ($$$)
{
  my ($type, $tokens_hg, $tokens_ccg) = @_;
  my $class = (ref $type or $type or 'Common::Scanner');
  my @tokens_hg_copy = (@{$tokens_hg});
  my @tokens_ccg_copy = (@{$tokens_ccg});
  my $self =
  {
    'tokens' => undef,
    'pairs' => [],
    'conversions' => [],
    'stages' =>
    {
      STAGE_HG () => \@tokens_hg_copy,
      STAGE_CCG () => \@tokens_ccg_copy,
      STAGE_INVALID () => []
    },
    'namespace_levels' => [],
    'namespaces' => [],
    'class_levels' => [],
    'classes' => [],
    'level' => 0
  };

  $self = bless $self, $class;

  $self->{'handlers'} =
  {
    '{' => [$self, \&_on_open_brace],
    '}' => [$self, \&_on_close_brace],
    '"' => [$self, \&_on_string_literal],
    '//' => [$self, \&_on_comment_cpp],
    '///' => [$self, \&_on_comment_cpp],
    '//!' => [$self, \&_on_comment_cpp],
    '/*' => [$self, \&_on_comment_c],
    '/**' => [$self, \&_on_comment_doxygen],
    '/*!' => [$self, \&_on_comment_doxygen],
    '#m4begin' => [$self, \&_on_m4_section],
    '#m4' => [$self, \&_on_m4_line],
    '_WRAP_METHOD' => [$self, \&_on_wrap_method],
    '_WRAP_CTOR' => [$self, \&_on_wrap_ctor],
    '_WRAP_ENUM' => [$self, \&_on_wrap_enum],
    '_WRAP_GERROR' => [$self, \&_on_wrap_gerror],
    '_CLASS_GENERIC' => [$self, \&_on_class_generic],
    '_CLASS_GOBJECT' => [$self, \&_on_class_g_object],
    '_CLASS_GTKOBJECT' => [$self, \&_on_class_gtk_object],
    '_CLASS_BOXEDTYPE' => [$self, \&_on_class_boxed_type],
    '_CLASS_BOXEDTYPE_STATIC' => [$self, \&_on_class_boxed_type_static],
    '_CLASS_INTERFACE' => [$self, \&_on_class_interface],
    '_CLASS_OPAQUE_COPYABLE' => [$self, \&_on_class_opaque_copyable],
    '_CLASS_OPAQUE_REFCOUNTED' => [$self, \&_on_class_opaque_refcounted],
    'namespace' => [$self, \&_on_namespace],
    'class' => [$self, \&_on_class]
  };

  return $self;
}

sub scan ($)
{
  my ($self) = @_;
  my $handlers = $self->_get_handlers;
  my @stages = (STAGE_HG, STAGE_CCG);

  for my $stage (@stages)
  {
    $self->_switch_to_stage ($stage);

    my $tokens = $self->_get_tokens;

    while (@{$tokens})
    {
      my $token = $self->_extract_token;

      if (exists $handlers->{$token})
      {
        my $pair = $handlers->{$token};
        my $object = $pair->[0];
        my $handler = $pair->[1];

        if (defined $object)
        {
          $object->$handler;
        }
        else
        {
          &{$handler};
        }
      }
    }
  }
}

sub get_pairs ($)
{
  my ($self) = @_;

  return $self->{'pairs'};
}

sub get_conversions ($)
{
  my ($self) = @_;

  return $self->{'conversions'};
}

sub push_conv ($$$$$$)
{
  my ($self, $from, $to, $none, $shallow, $full) = @_;
  my $conversions = $self->get_conversions;

  push @{$conversions}, [$from, $to, $none, $shallow, $full];
}

1; # indicate proper module load.
