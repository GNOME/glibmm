// -*- c++ -*-
/* $Id$ */

/* Copyright 2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm/dispatcher.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/fileutils.h>
#include <glibmm/main.h>
#include <glibmm/thread.h>

#include <fcntl.h>
#include <cerrno>
#include <glib.h>
#include <algorithm> //Needed by MSVC++.Net

#ifndef G_OS_WIN32
#include <unistd.h>
#else
#include <windows.h>
#include <io.h>
#include <direct.h>
#include <list>
#include <iostream>
#endif /* G_OS_WIN32 */


namespace
{

#ifdef G_OS_WIN32
/*
 * Template Class that is used to transfer notification data between
 * running thread and GUI-thread
 */
 //TODO: What does "TQ" mean?
template<class TQ> class Locked_Queue
{
public:
  Locked_Queue()
  {
  }
  
  ~Locked_Queue()
  {
    // We used new() to create the notification data so here we are
    // deleting all remaining pointers in the queue.
    std::transform(lqueue_.begin(), lqueue_.end(), lqueue_.begin(), delete_ptr);
  }

  TQ* get()
  {
    Glib::Mutex::Lock lock(mutex_);

    TQ* ret = 0;
    if(lqueue_.size() > 0)
    {
      ret = lqueue_.front();
      lqueue_.pop_front();
    }
    
    return ret;
  }
  
  void put(TQ* e)
  {
    Glib::Mutex::Lock lock(mutex_);
    lqueue_.push_back(e);
  }
  
private:
  Glib::Mutex mutex_;
  std::list<TQ*> lqueue_;
  
  static TQ* delete_ptr(TQ* p)
  {
    delete p;
    return 0;
  }
};

/*
 * Here we define differences between Win32 and UNIX pipe types and invalid values:
 */
#define FD_TYPE HANDLE
#define INVALID_FD (0)

#else //#ifdef G_OS_WIN32

#define FD_TYPE int
#define INVALID_FD (-1)

#endif //#ifdef G_OS_WIN32

struct DispatchNotifyData
{
  unsigned long           tag;
  Glib::Dispatcher*       dispatcher;
  Glib::DispatchNotifier* notifier;
};

void warn_failed_pipe_io(const char* what, int err_no)
{
  g_critical("Error in inter-thread communication: %s() failed: %s", what, g_strerror(err_no));
}

#ifndef G_OS_WIN32

/* Try to set the close-on-exec flag of the file descriptor,
 * so that it won't be leaked if a new process is spawned.
 */
void fd_set_close_on_exec(int fd)
{
  const int flags = fcntl(fd, F_GETFD, 0);
  g_return_if_fail(flags >= 0);

  fcntl(fd, F_SETFD, flags | FD_CLOEXEC);
}

#endif /* G_OS_WIN32 */

/* One word: paranoia.
 */
void fd_close_and_invalidate(FD_TYPE& fd)
{
  if(fd != INVALID_FD)
  {
#ifdef G_OS_WIN32
    // The way Win32 closes "pipe" handles
    if( !CloseHandle(fd) )
      warn_failed_pipe_io( "close", GetLastError() );
#else
    int result;

    do { result = close(fd); }
    while(result < 0 && errno == EINTR);

    if(result < 0)
      warn_failed_pipe_io("close", errno);
#endif /* G_OS_WIN32 */

    fd = INVALID_FD;
  }
}

} // anonymous namespace


namespace Glib
{

class DispatchNotifier
{
public:
  ~DispatchNotifier();

  static DispatchNotifier* reference_instance(const Glib::RefPtr<MainContext>& context);
  static void unreference_instance(DispatchNotifier* notifier);

  void send_notification(Dispatcher* dispatcher);

protected:
  // Only used by reference_instance().  Should be private, but that triggers
  // a silly gcc warning even though DispatchNotifier has static methods.
  explicit DispatchNotifier(const Glib::RefPtr<MainContext>& context);

private:
  static Glib::StaticPrivate<DispatchNotifier> thread_specific_instance_;

  Glib::RefPtr<MainContext> context_;
  int                       ref_count_;
  FD_TYPE                   fd_receiver_;
#ifdef G_OS_WIN32
  // queue used instead of sender pipe channel
  Locked_Queue<DispatchNotifyData>  notify_queue_;
#else
  FD_TYPE                   fd_sender_;
#endif /* G_OS_WIN32 */
  sigc::connection          conn_io_handler_;

  void create_pipe();
  bool pipe_io_handler(Glib::IOCondition condition);

  // noncopyable
  DispatchNotifier(const DispatchNotifier&);
  DispatchNotifier& operator=(const DispatchNotifier&);
};


/**** Glib::DispatchNotifier ***********************************************/

Glib::StaticPrivate<DispatchNotifier>
DispatchNotifier::thread_specific_instance_ = GLIBMM_STATIC_PRIVATE_INIT;

DispatchNotifier::DispatchNotifier(const Glib::RefPtr<MainContext>& context)
:
  context_      (context),
  ref_count_    (0),
  fd_receiver_  (INVALID_FD)
#ifndef G_OS_WIN32
  ,fd_sender_    (INVALID_FD)
#endif /* G_OS_WIN32 */
{
  create_pipe();

  try
  {
#ifdef G_OS_WIN32
    conn_io_handler_ = context_->signal_io().connect(
        sigc::mem_fun(*this, &DispatchNotifier::pipe_io_handler),
        GPOINTER_TO_INT(fd_receiver_), Glib::IO_IN);
#else
    conn_io_handler_ = context_->signal_io().connect(
        sigc::mem_fun(*this, &DispatchNotifier::pipe_io_handler),
        fd_receiver_, Glib::IO_IN);
#endif /* G_OS_WIN32 */
  }
  catch(...)
  {
#ifndef G_OS_WIN32
    fd_close_and_invalidate(fd_sender_);
#endif /* G_OS_WIN32 */
    fd_close_and_invalidate(fd_receiver_);

    throw;
  }
}

DispatchNotifier::~DispatchNotifier()
{
  // Disconnect manually because we don't inherit from sigc::trackable
  conn_io_handler_.disconnect();

#ifndef G_OS_WIN32
  fd_close_and_invalidate(fd_sender_);
#endif /* G_OS_WIN32 */
  fd_close_and_invalidate(fd_receiver_);
}

void DispatchNotifier::create_pipe()
{
#ifdef G_OS_WIN32
  // On Win32 we are using synchronization object instead of pipe
  // thus storing its handle as fd_receiver_
  if( !(fd_receiver_ = CreateEvent(NULL, FALSE, FALSE, NULL)) )
  {
    gint err_no = GetLastError();
    GError* const error = g_error_new( G_FILE_ERROR, g_file_error_from_errno( err_no ),
      "Failed to create pipe for inter-thread communication: %s",
      g_win32_error_message( err_no ) );

    throw Glib::FileError(error);
  }
#else
  int filedes[2] = { INVALID_FD, INVALID_FD };

  if(pipe(filedes) < 0)
  {
    GError* const error = g_error_new(G_FILE_ERROR, g_file_error_from_errno(errno),
      "Failed to create pipe for inter-thread communication: %s",
      g_strerror(errno));

    throw Glib::FileError(error);
  }

  fd_set_close_on_exec(filedes[0]);
  fd_set_close_on_exec(filedes[1]);

  fd_receiver_ = filedes[0];
  fd_sender_   = filedes[1];
#endif /* G_OS_WIN32 */
}

// static
DispatchNotifier* DispatchNotifier::reference_instance(const Glib::RefPtr<MainContext>& context)
{
  DispatchNotifier* instance = thread_specific_instance_.get();

  if(!instance)
  {
    instance = new DispatchNotifier(context);
    thread_specific_instance_.set(instance);
  }
  else
  {
    // Prevent massive mess-up.
    g_return_val_if_fail(instance->context_ == context, 0);
  }

  ++instance->ref_count_; // initially 0

  return instance;
}

// static
void DispatchNotifier::unreference_instance(DispatchNotifier* notifier)
{
  DispatchNotifier *const instance = thread_specific_instance_.get();

  // Yes, the notifier argument is only used to check for sanity.
  g_return_if_fail(instance == notifier);

  if(--instance->ref_count_ <= 0)
  {
    g_return_if_fail(instance->ref_count_ == 0); // could be < 0 if messed up

    // This will cause deletion of the notifier object.
    thread_specific_instance_.set(0);
  }
}

void DispatchNotifier::send_notification(Dispatcher* dispatcher)
{
#ifdef G_OS_WIN32
  DispatchNotifyData* data = new DispatchNotifyData();

  data->tag        = 0xdeadbeef;
  data->dispatcher = dispatcher;
  data->notifier   = this;

  // put notification data into queue
  notify_queue_.put(data);

  // send notification event to GUI-thread
  if( !SetEvent(fd_receiver_) )
  {
    warn_failed_pipe_io("write", GetLastError());
    return;
  }
#else
  DispatchNotifyData data = { 0xdeadbeef, dispatcher, this };
  gssize n_written;

  do { n_written = write(fd_sender_, &data, sizeof(data)); }
  while(n_written < 0 && errno == EINTR);

  if(n_written < 0)
  {
    warn_failed_pipe_io("write", errno);
    return;
  }

  // All data must be written in a single call to write(), otherwise we can't
  // guarantee reentrancy since another thread might be scheduled between two
  // write() calls.  The manpage is a bit unclear about this -- but I hope
  // it's safe to assume immediate success for the tiny amount of data we're
  // writing.
  g_return_if_fail(n_written == sizeof(data));
#endif /* G_OS_WIN32 */
}

bool DispatchNotifier::pipe_io_handler(Glib::IOCondition)
{
#ifdef G_OS_WIN32
  DispatchNotifyData* data;

  // read notification data from queue
  while( (data = notify_queue_.get()) )
  {
    DispatchNotifyData local_data = *data;
    // delete pointer cuz we did create it with new() operator
    delete data;
    g_return_val_if_fail(local_data.tag == 0xdeadbeef, true);
    g_return_val_if_fail(local_data.notifier == this, true);

    // Actually, we wouldn't need the try/catch block because
    // the Glib::Source C callback already does it for us.
    // However, we do it anyway because the default return value
    // is 'false', which is not what we want.
    try
    {
      local_data.dispatcher->signal_();
    }
    catch(...)
    {
      Glib::exception_handlers_invoke();
    }
  }
#else

  DispatchNotifyData data = { 0, 0, 0 };
  gsize n_read = 0;

  do
  {
    void * const buffer = reinterpret_cast<guint8*>(&data) + n_read;
    const gssize result = read(fd_receiver_, buffer, sizeof(data) - n_read);

    if(result < 0)
    {
      if(errno == EINTR)
        continue;

      warn_failed_pipe_io("read", errno);
      return true;
    }

    n_read += result;
  }
  while(n_read < sizeof(data));

  g_return_val_if_fail(data.tag == 0xdeadbeef, true);
  g_return_val_if_fail(data.notifier == this,  true);

  // Actually, we wouldn't need the try/catch block because the Glib::Source
  // C callback already does it for us.  However, we do it anyway because the
  // default return value is 'false', which is not what we want.
  try
  {
    data.dispatcher->signal_(); // emit
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }

#endif /* G_OS_WIN32 */

  return true;
}


/**** Glib::Dispatcher *****************************************************/

Dispatcher::Dispatcher()
:
  signal_   (),
  notifier_ (DispatchNotifier::reference_instance(MainContext::get_default()))
{}

Dispatcher::Dispatcher(const Glib::RefPtr<MainContext>& context)
:
  signal_   (),
  notifier_ (DispatchNotifier::reference_instance(context))
{}

Dispatcher::~Dispatcher()
{
  DispatchNotifier::unreference_instance(notifier_);
}

void Dispatcher::emit()
{
  notifier_->send_notification(this);
}

void Dispatcher::operator()()
{
  emit();
}

sigc::connection Dispatcher::connect(const sigc::slot<void>& slot)
{
  return signal_.connect(slot);
}

} // namespace Glib

