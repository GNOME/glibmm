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
#include <glibmm/exception.h>
#include <glibmm/value.h>
#include <glib.h>

namespace Glib
{

class GLIBMM_API Error : public Glib::Exception
{
public:
  Error();
  Error(GQuark error_domain, int error_code, const Glib::ustring& message);
  explicit Error(GError* gobject, bool take_copy = false);

  Error(const Error& other);
  Error& operator=(const Error& other);

  ~Error() noexcept override;

  /** Test whether the %Error has an underlying instance.
   *
   * @newin{2,60}
   */
  explicit operator bool() const;

  GQuark domain() const;
  int code() const;
  Glib::ustring what() const override;

  bool matches(GQuark error_domain, int error_code) const;

  GError* gobj();
  const GError* gobj() const;

#ifndef DOXYGEN_SHOULD_SKIP_THIS

  void propagate(GError** dest);

  using ThrowFunc = void(*)(GError*);

  static void register_init();
  static void register_cleanup();
  static void register_domain(GQuark error_domain, ThrowFunc throw_func);

  static void throw_exception(GError* gobject) G_GNUC_NORETURN;

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

protected:
  GError* gobject_;
};

#ifndef DOXYGEN_SHOULD_SKIP_THIS
// This is needed so Glib::Error can be used with
// Glib::Value and _WRAP_PROPERTY.
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
