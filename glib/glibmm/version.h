#ifndef _GLIBMM_VERSION_H
#define _GLIBMM_VERSION_H

/* Copyright (C) 2023 The gtkmm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmmconfig.h>

// GLIBMM_M*_VERSION are defined in glibmmconfig.h.
// They are described here because Doxygen does not document glibmmconfig.h.

#ifdef DOXYGEN_SHOULD_SKIP_THIS
// Only Doxygen sees this.
#define GLIBMM_MAJOR_VERSION
#define GLIBMM_MINOR_VERSION
#define GLIBMM_MICRO_VERSION
#endif

/** @defgroup Version Version
 * Glibmm version
 * @{
 */

/** @def GLIBMM_MAJOR_VERSION
 * The major version number of the GLIBMM library.
 *
 * From the headers used at application compile time.
 * E.g. in GLIBMM version 2.76.1 this is 2.
 */

/** @def GLIBMM_MINOR_VERSION
 * The minor version number of the GLIBMM library.
 *
 * From the headers used at application compile time.
 * E.g. in GLIBMM version 2.76.1 this is 76.
 */

/** @def GLIBMM_MICRO_VERSION
 * The micro version number of the GLIBMM library.
 *
 * From the headers used at application compile time.
 * E.g. in GLIBMM version 2.76.1 this is 1.
 */

/** Checks the version of the GLIBMM header files at compile time.
 *
 * Returns <tt>true</tt> if the version of the GLIBMM header files
 * is the same as or newer than the passed-in version.
 *
 * @newin{2,76}
 *
 * @param major Major version (e.g. 2 for version 2.76.1)
 * @param minor Minor version (e.g. 76 for version 2.76.1)
 * @param micro Micro version (e.g. 1 for version 2.76.1)
 * @returns <tt>true</tt> if GLIBMM headers are new enough.
 */
#define GLIBMM_CHECK_VERSION(major, minor, micro) \
  (GLIBMM_MAJOR_VERSION > (major) || \
  (GLIBMM_MAJOR_VERSION == (major) && GLIBMM_MINOR_VERSION > (minor)) || \
  (GLIBMM_MAJOR_VERSION == (major) && GLIBMM_MINOR_VERSION == (minor) && \
   GLIBMM_MICRO_VERSION >= (micro)))

/** @} */ // end of group Version

#endif // _GLIBMM_VERSION_H
