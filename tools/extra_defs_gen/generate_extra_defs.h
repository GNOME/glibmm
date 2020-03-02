/* generate_extra_defs.h
 *
 * Copyright (C) 2001 The Free Software Foundation
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
#include <iostream>
#include <string>

#if defined (_MSC_VER) && !defined (GLIBMM_GEN_EXTRA_DEFS_STATIC)
#if defined (GLIBMM_GEN_EXTRA_DEFS_BUILD)
#define GLIBMM_GEN_EXTRA_DEFS_API __declspec (dllexport)
#else
#define GLIBMM_GEN_EXTRA_DEFS_API __declspec (dllimport)
#endif
#else
#define GLIBMM_GEN_EXTRA_DEFS_API
#endif

/** Function pointer type for functions that determine if a GType is a pointer
 * type.
 */
using GTypeIsAPointerFunc = bool(*)(GType gtype);

/** Default extra defs utility function to determine if a GType is a pointer
 * type.
 * @param gtype The GType.
 * @return true if the GType is a GObject or a boxed type, false otherwise.
 */
GLIBMM_GEN_EXTRA_DEFS_API
bool gtype_is_a_pointer(GType gtype);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_defs(GType gtype, GTypeIsAPointerFunc is_a_pointer_func = gtype_is_a_pointer);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_property_with_node_name(
  GParamSpec* pParamSpec, const std::string& strObjectName, const std::string& strNodeName);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_properties(GType gtype);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_type_name(GType gtype, GTypeIsAPointerFunc is_a_pointer_func = gtype_is_a_pointer);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_type_name_parameter(
  GType gtype, GTypeIsAPointerFunc is_a_pointer_func = gtype_is_a_pointer);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_type_name_signal(
  GType gtype, GTypeIsAPointerFunc is_a_pointer_func = gtype_is_a_pointer);

GLIBMM_GEN_EXTRA_DEFS_API
std::string get_signals(GType gtype, GTypeIsAPointerFunc is_a_pointer_func = gtype_is_a_pointer);
