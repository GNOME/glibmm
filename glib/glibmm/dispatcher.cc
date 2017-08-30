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

#ifndef GLIBMM_CAN_USE_THREAD_LOCAL
#include <glibmm/threads.h>
#endif

#include <glibmm/dispatcher.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/fileutils.h>
#include <glibmm/main.h>

#include <cerrno>
#include <fcntl.h>
#include <glib.h>
#include <set>
#include <utility> // For std::move()

#ifdef G_OS_WIN32
#include <windows.h>
#include <io.h>
#include <direct.h>
#include <list>
#include <mutex>
#else
#include <unistd.h>
#endif

// EINTR is not defined on Tru64. I have tried including these:
// #include <sys/types.h>
// #include <sys/statvfs.h>
// #include <signal.h>
// danielk:  I think someone should just do a grep on a Tru64 box.  Googling
// for "tru64 EINTR" returns lots of hits telling me that handling EINTR is
// actually a requirement on Tru64.  So it must exist.
#if defined(_tru64) && !defined(EINTR)
#define EINTR 0 /* TODO: should use the real define */
#endif

namespace
{

struct DispatchNotifyData
{
  Glib::Dispatcher* dispatcher;
  Glib::DispatchNotifier* notifier;

  DispatchNotifyData() : dispatcher(nullptr), notifier(nullptr) {}

  DispatchNotifyData(Glib::Dispatcher* d, Glib::DispatchNotifier* n) : dispatcher(d), notifier(n) {}
};

static void
warn_failed_pipe_io(const char* what)
{
#ifdef G_OS_WIN32
  const char* const message = g_win32_error_message(GetLastError());
#else
  const char* const message = g_strerror(errno);
#endif
  g_critical("Error in inter-thread communication: %s() failed: %s", what, message);
}

#ifdef G_OS_WIN32

static void
fd_close_and_invalidate(HANDLE& fd)
{
  if (fd != 0)
  {
    if (!CloseHandle(fd))
      warn_failed_pipe_io("CloseHandle");

    fd = 0;
  }
}
#else /* !G_OS_WIN32 */
/*
 * Set the close-on-exec flag on the file descriptor,
 * so that it won't be leaked if a new process is spawned.
 */
static void
fd_set_close_on_exec(int fd)
{
  const int flags = fcntl(fd, F_GETFD, 0);

  if (flags < 0 || fcntl(fd, F_SETFD, unsigned(flags) | FD_CLOEXEC) < 0)
    warn_failed_pipe_io("fcntl");
}

static void
fd_close_and_invalidate(int& fd)
{
  if (fd >= 0)
  {
    int result;

    do
      result = close(fd);
    while (G_UNLIKELY(result < 0) && errno == EINTR);

    if (G_UNLIKELY(result < 0))
      warn_failed_pipe_io("close");

    fd = -1;
  }
}
#endif /* !G_OS_WIN32 */

} // anonymous namespace

namespace Glib
{

class DispatchNotifier : public sigc::trackable
{
public:
  ~DispatchNotifier() noexcept;

  // noncopyable
  DispatchNotifier(const DispatchNotifier&) = delete;
  DispatchNotifier& operator=(const DispatchNotifier&) = delete;

  static DispatchNotifier* reference_instance(
    const Glib::RefPtr<MainContext>& context, const Dispatcher* dispatcher);
  static void unreference_instance(DispatchNotifier* notifier, const Dispatcher* dispatcher);

  void send_notification(Dispatcher* dispatcher);

protected:
  // Only used by reference_instance().  Should be private, but that triggers
  // a silly gcc warning even though DispatchNotifier has static methods.
  explicit DispatchNotifier(const Glib::RefPtr<MainContext>& context);

private:
#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
  static thread_local DispatchNotifier* thread_specific_instance_;
#else
  static Glib::Threads::Private<DispatchNotifier> thread_specific_instance_;
#endif

  std::set<const Dispatcher*> deleted_dispatchers_;

  long ref_count_;
  Glib::RefPtr<MainContext> context_;
#ifdef G_OS_WIN32
  std::mutex mutex_;
  std::list<DispatchNotifyData> notify_queue_;
  HANDLE fd_receiver_;
#else
  int fd_receiver_;
  int fd_sender_;
#endif

  void create_pipe();
  bool pipe_io_handler(Glib::IOCondition condition);
  bool pipe_is_empty();
};

/**** Glib::DispatchNotifier ***********************************************/

// static

#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
thread_local DispatchNotifier* DispatchNotifier::thread_specific_instance_ = nullptr;
#else
Glib::Threads::Private<DispatchNotifier> DispatchNotifier::thread_specific_instance_;
#endif

DispatchNotifier::DispatchNotifier(const Glib::RefPtr<MainContext>& context)
: deleted_dispatchers_(),
  ref_count_(0),
  context_(context),
#ifdef G_OS_WIN32
  mutex_(),
  notify_queue_(),
  fd_receiver_(0)
#else
  fd_receiver_(-1),
  fd_sender_(-1)
#endif
{
  create_pipe();

  try
  {
    // PollFD::fd_t is the type of GPollFD::fd.
    // In Windows, it has the same size as HANDLE, but it's not guaranteed to be the same type.
    // In Unix, a file descriptor is an int.
    const auto fd = (PollFD::fd_t)fd_receiver_;

    // The following code is equivalent to
    // context_->signal_io().connect(
    //   sigc::mem_fun(*this, &DispatchNotifier::pipe_io_handler), fd, Glib::IO_IN);
    // except for source->set_can_recurse(true).

    const auto source = IOSource::create(fd, Glib::IO_IN);

    // If the signal emission in pipe_io_handler() starts a new main loop,
    // the event source shall not be blocked while that loop runs. (E.g. while
    // a connected slot function shows a modal dialog box.)
    source->set_can_recurse(true);

    source->connect(sigc::mem_fun(*this, &DispatchNotifier::pipe_io_handler));
    g_source_attach(source->gobj(), context_->gobj());
  }
  catch (...)
  {
#ifndef G_OS_WIN32
    fd_close_and_invalidate(fd_sender_);
#endif
    fd_close_and_invalidate(fd_receiver_);

    throw;
  }
}

DispatchNotifier::~DispatchNotifier() noexcept
{
#ifndef G_OS_WIN32
  fd_close_and_invalidate(fd_sender_);
#endif
  fd_close_and_invalidate(fd_receiver_);
}

void
DispatchNotifier::create_pipe()
{
#ifdef G_OS_WIN32

  // On Win32, create a synchronization object instead of a pipe and store
  // its handle as fd_receiver_.  Use a manual-reset event object, so that
  // we can closely match the behavior on Unix in pipe_io_handler().
  const HANDLE event = CreateEvent(0, TRUE, FALSE, 0);

  if (!event)
  {
    GError* const error = g_error_new(G_FILE_ERROR, G_FILE_ERROR_FAILED,
      "Failed to create event for inter-thread communication: %s",
      g_win32_error_message(GetLastError()));
    throw Glib::FileError(error);
  }

  fd_receiver_ = event;

#else /* !G_OS_WIN32 */

  int filedes[2] = { -1, -1 };

  if (pipe(filedes) < 0)
  {
    GError* const error = g_error_new(G_FILE_ERROR, g_file_error_from_errno(errno),
      "Failed to create pipe for inter-thread communication: %s", g_strerror(errno));
    throw Glib::FileError(error);
  }

  fd_set_close_on_exec(filedes[0]);
  fd_set_close_on_exec(filedes[1]);

  fd_receiver_ = filedes[0];
  fd_sender_ = filedes[1];

#endif /* !G_OS_WIN32 */
}

// static
DispatchNotifier*
DispatchNotifier::reference_instance(
  const Glib::RefPtr<MainContext>& context, const Dispatcher* dispatcher)
{
#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
  DispatchNotifier* instance = thread_specific_instance_;
#else
  DispatchNotifier* instance = thread_specific_instance_.get();
#endif

  if (!instance)
  {
    instance = new DispatchNotifier(context);
#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
    thread_specific_instance_ = instance;
#else
    thread_specific_instance_.replace(instance);
#endif
  }
  else
  {
    // Prevent massive mess-up.
    g_return_val_if_fail(instance->context_ == context, nullptr);

    // In the possible but unlikely case that a new dispatcher gets the same
    // address as a newly deleted one, if the pipe still contains messages to
    // the deleted dispatcher, those messages will be delivered to the new one.
    // Not ideal, but perhaps the best that can be done without breaking ABI.
    // The alternative would be to remove the following erase(), and risk not
    // delivering messages sent to the new dispatcher.
    // TODO: When we can break ABI, a better solution without this drawback can
    // be implemented. See https://bugzilla.gnome.org/show_bug.cgi?id=651942
    // especially comment 16.
    instance->deleted_dispatchers_.erase(dispatcher);
  }

  ++instance->ref_count_; // initially 0

  return instance;
}

// static
void
DispatchNotifier::unreference_instance(DispatchNotifier* notifier, const Dispatcher* dispatcher)
{
#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
  DispatchNotifier* const instance = thread_specific_instance_;
#else
  DispatchNotifier* const instance = thread_specific_instance_.get();
#endif

  // Yes, the notifier argument is only used to check for sanity.
  g_return_if_fail(instance == notifier);

  if (instance->pipe_is_empty())
    // No messages in the pipe. No need to keep track of deleted dispatchers.
    instance->deleted_dispatchers_.clear();
  else
    // There are messages in the pipe, possibly to the deleted dispatcher.
    // Keep its address, so pipe_io_handler() can avoid delivering messages to it.
    instance->deleted_dispatchers_.insert(dispatcher);

  if (--instance->ref_count_ <= 0)
  {
    g_return_if_fail(instance->ref_count_ == 0); // could be < 0 if messed up

#ifdef GLIBMM_CAN_USE_THREAD_LOCAL
    delete thread_specific_instance_;
    thread_specific_instance_ = nullptr;
#else
    thread_specific_instance_.replace(nullptr);
#endif
  }
}

void
DispatchNotifier::send_notification(Dispatcher* dispatcher)
{
#ifdef G_OS_WIN32
  {
    const std::lock_guard<std::mutex> lock(mutex_);

    const bool was_empty = notify_queue_.empty();
    notify_queue_.emplace_back(DispatchNotifyData(dispatcher, this));

    if (was_empty)
    {
      // The event will stay in signaled state until it is reset
      // in pipe_io_handler() after processing the last queued event.
      if (!SetEvent(fd_receiver_))
        warn_failed_pipe_io("SetEvent");
    }
  }
#else /* !G_OS_WIN32 */

  DispatchNotifyData data(dispatcher, this);
  gssize n_written;

  do
    n_written = write(fd_sender_, &data, sizeof(data));
  while (G_UNLIKELY(n_written < 0) && errno == EINTR);

  // All data must be written in a single call to write(), otherwise we cannot
  // guarantee reentrancy since another thread might be scheduled between two
  // write() calls.  From the glibc manual:
  //
  // "Reading or writing pipe data is atomic if the size of data written is not
  // greater than PIPE_BUF. This means that the data transfer seems to be an
  // instantaneous unit, in that nothing else in the system can observe a state
  // in which it is partially complete. Atomic I/O may not begin right away (it
  // may need to wait for buffer space or for data), but once it does begin it
  // finishes immediately."
  //
  // The minimum value allowed by POSIX for PIPE_BUF is 512, so we are on safe
  // grounds here.

  if (G_UNLIKELY(n_written != sizeof(data)))
    warn_failed_pipe_io("write");

#endif /* !G_OS_WIN32 */
}

bool
DispatchNotifier::pipe_is_empty()
{
#ifdef G_OS_WIN32
  return notify_queue_.empty();
#else
  PollFD poll_fd(fd_receiver_, Glib::IO_IN);
  // GPollFD*, number of file descriptors to poll, timeout (ms)
  g_poll(poll_fd.gobj(), 1, 0);
  return (poll_fd.get_revents() & Glib::IO_IN) == 0;
#endif
}

bool DispatchNotifier::pipe_io_handler(Glib::IOCondition)
{
  DispatchNotifyData data;

#ifdef G_OS_WIN32
  {
    const std::lock_guard<std::mutex> lock(mutex_);

    // Should never be empty at this point, but let's allow for bogus
    // notifications with no data available anyway; just to be safe.
    if (notify_queue_.empty())
    {
      if (!ResetEvent(fd_receiver_))
        warn_failed_pipe_io("ResetEvent");

      return true;
    }

    data = notify_queue_.front();
    notify_queue_.pop_front();

    // Handle only a single event with each invocation of the I/O handler,
    // and reset to nonsignaled state only after the last event in the queue
    // has been processed.  This matches the behavior on Unix.
    if (notify_queue_.empty())
    {
      if (!ResetEvent(fd_receiver_))
        warn_failed_pipe_io("ResetEvent");
    }
  }
#else /* !G_OS_WIN32 */

  gssize n_read;

  do
    n_read = read(fd_receiver_, &data, sizeof(data));
  while (G_UNLIKELY(n_read < 0) && errno == EINTR);

  // Pipe I/O of a block size not greater than PIPE_BUF should be atomic.
  // See the comment on atomicity in send_notification() for details.
  if (G_UNLIKELY(n_read != sizeof(data)))
  {
    // Should probably never be zero, but for safety let's allow for bogus
    // notifications when no data is actually available.  Although in fact
    // the read() should block in that case.
    if (n_read != 0)
      warn_failed_pipe_io("read");

    return true;
  }
#endif /* !G_OS_WIN32 */

  g_return_val_if_fail(data.notifier == this, true);

  // Drop the received message, if it is addressed to a deleted dispatcher.
  const bool drop_message =
    (deleted_dispatchers_.find(data.dispatcher) != deleted_dispatchers_.end());

  // If the pipe is empty, there can be no messages to deleted dispatchers.
  // No reason to keep track of them any more.
  if (!deleted_dispatchers_.empty() && pipe_is_empty())
    deleted_dispatchers_.clear();

  if (drop_message)
  {
    g_warning("Dropped dispatcher message as the dispatcher no longer exists");
    return true;
  }

  // Actually, we wouldn't need the try/catch block because the Glib::Source
  // C callback already does it for us.  However, we do it anyway because the
  // default return value is 'false', which is not what we want.
  try
  {
    data.dispatcher->signal_(); // emit
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }

  return true;
}

/**** Glib::Dispatcher *****************************************************/

Dispatcher::Dispatcher()
: signal_(), notifier_(DispatchNotifier::reference_instance(MainContext::get_default(), this))
{
}

Dispatcher::Dispatcher(const Glib::RefPtr<MainContext>& context)
: signal_(), notifier_(DispatchNotifier::reference_instance(context, this))
{
}

Dispatcher::~Dispatcher() noexcept
{
  DispatchNotifier::unreference_instance(notifier_, this);
}

void
Dispatcher::emit()
{
  notifier_->send_notification(this);
}

void
Dispatcher::operator()()
{
  notifier_->send_notification(this);
}

sigc::connection
Dispatcher::connect(const sigc::slot<void>& slot)
{
  return signal_.connect(slot);
}

sigc::connection
Dispatcher::connect(sigc::slot<void>&& slot)
{
  return signal_.connect(std::move(slot));
}

} // namespace Glib
