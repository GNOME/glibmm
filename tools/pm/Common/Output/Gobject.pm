# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Gobject module
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

package Common::Output::Gobject;

use strict;
use warnings;

use Common::Output::Shared;
use Common::SectionManager;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_in_class ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, undef, undef, undef, $cpp_type, undef) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $namespaces = $wrap_parser->get_namespaces;
  my $cpp_type_class = $cpp_type . '_Class';
  my $code_string = nl (Common::Output::Shared::doxy_skip_begin) .
                    nl () .
                    nl ('public:') .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $cpp_type_class . ' CppClassType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl ('  typedef ' . $c_type_class . ' BaseClassType;') .
                    nl ();

  $section_manager->append_string_to_section ($code_string, $main_section);

  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $protected_gclass_variable = $prefix . Common::Output::Shared::PROTECTED_GCLASS_VAR;
  my $conditional = $prefix . 'PROTECTED_GCLASS_H_CONDITIONAL';

  $code_string = nl ('protected:');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('private:');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, $main_section);
  $section_manager->set_variable_for_conditional ($protected_gclass_variable, $conditional);
  $code_string = nl ('  friend class ' . $cpp_type_class . ';') .
                 nl ('  static CppClassType ' . lc ($cpp_type) . '_class_;') .
                 nl () .
                 nl ('private:') .
                 nl ('  // noncopyable') .
                 nl ('  ' . $cpp_type . '(' . $cpp_type . '&);') .
                 nl ('  ' . $cpp_type . '& operator=(const ' . $cpp_type . '&);') .
                 nl () .
                 nl ('protected:') .
                 nl ('  explicit ' . $cpp_type . '(const Glib::ConstructParams& construct_params);') .
                 nl ('  explicit ' . $cpp_type . '(' . $c_type . '* castitem);') .
                 nl () .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('public:') .
                 nl ('  virtual ~' . $cpp_type . '();') .
                 nl () .
                 nl (Common::Output::Shared::doxy_skip_begin) .
                 nl ('  static GType get_type() G_GNUC_CONST;');
  $section_manager->append_string_to_section ($code_string, $main_section);
  $code_string = nl ('  static GType get_type(GTypeModule* module) G_GNUC_CONST');

  my $dynamic_gtype_registration_variable = $prefix . Common::Output::Shared::DYNAMIC_GTYPE_REGISTRATION_VAR;

  $conditional = $prefix . 'DYNAMIC_GTYPE_REGISTRATION_H_CONDITIONAL';
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional_to_section ($conditional, $main_section);
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_variable, $conditional);
  $code_string = nl ('  static GType get_base_type() G_GNUC_CONST;') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('  /// Provides access to the underlying C GObject.') .
                 nl ('  ' . $c_type . '* gobj() { return reinterpret_cast< ' . $c_type . '* >(gobject_); }') .
                 nl ('  /// Provides access to the underlying C GObject.') .
                 nl ('  const ' . $c_type . '* gobj() const { return reinterpret_cast< ' . $c_type . '* >(gobject_); }') .
                 nl ('  /// Provides access to the underlying C GObject. The caller is responsible for unrefing it. Use when directly setting fields in structs.') .
                 nl ('  ' . $c_type . '* gobj_copy();') .
                 nl () .
                 nl ('private:');
  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub output_h_before_namespace ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, undef, undef, undef, $cpp_type, undef) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $namespaces = $wrap_parser->get_namespaces;
  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $cpp_type_class = $cpp_type . '_Class';
  #TODO: Make it as a separate function?
  #STRUCT_PROTOTYPE
  my $code_string = nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('typedef struct _' . $c_type . ' ' . $c_type . ';') .
                    nl ('typedef struct _' . $c_type_class . ' ' . $c_type_class . ';') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();

  my $subconditional = $prefix . 'STRUCT_NOT_HIDDEN_BEFORE_NAMESPACE_CONDITIONAL';
  my $struct_not_hidden_variable = $prefix . Common::Output::Shared::STRUCT_NOT_HIDDEN_VAR;
  my $no_wrap_function_variable = $prefix . Common::Output::Shared::NO_WRAP_FUNCTION_VAR;
  my $conditional = $prefix . 'STRUCT_PROTOTYPE_CONDITIONAL';

  $section_manager->append_string_to_conditional ($code_string, $subconditional, 0);
  $section_manager->append_conditional_to_conditional ($subconditional, $conditional, 0);
  $section_manager->set_variable_for_conditional ($struct_not_hidden_variable, $subconditional);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_BEFORE_FIRST_NAMESPACE');
  $section_manager->set_variable_for_conditional ($no_wrap_function_variable, $conditional);
  $code_string = Common::Output::Shared::open_namespaces ($namespaces) .
                 nl ('class ' . $cpp_type_class . ';') .
                 Common::Output::Shared::close_namespaces ($namespaces) .
                 nl ();
  $section_manager->append_string_to_section ($code_string, 'SECTION_BEFORE_FIRST_NAMESPACE');
}

sub _output_h_after_namespace ($$$$$$$$)
{
  my ($wrap_parser, $c_type, undef, undef, undef, undef, $cpp_type, undef) = @_;
  my $namespaces = $wrap_parser->get_namespaces;
  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $full_cpp_type = Common::Output::Shared::join_namespaces ($namespaces) . '::' . $cpp_type;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl ('  /** A Glib::wrap() method for this object.') .
                    nl ('   *') .
                    nl ('   * @param object The C instance.') .
                    nl ('   * @param take_copy @c false if the result should take ownership of the C instance. @c true if it should take a new copy or ref.') .
                    nl ('   * @result A C++ instance that wraps this C instance.') .
                    nl ('   *') .
                    nl ('   * @relates ' . $full_cpp_type) .
                    nl ('   */') .
                    nl ('  Glib::RefPtr< ' . $full_cpp_type . ' > wrap(' . $c_type . '* object, bool take_copy = false);') .
                    nl ('}') .
                    nl ();
  my $conditional = $prefix . 'WRAP_DEFINITION_CONDITIONAL';
  my $variable = $prefix . Common::Output::Shared::NO_WRAP_FUNCTION_VAR;
  my $section_manager = $wrap_parser->get_section_manager;

  $section_manager->append_string_to_conditional ($code_string, $conditional);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_AFTER_FIRST_NAMESPACE');
  $section_manager->set_variable_for_conditional ($variable, $conditional);
}

sub _output_p_h ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, undef, $c_type_parent_class, undef, $cpp_type, $cpp_type_parent) = @_;
  my $namespaces = $wrap_parser->get_namespaces;
  my $cpp_type_class = $cpp_type . '_Class';
  my $cpp_type_parent_class = $cpp_type_parent . '_Class';
  my $section_manager = $wrap_parser->get_section_manager;
  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $code_string = nl ('#include <glibmm/class.h>') .
                    nl () .
                    Common::Output::Shared::open_namespaces ($namespaces) .
                    nl () .
                    nl ('class ' . $cpp_type_class . ' : public Glib::Class') .
                    nl ('{') .
                    nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;');
  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_P_H);

  my $do_not_derive_gtype_variable = $prefix . Common::Output::Shared::DO_NOT_DERIVE_GTYPE_VAR;
  my $conditional = $prefix . 'DO_NOT_DERIVE_GTYPE_TYPEDEF_CONDITIONAL';

  $code_string = nl ('  typedef ' . $cpp_type_parent_class . ' CppClassParent;');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('  typedef ' . $c_type_class . ' BaseClassType;') .
                 nl ('  typedef ' . $cpp_type_parent_class . ' CppClassParent;') .
                 nl ('  typedef ' . $c_type_parent_class . ' BaseClassParent;');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, Common::SectionManager::SECTION_P_H);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_variable, $conditional);
  $code_string = nl () .
                 nl ('  friend class ' . $cpp_type . ';') .
                 nl (Common::Output::Shared::doxy_skip_end) .
                 nl () .
                 nl ('  const Glib::Class& init();') .
                 nl ();
  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_P_H);
  $conditional = $prefix . 'DYNAMIC_GTYPE_REGISTRATION_PH_CONDITIONAL';

  my $dynamic_gtype_registration_variable = $prefix . Common::Output::Shared::DYNAMIC_GTYPE_REGISTRATION_VAR;

  $code_string = nl ('  const Glib::Class& init(GTypeModule* module);');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional_to_section ($conditional, Common::SectionManager::SECTION_P_H);
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_variable, $conditional);
  $conditional = $prefix . 'DO_NOT_DERIVE_GTYPE_CLASS_INIT_CONDITIONAL';
  $code_string = nl ('  static void class_init_function(void* g_class, void* class_data);');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, Common::SectionManager::SECTION_P_H);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_variable, $conditional);
  $code_string = nl ('  static Glib::ObjectBase* wrap_new(GObject*);') .
                 nl () .
                 nl ('protected:');
  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_P_H);
  $section_manager->append_section_to_section ($prefix . 'SECTION_P_H_DEFAULT_SIGNAL_HANDLERS', Common::SectionManager::SECTION_P_H);
  $section_manager->append_string_to_section (nl, Common::SectionManager::SECTION_P_H);
  $section_manager->append_section_to_section ($prefix . 'SECTION_P_H_VFUNCS', Common::SectionManager::SECTION_P_H);
  $code_string = nl () .
                 nl ('};') .
                 nl () .
                 Common::Output::Shared::close_namespaces ($namespaces) .
                 nl ();
  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_P_H);
}

sub _output_p_cc ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, undef, undef, $get_type_func, $cpp_type, undef) = @_;
  my $namespaces = $wrap_parser->get_namespaces;
  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $no_wrap_function_variable = $prefix . Common::Output::Shared::NO_WRAP_FUNCTION_VAR;
  my $section_manager = $wrap_parser->get_section_manager;
  my $cpp_type_class = $cpp_type . '_Class';
  my $code_string = Common::Output::Shared::open_namespaces ($namespaces) .
                    nl ('const Glib::Class& ' . $cpp_type_class . '::init()') .
                    nl ('{') .
                    nl ('  if(!gtype_) // create the GType if necessary') .
                    nl ('  {');

  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');

  my $conditional = $prefix . 'PCC_CLASS_IMPL_INIT_CONDITIONAL';
  my $do_not_derive_gtype_variable = $prefix . Common::Output::Shared::DO_NOT_DERIVE_GTYPE_VAR;

  $code_string = nl ('    gtype_ = CppClassParent::CppObjectType::get_type();');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $code_string = nl ('    // Glib::Class has to know the class init function to clone custom types.') .
                 nl ('    class_init_func_ = &' . $cpp_type_class . '::class_init_function;') .
                 nl () .
                 nl ('    // This is actually just optimized away, apparently with no harm.') .
                 nl ('    // Make sure that the parent type has been created.') .
                 nl ('    //CppClassParent::CppObjectType::get_type();') .
                 nl () .
                 nl ('    // Create the wrapper type, with the same class/instance size as the base type.') .
                 nl ('    register_derived_type(' . $get_type_func . '());') .
                 nl () .
                 nl ('    // Add derived versions of interfaces, if the C type implements any interfaces:');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_section_to_conditional ($prefix . 'SECTION_CC_IMPLEMENTS_INTERFACES', $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_variable, $conditional);
  $code_string = nl ('  }') .
                 nl () .
                 nl ('  return *this;') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
  $conditional = $prefix . 'PCC_CLASS_IMPL_INIT_DYNAMIC_GTYPE_CONDITIONAL';

  my $dynamic_gtype_registration_variable = $prefix . Common::Output::Shared::DYNAMIC_GTYPE_REGISTRATION_VAR;

  $code_string = nl ('const Glib::Class& ' . $cpp_type_class . '::init(GTypeModule* module)') .
                 nl ('{') .
                 nl ('  if(!gtype_) // create the GType if necessary') .
                 nl ('  {');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);

  my $subconditional = $prefix . 'PCC_CLASS_IMPL_INIT_DYNAMIC_GTYPE_NO_DERIVE_CONDITIONAL';

  $code_string = nl ('    // Do not derive a GType, or use a derived klass:') .
                 nl ('    gtype_ = CppClassParent::CppObjectType::get_type();');
  $section_manager->append_string_to_conditional ($code_string, $subconditional, 1);
  $code_string = nl ('    // Glib::Class has to know the class init function to clone custom types.') .
                 nl ('    class_init_func_ = &' . $cpp_type_class . '::class_init_function;') .
                 nl () .
                 nl ('    // This is actually just optimized away, apparently with no harm.') .
                 nl ('    // Make sure that the parent type has been created.') .
                 nl ('    //CppClassParent::CppObjectType::get_type();') .
                 nl () .
                 nl ('    // Create the wrapper type, with the same class/instance size as the base type.') .
                 nl ('    register_derived_type(' . $get_type_func . '(), module);') .
                 nl () .
                 nl ('    // Add derived versions of interfaces, if the C type implements any interfaces:');
  $section_manager->append_string_to_conditional ($code_string, $subconditional, 0);
  $section_manager->append_section_to_conditional ($prefix . 'SECTION_CC_IMPLEMENTS_INTERFACES', $subconditional);
  $section_manager->append_conditional_to_conditional ($subconditional, $conditional, 1);
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_variable, $subconditional);
  $code_string = nl ('  }') .
                 nl () .
                 nl ('  return *this;') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_variable, $conditional);
  $conditional = $prefix . 'PCC_CLASS_IMPL_CLASS_INIT_FUNCTION_NO_DERIVE_GTYPE_CONDITIONAL';
  $code_string = nl ('void ' . $cpp_type_class . '::class_init_function(void* g_class, void* class_data)') .
                 nl ('{') .
                 nl ('  BaseClassType* const klass = static_cast< BaseClassType* >(g_class);') .
                 nl ('  CppClassParent::class_init_function(klass, class_data);') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_section_to_conditional ($prefix . 'SECTION_PCC_CLASS_INIT_VFUNCS', $conditional, 0);
  $section_manager->append_string_to_conditional (nl (), $conditional, 0);
  $section_manager->append_section_to_conditional ($prefix . 'SECTION_PCC_CLASS_INIT_DEFAULT_SIGNAL_HANDLERS', $conditional, 0);
  $code_string = nl ('}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($do_not_derive_gtype_variable, $conditional);
  $section_manager->append_section_to_section ($prefix . 'SECTION_PCC_VFUNCS', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_PCC_DEFAULT_SIGNAL_HANDLERS', 'SECTION_CCG_END');
  $code_string = nl ('Glib::ObjectBase* ' . $cpp_type_class . '::wrap_new(GObject* object)') .
                 nl ('{') .
                 nl ('  return new ' . $cpp_type . '(static_cast< ' . $c_type . '* >(object));') .
                 nl ('}') .
                 nl ();
  $conditional = $prefix . 'CUSTOM_WRAP_NEW_CC_CONDITIONAL';

  my $custom_wrap_new_variable = $prefix . Common::Output::Shared::CUSTOM_WRAP_NEW_VAR;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($custom_wrap_new_variable, $conditional);
  $section_manager->append_string_to_section (Common::Output::Shared::close_namespaces ($namespaces), 'SECTION_CCG_END');
}

sub _output_cc ($$$$$$$$)
{
  my ($wrap_parser, $c_type, undef, $c_type_parent, undef, $get_type_func, $cpp_type, $cpp_type_parent) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $namespaces = $wrap_parser->get_namespaces;
  my $full_cpp_type = Common::Output::Shared::join_namespaces ($namespaces) . '::' . $cpp_type;
  my $code_string = nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('Glib::RefPtr< ' . $full_cpp_type . ' > wrap(' . $c_type . '* object, bool take_copy)') .
                    nl ('{') .
                    nl ('  return Glib::RefPtr< ' . $full_cpp_type . ' >(dynamic_cast< ' . $full_cpp_type . ' >(Glib::wrap_auto (static_cast< GObject* >(object), take_copy)));') .
                    nl ('  // We use dynamic_cast<> in case of multiple inheritance.') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl ();
  my $prefix = Common::Output::Shared::create_class_local_prefix ($namespaces, $cpp_type);
  my $no_wrap_function_variable = $prefix . Common::Output::Shared::NO_WRAP_FUNCTION_VAR;
  my $conditional = $prefix . 'GLIB_WRAP_IMPL_CONDITIONAL';

  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($no_wrap_function_variable, $conditional);
  $code_string = Common::Output::Shared::open_namespaces ($namespaces) .
                 nl ($c_type . '* ' . $cpp_type . '::gobj_copy()') .
                 nl ('{') .
                 nl ('  reference();') .
                 nl ('  return gobj();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
  $conditional = $prefix . 'CUSTOM_CTOR_CAST_CC_CONDITIONAL';

  my $custom_ctor_cast_variable = $prefix . Common::Output::Shared::CUSTOM_CTOR_CAST_VAR;

  $code_string = nl ($cpp_type . '::' . $cpp_type . '(const Glib::ConstructParams& construct_params)') .
                 nl (':') .
                 nl ('  ' . $cpp_type_parent . '(construct_params)') .
                 nl ('{');
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);

  my $subconditional = $prefix . 'CUSTOM_CTOR_CAST_CC_SINK_CONDITIONAL';
  my $derives_initially_unowned_variable = $prefix . Common::Output::Shared::DERIVES_INITIALLY_UNOWNED_VAR;

  $code_string = nl ('  if(gobject && g_object_is_floating (gobject_))') .
                 nl ('  {') .
                 nl ('    g_object_ref_sink(gobject_); // Stops it from being floating.') .
                 nl ('  }');
  $section_manager->append_string_to_conditional ($code_string, $subconditional, 1);
  $section_manager->append_conditional_to_conditional ($subconditional, $conditional, 0);
  $section_manager->set_variable_for_conditional ($derives_initially_unowned_variable, $subconditional);
  $code_string = nl ('}') .
                 nl () .
                 nl ($cpp_type . '::' . $cpp_type . '(' . $c_type . '* castitem)') .
                 nl (':') .
                 nl ('  ' . $cpp_type_parent . '(static_cast< ' . $c_type_parent . '* >(castitem))') .
                 nl ('{}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($custom_ctor_cast_variable, $conditional);
  $conditional = $prefix . 'CUSTOM_DTOR_CC_CONDITIONAL';

  my $custom_dtor_variable = $prefix . Common::Output::Shared::CUSTOM_DTOR_VAR;

  $code_string = nl ($cpp_type . '::~' . $cpp_type . '()') .
                 nl ('{}') .
                 nl ();
  $section_manager->append_string_to_conditional ($code_string, $conditional, 0);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($custom_dtor_variable, $conditional);
  $code_string = nl ($cpp_type . '::CppClassType ' . $cpp_type . '::' . lc ($cpp_type) . '_class_; // Initialize static member') .
                 nl () .
                 nl ('GType ' . $cpp_type . '::get_type()') .
                 nl ('{') .
                 nl ('  return ' . lc ($cpp_type) . '_class_.init().get_type();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
  $conditional = $prefix . 'GET_TYPE_GTYPEMODULE_IMPL_CONDITIONAL';
  $code_string = nl ('GType ' . $cpp_type . '::get_type(GTypeModule* module)') .
                 nl ('{') .
                 nl ('  return ' . lc ($cpp_type) . '_class_.init(module).get_type();') .
                 nl ('}') .
                 nl ();

  my $dynamic_gtype_registration_variable = $prefix . Common::Output::Shared::DYNAMIC_GTYPE_REGISTRATION_VAR;

  $section_manager->append_string_to_conditional ($code_string, $conditional, 1);
  $section_manager->append_conditional_to_section ($conditional, 'SECTION_CCG_END');
  $section_manager->set_variable_for_conditional ($dynamic_gtype_registration_variable, $conditional);
  $code_string = nl ('GType ' . $cpp_type . '::get_base_type()') .
                 nl ('{') .
                 nl ('  return ' . $get_type_func . '();') .
                 nl ('}') .
                 nl ();
  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC_SIGNALPROXIES', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC_PROPERTYPROXIES', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC_DEFAULT_SIGNAL_HANDLERS', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC_VFUNCS', 'SECTION_CCG_END');
  $section_manager->append_section_to_section ($prefix . 'SECTION_CC_VFUNCS_CPPWRAPPER', 'SECTION_CCG_END');
  $section_manager->append_string_to_section (Common::Output::Shared::close_namespaces ($namespaces), 'SECTION_CCG_END');
}

sub output ($$$$$$$$)
{
  my ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent) = @_;

  _output_h_in_class ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
  _output_h_before_namespace ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
  _output_h_after_namespace ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
  _output_p_h ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
  _output_p_cc ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
  _output_cc ($wrap_parser, $c_type, $c_type_class, $c_type_parent, $c_type_parent_class, $get_type_func, $cpp_type, $cpp_type_parent);
}

1; # indicate proper module load.
