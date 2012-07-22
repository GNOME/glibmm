# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::BoxedType module
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

package Common::Output::BoxedType;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_before_first_namespace ($$$)
{
  my ($wrap_parser, $c_type, $cxx_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_STRUCT_PROTOTYPE;
  my $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  my $code_string = nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('extern "C" { typedef struct _' . $c_type . ' ' . $c_type . '; }') .
                    nl (Common::Output::Shared::doxy_skip_end);
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_BEFORE_FIRST_NAMESPACE;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, $section);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
}

sub _output_h_in_class ($$$)
{
  my ($wrap_parser, $c_type, $cxx_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $code_string = nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cxx_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl () .
                    nl (  'static GType get_type() G_GNUC_CONST;') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();

  $section_manager->push_section ($main_section);
  $section_manager->append_string ($code_string);

  my $conditional = Common::Output::Shared::default_ctor_proto $wrap_parser, $cxx_type;
  my $copy_proto = 'const';
  my $reinterpret = 0;
  my $definitions = 1;
  my $virtual_dtor = 0;

  $section_manager->append_conditional ($conditional);
  $code_string = nl () .
                 nl ('explicit ' . $cxx_type . '(' . $c_type . '* gobject, bool make_a_copy = true);') .
                 nl () .
                 nl (Common::Output::Shared::copy_protos_str $cxx_type) .
                 nl () .
                 nl (Common::Output::Shared::dtor_proto_str $cxx_type, $virtual_dtor) .
                 nl () .
                 nl ('  void swap(' . $cxx_type . '& other);') .
                 nl () .
                 nl (Common::Output::Shared::gobj_protos_str $c_type, $copy_proto, $reinterpret, $definitions) .
                 nl () .
                 nl ('protected:') .
                 nl ('  ' . $c_type . '* gobject_;') .
                 nl () .
                 nl ('private:');
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_h_after_first_namespace ($$$)
{
  my ($wrap_parser, $c_type, $cxx_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_NAMESPACE;
  my $code_string = nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                    nl () .
                    nl ('/** @relates ' . $full_cxx_type) .
                    nl (' *') .
                    nl (' * @param lhs The left-hand side') .
                    nl (' * @param rhs The right-hand side') .
                    nl (' */') .
                    nl ('inline void swap(' . $cxx_type . '& lhs, ' . $cxx_type . '& rhs)') .
                    nl ('{ lhs.swap(rhs); }') .
                    nl () .
                    nl (Common::Output::Shared::close_namespaces $wrap_parser) .
                    nl () .
                    nl ('namespace Glib') .
                    nl ('{') .
                    nl ();

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);

  my $result_type = 'plain';
  my $take_copy_by_default = 'no';
  my $open_glib_namespace = 0;
  my $const_function = 0;
  my $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;

  $section_manager->append_conditional ($conditional);
  $code_string = nl (Common::Output::Shared::doxy_skip_begin) .
                 nl ('template <>') .
                 nl ('class Value< ' . $full_cxx_type . ' > : public Glib::Value_Boxed< ' . $full_cxx_type . ' >') .
                 nl ('{};') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('} // namespace Glib');
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_cc
{
  my ($wrap_parser, $c_type, $cxx_type, $get_type_func, $new_func, $copy_func, $free_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ($full_cxx_type . ' wrap(' . $c_type . '* object, bool take_copy)') .
                    nl ('{') .
                    nl ('  return ' . $full_cxx_type . '(object, take_copy);') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl ();
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_GENERATED;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  $code_string = nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                 nl ('// static') .
                 nl ('GType ' . $cxx_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . $get_type_func . '();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_DEFAULT_CTOR;
  $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  $code_string = nl($cxx_type . '::' . $cxx_type . '()') .
                 nl(':');
  if (defined $new_func and $new_func ne '' and $new_func ne 'NONE')
  {
    $code_string .= nl ('gobject_ (' . $new_func . '())');
  }
  else
  {
    $code_string .= nl ('gobject_ (0) // Allows creation of invalid wrapper, e.g. for output arguments to methods.');
  }
  $code_string .= nl ('{}');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  $code_string = nl ($cxx_type . '::' . $cxx_type . '(const ' . $cxx_type . '& other)') .
                 nl (':') .
                 nl ('  gobject_ ((other.gobject_) ? ' . $copy_func . '(other.gobject_) : 0)') .
                 nl ('{}') .
                 nl () .
                 nl ($cxx_type . '::' . $cxx_type . '(' . $c_type . '* gobject, bool make_a_copy)') .
                 nl (':') .
                 nl ('// For BoxedType wrappers, make_a_copy is true by default. The static') .
                 nl ('// BoxedTyoe wrappers always take a copy, thus make_a_copy = true') .
                 nl ('// ensures identical behaviour if the default argument is used.') .
                 nl ('  gobject_ ((make_a_copy && gobject) ? ' . $copy_func . '(gobject) : gobject)') .
                 nl ('{}') .
                 nl () .
                 nl ($cxx_type . '& ' . $cxx_type . '::operator=(const ' . $cxx_type . '& other)') .
                 nl ('{') .
                 nl ('  ' . $cxx_type . ' temp (other);') .
                 nl ('  swap(temp);') .
                 nl ('  return *this;') .
                 nl ('}') .
                 nl () .
                 nl ($cxx_type . '::~' . $cxx_type . '()') .
                 nl ('{') .
                 nl ('  if (gobject_)') .
                 nl ('    ' . $free_func . '(gobject_);') .
                 nl ('}') .
                 nl () .
                 nl ('void ' . $cxx_type . '::swap(' . $cxx_type . '& other)') .
                 nl ('{') .
                 nl ('  ' . $c_type . '* const temp = gobject_;') .
                 nl ('  gobject_ = other.gobject_;') .
                 nl ('  other.gobject_ = temp;') .
                 nl ('}') .
                 nl () .
                 nl ($c_type . '* ' . $cxx_type . '::gobj_copy() const') .
                 nl ('{') .
                 nl ('  return ' . $copy_func . '(gobject_);') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  $section_manager->append_section ($section);
  $code_string = nl (Common::Output::Shared::close_namespaces $wrap_parser);
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub output ($)
{
  my ($wrap_parser, $c_type, $cxx_type, $get_type_func, $new_func, $copy_func, $free_func) = @_;

  _output_h_before_first_namespace $wrap_parser, $c_type, $cxx_type;
  _output_h_in_class $wrap_parser, $c_type, $cxx_type;
  _output_h_after_first_namespace $wrap_parser, $c_type, $cxx_type;
  _output_cc $wrap_parser, $c_type, $cxx_type, $get_type_func, $new_func, $copy_func, $free_func;
}

1; # indicate proper module load.
