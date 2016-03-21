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
dnl  License along with this library; if not, write to the Free
dnl  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

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
class Value<$1> : public ValueBase
{
public:
  using CppType = $1;
  using CType = g$2;

  static GType value_type() G_GNUC_CONST;

  void set($1 data);
  $1 get() const;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  GParamSpec* create_param_spec(const Glib::ustring& name) const;
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
#ifndef GLIBMM_DISABLE_DEPRECATED
/// @deprecated Use Value<signed char> instead.
GLIB_VALUE_BASIC(char, char)
#endif // GLIBMM_DISABLE_DEPRECATED
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
