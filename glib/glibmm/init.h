#ifndef _GLIBMM_INIT_H
#define _GLIBMM_INIT_H

/* Copyright (C) 2002 The gtkmm Development Team
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

#include <glibmmconfig.h>

namespace Glib
{

/** Initialize glibmm.
 *
 * Call it before you use other parts of glibmm. You may call it more than once.
 * Calls after the first one have no effect.
 *
 * You do not need to call %Glib::init() if you are using Gtk::Application or
 * Gio::init(), because they call %Glib::init() for you.
 */
GLIBMM_API
void init();

} // namespace Glib

#endif /* _GLIBMM_INIT_H */
