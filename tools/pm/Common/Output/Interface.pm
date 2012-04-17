# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Interface module
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

package Common::Output::Interface;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_before_first_namespace ($$$)
{
  my ($wrap_parser, $c_type, $c_class_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $conditional = Common::Output::Shared::struct_prototype $wrap_parser, $c_type, $c_class_type;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_BEFORE_FIRST_NAMESPACE;

  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);

  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $code_string = nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                    nl () .
                    nl ('class ' . $cpp_class_type . ';') .
                    nl () .
                    nl (Common::Output::Shared::close_namespaces $wrap_parser) .
                    nl ();

  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_h_in_class ($$$$)
{
  my ($wrap_parser, $c_type, $c_class_type, $cpp_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $base_member = lc ($cpp_class_type) . '_';
  my $virtual_dtor = 1;
  my $copy_proto = 'no';
  my $reinterpret = 1;
  my $definitions = 1;
  my $code_string = nl () .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl () .
                    nl ('public:') .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $cpp_class_type . ' CppClassType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl ('  typedef ' . $c_class_type . ' BaseClassType;') .
                    nl () .
                    nl ('private:') .
                    nl ('  friend class ' . $cpp_class_type . ';') .
                    nl ('  static CppClassType ' . $base_member . ';') .
                    nl () .
                    nl ('  // noncopyable') .
                    nl (Common::Output::Shared::copy_protos_str $cpp_type) .
                    nl () .
                    nl ('protected:') .
                    nl ('  ' . $cpp_type . '(); // You must derive from this class.') .
                    nl () .
                    nl ('  /** Called by constructors of derived classes. Provide the result of') .
                    nl ('   * the Class init() function to ensure that it is properly') .
                    nl ('   * initialized.') .
                    nl ('   *') .
                    nl ('   * @param interface_class The Class object for the derived type.') .
                    nl ('   */') .
                    nl ('  explicit ' . $cpp_type . '(const Glib::Interface_class& interface_class);') .
                    nl () .
                    nl ('public:') .
                    nl ('  // This is public so that C++ wrapper instances can be') .
                    nl ('  // created for C instances of unwrapped types.') .
                    nl ('  // For instance, if an unexpected C type implements the C interface.') .
                    nl ('  explicit ' . $cpp_type . '(' . $c_type . '* castitem);') .
                    nl () .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl () .
                    nl ('public:') .
                    nl (Common::Output::Shared::dtor_proto_str $cpp_type, $virtual_dtor) .
                    nl () .
                    nl ('  static void add_interface(GType gtype_implementer);') .
                    nl () .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  static GType get_type() G_GNUC_CONST;') .
                    nl ('  static GType get_base_type() G_GNUC_CONST;') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl () .
                    nl (Common::Output::Shared::gobj_protos_str $c_type, $copy_proto, $reinterpret, $definitions) .
                    nl () .
                    nl ('private:') .
                    nl ('  // import section_class2?') .
                    nl () .
                    nl ('public:') .
                    nl ('  // import H_VFUNCS_AND_SIGNALS()') .
                    nl ();
  my $main_section = $wrap_parser->get_main_section;

  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub _output_h_after_first_namespace ($$)
{
  my ($wrap_parser, $c_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $result_type = 'refptr';
  my $take_copy_by_default = 'no';
  my $open_glib_namespace = 1;
  my $const_function = 0;
  my $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_NAMESPACE;

  $section_manager->append_conditional_to_section ($conditional, $section);
}

sub _output_p_h ($$$$)
{
  my ($wrap_parser, $c_type, $c_class_type, $cpp_parent_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $cpp_parent_class_type = $cpp_parent_type . '::CppClassType';
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $code_string = nl ('#include <glibmm/private/interface_p.h>') .
                    nl () .
                    nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                    nl () .
                    nl ('class ' . $cpp_class_type . ' : public ' . $cpp_parent_class_type) .
                    nl ('{') .
                    nl ('public:') .
                    nl ('  typedef ' . $full_cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl ('  typedef ' . $c_class_type . ' BaseClassType;') .
                    nl ('  typedef ' . $cpp_parent_class_type . ' CppClassParent;') .
                    nl () .
                    nl ('  friend class ' . $full_cpp_type . ';') .
                    nl () .
                    nl ('  const Glib::Interface_Class& init();') .
                    nl () .
                    nl ('  static void iface_init_function(void* g_iface, void* iface_data);') .
                    nl () .
                    nl ('  static Glib::ObjectBase* wrap_new(GObject*);') .
                    nl () .
                    nl ('protected:') .
                    nl ('  // Callbacks (default signal handlers):') .
                    nl ('  // These will call the *_impl member methods, which will then call the existing default signal callbacks, if any.') .
                    nl ('  // You could prevent the original default signal handlers being called by overriding the *_impl method.');
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_GENERATED;

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_DEFAULT_SIGNAL_HANDLERS;
  $section_manager->append_section ($section);
  $code_string = nl () .
                 nl () .
                 nl ('  // Callbacks (virtual functions):');
  $section_manager->append_string ($code_string);
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_VFUNCS;
  $section_manager->append_section ($section);
  $code_string = nl () .
                 nl ('};') .
                 nl () .
                 nl (Common::Output::Shared::close_namespaces $wrap_parser) .
                 nl ();
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_cc ($$$$$$)
{
  my ($wrap_parser, $c_type, $c_parent_type, $cpp_type, $cpp_parent_type, $get_type_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $conditional = Common::Output::Shared::generate_conditional $wrap_parser;
  my $no_wrap_function_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $complete_cpp_type = Common::Output::Shared::get_complete_cpp_type $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_GENERATED;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('Glib::RefPtr< ' . $complete_cpp_type . '> wrap(' . $c_type . '* object, bool take_copy)') .
                    nl ('{') .
                    nl ('  return Glib::RefPtr< ' . $complete_cpp_type . ' >(dynamic_cast< ' . $complete_cpp_type . '* >(Glib::wrap_auto_interface< ' . $complete_cpp_type . ' >(static_cast<GObject*>(object), take_copy)));') .
                    nl ('  // We use dynamic_cast<> in case of multiple inheritance.') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl ();

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($no_wrap_function_var, $conditional);

  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $base_member = lc ($cpp_class_type) . '_';
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;

  $code_string = nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                 nl ($full_cpp_type . '::' . $cpp_type . '()') .
                 nl (':') .
                 nl ('  ' . $cpp_parent_type . '(' . $base_member . '.init())') .
                 nl ('{}') .
                 nl () .
                 nl ($full_cpp_type . '::' . $cpp_type . '(' . $c_type . '* castitem)') .
                 nl (':') .
                 nl ('  ' . $cpp_parent_type . '(static_cast< ' . $c_parent_type . '* >(castitem))') .
                 nl ('{}') .
                 nl () .
                 nl ($full_cpp_type . '::' . $cpp_type . '(const Glib::Interface_Class& interface_class)') .
                 nl (':') .
                 nl ('  ' . $cpp_parent_type . '(interface_class)') .
                 nl ('{}') .
                 nl () .
                 nl ($full_cpp_type . '::~' . $cpp_type . '()') .
                 nl ('{}') .
                 nl () .
                 nl ('// static') .
                 nl ('void ' . $full_cpp_type . '::add_interface(GType gtype_implementer)') .
                 nl ('{') .
                 nl ('  ' . $base_member . '.init().add_interface(gtype_implementer);') .
                 nl ('}') .
                 nl () .
                 nl ($full_cpp_type . '::CppClassType ' . $full_cpp_type . '::' . $base_member . '; // initialize static member') .
                 nl () .
                 nl ('GType ' . $full_cpp_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . $base_member . '.init().get_type();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
# TODO: move to Shared?
  $code_string = nl ($full_cpp_type . '::CppClassType ' . $full_cpp_type . '::' . $base_member . '; // Initialize static member') .
                 nl () .
                 nl ('GType ' . $full_cpp_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . $base_member . '.init().get_type();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  $code_string = nl ('GType ' . $full_cpp_type . '::get_type(GTypeModule* module)') .
                 nl ('{') .
                 nl ('  return ' . $base_member . '.init(module).get_type();') .
                 nl ('}') .
                 nl ();

  my $dynamic_gtype_registration_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DYNAMIC_GTYPE_REGISTRATION;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_var, $conditional);
  $code_string = nl ('GType ' . $full_cpp_type . '::get_base_type()') .
                 nl ('{') .
                 nl ('  return ' . $get_type_func . '();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);

  my @sections =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_SIGNAL_PROXIES),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_PROPERTY_PROXIES),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_DEFAULT_SIGNAL_HANDLERS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_VFUNCS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_VFUNCS_CPP_WRAPPER),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_NAMESPACE)
  );

  foreach my $cc_section (@sections)
  {
    $section_manager->append_section ($cc_section);
    $section_manager->append_string (nl);
  }

  $section_manager->append_string (Common::Output::Shared::close_namespaces ($wrap_parser));
  $section_manager->pop_entry;
}

sub _output_p_cc ($$$)
{
  my ($wrap_parser, $c_type, $get_type_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $cpp_class_type = Common::Output::Shared::get_class_type $wrap_parser;
  my $code_string = nl ('const Glib::Interface_Class& ' . $cpp_class_type . '::init()') .
                    nl ('{') .
                    nl ('  if (!gtype) // create GType if necessary.') .
                    nl ('  {') .
                    nl ('    // Glib::Interface_Class has to know the interface init function') .
                    nl ('    // in order to add interfaces to implementing types') .
                    nl ('    class_init_func_ = &' . $cpp_class_type . '::iface_init_function;') .
                    nl () .
                    nl ('    // We can not derive from another interface and it is not necessary anyway.') .
                    nl ('    gtype_ = ' . $get_type_func . '();') .
                    nl ('  }') .
                    nl () .
                    nl ('  return *this;') .
                    nl ('}') .
                    nl () .
                    nl ('void ' . $cpp_class_type . '::iface_init_function(void* g_iface, void*)') .
                    nl ('{') .
                    nl ('  BaseClassType* const klass(static_cast<BaseClassType*>(g_iface));') .
                    nl () .
                    nl ('  // This is just to avoid an "unused variable" warning when there are no vfuncs or signal handlers to connect.') .
                    nl ('  // This is a temporary fix until I find out why I can not seem to derive a GtkFileChooser interface. murrayc') .
                    nl ('  g_assert(klass != 0);') .
                    nl ();
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_NAMESPACE;
  my @cc_sections_inside_func =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_VFUNCS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_DEFAULT_SIGNAL_HANDLERS),
  );
  my @cc_sections_outside_func =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_VFUNCS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_DEFAULT_SIGNAL_HANDLERS)
  );

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);

  foreach my $cc_section (@cc_sections_inside_func)
  {
    $section_manager->append_section ($cc_section);
    $section_manager->append_string (nl);
  }

  $code_string = nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);

  foreach my $cc_section (@cc_sections_outside_func)
  {
    $section_manager->append_section ($cc_section);
    $section_manager->append_string (nl);
  }

  $code_string = nl ('Glib::ObjectBase* ' . $cpp_class_type . '::wrap_new(GObject* object)') .
                 nl ('{') .
                 nl ('  return new ' . $full_cpp_type . '(static_cast< ' . $c_type .' >(object));') .
                 nl ('}');
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub output ($$$$$$$)
{
  my ($wrap_parser, $c_type, $c_class_type, $c_parent_type, $cpp_type, $cpp_parent_type, $get_type_func) = @_;

  _output_h_before_first_namespace $wrap_parser, $c_type, $c_class_type;
  _output_h_in_class $wrap_parser, $c_type, $c_class_type, $cpp_type;
  _output_h_after_first_namespace $wrap_parser, $c_type;
  _output_p_h $wrap_parser, $c_type, $c_class_type, $cpp_parent_type;
  _output_cc $wrap_parser, $c_type, $c_parent_type, $cpp_type, $cpp_parent_type, $get_type_func;
  _output_cc_p $wrap_parser, $c_type, $get_type_func;
}

1; # indicate proper module load.
