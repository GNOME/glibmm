/* Copyright (C) 2014 The giomm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <giomm/socketsource.h>
#include <giomm/socket.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/wrap.h>
#include <gio/gio.h>

namespace
{
extern "C"
{
static gboolean
giomm_generic_socket_callback(sigc::slot_base* slot, GIOCondition condition)
{
  g_return_val_if_fail(slot != nullptr, FALSE);

  try
  {
    // Recreate the specific slot from the generic slot node.
    return (*static_cast<sigc::slot<bool(Glib::IOCondition)>*>(slot))((Glib::IOCondition)condition);
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

static gboolean
giomm_signalsocket_callback(GSocket*, GIOCondition condition, void* user_data)
{
  sigc::slot_base* const slot = Glib::Source::get_slot_from_connection_node(user_data);
  return giomm_generic_socket_callback(slot, condition);
}

static gboolean
giomm_socketsource_callback(GSocket*, GIOCondition condition, void* user_data)
{
  sigc::slot_base* const slot = Glib::Source::get_slot_from_callback_data(user_data);
  return giomm_generic_socket_callback(slot, condition);
}
} // extern "C"
} // anonymous namespace

namespace Gio
{

/**** Glib::SignalSocket *******************************************************/

inline SignalSocket::SignalSocket(GMainContext* context) : context_(context)
{
}

sigc::connection
SignalSocket::connect(const sigc::slot<bool(Glib::IOCondition)>& slot,
  const Glib::RefPtr<Socket>& socket, Glib::IOCondition condition,
  const Glib::RefPtr<Cancellable>& cancellable, int priority)
{
  GSource* const source =
    g_socket_create_source(socket->gobj(), (GIOCondition)condition, Glib::unwrap(cancellable));
  return Glib::Source::attach_signal_source(
    slot, priority, source, context_,
    Glib::function_pointer_cast<GSourceFunc>(&giomm_signalsocket_callback));
}

SignalSocket
signal_socket(const Glib::RefPtr<Glib::MainContext>& context)
{
  return SignalSocket(Glib::unwrap(context)); // 0 means default context
}

/**** Glib::SocketSource *******************************************************/

// static
Glib::RefPtr<SocketSource>
SocketSource::create(const Glib::RefPtr<Socket>& socket, Glib::IOCondition condition,
  const Glib::RefPtr<Cancellable>& cancellable)
{
  return Glib::make_refptr_for_instance<SocketSource>(new SocketSource(socket, condition, cancellable));
}

// static
Glib::RefPtr<SocketSource>
SocketSource::create(GSocket* socket, Glib::IOCondition condition,
  const Glib::RefPtr<Cancellable>& cancellable)
{
  return Glib::make_refptr_for_instance<SocketSource>(new SocketSource(socket, condition, cancellable));
}

SocketSource::SocketSource(const Glib::RefPtr<Socket>& socket, Glib::IOCondition condition,
  const Glib::RefPtr<Cancellable>& cancellable)
: IOSource(
    g_socket_create_source(socket->gobj(), (GIOCondition)condition, Glib::unwrap(cancellable)),
    Glib::function_pointer_cast<GSourceFunc>(&giomm_socketsource_callback))
{
}

SocketSource::SocketSource(GSocket* socket, Glib::IOCondition condition,
  const Glib::RefPtr<Cancellable>& cancellable)
: IOSource(
    g_socket_create_source(socket, (GIOCondition)condition, Glib::unwrap(cancellable)),
    Glib::function_pointer_cast<GSourceFunc>(&giomm_socketsource_callback))
{
}

SocketSource::~SocketSource() noexcept
{
}

} // namespace Gio
