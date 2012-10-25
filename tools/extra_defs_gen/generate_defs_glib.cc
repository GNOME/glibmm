/* $Id$ */

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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "generate_extra_defs.h"
#include <glib.h>

int main()
{
  // g_type_init() is deprecated as of 2.36.
  // g_type_init();

  std::cout << get_defs( G_TYPE_DATE )
            << get_defs( G_TYPE_IO_CHANNEL )
            << get_defs( G_TYPE_REGEX )
            << get_defs( G_TYPE_VARIANT )
            << std::endl;

  return 0;
}
