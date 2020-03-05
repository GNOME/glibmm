divert(-1)

dnl  Glib::Value specializations for fundamental types
dnl
dnl  Copyright 2002 The gtkmm Development Team
dnl
dnl  This library is free software; you can redistribute it and/or
dnl  modify it under the terms of the GNU Lesser General Public
dnl  License as published by the Free Software Foundation; either
dnl  version 2.1 of the License, or (at your option) any later version.
dnl
dnl  This library is distributed in the hope that it will be useful,
dnl  but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl  Lesser General Public License for more details.
dnl
dnl  You should have received a copy of the GNU Lesser General Public
dnl  License along with this library.  If not, see <http://www.gnu.org/licenses/>.

include(template.macros.m4)

dnl
dnl GLIB_VALUE_BASIC(bool, boolean)
dnl
define([GLIB_VALUE_BASIC],[dnl
LINE(]__line__[)dnl

/**
 * @ingroup glibmmValue
 */
template <>
class GLIBMM_API Value<$1> : public ValueBase
{
public:
  using CppType = $1;

  static GType value_type() G_GNUC_CONST;

  void set($1 data);
  $1 get() const;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  GParamSpec* create_param_spec(const Glib::ustring& name, const Glib::ustring& nick,
                                const Glib::ustring& blurb, Glib::ParamFlags flags) const;
#endif
};
])

divert[]dnl
// This is a generated file, do not edit.  Generated from __file__

#ifndef DOXYGEN_SHOULD_SKIP_THIS
#ifndef _GLIBMM_VALUE_H_INCLUDE_VALUE_BASICTYPES_H
#error "glibmm/value_basictypes.h cannot be included directly"
#endif
#endif

/* Suppress warnings about `long long' when GCC is in -pedantic mode.
 */
#if (__GNUC__ >= 3 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 96))
#pragma GCC system_header
#endif

namespace Glib
{
GLIB_VALUE_BASIC(bool, boolean)
/// @newin{2,44}
GLIB_VALUE_BASIC(signed char, int8)
GLIB_VALUE_BASIC(unsigned char, uchar)
GLIB_VALUE_BASIC(int, int)
GLIB_VALUE_BASIC(unsigned int, uint)
GLIB_VALUE_BASIC(long, long)
GLIB_VALUE_BASIC(unsigned long, ulong)
GLIB_VALUE_BASIC(long long, int64)
GLIB_VALUE_BASIC(unsigned long long, uint64)
GLIB_VALUE_BASIC(float, float)
GLIB_VALUE_BASIC(double, double)
GLIB_VALUE_BASIC(void*, pointer)
} // namespace Glib
