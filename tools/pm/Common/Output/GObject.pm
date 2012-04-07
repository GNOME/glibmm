# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::GObject module
#
# Copyright 2011, 2012 glibmm development team
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

package Common::Output::GObject;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_before_namespace ($$$)
{
  my ($wrap_parser, $c_type, $c_class_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $subconditional = Common::Output::Shared::struct_prototype $wrap_parser, $c_type, $c_class_type;
  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_BEFORE_FIRST_NAMESPACE;

  $section_manager->append_conditional_to_conditional ($subconditional, $conditional, 0);
  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);
  my $code_string = Common::Output::Shared::open_namespaces ($wrap_parser) .
                    nl ('class ' . $cpp_class_type . ';') .
                    Common::Output::Shared::close_namespaces ($wrap_parser) .
                    nl ();
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_h_in_class ($$$$$$)
{
  my ($wrap_parser, $c_type, $c_parent_type, $c_class_type, $cpp_type, $cpp_parent_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $code_string = nl (Common::Output::Shared::doxy_skip_begin) .
                    nl () .
                    nl ('public:') .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $cpp_class_type . ' CppClassType;') .
                    nl ('  typedef ' . $cpp_parent_type . ' CppParentType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl ('  typedef ' . $c_class_type . ' BaseClassType;') .
                    nl ('  typedef ' . $c_parent_type . ' BaseParentType;') .
                    nl ();

  $section_manager->push_section ($main_section);
  $section_manager->append_string ($code_string);

  my $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::PROTECTED_GCLASS;
  my $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  $code_string = nl ('protected:');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('private:');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  my $virtual_dtor = 1;
  my $base_member = lc ($cpp_class_type) . '_';

  $code_string = nl ('  friend class ' . $cpp_class_type . ';') .
                 nl ('  static CppClassType ' . $base_member . '_;') .
                 nl () .
                 nl ('private:') .
                 nl ('  // noncopyable') .
                 nl (Common::Output::Shared::copy_protos_str $cpp_type) .
                 nl () .
                 nl ('protected:') .
                 nl ('  explicit ' . $cpp_type . '(const Glib::ConstructParams& construct_params);') .
                 nl ('  explicit ' . $cpp_type . '(' . $c_type . '* castitem);') .
                 nl () .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('public:') .
                 nl (Common::Output::Shared::dtor_proto_str $cpp_type, $virtual_dtor) .
                 nl () .
                 nl (Common::Output::Shared::doxy_skip_begin) .
                 nl ('  static GType get_type() G_GNUC_CONST;');
  $section_manager->append_string ($code_string);
  $code_string = nl ('  static GType get_type(GTypeModule* module) G_GNUC_CONST');
  $variable = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DYNAMIC_GTYPE_REGISTRATION;
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($variable, $conditional);

  my $copy_proto = 'no';
  my $reinterpret = 1;
  my $definitions = 1;

  $code_string = nl ('  static GType get_base_type() G_GNUC_CONST;') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl (Common::Output::Shared::gobj_protos_str $c_type, $copy_proto, $reinterpret, $definitions) .
                 nl () .
                 nl ('private:');
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_h_after_namespace ($$)
{
  my ($wrap_parser, $c_type) = @_;
  my $result_type = 'refptr';
  my $take_copy_by_default = 'no';
  my $open_glib_namespace = 1;
  my $const_function = 0;
  my $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;
  my $section_manager = $wrap_parser->get_section_manager;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_NAMESPACE;

  $section_manager->append_conditional_to_section ($conditional, $section);
}

sub _output_p_h ($$$$$)
{
  my ($wrap_parser, $c_type, $c_class_type, $c_parent_class_type, $cpp_parent_type) = @_;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $cpp_parent_class_type = $cpp_parent_type . '::CppClassType';
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = nl ('#include <glibmm/class.h>') .
                    nl () .
                    Common::Output::Shared::open_namespaces ($wrap_parser) .
                    nl () .
                    nl ('class ' . $cpp_class_type . ' : public Glib::Class') .
                    nl ('{') .
                    nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $full_cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;');
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_CONTENTS;

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);

  my $do_not_derive_gtype_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DO_NOT_DERIVE_GTYPE;
  my $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  $code_string = nl ('  typedef ' . $cpp_parent_class_type . ' CppClassParent;');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('  typedef ' . $c_class_type . ' BaseClassType;') .
                 nl ('  typedef ' . $cpp_parent_class_type . ' CppClassParent;') .
                 nl ('  typedef ' . $c_parent_class_type . ' BaseClassParent;');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_var, $conditional);
  $code_string = nl () .
                 nl ('  friend class ' . $full_cpp_type . ';') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('  const Glib::Class& init();') .
                 nl ();
  $section_manager->append_string ($code_string);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  my $dynamic_gtype_registration_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DYNAMIC_GTYPE_REGISTRATION;

  $code_string = nl ('  const Glib::Class& init(GTypeModule* module);');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_var, $conditional);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  $code_string = nl ('  static void class_init_function(void* g_class, void* class_data);');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_var, $conditional);
  $code_string = nl ('  static Glib::ObjectBase* wrap_new(GObject*);') .
                 nl () .
                 nl ('protected:');
  $section_manager->append_string ($code_string);

  my @h_sections =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_DEFAULT_SIGNAL_HANDLERS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_VFUNCS)
  );

  foreach my $h_section (@h_sections)
  {
    $section_manager->append_section ($h_section);
    $section_manager->append_string (nl);
  }

  $code_string = nl ('};') .
                 nl () .
                 Common::Output::Shared::close_namespaces ($wrap_parser);
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry;
}

sub _output_cc ($$$$$$)
{
  my ($wrap_parser, $c_type, $c_parent_type, $get_type_func, $cpp_type, $cpp_parent_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $complete_cpp_type = Common::Output::Shared::get_complete_cpp_type $wrap_parser;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('Glib::RefPtr< ' . $complete_cpp_type . ' > wrap(' . $c_type . '* object, bool take_copy)') .
                    nl ('{') .
                    nl ('  return Glib::RefPtr< ' . $complete_cpp_type . ' >(dynamic_cast< ' . $complete_cpp_type . ' >(Glib::wrap_auto (static_cast< GObject* >(object), take_copy)));') .
                    nl ('  // We use dynamic_cast<> in case of multiple inheritance.') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl ();
  my $no_wrap_function_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::NO_WRAP_FUNCTION;
  my $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_END;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->push_section ($section);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($no_wrap_function_var, $conditional);
  $code_string = Common::Output::Shared::open_namespaces ($wrap_parser) .
                 nl ($c_type . '* ' . $full_cpp_type . '::gobj_copy()') .
                 nl ('{') .
                 nl ('  reference();') .
                 nl ('  return gobj();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  my $custom_ctor_cast_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_CTOR_CAST;

  $code_string = nl ($full_cpp_type . '::' . $cpp_type . '(const Glib::ConstructParams& construct_params)') .
                 nl (':') .
                 nl ('  ' . $cpp_parent_type . '(construct_params)') .
                 nl ('{');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);

  my $subconditional = Common::Output::Ctor::initially_unowned_sink $wrap_parser;

  $section_manager->append_conditional_to_conditional ($subconditional, $conditional, 0);
  $code_string = nl ('}') .
                 nl () .
                 nl ($full_cpp_type . '::' . $cpp_type . '(' . $c_type . '* castitem)') .
                 nl (':') .
                 nl ('  ' . $cpp_parent_type . '(static_cast< ' . $c_parent_type . '* >(castitem))') .
                 nl ('{}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($custom_ctor_cast_var, $conditional);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  my $custom_dtor_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_DTOR;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;

  $code_string = nl ($full_cpp_type . '::~' . $cpp_type . '()') .
                 nl ('{}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($custom_dtor_var, $conditional);

  my $base_member = lc ($cpp_class_type) . '_';

# TODO: move to Shared?
  $code_string = nl ($full_cpp_type . '::CppClassType ' . $full_cpp_type . '::' . $base_member . '; // Initialize static member') .
                 nl () .
                 nl ('GType ' . $full_cpp_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . $base_member . '_.init().get_type();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  $code_string = nl ('GType ' . $full_cpp_type . '::get_type(GTypeModule* module)') .
                 nl ('{') .
                 nl ('  return ' . $base_member . '_.init(module).get_type();') .
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
}

sub _output_p_cc ($$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, $get_type_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $full_cpp_class_type = Common::Output::Shared::get_full_cpp_class_type $wrap_parser;
  my $code_string = nl ('const Glib::Class& ' . $full_cpp_class_type . '::init()') .
                    nl ('{') .
                    nl ('  if (!gtype_) // create the GType if necessary') .
                    nl ('  {');
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_NAMESPACE;

  $section_manager->push_section ($section);
  $section_manager->append_string ($code_string);

  my $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  my $do_not_derive_gtype_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DO_NOT_DERIVE_GTYPE;

  $code_string = nl ('    gtype_ = CppClassParent::CppObjectType::get_type();');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('    // Glib::Class has to know the class init function to clone custom types.') .
                 nl ('    class_init_func_ = &' . $full_cpp_class_type . '::class_init_function;') .
                 nl () .
                 nl ('    // This is actually just optimized away, apparently with no harm.') .
                 nl ('    // Make sure that the parent type has been created.') .
                 nl ('    //CppClassParent::CppObjectType::get_type();') .
                 nl () .
                 nl ('    // Create the wrapper type, with the same class/instance size as the base type.') .
                 nl ('    register_derived_type(' . $get_type_func . '());') .
                 nl () .
                 nl ('    // Add derived versions of interfaces, if the C type implements any interfaces:');
  $section_manager->push_conditional ($conditional, 0);
  $section_manager->append_string ($code_string);
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_IMPLEMENTS_INTERFACES;
  $section_manager->append_section ($section);
  $section_manager->append_string (nl);
  $section_manager->pop_entry;
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_var, $conditional);
  $code_string = nl ('  }') .
                 nl () .
                 nl ('  return *this;') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  my $dynamic_gtype_registration_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::DYNAMIC_GTYPE_REGISTRATION;

  $code_string = nl ('const Glib::Class& ' . $full_cpp_class_type . '::init(GTypeModule* module)') .
                 nl ('{') .
                 nl ('  if (!gtype_) // create the GType if necessary') .
                 nl ('  {');
  $section_manager->push_conditional ($conditional, 1);
  $section_manager->append_string ($code_string);

  my $subconditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  $code_string = nl ('    // Do not derive a GType, or use a derived klass:') .
                 nl ('    gtype_ = CppClassParent::CppObjectType::get_type();');
  $section_manager->append_string_to_conditional ($code_string, $subconditional, 1);
  $code_string = nl ('    // Glib::Class has to know the class init function to clone custom types.') .
                 nl ('    class_init_func_ = &' . $full_cpp_class_type . '::class_init_function;') .
                 nl () .
                 nl ('    // This is actually just optimized away, apparently with no harm.') .
                 nl ('    // Make sure that the parent type has been created.') .
                 nl ('    //CppClassParent::CppObjectType::get_type();') .
                 nl () .
                 nl ('    // Create the wrapper type, with the same class/instance size as the base type.') .
                 nl ('    register_derived_type(' . $get_type_func . '(), module);') .
                 nl () .
                 nl ('    // Add derived versions of interfaces, if the C type implements any interfaces:');
  $section_manager->push_conditional ($subconditional, 1);
  $section_manager->append_string ($code_string);
  $section_manager->append_section ($section);
  $section_manager->append_string (nl);
  $section_manager->pop_entry; # subconditional, 1
  $section_manager->append_conditional ($subconditional);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_var, $subconditional);
  $code_string = nl ('  }') .
                 nl () .
                 nl ('  return *this;') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry; # conditional, 1
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_var, $conditional);
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);
  $code_string = nl ('void ' . $full_cpp_class_type . '::class_init_function(void* g_class, void* class_data)') .
                 nl ('{') .
                 nl ('  BaseClassType* const klass = static_cast< BaseClassType* >(g_class);') .
                 nl ('  CppClassParent::class_init_function(klass, class_data);') .
                 nl ();
  $section_manager->push_conditional ($conditional, 0);
  $section_manager->append_string ($code_string);

  my @p_cc_sections_inside_func =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_VFUNCS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_DEFAULT_SIGNAL_HANDLERS)
  );

  foreach my $p_cc_section (@p_cc_sections_inside_func)
  {
    $section_manager->append_section ($section);
    $section_manager->append_string (nl);
  }
  $code_string = nl ('}') .
                 nl ();
  $section_manager->append_string ($code_string);
  $section_manager->pop_entry; # conditional, 0
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_var, $conditional);

  my @p_cc_sections_outside_func =
  (
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_VFUNCS),
    (Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_DEFAULT_SIGNAL_HANDLERS)
  );

  foreach my $p_cc_section (@p_cc_sections_outside_func)
  {
    $section_manager->append_section ($section);
    $section_manager->append_string (nl);
  }

  $code_string = nl ('Glib::ObjectBase* ' . $full_cpp_class_type . '::wrap_new(GObject* object)') .
                 nl ('{') .
                 nl ('  return new ' . $full_cpp_type . '(static_cast< ' . $c_type . '* >(object));') .
                 nl ('}') .
                 nl ();
  $conditional = Common::Output::Shared::generate_conditional ($wrap_parser);

  my $custom_wrap_new_var = Common::Output::Shared::get_variable $wrap_parser, Common::Variables::CUSTOM_WRAP_NEW;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional ($conditional);
  $section_manager->set_variable_for_conditional ($custom_wrap_new_var, $conditional);
  $section_manager->append_string (Common::Output::Shared::close_namespaces $wrap_parser);
  $section_manager->pop_entry;
}

sub output ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_class_type, $c_parent_type, $c_parent_class_type, $get_type_func, $cpp_type, $cpp_parent_type) = @_;

  _output_h_before_namespace $wrap_parser, $c_type, $c_class_type;
  _output_h_in_class $wrap_parser, $c_type, $c_parent_type, $c_class_type, $cpp_type, $cpp_parent_type;
  _output_h_after_namespace $wrap_parser, $c_type;
  _output_p_h $wrap_parser, $c_type, $c_class_type, $c_parent_class_type, $cpp_parent_type;
  _output_cc $wrap_parser, $c_type, $c_parent_type, $get_type_func, $cpp_type, $cpp_parent_type;
  _output_p_cc $wrap_parser, $c_type, $c_class_type, $get_type_func;
}

sub implements_interface ($$$)
{
  my ($wrap_parser, $interface, $ifdef) = @_;
  my $section_manager = $wrap_parser->get_section_interface;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_IMPLEMENTS_INTERFACES;
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    (nl '  ', $interface, '::add_interface(get_type());') .
                    (Common::Output::Shared::endif $ifdef);

  $section_manager->append_string_to_section ($code_string, $section);
}

1; # indicate proper module load.
