/* generate_defs_gtk.cc
 *
 * Copyright (C) 2001 The Free Software Foundation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "generate_extra_defs.h"
#include <glib.h>

int
main()
{
  // g_type_init() is deprecated as of 2.36.
  // g_type_init();

  std::cout << get_defs(G_TYPE_BINDING) << get_defs(G_TYPE_BYTES) << get_defs(G_TYPE_CHECKSUM)
            << get_defs(G_TYPE_DATE) << get_defs(G_TYPE_DATE_TIME) << get_defs(G_TYPE_IO_CHANNEL)
            << get_defs(G_TYPE_KEY_FILE) << get_defs(G_TYPE_MAIN_CONTEXT)
            << get_defs(G_TYPE_MAIN_LOOP) << get_defs(G_TYPE_MATCH_INFO) << get_defs(G_TYPE_REGEX)
            << get_defs(G_TYPE_SOURCE) << get_defs(G_TYPE_THREAD) << get_defs(G_TYPE_VARIANT)
            << get_defs(G_TYPE_VARIANT_BUILDER) << get_defs(G_TYPE_VARIANT_DICT) << std::endl;

  return 0;
}
