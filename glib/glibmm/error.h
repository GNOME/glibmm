#ifndef _GLIBMM_ERROR_H
#define _GLIBMM_ERROR_H

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

#include <glibmmconfig.h>
#include <glibmm/value.h>
#include <glib.h>
#include <exception>

namespace Glib
{

class Error : public std::exception
{
public:
  GLIBMM_API Error();
  GLIBMM_API Error(GQuark error_domain, int error_code, const Glib::ustring& message);
  GLIBMM_API explicit Error(GError* gobject, bool take_copy = false);

  GLIBMM_API Error(const Error& other);
  GLIBMM_API Error& operator=(const Error& other);

  GLIBMM_API ~Error() noexcept override;

  /** Test whether the %Error has an underlying instance.
   *
   * @newin{2,60}
   */
  GLIBMM_API explicit operator bool() const;

  GLIBMM_API GQuark domain() const;
  GLIBMM_API int code() const;
  GLIBMM_API const char* what() const noexcept override;

  GLIBMM_API bool matches(GQuark error_domain, int error_code) const;

  GLIBMM_API GError* gobj();
  GLIBMM_API const GError* gobj() const;

#ifndef DOXYGEN_SHOULD_SKIP_THIS

  GLIBMM_API void propagate(GError** dest);

  using ThrowFunc = void(*)(GError*);

  GLIBMM_API static void register_init();
  GLIBMM_API static void register_cleanup();
  GLIBMM_API static void register_domain(GQuark error_domain, ThrowFunc throw_func);

  GLIBMM_API static void throw_exception(GError* gobject) G_GNUC_NORETURN;

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

protected:
  GError* gobject_;
};

#ifndef DOXYGEN_SHOULD_SKIP_THIS
// This is needed so Glib::Error can be used with
// Glib::Value and _WRAP_PROPERTY in Gtk::MediaStream.
template <>
class GLIBMM_API Value<Glib::Error> : public ValueBase_Boxed
{
public:
  using CppType = Glib::Error;
  using CType = GError*;

  static GType value_type();

  void set(const CppType& data);
  CppType get() const;
};
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

#endif /* _GLIBMM_ERROR_H */
