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

#include <glibmm/exceptionhandler.h>
#include <giomm/asyncresult.h>
#include <giomm/slot_async.h>

namespace Gio
{
extern "C"
{
// A function with external linkage and C linkage does not get a mangled name.
// Even though giomm_SignalProxy_async_callback is declared in a named namespace,
// the linker does not see the namespace name, only 'giomm_SignalProxy_async_callback'.
// Therefore the function name shall have a prefix, hopefully unique.
void
giomm_SignalProxy_async_callback(GObject*, GAsyncResult* res, void* data)
{
  Gio::SlotAsyncReady* the_slot = static_cast<Gio::SlotAsyncReady*>(data);

  try
  {
    auto result = Glib::wrap(res, true /* take copy */);
    (*the_slot)(result);
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }

  delete the_slot;
}
} // extern "C"

//TODO: Remove SignalProxy_async_callback when we can break ABI and API.
void
SignalProxy_async_callback(GObject* source_object, GAsyncResult* res, void* data)
{
  giomm_SignalProxy_async_callback(source_object, res, data);
}

} // namespace Gio
