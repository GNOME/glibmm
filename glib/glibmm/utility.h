#ifndef _GLIBMM_UTILITY_H
#define _GLIBMM_UTILITY_H

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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmmconfig.h>
#include <glibmm/ustring.h>
#include <glib.h>
#include <memory> //For std::unique_ptr.

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Glib
{

// These are used by gmmproc-generated type conversions:

/** Helper to deal with memory allocated
 * by GLib functions in an exception-safe manner.
 *
 * This just creates a std::unique_ptr that uses g_free() as its deleter.
 */
template <typename T>
std::unique_ptr<T[], decltype(&g_free)>
make_unique_ptr_gfree(T* p)
{
  return std::unique_ptr<T[], decltype(&g_free)>(p, &g_free);
}

// TODO: Deprecate this? We don't use it ourselves.
/** Removes the const nature of a ptr
 *
 */
template <class T>
inline T*
unconst(const T* t)
{
  return const_cast<T*>(t);
}

// Convert const gchar* to ustring, while treating NULL as empty string.
inline Glib::ustring
convert_const_gchar_ptr_to_ustring(const char* str)
{
  return (str) ? Glib::ustring(str) : Glib::ustring();
}

// Convert const gchar* to std::string, while treating NULL as empty string.
inline std::string
convert_const_gchar_ptr_to_stdstring(const char* str)
{
  return (str) ? std::string(str) : std::string();
}

// Convert a non-const gchar* return value to ustring, freeing it too.
inline Glib::ustring
convert_return_gchar_ptr_to_ustring(char* str)
{
  return (str) ? Glib::ustring(Glib::make_unique_ptr_gfree(str).get()) : Glib::ustring();
}

// Convert a non-const gchar* return value to std::string, freeing it too.
inline std::string
convert_return_gchar_ptr_to_stdstring(char* str)
{
  return (str) ? std::string(Glib::make_unique_ptr_gfree(str).get()) : std::string();
}

/** Get a pointer to the C style string in a std::string or Glib::ustring.
 * If the string is empty, a nullptr is returned.
 */
template <typename T>
inline const char*
c_str_or_nullptr(const T& str)
{
  return str.empty() ? nullptr : str.c_str();
}

// Append type_name to dest, while replacing special characters with '+'.
void append_canonical_typename(std::string& dest, const char* type_name);

// Delete data referred to by a void*.
// Instantiations can be used as destroy callbacks in glib functions
// that take a GDestroyNotify parameter, such as g_object_set_qdata_full()
// and g_option_group_set_translate_func().
template <typename T>
void
destroy_notify_delete(void* data)
{
  delete static_cast<T*>(data);
}

} // namespace Glib

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _GLIBMM_UTILITY_H */
