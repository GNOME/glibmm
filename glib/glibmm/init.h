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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

namespace Glib
{

/** Initialize glibmm.
 *
 * You may call this more than once. Calls after the first one have no effect.
 * Sets the global locale as specified by set_init_to_users_preferred_locale().
 * You do not need to call %Glib::init() if you are using Gtk::Application,
 * because it calls %Glib::init() for you.
 *
 * @see set_init_to_users_preferred_locale()
 */
void init();

/** Instruct Glib::init() which global locale to set.
 *
 * To have the intended effect, this function must be called before init() is called.
 * Not calling it has the same effect as calling it with @a state = <tt>true</tt>.
 *
 * Note the confusing difference between C locale and "C" locale.
 * The C locale is the locale used by C code, set by std::setlocale(LC_ALL,&nbsp;locale_name).
 * The "C" locale is the classic locale, set by std::setlocale(LC_ALL,&nbsp;"C")
 * or std::locale::global(std::locale::classic()). It's the default global locale
 * in a C or C++ program.
 *
 * In a mixed C and C++ program, like a program using glibmm, having the C global
 * locale differ from std::locale::global() is error prone. Glib::init() tries
 * to avoid that.
 *
 * @param state If <tt>true</tt>, init() will set the C and C++ global locale
 *              to the user's preferred locale (std::locale::global(std::locale(""))).
 *              The user's preferred locale is set in the program's environment,
 *              usually with the LANG environment variable.<br>
 *              If <tt>false</tt>, init() will set the C++ global locale to the C global locale
 *              (std::locale::global(std::locale(std::setlocale(LC_ALL,&nbsp;nullptr)))).
 *
 * @newin{2,52}
 */
void set_init_to_users_preferred_locale(bool state = true);

/** Get the state, set with set_init_to_users_preferred_locale().
 * @returns The state, set with set_init_to_users_preferred_locale(); <tt>true</tt>
 *          if set_init_to_users_preferred_locale() has not been called.
 *
 * @newin{2,52}
 */
bool get_init_to_users_preferred_locale();

} // namespace Glib

#endif /* _GLIBMM_INIT_H */
