#ifndef _GLIBMM_BASE64_H
#define _GLIBMM_BASE64_H

/*
 * Copyright (C) 2012-2013 The gtkmm Development Team
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

#include <string>
#include <glib.h>

namespace Glib
{

/** @defgroup Base64 Base64 routines
 * Base64 encoding/decoding routines.
 * @{
 */

namespace Base64
{

/** Encode the given string in base64 encoding.
 *  You can pass <tt>true</tt> as the @a break_lines parameter to enable
 *  line breaking, that is usually used in mail systems. The new line
 *  character will appear for every 72 bytes.
 * @param source A string to encode.
 * @param break_lines Enables/disables line breaking.
 * @return The string encoded in Base-64.
 */
std::string encode(const std::string& source, bool break_lines = false);

/** Decode the given base64 encoded string.
 * @param source A string to decode.
 * @return The resulting decode string
 */
std::string decode(const std::string& source);
}

/** @} group Base64 */

} // namespace Glib

#endif /* _GLIBMM_BASE64_H */
