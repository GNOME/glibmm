#ifndef _GLIBMM_CLASS_H
#define _GLIBMM_CLASS_H

/* Copyright 2001 Free Software Foundation
 * Copyright (C) 1998-2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glib-object.h>
#include <glibmmconfig.h> //Include this here so that the /private/*.h classes have access to GLIBMM_VFUNCS_ENABLED

#include <vector> //For interface properties that custom types might override.
#include <tuple>

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Glib
{
class GLIBMM_API Interface_Class;

class GLIBMM_API Class
{
public:
  /* No constructor/destructor:
   * Glib::Class objects are used only as static data, which would cause
   * lots of ugly global constructor invocations.  These are avoidable,
   * because the C/C++ standard explicitly specifies that all _static_ data
   * is zero-initialized at program start.
   */
  // Class();
  //~Class() noexcept;

  // static void class_init_function(BaseClassType *p);
  // static void object_init_function(BaseObjectType *o);
  // GType get_type() = 0; //Creates the GType when this is first called.

  // Hook for translating API
  // static Glib::Object* wrap_new(GObject*);

  inline GType get_type() const;

  /// The type that holds pointers to the interfaces of custom types.
  using interface_classes_type = std::vector<const Interface_Class*>;
  /** The type that holds pointers to extra class init functions of custom types.
   * The std::tuple contains a function pointer and a pointer to class data.
   * The class data pointer can be nullptr, if the function does not need it.
   */
  using class_init_funcs_type = std::vector<std::tuple<GClassInitFunc, void*>>;

  /** Register a static custom GType, derived from the parent of this class's type.
   * The parent type of the registered custom type is the same C class as the parent
   * of the get_type() type. If a type with the specified name is already registered,
   * nothing is done. register_derived_type() must have been called.
   * @param custom_type_name The name of the registered type is
   *        "gtkmm__CustomObject_" + canonic(custom_type_name), where canonic()
   *        replaces special characters with '+'.
   * @param interface_classes Interfaces that the custom type implements (can be nullptr).
   * @param class_init_funcs Extra class init functions (can be nullptr). These
   *        functions, if any, are called after the class init function of this
   *        class's type, e.g. Gtk::Widget.
   * @param instance_init_func Instance init function (can be nullptr).
   * @return The registered type.
   */
  GType clone_custom_type(
    const char* custom_type_name, const interface_classes_type* interface_classes,
    const class_init_funcs_type* class_init_funcs, GInstanceInitFunc instance_init_func) const;

protected:
  GType gtype_;
  GClassInitFunc class_init_func_;

  /** Register a GType, derived from the @a base_type.
   */
  void register_derived_type(GType base_type);

  /** Register a GType, derived from the @a base_type.
   * @param module If this is not 0 then g_type_module_register_type() will be used. Otherwise
   * g_type_register_static() will be used.
   */
  void register_derived_type(GType base_type, GTypeModule* module);

private:
  static void custom_class_base_finalize_function(void* g_class);
  static void custom_class_init_function(void* g_class, void* class_data);

public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  // The type that holds the values of the interface properties of custom types.
  using iface_properties_type = std::vector<GValue*>;
  // The quark used for storing/getting the interface properties of custom types.
  static GQuark iface_properties_quark;
#endif
};

inline GType
Class::get_type() const
{
  return gtype_;
}

} // namespace Glib

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _GLIBMM_CLASS_H */
