#ifndef _GIOMM_SLOT_ASYNC_H
#define _GIOMM_SLOT_ASYNC_H

/* Copyright (C) 2007 The gtkmm Development Team
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

#include <giommconfig.h>
#include <gio/gio.h>

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Gio
{

/** Callback function, used in combination with Gio::SlotAsyncReady.
 *
 * Example:
 * @code
 * _WRAP_METHOD(void acquire_async(const SlotAsyncReady& slot{callback},
 *   const Glib::RefPtr<Cancellable>& cancellable{.?}), g_permission_acquire_async,
 *   slot_name slot, slot_callback SignalProxy_async_callback)
 * @endcode
 */
GIOMM_API
void SignalProxy_async_callback(GObject*, GAsyncResult* res, void* data);

} // namespace Gio

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _GIOMM_SLOT_ASYNC_H */
