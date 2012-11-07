divert(-1)

dnl $Id$

dnl  Glib::Variant specializations for fundamental types
dnl
dnl  Copyright 2010 The gtkmm Development Team
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
dnl For instance, GLIB_VARIANT_BASIC(c++ type, c type, c type name)
dnl parameters:
dnl c++ type: The C++ type for the specialization, such as bool
dnl c type: The C type used by the C API, such as gboolean.
dnl c type name: The text used in the C API functions and macros, such as boolean, in g_variant_get_boolean() and G_VARIANT_TYPE_BOOLEAN.
dnl
define([GLIB_VARIANT_BASIC],[dnl
LINE(]__line__[)dnl

dnl Please ignore the format stuff.  I was just tired and played a little.
/**** Glib::Variant<$1> translit(format([%]eval(57-len([$1]))[s],[****/]),[ ],[*])

// static
const VariantType& Variant<$1>::variant_type()
{
  static VariantType type(G_VARIANT_TYPE_[]UPPER($3));
  return type;
}

Variant<$1> Variant<$1>::create($1 data)
{
  Variant<$1> result = Variant<$1>(g_variant_new_$3(data));
  return result;
}

$1 Variant<$1>::get() const
{
  return g_variant_get_$3(gobject_);
}
])

divert[]dnl
// This is a generated file, do not edit.  Generated from __file__

#include <glibmm/variant.h>

namespace Glib
{

GLIB_VARIANT_BASIC(bool, gboolean, boolean)
GLIB_VARIANT_BASIC(unsigned char, guchar, byte)
GLIB_VARIANT_BASIC(gint16, gint16, int16)
GLIB_VARIANT_BASIC(guint16, guint16, uint16)
GLIB_VARIANT_BASIC(gint32, gint32, int32)
GLIB_VARIANT_BASIC(guint32, guint32, uint32)
GLIB_VARIANT_BASIC(gint64, gint64, int64)
GLIB_VARIANT_BASIC(guint64, guint64, uint64)
dnl This would redeclare the <int> GLIB_VARIANT_BASIC(gint32, guint32, handle)
GLIB_VARIANT_BASIC(double, gdouble, double)

} // namespace Glib
