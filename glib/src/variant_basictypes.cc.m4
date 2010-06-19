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
dnl GLIB_VARIANT_BASIC(bool, boolean)
dnl
define([GLIB_VARIANT_BASIC],[dnl
LINE(]__line__[)dnl

dnl Please ignore the format stuff.  I was just tired and played a little.
/**** Glib::Variant<$1> translit(format([%]eval(57-len([$1]))[s],[****/]),[ ],[*])

// static
const GVariantType* Variant<$1>::variant_type()
{
  return G_VARIANT_TYPE_[]UPPER($2);
}

Variant<$1> Variant<$1>::create($1 data)
{
  return Variant<$1>(g_variant_new_$2(data));
}

$1 Variant<$1>::get() const
{
  return g_variant_get_$2(gobject_);
}
])

divert[]dnl
// This is a generated file, do not edit.  Generated from __file__

#include <glibmm/variant.h>

namespace Glib
{
GLIB_VARIANT_BASIC(bool, boolean)
dnl GLIB_VARIANT_BASIC(unsigned char, byte)
GLIB_VARIANT_BASIC(gint16, int16)
GLIB_VARIANT_BASIC(guint16, uint16)
GLIB_VARIANT_BASIC(gint32, int32)
GLIB_VARIANT_BASIC(guint32, uint32)
GLIB_VARIANT_BASIC(gint64, int64)
GLIB_VARIANT_BASIC(guint64, uint64)
dnl GLIB_VARIANT_BASIC(gint32, handle)
GLIB_VARIANT_BASIC(double, double)
} // namespace Glib
