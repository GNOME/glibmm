/* Copyright 2002 The gtkmm Development Team
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

#include <glibmm/value.h>
#include <glibmm/utility.h>
#include <glib.h>
#include <map>

namespace
{
std::map<GType, Glib::ValueInitCppFuncType> custom_init_funcmap;
std::map<GType, Glib::ValueFreeCppFuncType> custom_free_funcmap;
std::map<GType, Glib::ValueCopyCppFuncType> custom_copy_funcmap;

extern "C"
{
static void Value_custom_init_func(GValue* value)
{
  Glib::ValueInitCppFuncType init_func = custom_init_funcmap[G_VALUE_TYPE(value)];
  if (init_func)
    init_func(value);
  else
    g_critical("Value_custom_init_func(): No init_func for GValue %s\n", G_VALUE_TYPE_NAME(value));
}
static void Value_custom_free_func(GValue* value)
{
  Glib::ValueFreeCppFuncType free_func = custom_free_funcmap[G_VALUE_TYPE(value)];
  if (free_func)
    free_func(value);
  else
    g_critical("Value_custom_free_func(): No free_func for GValue %s\n", G_VALUE_TYPE_NAME(value));
}
static void Value_custom_copy_func(const GValue* src_value, GValue* dest_value)
{
  Glib::ValueCopyCppFuncType copy_func = custom_copy_funcmap[G_VALUE_TYPE(src_value)];
  if (copy_func)
    copy_func(src_value, dest_value);
  else
    g_critical("Value_custom_copy_func(): No copy_func for GValue %s\n", G_VALUE_TYPE_NAME(src_value));
}
} // extern "C"

static void
warn_already_registered(const char* location, const std::string& full_name)
{
  g_warning("file %s: (%s): The type name `%s' has been registered already.\n"
            "This is not supposed to happen -- please create an issue with "
            "detailed information about your platform\n"
            "at https://gitlab.gnome.org/GNOME/glibmm/-/issues. Thanks.\n",
    __FILE__, location, full_name.c_str());
}

} // anonymous namespace

namespace Glib
{

GType
custom_boxed_type_cpp_register(const char* type_name,
  ValueInitCppFuncType init_func, ValueFreeCppFuncType free_func,
  ValueCopyCppFuncType copy_func)
{
  const GType custom_gtype = custom_boxed_type_register(type_name,
    &Value_custom_init_func, &Value_custom_free_func, &Value_custom_copy_func);
  custom_init_funcmap[custom_gtype] = init_func;
  custom_free_funcmap[custom_gtype] = free_func;
  custom_copy_funcmap[custom_gtype] = copy_func;
  return custom_gtype;
}

//TODO: When we can break ABI, move the contents of custom_boxed_type_register()
// (with small modifications) to custom_boxed_type_cpp_register() and
// remove custom_boxed_type_register().
GType
custom_boxed_type_register(
  const char* type_name, ValueInitFunc init_func, ValueFreeFunc free_func, ValueCopyFunc copy_func)
{
  std::string full_name("glibmm__CustomBoxed_");
  Glib::append_canonical_typename(full_name, type_name);

  // Templates of the same type _might_ be duplicated when instantiated in
  // multiple translation units -- I'm not sure whether this is true.  If the
  // static custom_type_ variable in Value<> is duplicated, then the type
  // would be registered more than once.
  //
  // Lookup the type name to see whether this scenario actually happens.
  // If this turns out to be common behaviour on some platform the warning
  // should be removed.

  if (const GType existing_type = g_type_from_name(full_name.c_str()))
  {
    warn_already_registered("Glib::custom_boxed_type_register", full_name);
    return existing_type;
  }

  // Via GTypeValueTable, we can teach GValue how to instantiate,
  // destroy, and copy arbitrary objects of the C++ type.

  const GTypeValueTable value_table = {
    //TODO: When moved to custom_boxed_type_cpp_register():
    // &Value_custom_init_func, &Value_custom_free_func, &Value_custom_copy_func,
    init_func, free_func, copy_func,
    nullptr, // value_peek_pointer
    nullptr, // collect_format
    nullptr, // collect_value
    nullptr, // lcopy_format
    nullptr, // lcopy_value
  };

  const GTypeInfo type_info = {
    0, // class_size
    nullptr, // base_init
    nullptr, // base_finalize
    nullptr, // class_init_func
    nullptr, // class_finalize
    nullptr, // class_data
    0, // instance_size
    0, // n_preallocs
    nullptr, // instance_init
    &value_table,
  };

  // Don't use g_boxed_type_register_static(), because that wouldn't allow
  // for a non-NULL default value.  The implementation of g_boxed_copy() will
  // use our custom GTypeValueTable automatically.

  return g_type_register_static(G_TYPE_BOXED, full_name.c_str(), &type_info, GTypeFlags(0));
}

GType
custom_pointer_type_register(const char* type_name)
{
  std::string full_name("glibmm__CustomPointer_");
  Glib::append_canonical_typename(full_name, type_name);

  // Templates of the same type _might_ be duplicated when instantiated in
  // multiple translation units -- I'm not sure whether this is true.  If the
  // static custom_type variable in Value<>::value_type_() is duplicated, then
  // the type would be registered more than once.
  //
  // Lookup the type name to see whether this scenario actually happens.
  // If this turns out to be common behaviour on some platform the warning
  // should be removed.

  if (const GType existing_type = g_type_from_name(full_name.c_str()))
  {
    warn_already_registered("Glib::custom_pointer_type_register", full_name);
    return existing_type;
  }

  const GTypeInfo type_info = {
    0, // class_size
    nullptr, // base_init
    nullptr, // base_finalize
    nullptr, // class_init_func
    nullptr, // class_finalize
    nullptr, // class_data
    0, // instance_size
    0, // n_preallocs
    nullptr, // instance_init
    nullptr, // value_table
  };

  // We could probably use g_pointer_type_register_static(), but I want
  // to keep this function symmetric to custom_boxed_type_register().  Also,
  // g_pointer_type_register_static() would lookup the type name once again.

  return g_type_register_static(G_TYPE_POINTER, full_name.c_str(), &type_info, GTypeFlags(0));
}

} // namespace Glib
