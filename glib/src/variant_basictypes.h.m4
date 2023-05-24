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
dnl  License along with this library.  If not, see <http://www.gnu.org/licenses/>.

include(template.macros.m4)

dnl
dnl For instance, GLIB_VARIANT_BASIC(C++ type, C type, C type name [,C type name 2])
dnl Parameters:
dnl C++ type: The C++ type for the specialization, such as bool.
dnl C type: The C type used by the C API, such as gboolean.
dnl C type name: The text used in the C API functions and macros, such as boolean
dnl   in g_variant_get_boolean() and G_VARIANT_TYPE_BOOLEAN.
dnl C type name 2: Optional second text, such as handle in g_variant_get_handle()
dnl   and G_VARIANT_TYPE_HANDLE.
dnl
define([GLIB_VARIANT_BASIC],[dnl
LINE(]__line__[)dnl

/** Specialization of Glib::Variant containing a $1 type.
 *
 * @ingroup Variant
 */
template <>
class GLIBMM_API Variant<$1> : public VariantBase
{
public:
  using CType = $2;

  /// Default constructor.
  Variant()
  : VariantBase()
  {}

  /** GVariant constructor.
   * @param castitem The GVariant to wrap.
   * @param take_a_reference Whether to take an extra reference of the
   * GVariant or not (not taking one could destroy the GVariant with the
   * wrapper).
   */
  explicit Variant(GVariant* castitem, bool take_a_reference = false)
  : VariantBase(castitem, take_a_reference)
  {}

  /** Gets the Glib::VariantType.
   * @return The Glib::VariantType.
   */
  static const VariantType& variant_type() G_GNUC_CONST;

  /** Creates a new Glib::Variant<$1>.
   * @param data The value of the new Glib::Variant<$1>.
   * @return The new Glib::Variant<$1>.
   */
  static Variant<$1> create($1 data);
ifelse($4,,,[
  /** Creates a new Glib::Variant<$1> of type VARIANT_TYPE_[]UPPER($4).
   * @param data The value of the new Glib::Variant<$1>.
   * @return The new Glib::Variant<$1>.
   */
  static Variant<$1> create_$4($1 data);
])
  /** Gets the value of the Glib::Variant<$1>.
   * @return The $1 value of the Glib::Variant<$1>.
   */
  $1 get() const;
};
])

divert[]dnl
// This is a generated file. Do not edit it.  Generated from __file__

#ifndef DOXYGEN_SHOULD_SKIP_THIS
#ifndef _GLIBMM_VARIANT_H_INCLUDE_VARIANT_BASICTYPES_H
#error "glibmm/variant_basictypes.h cannot be included directly"
#endif
#else
#include <glibmmconfig.h>
#endif

namespace Glib
{
GLIB_VARIANT_BASIC(bool, gboolean, boolean)
GLIB_VARIANT_BASIC(unsigned char, guchar, byte)

#if GLIBMM_SIZEOF_SHORT == 2 && GLIBMM_SIZEOF_INT == 2
GLIB_VARIANT_BASIC(short, gint16, int16)
GLIB_VARIANT_BASIC(unsigned short, guint16, uint16)
GLIB_VARIANT_BASIC(int, gint16, int16)
GLIB_VARIANT_BASIC(unsigned int, guint16, uint16)
#else
GLIB_VARIANT_BASIC(gint16, gint16, int16)
GLIB_VARIANT_BASIC(guint16, guint16, uint16)
#endif

#if GLIBMM_SIZEOF_INT == 4 && GLIBMM_SIZEOF_LONG == 4
GLIB_VARIANT_BASIC(int, gint32, int32, handle)
GLIB_VARIANT_BASIC(unsigned int, guint32, uint32)
GLIB_VARIANT_BASIC(long, gint32, int32, handle)
GLIB_VARIANT_BASIC(unsigned long, guint32, uint32)
#else
GLIB_VARIANT_BASIC(gint32, gint32, int32, handle)
GLIB_VARIANT_BASIC(guint32, guint32, uint32)
#endif

#if GLIBMM_SIZEOF_LONG == 8 && GLIBMM_SIZEOF_LONG_LONG == 8
GLIB_VARIANT_BASIC(long, gint64, int64)
GLIB_VARIANT_BASIC(unsigned long, guint64, uint64)
GLIB_VARIANT_BASIC(long long, gint64, int64)
GLIB_VARIANT_BASIC(unsigned long long, guint64, uint64)
#else
GLIB_VARIANT_BASIC(gint64, gint64, int64)
GLIB_VARIANT_BASIC(guint64, guint64, uint64)
#endif

GLIB_VARIANT_BASIC(DBusHandle, gint32, handle)
GLIB_VARIANT_BASIC(double, gdouble, double)

} // namespace Glib
