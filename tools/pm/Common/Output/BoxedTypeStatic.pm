# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::BoxedTypeStatic module
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

package Common::Output::BoxedTypeStatic;

use strict;
use warnings;

use Common::Output::Shared;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_in_class ($$$)
{
  my ($wrap_parser, $c_type, $cpp_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cpp_type . 'CppObjectType;') .
                    nl ('  typedef ' . $c_type . 'BaseObjectType;') .
                    nl () .
                    nl ('  static GType get_type() G_GNUC_CONST') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();
  my $main_section = $wrap_parser->get_main_section;

  $section_manager->push_section ($main_section);
  $section_manager->append_string ($code_string);

  my $conditional = Common::Output::Shared::default_ctor_proto $wrap_parser, $cpp_type;

  $section_manager->append_conditional ($conditional);

  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_CTOR_CAST;

  $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  $code_string = nl ('  explicit ' . $cpp_type . '(const ' . $c_type . '* gobject); // always takes a copy');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  my $copy_proto = 'no';
  my $reinterpret = 0;
  my $definitions = 1;

  $code_string = nl (Common::Output::Shared::gobj_protos_str $c_type, $copy_proto, $reinterpret, $definitions) .
                 nl () .
                 nl ('protected:') .
                 nl ('  ' . $c_type . ' gobject_;') .
                 nl () .
                 nl ('private:');
  $section_manager->append_string ($code_string, $main_section);
  $section_manager->pop_entry;
}

sub _output_h_after_namespace ($$$)
{
  my ($wrap_parser, $c_type, $cpp_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = nl ('namespace Glib') .
                    nl ('{');
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_NAMESPACE;

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);

  my $result_type = 'ref';
  my $take_copy_by_default = 'N/A';
  my $open_glib_namespace = 0;
  my $const_function = 0;
  my $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;
  $section_manager->append_conditional ($conditional);
  $const_function = 1;
  $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;
  $section_manager->append_conditional ($conditional);

  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type ($wrap_parser);

  $code_string = nl () .
                 nl (Common::Output::Shared::doxy_skip_begin) .
                 nl ('template <>') .
                 nl ('class Value< ' . $full_cpp_type . ' > : public Glib::Value_Boxed< ' . $full_cpp_type . ' >') .
                 nl ('{};') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('} // namespace Glib') .
                 nl ();
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_cc ($$$$)
{
  my ($wrap_parser, $c_type, $cpp_type, $get_type_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $complete_cpp_type = Common::Output::Shared::get_complete_cpp_type $wrap_parser;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ($complete_cpp_type . '& wrap(' . $c_type . '* object)') .
                    nl ('{') .
                    nl ('  return *reinterpret_cast< ' . $complete_cpp_type . '* >(object);') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl ();
  my $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_END;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  $code_string = nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                 nl ('// static') .
                 nl ('GType ' . $full_cpp_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . $get_type_func . '();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_DEFAULT_CTOR;
  $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  $code_string = nl ($full_cpp_type . '::' . $cpp_type . '()') .
                 nl ('{') .
                 nl ('  GLIBMM_INITIALIZE_STRUCT(gobject_, ' . $c_type . ');') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_CTOR_CAST;
  $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  $code_string = nl ($full_cpp_type . '::' . $cpp_type . '(const ' . $c_type . '* gobject)') .
                 nl ('{') .
                 nl ('  if (gobject)') .
                 nl ('  {') .
                 nl ('    gobject_ = *gobject;') .
                 nl ('  }') .
                 nl ('  else') .
                 nl ('  {') .
                 nl ('    GLIBMM_INITIALIZE_STRUCT(gobject_, ' . $c_type . ');') .
                 nl ('  }') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  $section_manager->append_section ($section);
  $code_string = nl () .
                 nl (Common::Output::Shared::close_namespaces $wrap_parser);
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub output ($$$$)
{
  my ($wrap_parser, $c_type, $cpp_type, $get_type_func) = @_;

  _output_h_in_class $wrap_parser, $c_type, $cpp_type;
  _output_h_after_namespace $wrap_parser, $c_type, $cpp_type;
  _output_cc $wrap_parser, $c_type, $cpp_type, $get_type_func;
}

1; # indicate proper module load.
