#ifndef _GIOMM_INIT_H
#define _GIOMM_INIT_H

#include "wrap_init.h"

/* init.h
 *
 * Copyright (C) 2007 The gtkmm development team
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

namespace Gio
{

/** Initialize giomm and glibmm.
 *
 * Call it before you use other parts of giomm. You may call it more than once.
 * Calls after the first one have no effect. %Gio::init() calls Glib::init(), which
 * sets the global locale as specified by Glib::set_init_to_users_preferred_locale().
 *
 * You do not need to call %Gio::init() if you are using Gtk::Application,
 * because it calls %Gio::init() for you.
 *
 * @see Glib::set_init_to_users_preferred_locale()
 */
GIOMM_API
void init();

} // end namespace Gio

#endif //_GIOMM_INIT_H
