#ifndef _GLIBMM_EXCEPTIONHANDLER_H
#define _GLIBMM_EXCEPTIONHANDLER_H

/* exceptionhandler.h
 *
 * Copyright 2002 The gtkmm Development Team
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
#include <sigc++/sigc++.h>

namespace Glib
{

/** Specify a slot to be called when an exception is thrown by a signal handler.
 */
GLIBMM_API
sigc::connection add_exception_handler(const sigc::slot<void()>& slot);

#ifndef DOXYGEN_SHOULD_SKIP_THIS
// internal
GLIBMM_API
void exception_handlers_invoke() noexcept;
#endif // DOXYGEN_SHOULD_SKIP_THIS

} // namespace Glib

#endif /* _GLIBMM_EXCEPTIONHANDLER_H */
