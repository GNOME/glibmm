/*
 * Copyright (C) 2012-13 The gtkmm Development Team
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

#include <glibmm/base64.h>
#include <glibmm/utility.h>

namespace Glib
{

std::string
Base64::encode(const std::string& source, bool break_lines)
{
  /* The output buffer must be large enough to fit all the data that will be
     written to it. Due to the way base64 encodes you will need at least:
     (len / 3 + 1) * 4 + 4 bytes (+ 4 may be needed in case of non-zero state).
     If you enable line-breaking you will need at least:
     ((len / 3 + 1) * 4 + 4) / 72 + 1 bytes of extra space.
  */
  gsize length = (source.length() / 3 + 1) * 4 + 1; // + 1 for the terminating zero
  length += ((length / 72) + 1); // in case break_lines = true
  const auto buf = make_unique_ptr_gfree((char*)g_malloc(length));
  gint state = 0, save = 0;
  const guchar* src = reinterpret_cast<const unsigned char*>(source.data());
  gsize out = g_base64_encode_step(src, source.length(), break_lines, buf.get(), &state, &save);
  out += g_base64_encode_close(break_lines, buf.get() + out, &state, &save);
  return std::string(buf.get(), buf.get() + out);
}

std::string
Base64::decode(const std::string& source)
{
  gsize size;
  const auto buf = make_unique_ptr_gfree((char*)g_base64_decode(source.c_str(), &size));
  return std::string(buf.get(), buf.get() + size);
}

} // namespace Glib
