#ifndef _GLIBMM_DISPATCHER_H
#define _GLIBMM_DISPATCHER_H

/* Copyright 2002 The gtkmm Development Team
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

#include <sigc++/sigc++.h>
#include <glibmm/main.h>

namespace Glib
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS
class DispatchNotifier;
#endif

/** Signal class for inter-thread communication.
 * @ingroup Threads
 * Glib::Dispatcher works similar to sigc::signal<void>.  But unlike normal
 * signals, the notification happens asynchronously through a pipe.  This is
 * a simple and efficient way of communicating between threads, and especially
 * useful in a thread model with a single GUI thread.
 *
 * No mutex locking is involved, apart from the operating system's internal
 * I/O locking.  That implies some usage rules:
 *
 * @li Only one thread may connect to the signal and receive notification, but
 * multiple senders are allowed even without locking.
 * @li The GLib main loop must run in the receiving thread (this will be the
 * GUI thread usually).
 * @li The Dispatcher object must be instantiated by the receiver thread.
 * @li The Dispatcher object should be instantiated before creating any of the
 * sender threads, if you want to avoid extra locking.
 * @li The Dispatcher object must be deleted by the receiver thread.
 * @li All Dispatcher objects instantiated by the same receiver thread must
 * use the same main context.
 *
 * Notes about performance:
 *
 * @li After instantiation, Glib::Dispatcher will never lock any mutexes on its
 * own.  The interaction with the GLib main loop might involve locking on the
 * @em receiver side.  The @em sender side, however, is guaranteed not to lock,
 * except for internal locking in the <tt>%write()</tt> system call.
 * @li All Dispatcher instances of a receiver thread share the same pipe.  That
 * is, if you use Glib::Dispatcher only to notify the GUI thread, only one pipe
 * is created no matter how many Dispatcher objects you have.
 *
 * Using Glib::Dispatcher on Windows:
 *
 * Glib::Dispatcher also works on win32-based systems.  Unfortunately though,
 * the implementation cannot use a pipe on win32 and therefore does have to
 * lock a mutex on emission, too.  However, the impact on performance is
 * likely minor and the notification still happens asynchronously.  Apart
 * from the additional lock the behavior matches the Unix implementation.
 */
class Dispatcher
{
public:
  /** Create new Dispatcher instance using the default main context.
   * @throw Glib::FileError
   */
  Dispatcher();

  // noncopyable
  Dispatcher(const Dispatcher&) = delete;
  Dispatcher& operator=(const Dispatcher&) = delete;

  /** Create new Dispatcher instance using an arbitrary main context.
   * @throw Glib::FileError
   */
  explicit Dispatcher(const Glib::RefPtr<MainContext>& context);
  ~Dispatcher() noexcept;

  void emit();
  void operator()();

  sigc::connection connect(const sigc::slot<void>& slot);
  /** @newin{2,48}
   */
  sigc::connection connect(sigc::slot<void>&& slot);

private:
  sigc::signal<void> signal_;
  DispatchNotifier* notifier_;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  friend class Glib::DispatchNotifier;
#endif
};

/*! A Glib::Dispatcher example.
 * @example thread/dispatcher.cc
 */

} // namespace Glib

#endif /* _GLIBMM_DISPATCHER_H */
