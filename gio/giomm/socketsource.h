#ifndef _GIOMM_SOCKETSOURCE_H
#define _GIOMM_SOCKETSOURCE_H

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

#include <glibmm/refptr.h>
#include <glibmm/main.h>
#include <glibmm/priorities.h>
#include <giomm/cancellable.h>
#include <sigc++/sigc++.h>

namespace Gio
{
class Socket;

/** @newin{2,42}
 * @ingroup NetworkIO
 */
class SignalSocket
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalSocket(GMainContext* context);
#endif

  /** Connects an I/O handler that watches a socket.
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * Gio::signal_socket().connect(sigc::ptr_fun(&io_handler), socket, Glib::IO_IN | Glib::IO_OUT);
   * @endcode
   * is equivalent to:
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * const auto socket_source = Gio::SocketSource::create(socket, Glib::IO_IN | Glib::IO_OUT);
   * socket_source->connect(sigc::ptr_fun(&io_handler));
   * socket_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalSocket
   * object's MainContext runs.
   *
   * @newin{2,42}
   *
   * @param slot A slot to call when polling @a socket results in an event that matches @a
   * condition.
   * The event will be passed as a parameter to @a slot.
   * If <tt>io_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param socket The Socket object to watch.
   * @param condition The conditions to watch for.
   * @param cancellable A Cancellable object which can be used to cancel the source,
   *        which will cause the source to trigger, reporting the current condition
   *        (which is likely 0 unless cancellation happened at the same time as a condition change).
   *        You can check for this in the callback using Cancellable::is_cancelled().
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(const sigc::slot<bool, Glib::IOCondition>& slot,
    const Glib::RefPtr<Socket>& socket, Glib::IOCondition condition,
    const Glib::RefPtr<Cancellable>& cancellable = Glib::RefPtr<Cancellable>(),
    int priority = Glib::PRIORITY_DEFAULT);

private:
  GMainContext* context_;

  // no copy assignment
  SignalSocket& operator=(const SignalSocket&);
};

/** Convenience socket signal.
 * @param context The main context to which the signal shall be attached.
 * @return A signal proxy; you want to use SignalSocket::connect().
 *
 * @newin{2,42}
 * @ingroup NetworkIO
 */
SignalSocket signal_socket(
  const Glib::RefPtr<Glib::MainContext>& context = Glib::RefPtr<Glib::MainContext>());

/** An event source that can monitor a Gio::Socket.
 * @see Gio::Socket::create_source().
 *
 * @newin{2,42}
 * @ingroup NetworkIO
 */
class SocketSource : public Glib::IOSource
{
public:
  using CppObjectType = Gio::SocketSource;

  static Glib::RefPtr<SocketSource> create(const Glib::RefPtr<Socket>& socket,
    Glib::IOCondition condition,
    const Glib::RefPtr<Cancellable>& cancellable = Glib::RefPtr<Cancellable>());

protected:
  SocketSource(const Glib::RefPtr<Socket>& socket, Glib::IOCondition condition,
    const Glib::RefPtr<Cancellable>& cancellable);
  ~SocketSource() noexcept override;
};

} // namespace Gio

#endif /* _GIOMM_SOCKETSOURCE_H */
