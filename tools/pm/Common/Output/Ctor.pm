# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Ctor module
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

package Common::Output::Ctor;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

# TODO: This should be moved to Shared. Here should be a function usable from WrapParser.
sub initially_unowned_sink ($)
{
  my ($wrap_parser) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DERIVES_INITIALLY_UNOWNED;
  my $code_string = (nl '  if (gobject && g_object_is_floating(gobject_))') .
                    (nl '  {') .
                    (nl '    g_object_ref_sink(gobject_); // Stops it from being floating.') .
                    (nl '  }');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  return $conditional;
}

sub ctor_default ($)
{
  my ($wrap_parser) = @_;
  my $cxx_type = Common::Output::Shared::get_cxx_type $wrap_parser;

  unless (defined $cxx_type)
  {
# TODO: warn.
    return;
  }

  my $code_string = nl $cxx_type, '();';
  my $main_section = $wrap_parser->get_main_section;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $conditional = initially_unowned_sink $wrap_parser;

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl $full_cxx_type, '::', $cxx_type, '()') .
                 (nl ':') .
                 (nl '  // Mark this class as non-derived to allow C++ vfuncs to be skipped.') .
                 (nl '  Glib::ObjectBase(0),') .
                 (nl '  CppParentType(Glib::ConstructParams(get_static_cpp_class_type_instance().init()))') .
                 (nl '{');
# TODO: There is SECTION_CC_INITIALIZE_CLASS_EXTRA imported. Check if it is needed.
  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);
  $section_manager->append_conditional ($conditional);
  $code_string = (nl '}') .
                 (nl);
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub wrap_ctor ($$$$$$$)
{
  my ($wrap_parser, $c_param_types, $c_param_transfers, $c_prop_names, $cxx_param_types, $cxx_param_names, $cxx_param_values) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cxx_type = Common::Output::Shared::get_cxx_type $wrap_parser;
  my $cxx_params_str_h = Common::Output::Shared::paramzipstr ($cxx_param_types, $cxx_param_names, $cxx_param_values);
  my $cxx_params_str_cc = Common::Output::Shared::paramzipstr ($cxx_param_types, $cxx_param_names);
  my $code_string = (nl 'explicit ', $cxx_type, '(', $cxx_params_str_h, ');') .
                    (nl);
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $conditional = initially_unowned_sink $wrap_parser;
  my $ctor_params_str = '';

  if (@{$c_prop_names} > 0)
  {
# TODO: consider using C++11 nullptr
    $ctor_params_str = join (', ', '', (map { join ('', '"', $c_prop_names->[$_], '", ', Common::Output::Shared::convert_or_die ($wrap_parser, $cxx_param_types->[$_], $c_param_types->[$_], $c_param_transfers->[$_], $cxx_param_names->[$_])); } 0 .. (@{$cxx_param_types} - 1)), 'static_cast<char*>(0)');
  }

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl $full_cxx_type, '::', $cxx_type, '(', $cxx_params_str_cc, ')') .
                 (nl ':') .
                 (nl '  // Mark this class as non-derived to allow C++ vfuncs to be skipped.') .
                 (nl '  Glib::ObjectBase(0),') .
                 (nl '  CppParentType(Glib::ConstructParams(get_static_cpp_class_type_instance().init()', $ctor_params_str, '))') .
                 (nl '{');
# TODO: There is SECTION_CC_INITIALIZE_CLASS_EXTRA imported. Check if it is needed.
  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);
  $section_manager->append_conditional ($conditional);
  $code_string = (nl '}') .
                 (nl);
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub wrap_create ($$$$)
{
  my ($wrap_parser, $cxx_param_types, $cxx_param_names, $cxx_param_values) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $cxx_type = Common::Output::Shared::get_cxx_type $wrap_parser;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $cxx_params_str_h = Common::Output::Shared::paramzipstr ($cxx_param_types, $cxx_param_names, $cxx_param_values);
  my $cxx_params_str_cc = Common::Output::Shared::paramzipstr ($cxx_param_types, $cxx_param_names);
  my $cxx_names_str = join ', ', @{$cxx_param_names};
  my $code_string = (nl 'static Glib::RefPtr< ', $cxx_type, ' > create(', $cxx_params_str_h, ');');

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl 'Glib::RefPtr< ', $full_cxx_type, ' > ', $full_cxx_type, '::create(', $cxx_params_str_cc, ')') .
                 (nl '{') .
                 (nl '  return Glib::RefPtr< ', $cxx_type, ' >(new ', $cxx_type, '(', $cxx_names_str, '));') .
                 (nl '}') .
                 (nl);
  $section_manager->append_string_to_section ($code_string, $section);
}

1; # indicate proper module load.
