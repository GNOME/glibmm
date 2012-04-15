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
  my $cpp_type = Common::Output::Shared::get_cpp_type $wrap_parser;

  unless (defined $cpp_type)
  {
# TODO: warn.
    return;
  }

  my $code_string = nl $cpp_type, '();';
  my $main_section = $wrap_parser->get_main_section;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $base_member = (lc $cpp_class_type) . '_';
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $conditional = initially_unowned_sink $wrap_parser;

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl $full_cpp_type, '::', $cpp_type, '()') .
                 (nl ':') .
                 (nl '  // Mark this class as non-derived to allow C++ vfuncs to be skipped.') .
                 (nl '  Glib::ObjectBase(0),') .
                 (nl '  CppParentType(Glib::ConstructParams(', $base_member, '.init()))') .
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

sub wrap_ctor ($$$$$$)
{
  my ($wrap_parser, $c_param_types, $c_param_transfers, $c_prop_names, $cpp_param_types, $cpp_param_names) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cpp_type = Common::Output::Shared::get_cpp_type $wrap_parser;
  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;
  my $code_string = (nl 'explicit ', $cpp_type, '(', $cpp_params_str, ');') .
                    (nl);
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $base_member = (lc $cpp_class_type) . '_';
  my $conditional = initially_unowned_sink $wrap_parser;
  my $conversions_store = $wrap_parser->get_conversions_store;
  my $ctor_params_str = join ', ', '', (map { join '', '"', $c_prop_names->[$_], '"', $conversions_store->get_conversion ($cpp_param_types->[$_], $c_param_types->[$_], $c_param_transfers->[$_], $cpp_param_names->[$_]) } 0 .. (@{$cpp_param_types} - 1)), 'static_cast<char*>(0)';

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl $full_cpp_type, '::', $cpp_type, '(', $cpp_params_str, ')') .
                 (nl ':') .
                 (nl '  // Mark this class as non-derived to allow C++ vfuncs to be skipped.') .
                 (nl '  Glib::ObjectBase(0),') .
                 (nl '  CppParentType(Glib::ConstructParams(', $base_member, '.init()', $ctor_params_str, '))') .
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

sub wrap_create ($$$)
{
  my ($wrap_parser, $cpp_param_types, $cpp_param_names) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $cpp_type = Common::Output::Shared::get_cpp_type $wrap_parser;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;
  my $cpp_names_str = join ', ', @{$cpp_param_names};
  my $code_string = (nl 'static Glib::RefPtr< ', $cpp_type, ' > create(', $cpp_params_str, ')');

  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = (nl 'Glib::RefPtr< ', $full_cpp_type, ' > ', $full_cpp_type, '::create(', $cpp_params_str, ')') .
                 (nl '{') .
                 (nl '  return Glib::RefPtr< ', $cpp_type, ' >(new ', $cpp_type, '(', $cpp_names_str, '));') .
                 (nl '}') .
                 (nl);
  $section_manager->append_string_to_section ($code_string, $section);
}

1; # indicate proper module load.
