# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Shared module
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

package Common::Output::Shared;

use strict;
use warnings;
use feature ':5.10';

use constant
{
  'FLAGS_TYPE' => 'Flags',
  'ENUM_TYPE' => 'Enum',
};

use Common::Variables;
use Common::Sections;

sub nl
{
  return join '', @_, "\n";
}

sub doxy_skip_begin ()
{
  return '#ifndef DOXYGEN_SHOULD_SKIP_THIS';
}

sub doxy_skip_end ()
{
  return '#endif // DOXYGEN_SHOULD_SKIP_THIS';
}

sub open_some_namespaces
{
  my ($namespaces) = @_;
  my $code_string = '';

  foreach my $opened_name (@{$namespaces})
  {
    $code_string .= nl ('namespace ' . $opened_name) .
                    nl ('{') .
                    nl ();
  }
  return $code_string;
}

sub open_namespaces
{
  my ($wrap_parser) = @_;

  return open_some_namespaces ($wrap_parser->get_namespaces ());
}

sub close_some_namespaces
{
  my ($namespaces) = @_;
  my $code_string = '';

  foreach my $closed_name (reverse @{$namespaces})
  {
    $code_string .= nl ('} // namespace ' . $closed_name) .
                    nl ();
  }
  return $code_string;
}

sub close_namespaces
{
  my ($wrap_parser, $namespaces) = @_;

  return close_some_namespaces ($wrap_parser->get_namespaces ());
}

sub get_first_class ($)
{
  my ($wrap_parser) = @_;
  my $classes = $wrap_parser->get_classes;

  if (@{$classes})
  {
    return $classes->[0];
  }
  die;
}

sub get_first_namespace ($)
{
  my ($wrap_parser) = @_;
  my $namespaces = $wrap_parser->get_namespaces;

  if (@{$namespaces})
  {
    return $namespaces->[0];
  }
  die;
}

# returns VteTerminal
sub get_c_type ($)
{
  my ($wrap_parser) = @_;

  return $wrap_parser->get_c_class;
}

# returns Terminal
sub get_cxx_type ($)
{
  my ($wrap_parser) = @_;
  my $classes = $wrap_parser->get_classes;

  if (@{$classes})
  {
    return $classes->[-1];
  }
  return undef;
}

# returns Terminal, the difference is that it can also return Foo::Bar if Bar is
# a class inside a Foo class
sub get_full_cxx_type ($)
{
  my ($wrap_parser) = @_;
  my $classes = $wrap_parser->get_classes ();
  my $full_cxx_class = join ('::', @{$classes});

  return $full_cxx_class;
}

# returns Gnome::Vte
sub get_full_namespace ($)
{
  my ($wrap_parser) = @_;
  my $namespaces = $wrap_parser->get_namespaces ();
  my $full_namespace = join ('::', @{$namespaces});

  return $full_namespace;
}

# returns Gnome::Vte::Terminal
sub get_complete_cxx_type ($)
{
  my ($wrap_parser) = @_;
  my $namespaces = get_full_namespace $wrap_parser;
  my $classes = get_full_cxx_type $wrap_parser;
  my @type = ();

  if ($namespaces)
  {
    push (@type, $namespaces);
  }
  if ($classes)
  {
    push (@type, $classes);
  }
  return join ('::', @type);
}

# returns Terminal_Class for Gnome::Vte::Terminal.
# returns Terminal_Foo_Class for Gnome::Vte::Terminal::Foo.
sub get_cxx_class_type ($)
{
  my ($wrap_parser) = @_;
  my $full_cxx_type = get_full_cxx_type ($wrap_parser);

  $full_cxx_type =~ s/::/_/g;
  return $full_cxx_type . '_Class';
}

# returns Gnome::Vte::Terminal_Class for Gnome::Vte::Terminal.
# returns Gnome::Vte::Terminal_Foo_Class for Gnome::Vte::Terminal::Foo.
sub get_complete_cxx_class_type ($)
{
  my ($wrap_parser) = @_;
  my $full_namespace = get_full_namespace ($wrap_parser);
  my $cxx_class_type = get_cxx_class_type ($wrap_parser);
  my @type = ();

  if ($full_namespace)
  {
    push (@type, $full_namespace);
  }
  if ($cxx_class_type)
  {
    push (@type, $cxx_class_type);
  }

  return join ('::', @type);
}

# TODO: implement beautifying if I am really bored.
sub convert_members_to_strings ($)
{
  my ($members) = @_;
  my @strings = ();

  foreach my $pair (@{$members})
  {
    my $name = $pair->[0];
    my $value = $pair->[1];

    push @strings, '    ' . $name . ' = ' . $value;
  }
  return \@strings;
}

# TODO: reorder the functions, so we don't have to declare them first.
sub get_section ($$);
sub get_variable ($$);

sub output_enum_gtype_func_h ($$$$)
{
  my ($wrap_parser, $cxx_type, $type, $get_type_func) = @_;

  if (defined $get_type_func)
  {
    my $namespaces = $wrap_parser->get_namespaces ();
    my $main_section = $wrap_parser->get_main_section ();
    my $container_type = get_full_cxx_type ($wrap_parser);
    my $full_cxx_type = $cxx_type;
    my $h_includes_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::H_INCLUDES);
    my $section_manager = $wrap_parser->get_section_manager ();

    $section_manager->append_string_to_section (nl ('#include <glibmm/value.h>'),
                                                $h_includes_section);
    if ($container_type)
    {
      $full_cxx_type = $container_type . '::' . $full_cxx_type;
    }

    my $glib_namespace = 0;
    my $value_base = 'Glib::Value_' . $type;
    my $code_string = '';

    if (@{$namespaces} == 1 and $namespaces->[0] eq 'Glib')
    {
      $glib_namespace = 1;
    }

    unless ($glib_namespace)
    {
      $code_string .= close_namespaces ($wrap_parser) .
                      nl (doxy_skip_begin) .
                      nl ('namespace Glib') .
                      nl ('{') .
                      nl ();
    }
    else
    {
      $code_string .= nl (doxy_skip_begin);
    }

    $code_string .= nl ('template <>') .
                    nl ('class Value< ' . $full_cxx_type . ' > : public ' . $value_base . '< ' . $full_cxx_type . ' >') .
                    nl ('{') .
                    nl ('public:') .
                    nl ('  static GType value_type() G_GNUC_CONST;') .
                    nl ('};') .
                    nl ();

    unless ($glib_namespace)
    {
      $code_string .= nl ('} // namespace Glib') .
                      nl (doxy_skip_end) .
                      nl () .
                      open_namespaces ($wrap_parser);
    }
    else
    {
      $code_string .= nl (doxy_skip_end) .
                      nl ();
    }

    if ($container_type)
    {
      my $section = get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_CLASS;

      $section_manager->append_string_to_section ($code_string, $section);
    }
    else
    {
      $section_manager->append_string_to_section ($code_string, $main_section);
    }
  }
}

sub output_enum_gtype_func_cc ($$$)
{
  my ($wrap_parser, $cxx_type, $get_type_func) = @_;

  if (defined $get_type_func)
  {
    my $container_cxx_type = get_full_cxx_type $wrap_parser;
    my $full_cxx_type = $cxx_type;

    if ($container_cxx_type)
    {
      $full_cxx_type = $container_cxx_type . '::' . $full_cxx_type;
    }

    my $section_manager = $wrap_parser->get_section_manager;
    my $code_string = nl ('namespace Glib') .
                      nl ('{') .
                      nl () .
                      nl ('// static') .
                      nl ('GType Glib::Value< ' . $full_cxx_type . ' >::value_type()') .
                      nl ('{') .
                      nl ('  return ' . $get_type_func . '();') .
                      nl ('}') .
                      nl () .
                      nl ('} // namespace Glib') .
                      nl ();
    my $section = get_section $wrap_parser, Common::Sections::CC_GENERATED;

    $section_manager->append_string_to_section ($code_string, $section);
  }
}

sub generate_conditional ($)
{
  my ($wrap_parser) = @_;
  my $number = $wrap_parser->get_number;

  return 'CONDITIONAL#' . $number;
}

sub struct_prototype ($$$)
{
  my ($wrap_parser, $c_type, $c_class_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = nl (doxy_skip_begin) .
                    nl ('typedef struct _' . $c_type . ' ' . $c_type . ';') .
                    nl ('typedef struct _' . $c_class_type . ' ' . $c_class_type . ';') .
                    nl (doxy_skip_end) .
                    nl ();
  my $variable = get_variable $wrap_parser, Common::Variables::STRUCT_NOT_HIDDEN;
  my $conditional = generate_conditional $wrap_parser;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  return $conditional;
}

sub wrap_proto ($$$$$$)
{
  my ($wrap_parser, $c_type, $result_type, $take_copy, $open, $const) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $result = undef;
  my $complete_cxx_type = get_complete_cxx_type $wrap_parser;

# TODO: make result type constant
  if ($result_type eq 'refptr')
  {
    $result = 'Glib::RefPtr< ' . $complete_cxx_type . ' >';
  }
  elsif ($result_type eq 'ref')
  {
    $result = $complete_cxx_type . '&';
  }
  elsif ($result_type eq 'ptr')
  {
    $result = $complete_cxx_type . '*';
  }
  elsif ($result_type eq 'plain')
  {
    $result = $complete_cxx_type;
  }
  else
  {
    die;
  }

  if ($const)
  {
    $result = 'const ' . $result;
  }

  my $params = ($const ? 'const ' : '') . $c_type . '* object';
  my $params_doc = ' * @param object The C instance.';

  if ($take_copy ne 'N/A')
  {
    $params_doc = nl ($params_doc) .
                  nl (' * @param take_copy @c false if the result should take ownership') .
                  ' * of the C instance. @c true if it should take a new copy or reference.';
    $params .= ', bool take_copy = ';
    if ($take_copy eq 'yes')
    {
      $params .= 'true';
    }
    elsif ($take_copy eq 'no')
    {
      $params .= 'false';
    }
    else
    {
      die;
    }
  }

  my $conditional = generate_conditional $wrap_parser;
  my $variable = get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $code_string = '';

  if ($open)
  {
    $code_string .= nl ('namespace Glib') .
                    nl ('{') .
                    nl ();
  }

  $code_string .= nl ('/** A Glib::wrap() method for this object.') .
                  nl (' *') .
                  nl ($params_doc) .
                  nl (' * @result A C++ instance that wraps this C instance') .
                  nl (' *') .
                  nl (' * @relates ' . $complete_cxx_type) .
                  nl (' */') .
                  nl ($result . ' wrap(' . $params . ');') .
                  nl ();
  if ($open)
  {
    $code_string .= nl ('} //namespace Glib') .
                    nl ();
  }

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  return $conditional;
}

sub default_ctor_proto ($$)
{
  my ($wrap_parser, $cxx_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $variable = get_variable $wrap_parser, Common::Variables::CUSTOM_DEFAULT_CTOR;
  my $conditional = generate_conditional $wrap_parser;
  my $code_string = nl ('  ' . $cxx_type . '();');

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  return $conditional;
}

# wrap output of this function with nl();
sub copy_protos_str ($)
{
  my ($cxx_type) = @_;
  my $code_string = nl ('  ' . $cxx_type . '(const ' . $cxx_type . '& src);') .
                    '  ' . $cxx_type . '& operator=(const ' . $cxx_type . '& src);';

  return $code_string;
}

sub dtor_proto_str ($$)
{
  my ($cxx_type, $virtual_dtor) = @_;
  my $code_string = '  ' . ($virtual_dtor ? 'virtual ' : '') . '~' . $cxx_type . '();';

  return $code_string;
}

sub gobj_protos_str ($$$$)
{
  my ($c_type, $copy_proto, $reinterpret, $definitions) = @_;
  my $gobj = ($reinterpret ? 'reinterpret_cast< ' . $c_type . '* >(gobject_)' : 'gobject_');
  my $code_string = nl ('  /// Provides access to the underlying C instance.') .
                    nl ('  ' . $c_type . '* gobj()' . ($definitions ? ' { return ' . $gobj . '; }' : ';')) .
                    nl () .
                    nl ('  /// Provides access to the underlying C instance.') .
                    '  const ' . $c_type . '* gobj() const' . ($definitions ? ' { return ' . $gobj . '; }' : ';');

  if ($copy_proto ne 'no')
  {
    $code_string = nl ($code_string) .
                   nl () .
                   nl ('  /// Provides access to the underlying C instance. The caller is responsible for freeing it. Use when directly setting fields in structs.') .
                   '  ' . $c_type . '* gobj_copy()';
    if ($copy_proto eq 'const')
    {
      $code_string .= ' const';
    }
    elsif ($copy_proto ne 'yes')
    {
      die;
    }
    $code_string .= ';';
  }
  return $code_string;
}

sub _get_prefixed_name ($$$)
{
  my ($wrap_parser, $name, $name_type) = @_;
  my $prefixed_name = undef;

  given ($name_type)
  {
    when (Common::Constants::CLASS)
    {
      my $complete_type = get_complete_cxx_type $wrap_parser;

      $complete_type =~ s/::/_/g;
      $prefixed_name = join '_', $complete_type, $name;
    }
    when (Common::Constants::NAMESPACE)
    {
      my $full_namespace = get_full_namespace $wrap_parser;

      $full_namespace =~ s/::/_/g;
      $prefixed_name = join '_', $full_namespace, $name;
    }
    when (Common::Constants::FILE)
    {
      $prefixed_name = $name;
    }
    when (Common::Constants::FIRST_NAMESPACE)
    {
      my $first_namespace = get_first_namespace $wrap_parser;
      my $first_namespace_number = $wrap_parser->get_first_namespace_number;

      $prefixed_name = join '_', $first_namespace, $first_namespace_number, $name;
    }
    when (Common::Constants::FIRST_CLASS)
    {
      my $full_namespace = get_full_namespace $wrap_parser;
      my $first_class = get_first_class $wrap_parser;
      my $first_class_number = $wrap_parser->get_first_class_number;

      $full_namespace =~ s/::/_/g;

      $prefixed_name = join '_', $full_namespace, $first_class, $first_class_number, $name;
    }
    default
    {
      die;
    }
  }

  return $prefixed_name;
}

sub get_variable ($$)
{
  my ($wrap_parser, $variable) = @_;

  return _get_prefixed_name $wrap_parser, $variable->[0], $variable->[1];
}

sub get_section ($$)
{
  my ($wrap_parser, $section) = @_;

  return _get_prefixed_name $wrap_parser, $section->[0], $section->[1];
}

sub ifdef ($)
{
  my ($ifdef) = @_;

  if ($ifdef)
  {
    my $str = nl ('#ifdef ' . $ifdef) .
              nl ();

    return $str;
  }

  return '';
}

sub endif ($)
{
  my ($ifdef) = @_;

  if ($ifdef)
  {
    my $str = nl ('#endif // ' . $ifdef) .
              nl();

    return $str;
  }

  return '';
}

sub paramzipstr
{
  my ($types, $names, $values) = @_;
  my $count = @{$types};

# TODO: throw runtime error or internal error or whatever.
  die if ($count != scalar (@{$names}));
  unless (defined ($values))
  {
    $values = [];
  }

  my @params = ();

  foreach my $index (0 .. $count - 1)
  {
    my $type = $types->[$index];

    if (defined ($type))
    {
      my $value = $values->[$index];
      my $name = $names->[$index] . (defined ($value) ? (' = ' . $value) : '');

      push (@params, join (' ', $type, $name));
    }
  }

  return join (', ', @params);
}

sub get_parent_from_object ($$)
{
  my ($wrap_parser, $object) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $variable = get_variable $wrap_parser, Common::Variables::IS_INTERFACE;
  my $code_string = '';

  if ($section_manager->get_variable ($variable))
  {
    $code_string = (nl 'g_type_interface_peek_parent( // Get the parent interface of the interface (The original underlying C inteface)') .
                   (nl '    g_type_interface_peek(G_OBJECT_GET_CLASS(', $object, '), CppObjectType::get_type()) // Get the interface.') .
                       '    )';
  }
  else
  {
    $code_string = 'g_type_class_peek_parent(G_OBJECT_GET_CLASS(' . $object . ')) // Get the parent class of the object class (The original underlying C class).';
  }

  return $code_string;
}

sub convert_or_die
{
  my ($wrap_parser, $from, $to, $transfer, $subst) = @_;
  my @good_range = Common::TypeInfo::Common::transfer_good_range ();

  unless ($transfer ~~ @good_range)
  {
    my $message = join ('', 'Got invalid transfer for conversion from `', $from, '\' to `', $to, '\' for substitution `', $subst, '\'. Please fix it in C library by adding correct transfer annotation.');
    $wrap_parser->fixed_error ($message);
  }

  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $conversion = $type_info_local->get_conversion ($from,
                                                     $to,
                                                     $transfer,
                                                     $subst);

  unless (defined ($conversion))
  {
    my $message = join ('', 'Could not find conversion from `', $from, '\' to `', $to, '\' with transfer `', Common::TypeInfo::Common::transfer_to_string ($transfer), '\' for substitution `', $subst, '\'');

    $wrap_parser->fixed_error ($message);
  }

  return $conversion;
}

sub convzipstr ($$$$$)
{
  my ($wrap_parser, $from_types, $to_types, $transfers, $substs) = @_;
  my $from_types_count = @{$from_types};
  my $to_types_count = @{$to_types};
  my $transfers_count = @{$transfers};
  my $substs_count = @{$substs};

# TODO: internal error.
  if ($from_types_count != $to_types_count)
  {
    $wrap_parser->fixed_error ('From types count should be equal to to types count.');
  }
  if ($to_types_count != $transfers_count)
  {
    $wrap_parser->fixed_error ('To types count should be equal to transfers count.');
  }
  if ($transfers_count != $substs_count)
  {
    $wrap_parser->fixed_error ('Transfers count should be equal to substs count.');
  }

  my @conversions = ();

  foreach my $index (0 .. $from_types_count - 1)
  {
    if (defined ($from_types->[$index]))
    {
      push (@conversions,
            convert_or_die ($wrap_parser,
                            $from_types->[$index],
                            $to_types->[$index],
                            $transfers->[$index],
                            $substs->[$index]));
    }
    else
    {
# TODO: consider using C++11 nullptr
      push (@conversions,
            join ('', 'static_cast< ', $to_types->[$index], ' >(0)'));
    }
  }

  return join (', ', @conversions);
}

sub deprecate_start ($)
{
  my ($wrap_parser) = @_;
  my $mm_module = $wrap_parser->get_mm_module;

  return (nl '#ifdef ' . (uc $mm_module) . '_DISABLE_DEPRECATED') .
         (nl);
}

sub deprecate_end ($)
{
  my ($wrap_parser) = @_;
  my $mm_module = $wrap_parser->get_mm_module;

  return (nl '#endif // ' . (uc $mm_module) . '_DISABLE_DEPRECATED') .
         (nl);

}

sub generate_include_variable ($)
{
  my ($include) = @_;
  my $variable = $include;
  $variable =~ s#[/.-]#_#g;

  return join '_', 'FLAG', (uc $variable), 'BOOL_VARIABLE';
}

sub already_included ($$)
{
  my ($wrap_parser, $include) = @_;
  my $variable = generate_include_variable $include;
  my $section_manager = $wrap_parser->get_section_manager;
  my $value = $section_manager->get_variable ($variable);

  unless ($value)
  {
    $section_manager->set_variable ($variable, 1);
    return 0;
  }
  return 1;
}

sub get_types_permutations;

sub get_types_permutations
{
  my ($param_types, $param_nullables, $index) = @_;

  unless (defined ($index))
  {
    $index = 0;
  }

  my $count = @{$param_types};

  unless ($count)
  {
    return [[]];
  }

  if ($index == $count - 1)
  {
    my $permutations = [[$param_types->[$index]]];

    if ($param_nullables->[$index])
    {
      push (@{$permutations}, [undef]);
    }

    return $permutations;
  }

  my $tail_permutations = get_types_permutations ($param_types, $param_nullables, $index + 1);

  if ($param_nullables->[$index])
  {
    my $permutations = [];

    foreach my $tail_permutation (@{$tail_permutations})
    {
      push (@{$permutations}, [$param_types->[$index],
                               @{$tail_permutation}]);
    }

    foreach my $tail_permutation (@{$tail_permutations})
    {
      push (@{$permutations}, [undef,
                               @{$tail_permutation}]);
    }

    return $permutations;
  }
  else
  {
    foreach my $tail_permutation (@{$tail_permutations})
    {
      unshift (@{$tail_permutation}, $param_types->[$index]);
    }

    return $tail_permutations;
  }
}

1; # indicate proper module load.
