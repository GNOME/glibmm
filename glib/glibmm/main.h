#ifndef _GLIBMM_MAIN_H
#define _GLIBMM_MAIN_H

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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/refptr.h>
#include <glibmm/priorities.h>
#include <glibmm/iochannel.h>
#include <glibmm/enums.h>
#include <sigc++/sigc++.h>
#include <vector>
#include <cstddef>
#include <atomic>

namespace Glib
{

/** @defgroup MainLoop The Main Event Loop
 * Manages all available sources of events.
 * @{
 */
class GLIBMM_API PollFD
{
public:
  using fd_t = decltype(GPollFD::fd);

  PollFD();
  explicit PollFD(fd_t fd);
  PollFD(fd_t fd, IOCondition events);

  void set_fd(fd_t fd) { gobject_.fd = fd; }
  fd_t get_fd() const { return gobject_.fd; }

  void set_events(IOCondition events) { gobject_.events = static_cast<decltype(gobject_.events)>(events); }
  IOCondition get_events() const { return static_cast<IOCondition>(gobject_.events); }

  void set_revents(IOCondition revents) { gobject_.revents = static_cast<decltype(gobject_.revents)>(revents); }
  IOCondition get_revents() const { return static_cast<IOCondition>(gobject_.revents); }

  GPollFD* gobj() { return &gobject_; }
  const GPollFD* gobj() const { return &gobject_; }

private:
  GPollFD gobject_;
};

class GLIBMM_API SignalTimeout
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalTimeout(GMainContext* context);
#endif

  /** Connects a timeout handler.
   *
   * Note that timeout functions may be delayed, due to the processing of other
   * event sources. Thus they should not be relied on for precise timing.
   * After each call to the timeout function, the time of the next
   * timeout is recalculated based on the current time and the given interval
   * (it does not try to 'catch up' time lost in delays).
   *
   * If you want to have a timer in the "seconds" range and do not care
   * about the exact time of the first call of the timer, use the
   * connect_seconds() function; this function allows for more
   * optimizations and more efficient system power usage.
   *
   * @code
   * bool timeout_handler() { ... }
   * Glib::signal_timeout().connect(sigc::ptr_fun(&timeout_handler), 1000);
   * @endcode
   * is equivalent to:
   * @code
   * bool timeout_handler() { ... }
   * const auto timeout_source = Glib::TimeoutSource::create(1000);
   * timeout_source->connect(sigc::ptr_fun(&timeout_handler));
   * timeout_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalTimeout
   * object's MainContext runs.
   *
   * @param slot A slot to call when @a interval has elapsed.
   * If <tt>timeout_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param interval The timeout in milliseconds.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(
    const sigc::slot<bool()>& slot, unsigned int interval, int priority = PRIORITY_DEFAULT);

  /** Connects a timeout handler that runs only once.
   * This method takes a function pointer to a function with a void return
   * and no parameters. After running once it is not called again.
   *
   * Because sigc::trackable is not thread-safe, if the slot represents a
   * non-static method of a class deriving from sigc::trackable, and the slot is
   * created by sigc::mem_fun(), connect_once() should only be called from
   * the thread where the SignalTimeout object's MainContext runs. You can use,
   * say, boost::bind() or, in C++11, std::bind() or a C++11 lambda expression
   * instead of sigc::mem_fun().
   *
   * @see connect()
   * @param slot A slot to call when @a interval has elapsed. For example:
   * @code
   * void on_timeout_once()
   * @endcode
   * @param interval The timeout in milliseconds.
   * @param priority The priority of the new event source.
   */
  void connect_once(
    const sigc::slot<void()>& slot, unsigned int interval, int priority = PRIORITY_DEFAULT);

  /** Connects a timeout handler with whole second granularity.
   *
   * Unlike connect(), this operates at whole second granularity.
   * The initial starting point of the timer is determined by the implementation
   * and the implementation is expected to group multiple timers together so that
   * they fire all at the same time.
   *
   * To allow this grouping, the @a interval to the first timer is rounded
   * and can deviate up to one second from the specified interval.
   * Subsequent timer iterations will generally run at the specified interval.
   *
   * @code
   * bool timeout_handler() { ... }
   * Glib::signal_timeout().connect_seconds(sigc::ptr_fun(&timeout_handler), 5);
   * @endcode
   * is equivalent to:
   * @code
   * bool timeout_handler() { ... }
   * const auto timeout_source = Glib::TimeoutSource::create(5000);
   * timeout_source->connect(sigc::ptr_fun(&timeout_handler));
   * timeout_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalTimeout
   * object's MainContext runs.
   *
   * @param slot A slot to call when @a interval has elapsed.
   * If <tt>timeout_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param interval The timeout in seconds.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   *
   * @newin{2,14}
   */
  sigc::connection connect_seconds(
    const sigc::slot<bool()>& slot, unsigned int interval, int priority = PRIORITY_DEFAULT);

  /** Connects a timeout handler that runs only once with whole second
   *  granularity.
   *
   * This method takes a function pointer to a function with a void return
   * and no parameters. After running once it is not called again.
   *
   * Because sigc::trackable is not thread-safe, if the slot represents a
   * non-static method of a class deriving from sigc::trackable, and the slot is
   * created by sigc::mem_fun(), connect_seconds_once() should only be called from
   * the thread where the SignalTimeout object's MainContext runs. You can use,
   * say, boost::bind() or, in C++11, std::bind() or a C++11 lambda expression
   * instead of sigc::mem_fun().
   *
   * @see connect_seconds()
   * @param slot A slot to call when @a interval has elapsed. For example:
   * @code
   * void on_timeout_once()
   * @endcode
   * @param interval The timeout in seconds.
   * @param priority The priority of the new event source.
   */
  void connect_seconds_once(
    const sigc::slot<void()>& slot, unsigned int interval, int priority = PRIORITY_DEFAULT);

private:
  GMainContext* context_;

  // no copy assignment
  SignalTimeout& operator=(const SignalTimeout&) = delete;
};

class GLIBMM_API SignalIdle
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalIdle(GMainContext* context);
#endif

  /** Connects an idle handler.
   * @code
   * bool idle_handler() { ... }
   * Glib::signal_idle().connect(sigc::ptr_fun(&idle_handler));
   * @endcode
   * is equivalent to:
   * @code
   * bool idle_handler() { ... }
   * const auto idle_source = Glib::IdleSource::create();
   * idle_source->connect(sigc::ptr_fun(&idle_handler));
   * idle_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalIdle
   * object's MainContext runs.
   *
   * @param slot A slot to call when the main loop is idle.
   * If <tt>idle_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(const sigc::slot<bool()>& slot, int priority = PRIORITY_DEFAULT_IDLE);

  /** Connects an idle handler that runs only once.
   * This method takes a function pointer to a function with a void return
   * and no parameters. After running once it is not called again.
   *
   * Because sigc::trackable is not thread-safe, if the slot represents a
   * non-static method of a class deriving from sigc::trackable, and the slot is
   * created by sigc::mem_fun(), connect_once() should only be called from
   * the thread where the SignalIdle object's MainContext runs. You can use,
   * say, boost::bind() or, in C++11, std::bind() or a C++11 lambda expression
   * instead of sigc::mem_fun().
   *
   * @see connect()
   * @param slot A slot to call when the main loop is idle. For example:
   * @code
   * void on_idle_once()
   * @endcode
   * @param priority The priority of the new event source.
   */
  void connect_once(const sigc::slot<void()>& slot, int priority = PRIORITY_DEFAULT_IDLE);

private:
  GMainContext* context_;

  // no copy assignment
  SignalIdle& operator=(const SignalIdle&) = delete;
};

class GLIBMM_API SignalIO
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalIO(GMainContext* context);
#endif

  /** Connects an I/O handler that watches a file descriptor.
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * Glib::signal_io().connect(sigc::ptr_fun(&io_handler), fd, Glib::IO_IN | Glib::IO_HUP);
   * @endcode
   * is equivalent to:
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * const auto io_source = Glib::IOSource::create(fd, Glib::IO_IN | Glib::IO_HUP);
   * io_source->connect(sigc::ptr_fun(&io_handler));
   * io_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalIO
   * object's MainContext runs.
   *
   * @param slot A slot to call when polling @a fd results in an event that matches @a condition.
   * The event will be passed as a parameter to @a slot.
   * If <tt>io_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param fd The file descriptor (or a @c HANDLE on Win32 systems) to watch.
   * @param condition The conditions to watch for.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(const sigc::slot<bool(IOCondition)>& slot, PollFD::fd_t fd, IOCondition condition,
    int priority = PRIORITY_DEFAULT);

  /** Connects an I/O handler that watches an I/O channel.
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * Glib::signal_io().connect(sigc::ptr_fun(&io_handler), channel, Glib::IO_IN | Glib::IO_HUP);
   * @endcode
   * is equivalent to:
   * @code
   * bool io_handler(Glib::IOCondition io_condition) { ... }
   * const auto io_source = Glib::IOSource::create(channel, Glib::IO_IN | Glib::IO_HUP);
   * io_source->connect(sigc::ptr_fun(&io_handler));
   * io_source->attach(Glib::MainContext::get_default());
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalIO
   * object's MainContext runs.
   *
   * @param slot A slot to call when polling @a channel results in an event that matches @a
   * condition.
   * The event will be passed as a parameter to @a slot.
   * If <tt>io_handler()</tt> returns <tt>false</tt> the handler is disconnected.
   * @param channel The IOChannel object to watch.
   * @param condition The conditions to watch for.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(const sigc::slot<bool(IOCondition)>& slot,
    const Glib::RefPtr<IOChannel>& channel, IOCondition condition, int priority = PRIORITY_DEFAULT);

private:
  GMainContext* context_;

  // no copy assignment
  SignalIO& operator=(const SignalIO&) = delete;
};

class GLIBMM_API SignalChildWatch
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalChildWatch(GMainContext* context);
#endif
  /** Connects a child watch handler.
   * @code
   * void child_watch_handler(GPid pid, int child_status) { ... }
   * Glib::signal_child_watch().connect(sigc::ptr_fun(&child_watch_handler), pid);
   * @endcode
   *
   * This method is not thread-safe. You should call it, or manipulate the
   * returned sigc::connection object, only from the thread where the SignalChildWatch
   * object's MainContext runs.
   *
   * @param slot A slot to call when child process @a pid exited.
   * @param pid The child process to watch for.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  sigc::connection connect(
    const sigc::slot<void(GPid, int)>& slot, GPid pid, int priority = PRIORITY_DEFAULT);

private:
  GMainContext* context_;

  // no copy assignment
  SignalChildWatch& operator=(const SignalChildWatch&) = delete;
};

/** Convenience timeout signal.
 * @return A signal proxy; you want to use SignalTimeout::connect().
 */
GLIBMM_API
SignalTimeout signal_timeout();

/** Convenience idle signal.
 * @return A signal proxy; you want to use SignalIdle::connect().
 */
GLIBMM_API
SignalIdle signal_idle();

/** Convenience I/O signal.
 * @return A signal proxy; you want to use SignalIO::connect().
 */
GLIBMM_API
SignalIO signal_io();

/** Convenience child watch signal.
 * @return A signal proxy; you want to use SignalChildWatch::connect().
 */
GLIBMM_API
SignalChildWatch signal_child_watch();

/** Main context.
 */
class GLIBMM_API MainContext
{
public:
  using CppObjectType = Glib::MainContext;
  using BaseObjectType = GMainContext;

  // noncopyable
  MainContext(const MainContext& other) = delete;
  MainContext& operator=(const MainContext& other) = delete;

  /** Creates a new %MainContext.
   * @return The new %MainContext.
   */
  static Glib::RefPtr<MainContext> create();
  /** Creates a new %MainContext.
   *
   * @param flags A bitwise-OR combination of MainContextFlags flags that
   *              can only be set at creation time.
   * @return The new %MainContext.
   *
   * @newin{2,72}
   */
  static Glib::RefPtr<MainContext> create(MainContextFlags flags);

  /** Returns the global default main context.
   * This is the main context used for main loop functions when a main loop
   * is not explicitly specified, and corresponds to the "main" main loop.
   *
   * @return The global default main context.
   * @see get_thread_default()
   */
  static Glib::RefPtr<MainContext> get_default();

  /** Runs a single iteration for the given main loop.
   * This involves checking to see if any event sources are ready to be processed, then if no events
   * sources are
   * ready and may_block is true, waiting for a source to become ready, then dispatching the highest
   * priority events
   * sources that are ready. Note that even when may_block is true, it is still possible for
   * iteration() to return
   * false, since the the wait may be interrupted for other reasons than an event source becoming
   * ready.
   * @param may_block Whether the call may block.
   * @return true if events were dispatched.
   */
  bool iteration(bool may_block);

  /** Checks if any sources have pending events for the given context.
   * @return true if events are pending.
   */
  bool pending();

  /** If context is currently waiting in a poll(), interrupt the poll(), and continue the iteration
   * process.
   */
  void wakeup();

  /** Tries to become the owner of the specified context.
   * If some other thread is the owner of the context, returns <tt>false</tt> immediately. Ownership
   * is properly recursive:
   * the owner can require ownership again and will release ownership when release() is called as
   * many times as
   * acquire().
   * You must be the owner of a context before you can call prepare(), query(), check(), dispatch().
   * @return true if the operation succeeded, and this thread is now the owner of context.
   */
  bool acquire();

  /** Releases ownership of a context previously acquired by this thread with acquire(). If the
   * context was acquired
   * multiple times, the only release ownership when release() is called as many times as it was
   * acquired.
   */
  void release();

  /** Prepares to poll sources within a main loop. The resulting information for polling is
   * determined by calling query().
   * @param priority Location to store priority of highest priority source already ready.
   * @return true if some source is ready to be dispatched prior to polling.
   */
  bool prepare(int& priority);

  /** Prepares to poll sources within a main loop. The resulting information for polling is
   * determined by calling query().
   * @return true if some source is ready to be dispatched prior to polling.
   */
  bool prepare();

  /** Determines information necessary to poll this main loop.
   * @param max_priority Maximum priority source to check.
   * @param[out] timeout Location to store timeout to be used in polling.
   * @param[out] fds Location to store Glib::PollFD records that need to be polled.
   */
  void query(int max_priority, int& timeout, std::vector<PollFD>& fds);

  /** Passes the results of polling back to the main loop.
   * @param max_priority Maximum numerical priority of sources to check.
   * @param fds Vector of Glib::PollFD's that was passed to the last call to query()
   * @return true if some sources are ready to be dispatched.
   */
  bool check(int max_priority, std::vector<PollFD>& fds);

  /** Dispatches all pending sources.
   */
  void dispatch();

  // TODO: Use slot instead?
  /** Sets the function to use to handle polling of file descriptors. It will be used instead of the
   * poll() system call (or GLib's replacement function, which is used where poll() isn't
   * available).
   * This function could possibly be used to integrate the GLib event loop with an external event
   * loop.
   * @param poll_func The function to call to poll all file descriptors.
   *        This function shall have C linkage. (Many compilers also accept
   *        a function with C++ linkage.)
   */
  void set_poll_func(GPollFunc poll_func);

  /** Gets the poll function set by g_main_context_set_poll_func().
   * @return The poll function
   */
  GPollFunc get_poll_func();

  /** Adds a file descriptor to the set of file descriptors polled for this context. This will very
   * seldomly be used directly. Instead a typical event source will use Glib::Source::add_poll()
   * instead.
   * @param fd A PollFD structure holding information about a file descriptor to watch.
   * @param priority The priority for this file descriptor which should be the same as the priority
   * used for Glib::Source::attach() to ensure that the file descriptor is polled whenever the
   * results may be needed.
   */
  void add_poll(PollFD& fd, int priority);

  /** Removes file descriptor from the set of file descriptors to be polled for a particular
   * context.
   * @param fd A PollFD structure holding information about a file descriptor.
   */
  void remove_poll(PollFD& fd);

  /** Acquires the context and sets it as the thread-default context for the current thread.
   *
   * This will cause certain asynchronous operations (such as most gio-based I/O)
   * which are started in this thread to run under this context and deliver their
   * results to its main loop, rather than running under the global
   * default context in the main thread. Note that calling this function
   * changes the context returned by get_thread_default(),
   * not the one returned by get_default(), so it does not affect
   * the context used by functions like g_idle_add().
   *
   * Normally you would call this function shortly after creating a new
   * thread, passing it a Glib::MainContext which will be run by a
   * Glib::MainLoop in that thread, to set a new default context for all
   * async operations in that thread. In this case you may not need to
   * ever call pop_thread_default(), assuming you want the
   * new Glib::MainContext to be the default for the whole lifecycle of the
   * thread.
   *
   * If you don't have control over how the new thread was created (e.g.
   * if the new thread isn't newly created, or if the thread life
   * cycle is managed by a GThreadPool), it is always suggested to wrap
   * the logic that needs to use the new Glib::MainContext inside a
   * push_thread_default() / pop_thread_default()
   * pair, otherwise threads that are re-used will end up never explicitly
   * releasing the Glib::MainContext reference they hold.
   *
   * In some cases you may want to schedule a single operation in a
   * non-default context, or temporarily use a non-default context in
   * the main thread. In that case, you can wrap the call to the
   * asynchronous operation inside a push_thread_default() / pop_thread_default()
   * pair, but it is up to you to ensure that no other asynchronous operations
   * accidentally get started while the non-default context is active.
   *
   * Beware that libraries that predate this function may not correctly
   * handle being used from a thread with a thread-default context. Eg,
   * see Gio::File::supports_thread_contexts().
   *
   * @newin{2,64}
   */
  void push_thread_default();

  /** Pops the context off the thread-default context stack (verifying that
   * it was on the top of the stack).
   *
   * @newin{2,64}
   */
  void pop_thread_default();

  /** Gets the thread-default MainContext for this thread.
   * Asynchronous operations that want to be able to be run in contexts
   * other than the default one should call this method to get a MainContext
   * to add their Glib::Sources to. (Note that even in single-threaded
   * programs applications may sometimes want to temporarily push a
   * non-default context, so it is not safe to assume that this will
   * always return the global default context if you are running in
   * the default thread.)
   *
   * This method wraps g_main_context_ref_thread_default(),
   * and not g_main_context_get_thread_default().
   *
   * @return The thread-default MainContext.
   *
   * @newin{2,64}
   */
  static Glib::RefPtr<MainContext> get_thread_default();

  /** Invokes a function in such a way that this MainContext is owned during
   * the invocation of @a slot.
   *
   * If the context is owned by the current thread, @a slot is called
   * directly. Otherwise, if the context is the thread-default main context
   * of the current thread and acquire() succeeds, then
   * @a slot is called and release() is called afterwards.
   *
   * In any other case, an idle source is created to call @a slot and
   * that source is attached to the context (presumably to be run in another
   * thread).
   *
   * Note that, as with normal idle functions, @a slot should probably
   * return <tt>false</tt>. If it returns <tt>true</tt>, it will be continuously
   * run in a loop (and may prevent this call from returning).
   *
   * If an idle source is created to call @a slot, invoke() may return before
   * @a slot is called.
   *
   * Because sigc::trackable is not thread-safe, if the slot represents a
   * non-static method of a class deriving from sigc::trackable, and the slot is
   * created by sigc::mem_fun(), invoke() should only be called from
   * the thread where the context runs. You can use, say, boost::bind() or,
   * in C++11, std::bind() or a C++11 lambda expression instead of sigc::mem_fun().
   *
   * @param slot A slot to call.
   * @param priority The priority of the idle source, if one is created.
   *
   * @newin{2,38}
   */
  void invoke(const sigc::slot<bool()>& slot, int priority = PRIORITY_DEFAULT);

  /** Timeout signal, attached to this MainContext.
   * @return A signal proxy; you want to use SignalTimeout::connect().
   */
  SignalTimeout signal_timeout();

  /** Idle signal, attached to this MainContext.
   * @return A signal proxy; you want to use SignalIdle::connect().
   */
  SignalIdle signal_idle();

  /** I/O signal, attached to this MainContext.
   * @return A signal proxy; you want to use SignalIO::connect().
   */
  SignalIO signal_io();

  /** child watch signal, attached to this MainContext.
   * @return A signal proxy; you want to use SignalChildWatch::connect().
   */
  SignalChildWatch signal_child_watch();

  void reference() const;
  void unreference() const;

  GMainContext* gobj();
  const GMainContext* gobj() const;
  GMainContext* gobj_copy() const;

private:
  // Glib::MainContext can neither be constructed nor deleted.
  MainContext();
  void operator delete(void*, std::size_t);
};

/** @relates Glib::MainContext */
GLIBMM_API
Glib::RefPtr<MainContext> wrap(GMainContext* gobject, bool take_copy = false);

class GLIBMM_API MainLoop
{
public:
  using CppObjectType = Glib::MainLoop;
  using BaseObjectType = GMainLoop;

  static Glib::RefPtr<MainLoop> create(bool is_running = false);
  static Glib::RefPtr<MainLoop> create(
    const Glib::RefPtr<MainContext>& context, bool is_running = false);

  /** Runs a main loop until quit() is called on the loop.
   * If this is called for the thread of the loop's MainContext, it will process events from the
   * loop, otherwise it will simply wait.
   */
  void run();

  /** Stops a MainLoop from running. Any calls to run() for the loop will return.
   */
  void quit();

  /** Checks to see if the main loop is currently being run via run().
   * @return true if the mainloop is currently being run.
   */
  bool is_running();

  /** Returns the MainContext of loop.
   * @return The MainContext of loop.
   */
  Glib::RefPtr<MainContext> get_context();

  // TODO: C++ize the (big) g_main_depth docs here.
  static int depth();

  /** Increases the reference count on a MainLoop object by one.
   */
  void reference() const;

  /** Decreases the reference count on a MainLoop object by one.
   * If the result is zero, free the loop and free all associated memory.
   */
  void unreference() const;

  GMainLoop* gobj();
  const GMainLoop* gobj() const;
  GMainLoop* gobj_copy() const;

private:
  // Glib::MainLoop can neither be constructed nor deleted.
  MainLoop();
  void operator delete(void*, std::size_t);

  // noncopyable
  MainLoop(const MainLoop&) = delete;
  MainLoop& operator=(const MainLoop&) = delete;
};

/** @relates Glib::MainLoop */
GLIBMM_API
Glib::RefPtr<MainLoop> wrap(GMainLoop* gobject, bool take_copy = false);

class Source
{
public:
  using CppObjectType = Glib::Source;
  using BaseObjectType = GSource;

  // noncopyable
  Source(const Source&) = delete;
  Source& operator=(const Source&) = delete;

  GLIBMM_API static Glib::RefPtr<Source> create() /* = 0 */;

  /** Adds a Source to a context so that it will be executed within that context.
   * @param context A MainContext.
   * @return The ID for the source within the MainContext.
   */
  GLIBMM_API unsigned int attach(const Glib::RefPtr<MainContext>& context);

  /** Adds a Source to a context so that it will be executed within that context.
   * The default context will be used.
   * @return The ID for the source within the MainContext.
   */
  GLIBMM_API unsigned int attach();

  // TODO: Does this destroy step make sense in C++? Should it just be something that happens in a
  // destructor?

  /** Removes a source from its MainContext, if any, and marks it as destroyed.
   * The source cannot be subsequently added to another context.
   */
  GLIBMM_API void destroy();

  /** Sets the priority of a source. While the main loop is being run, a source will be dispatched
   * if it is ready to be dispatched and no sources at a higher (numerically smaller) priority are
   * ready to be dispatched.
   * @param priority The new priority.
   */
  GLIBMM_API void set_priority(int priority);

  /** Gets the priority of a source.
   * @return The priority of the source.
   */
  GLIBMM_API int get_priority() const;

  /** Sets whether a source can be called recursively.
   * If @a can_recurse is true, then while the source is being dispatched then this source will be
   * processed normally. Otherwise, all processing of this source is blocked until the dispatch
   * function returns.
   * @param can_recurse Whether recursion is allowed for this source.
   */
  GLIBMM_API void set_can_recurse(bool can_recurse);

  /** Checks whether a source is allowed to be called recursively. see set_can_recurse().
   * @return Whether recursion is allowed.
   */
  GLIBMM_API bool get_can_recurse() const;

  /** Returns the numeric ID for a particular source.
   * The ID of a source is unique within a particular main loop context. The reverse mapping from ID
   * to source is done by MainContext::find_source_by_id().
   * @return The ID for the source.
   */
  GLIBMM_API unsigned int get_id() const;

  // TODO: Add a const version of this method?
  /** Gets the MainContext with which the source is associated.
   * Calling this function on a destroyed source is an error.
   * @return The MainContext with which the source is associated, or a null RefPtr if the context
   * has not yet been added to a source.
   */
  GLIBMM_API Glib::RefPtr<MainContext> get_context();

  GLIBMM_API GSource* gobj() { return gobject_; }
  GLIBMM_API const GSource* gobj() const { return gobject_; }
  GLIBMM_API GSource* gobj_copy() const;

  GLIBMM_API void reference() const;
  GLIBMM_API void unreference() const;

protected:
  /** Construct an object that uses the virtual functions prepare(), check() and dispatch().
   */
  GLIBMM_API Source();

  /** Wrap an existing GSource object and install the given callback function.
   * The constructed object doesn't use the virtual functions prepare(), check() and dispatch().
   * This constructor is for use by derived types that need to wrap a GSource object.
   * The callback function is called from GLib (a C library). It shall have C
   * linkage. (Many compilers accept a function with C++ linkage. If you use
   * only such compilers, the callback function can be a static member function.)
   * But beware - depending on the actual implementation of the GSource's virtual
   * functions the expected type of the callback function can differ from GSourceFunc.
   */
  GLIBMM_API Source(GSource* cast_item, GSourceFunc callback_func);

  GLIBMM_API virtual ~Source() noexcept;

  GLIBMM_API sigc::connection connect_generic(const sigc::slot_base& slot);

  /** Adds a file descriptor to the set of file descriptors polled for this source.
   * The event source's check function will typically test the revents field in the PollFD  and
   * return true if events need to be processed.
   * @param poll_fd A PollFD object holding information about a file descriptor to watch.
   */
  GLIBMM_API void add_poll(PollFD& poll_fd);

  /** Removes a file descriptor from the set of file descriptors polled for this source.
   * @param poll_fd A PollFD object previously passed to add_poll().
   */
  GLIBMM_API void remove_poll(PollFD& poll_fd);

  // TODO: Remove mention of g_get_monotonic time when we wrap it in C++.
  /** Gets the time to be used when checking this source. The advantage of
   * calling this function over calling g_get_monotonic_time() directly is
   * that when checking multiple sources, GLib can cache a single value
   * instead of having to repeatedly get the system monotonic time.
   *
   * The time here is the system monotonic time, if available, or some
   * other reasonable alternative otherwise.  See g_get_monotonic_time().
   *
   * @result The monotonic time in microseconds.
   *
   * @newin{2,28}
   */
  GLIBMM_API gint64 get_time() const;

  GLIBMM_API virtual bool prepare(int& timeout) = 0;
  GLIBMM_API virtual bool check() = 0;
  GLIBMM_API virtual bool dispatch(sigc::slot_base* slot) = 0;

private:
  GSource* gobject_;

  mutable std::atomic_int ref_count_ {1};
  // The C++ wrapper (the Source instance) is deleted, when both Source::unreference()
  // and SourceCallbackData::destroy_notify_callback() have decreased keep_wrapper_
  // by calling destroy_notify_callback2().
  // https://bugzilla.gnome.org/show_bug.cgi?id=561885
  std::atomic_int keep_wrapper_ {2};

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  GLIBMM_API static inline Source* get_wrapper(GSource* source);

  static const GSourceFuncs vfunc_table_;

  GLIBMM_API static gboolean prepare_vfunc(GSource* source, int* timeout);
  GLIBMM_API static gboolean check_vfunc(GSource* source);
  GLIBMM_API static gboolean dispatch_vfunc(GSource* source, GSourceFunc callback, void* user_data);

public:
  // Really destroys the object during the second call. See keep_wrapper_.
  GLIBMM_API static void destroy_notify_callback2(void* data);
  // Used by SignalXyz, possibly in other files.
  GLIBMM_API static sigc::connection attach_signal_source(const sigc::slot_base& slot, int priority,
    GSource* source, GMainContext* context, GSourceFunc callback_func);
  // Used by SignalXyz in other files.
  GLIBMM_API static sigc::slot_base* get_slot_from_connection_node(void* data);
  // Used by derived Source classes in other files.
  GLIBMM_API static sigc::slot_base* get_slot_from_callback_data(void* data);
#endif /* DOXYGEN_SHOULD_SKIP_THIS */
};

class TimeoutSource : public Glib::Source
{
public:
  using CppObjectType = Glib::TimeoutSource;

  GLIBMM_API static Glib::RefPtr<TimeoutSource> create(unsigned int interval);
  GLIBMM_API sigc::connection connect(const sigc::slot<bool()>& slot);

protected:
  GLIBMM_API explicit TimeoutSource(unsigned int interval);
  GLIBMM_API ~TimeoutSource() noexcept override;

  GLIBMM_API bool prepare(int& timeout) override;
  GLIBMM_API bool check() override;
  GLIBMM_API bool dispatch(sigc::slot_base* slot) override;

private:
  gint64 expiration_;     // microseconds
  unsigned int interval_; // milliseconds
};

class IdleSource : public Glib::Source
{
public:
  using CppObjectType = Glib::IdleSource;

  GLIBMM_API static Glib::RefPtr<IdleSource> create();
  GLIBMM_API sigc::connection connect(const sigc::slot<bool()>& slot);

protected:
  GLIBMM_API IdleSource();
  GLIBMM_API ~IdleSource() noexcept override;

  GLIBMM_API bool prepare(int& timeout) override;
  GLIBMM_API bool check() override;
  GLIBMM_API bool dispatch(sigc::slot_base* slot_data) override;
};

class IOSource : public Glib::Source
{
public:
  using CppObjectType = Glib::IOSource;

  GLIBMM_API static Glib::RefPtr<IOSource> create(PollFD::fd_t fd, IOCondition condition);
  GLIBMM_API static Glib::RefPtr<IOSource> create(
    const Glib::RefPtr<IOChannel>& channel, IOCondition condition);
  GLIBMM_API sigc::connection connect(const sigc::slot<bool(IOCondition)>& slot);

protected:
  GLIBMM_API IOSource(PollFD::fd_t fd, IOCondition condition);
  GLIBMM_API IOSource(const Glib::RefPtr<IOChannel>& channel, IOCondition condition);

  /** Wrap an existing GSource object and install the given callback function.
   * This constructor is for use by derived types that need to wrap a GSource object.
   * The callback function is called from GLib (a C library). It shall have C
   * linkage. (Many compilers accept a function with C++ linkage. If you use
   * only such compilers, the callback function can be a static member function.)
   * @see Source::Source(GSource*, GSourceFunc).
   * @newin{2,42}
   */
  GLIBMM_API IOSource(GSource* cast_item, GSourceFunc callback_func);

  GLIBMM_API ~IOSource() noexcept override;

  GLIBMM_API bool prepare(int& timeout) override;
  GLIBMM_API bool check() override;
  GLIBMM_API bool dispatch(sigc::slot_base* slot) override;

private:
  friend GLIBMM_API IOChannel;

  // This is just to avoid the need for Gio::Socket to create a RefPtr<> to itself.
  GLIBMM_API static Glib::RefPtr<IOSource> create(GIOChannel* channel, IOCondition condition);

  // This is just to avoid the need for Gio::Socket to create a RefPtr<> to itself.
  GLIBMM_API IOSource(GIOChannel* channel, IOCondition condition);

  PollFD poll_fd_;
};

/** @} group MainLoop */

} // namespace Glib

#endif /* _GLIBMM_MAIN_H */
