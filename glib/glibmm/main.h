// -*- c++ -*-
#ifndef _GLIBMM_MAIN_H
#define _GLIBMM_MAIN_H

/* $Id$ */

/* Copyright (C) 2002 The gtkmm Development Team
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

#include <glib/giochannel.h>
#include <glib/gmain.h>

#include <vector>
#include <sigc++/sigc++.h>

#include <glibmmconfig.h>
#include <glibmm/refptr.h>
#include <glibmm/timeval.h>

GLIBMM_USING_STD(vector)


namespace Glib
{

class Cond;
class Mutex;
class IOChannel;


/** @defgroup MainLoop The Main Event Loop
 * Manages all available sources of events.
 * @{
 */

enum
{
  /*! Use this for high priority event sources.  It is not used within
   * GLib or GTK+.<br><br>
   */
  PRIORITY_HIGH = -100,

  /*! Use this for default priority event sources.  In glibmm this
   * priority is used by default when installing timeout handlers with
   * SignalTimeout::connect().  In GDK this priority is used for events
   * from the X server.<br><br>
   */
  PRIORITY_DEFAULT = 0,

  /*! Use this for high priority idle functions.  GTK+ uses
   * <tt>PRIORITY_HIGH_IDLE&nbsp;+&nbsp;10</tt> for resizing operations, and
   * <tt>PRIORITY_HIGH_IDLE&nbsp;+&nbsp;20</tt> for redrawing operations.
   * (This is done to ensure that any pending resizes are processed before
   * any pending redraws, so that widgets are not redrawn twice unnecessarily.)
   * <br><br>
   */
  PRIORITY_HIGH_IDLE = 100,

  /*! Use this for default priority idle functions.  In glibmm this priority is
   * used by default when installing idle handlers with SignalIdle::connect().
   * <br><br>
   */
  PRIORITY_DEFAULT_IDLE = 200,

  /*! Use this for very low priority background tasks.  It is not used within
   * GLib or GTK+.
   */
  PRIORITY_LOW = 300
};


/** A bitwise combination representing an I/O condition to watch for on an
 * event source.
 * The flags correspond to those used by the <tt>%poll()</tt> system call
 * on UNIX (see <tt>man 2 poll</tt>).  To test for individual flags, do
 * something like this:
 * @code
 * if((condition & Glib::IO_OUT) != 0)
 *   do_some_output();
 * @endcode
 * @par Bitwise operators:
 * <tt>IOCondition operator|(IOCondition, IOCondition)</tt><br>
 * <tt>IOCondition operator&(IOCondition, IOCondition)</tt><br>
 * <tt>IOCondition operator^(IOCondition, IOCondition)</tt><br>
 * <tt>IOCondition operator~(IOCondition)</tt><br>
 * <tt>IOCondition& operator|=(IOCondition&, IOCondition)</tt><br>
 * <tt>IOCondition& operator&=(IOCondition&, IOCondition)</tt><br>
 * <tt>IOCondition& operator^=(IOCondition&, IOCondition)</tt><br>
 */
enum IOCondition
{
  IO_IN   = G_IO_IN,  /*!< @hideinitializer There is data to read. */
  IO_OUT  = G_IO_OUT, /*!< @hideinitializer Data can be written (without blocking). */
  IO_PRI  = G_IO_PRI, /*!< @hideinitializer There is urgent data to read. */
  IO_ERR  = G_IO_ERR, /*!< @hideinitializer %Error condition. */
  IO_HUP  = G_IO_HUP, /*!< @hideinitializer Hung up (the connection has been broken,
                                            usually for pipes and sockets). */
  IO_NVAL = G_IO_NVAL /*!< @hideinitializer Invalid request. The file descriptor is not open. */
};

inline IOCondition operator|(IOCondition lhs, IOCondition rhs)
  { return static_cast<IOCondition>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs)); }

inline IOCondition operator&(IOCondition lhs, IOCondition rhs)
  { return static_cast<IOCondition>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs)); }

inline IOCondition operator^(IOCondition lhs, IOCondition rhs)
  { return static_cast<IOCondition>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs)); }

inline IOCondition operator~(IOCondition flags)
  { return static_cast<IOCondition>(~static_cast<unsigned>(flags)); }

inline IOCondition& operator|=(IOCondition& lhs, IOCondition rhs)
  { return (lhs = static_cast<IOCondition>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs))); }

inline IOCondition& operator&=(IOCondition& lhs, IOCondition rhs)
  { return (lhs = static_cast<IOCondition>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs))); }

inline IOCondition& operator^=(IOCondition& lhs, IOCondition rhs)
  { return (lhs = static_cast<IOCondition>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs))); }


class PollFD
{
public:
  PollFD();
  explicit PollFD(int fd);
  PollFD(int fd, IOCondition events);

  void set_fd(int fd) { gobject_.fd = fd;   }
  int  get_fd() const { return gobject_.fd; }

  void set_events(IOCondition events)   { gobject_.events = events; }
  IOCondition get_events() const        { return static_cast<IOCondition>(gobject_.events); }

  void set_revents(IOCondition revents) { gobject_.revents = revents; }
  IOCondition get_revents() const       { return static_cast<IOCondition>(gobject_.revents); }

  GPollFD*       gobj()       { return &gobject_; }
  const GPollFD* gobj() const { return &gobject_; }

private:
  GPollFD gobject_;
};


class SignalTimeout
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalTimeout(GMainContext* context);
#endif

  /** Connects a timeout handler.
   * @code
   * Glib::signal_timeout().connect(SigC::slot(&timeout_handler), 1000);
   * @endcode
   * is equivalent to:
   * @code
   * const Glib::RefPtr<Glib::TimeoutSource> timeout_source = Glib::TimeoutSource::create(1000);
   * timeout_source->connect(SigC::slot(&timeout_handler));
   * timeout_source->attach(Glib::MainContext::get_default());
   * @endcode
   * @param slot A slot to call when @a interval elapsed.
   * @param interval The timeout in milliseconds.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  SigC::Connection connect(const SigC::Slot0<bool>& slot, unsigned int interval,
                           int priority = PRIORITY_DEFAULT);
private:
  GMainContext* context_;

  // no copy assignment
  SignalTimeout& operator=(const SignalTimeout&);
};


class SignalIdle
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalIdle(GMainContext* context);
#endif

  /** Connects an idle handler.
   * @code
   * Glib::signal_idle().connect(SigC::slot(&idle_handler));
   * @endcode
   * is equivalent to:
   * @code
   * const Glib::RefPtr<Glib::IdleSource> idle_source = Glib::IdleSource::create();
   * idle_source->connect(SigC::slot(&idle_handler));
   * idle_source->attach(Glib::MainContext::get_default());
   * @endcode
   * @param slot A slot to call when the main loop is idle.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  SigC::Connection connect(const SigC::Slot0<bool>& slot, int priority = PRIORITY_DEFAULT_IDLE);

private:
  GMainContext* context_;

  // no copy assignment
  SignalIdle& operator=(const SignalIdle&);
};


class SignalIO
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  explicit inline SignalIO(GMainContext* context);
#endif

  /** Connects an I/O handler.
   * @code
   * Glib::signal_io().connect(SigC::slot(&io_handler), fd, Glib::IO_IN | Glib::IO_HUP);
   * @endcode
   * is equivalent to:
   * @code
   * const Glib::RefPtr<Glib::IOSource> io_source = Glib::IOSource::create(fd, Glib::IO_IN | Glib::IO_HUP);
   * io_source->connect(SigC::slot(&io_handler));
   * io_source->attach(Glib::MainContext::get_default());
   * @endcode
   * @param slot A slot to call when polling @a fd results in an event that matches @a condition.
   * The event will be passed as a parameter to @a slot.
   * If @a io_handler returns <tt>false</tt> the signal is disconnected.
   * @param fd The file descriptor (or a @c HANDLE on Win32 systems) to watch.
   * @param condition The conditions to watch for.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  SigC::Connection connect(const SigC::Slot1<bool,IOCondition>& slot, int fd,
                           IOCondition condition, int priority = PRIORITY_DEFAULT);

  /** Connects an I/O channel.
   * @code
   * Glib::signal_io().connect(SigC::slot(&io_handler), channel, Glib::IO_IN | Glib::IO_HUP);
   * @endcode
   * is equivalent to:
   * @code
   * const Glib::RefPtr<Glib::IOSource> io_source = Glib::IOSource::create(channel, Glib::IO_IN | Glib::IO_HUP);
   * io_source->connect(SigC::slot(&io_handler));
   * io_source->attach(Glib::MainContext::get_default());
   * @endcode
   * @param slot A slot to call when polling @a fd results in an event that matches @a condition.
   * The event will be passed as a parameter to @a slot.
   * If @a io_handler returns <tt>false</tt> the signal is disconnected.
   * @param channel The IOChannel object to watch.
   * @param condition The conditions to watch for.
   * @param priority The priority of the new event source.
   * @return A connection handle, which can be used to disconnect the handler.
   */
  SigC::Connection connect(const SigC::Slot1<bool,IOCondition>& slot, const Glib::RefPtr<IOChannel>& channel,
                           IOCondition condition, int priority = PRIORITY_DEFAULT);

private:
  GMainContext* context_;

  // no copy assignment
  SignalIO& operator=(const SignalIO&);
};


/** Convenience timeout signal.
 * @return A signal proxy; you want to use SignalTimeout::connect().
 */
SignalTimeout signal_timeout();

/** Convenience idle signal.
 * @return A signal proxy; you want to use SignalIdle::connect().
 */
SignalIdle signal_idle();

/** Convenience I/O signal.
 * @return A signal proxy; you want to use SignalIO::connect().
 */
SignalIO signal_io();


/** Main context.
 */
class MainContext
{
public:
  typedef Glib::MainContext  CppObjectType;
  typedef GMainContext       BaseObjectType;

  static Glib::RefPtr<MainContext> create();
  static Glib::RefPtr<MainContext> get_default();

  bool iteration(bool may_block);
  bool pending();
  void wakeup();

  bool acquire();
  bool wait(Glib::Cond& cond, Glib::Mutex& mutex);
  void release();

  bool prepare(int& priority);
  bool prepare();

  void query(int max_priority, int& timeout, std::vector<PollFD>& fds);
  bool check(int max_priority, std::vector<PollFD>& fds);
  void dispatch();

  void set_poll_func(GPollFunc poll_func);
  GPollFunc get_poll_func();

  void add_poll(PollFD& fd, int priority);
  void remove_poll(PollFD& fd);

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

  void reference()   const;
  void unreference() const;

  GMainContext*       gobj();
  const GMainContext* gobj() const;
  GMainContext*       gobj_copy() const;

private:
  // Glib::MainContext can neither be constructed nor deleted.
  MainContext();
  void operator delete(void*, size_t);

  // noncopyable
  MainContext(const MainContext& other);
  MainContext& operator=(const MainContext& other);

};

/** @relates Glib::MainContext */
Glib::RefPtr<MainContext> wrap(GMainContext* gobject, bool take_copy = false);


class MainLoop
{
public:
  typedef Glib::MainLoop  CppObjectType;
  typedef GMainLoop       BaseObjectType;

  static Glib::RefPtr<MainLoop> create(bool is_running = false);
  static Glib::RefPtr<MainLoop> create(const Glib::RefPtr<MainContext>& context,
                                       bool is_running = false);

  void run();
  void quit();
  bool is_running();

  Glib::RefPtr<MainContext> get_context();

  void reference()   const;
  void unreference() const;

  GMainLoop*       gobj();
  const GMainLoop* gobj() const;
  GMainLoop*       gobj_copy() const;

private:
  // Glib::MainLoop can neither be constructed nor deleted.
  MainLoop();
  void operator delete(void*, size_t);

  MainLoop(const MainLoop&);
  MainLoop& operator=(const MainLoop&);
};

/** @relates Glib::MainLoop */
Glib::RefPtr<MainLoop> wrap(GMainLoop* gobject, bool take_copy = false);


class Source
{
public:
  typedef Glib::Source  CppObjectType;
  typedef GSource       BaseObjectType;

  static Glib::RefPtr<Source> create() /* = 0 */;

  unsigned int attach(const Glib::RefPtr<MainContext>& context);
  unsigned int attach();
  void destroy();

  void set_priority(int priority);
  int  get_priority() const;

  void set_can_recurse(bool can_recurse);
  bool get_can_recurse() const;

  unsigned int get_id() const;
  Glib::RefPtr<MainContext> get_context();

  GSource*       gobj()       { return gobject_; }
  const GSource* gobj() const { return gobject_; }
  GSource*       gobj_copy() const;

  void reference()   const;
  void unreference() const;

protected:
  /** Construct an object that uses the virtual functions prepare(), check() and dispatch().
   */
  Source();

  /** Wrap an existing GSource object and install the given callback function.
   * The constructed object doesn't use the virtual functions prepare(), check() and dispatch().
   * This ctor is for use by derived types that need to wrap a GSource object.
   * The callback function can be a static member function. But beware!
   * Depending on the actual implementation of the GSource's virtual functions
   * the expected type of the callback function can differ from GSourceFunc.
   */
  Source(GSource* cast_item, GSourceFunc callback_func);

  virtual ~Source();

  SigC::Connection connect_generic(const SigC::SlotBase& slot);

  void add_poll   (PollFD& poll_fd);
  void remove_poll(PollFD& poll_fd);

  void get_current_time(Glib::TimeVal& current_time);

  virtual bool prepare(int& timeout) = 0;
  virtual bool check() = 0;
  virtual bool dispatch(SigC::SlotNode* slot_data) = 0;

private:
  GSource* gobject_;

#ifndef DOXGEN_SHOULD_SKIP_THIS

  static inline Source* get_wrapper(GSource* source);

  static const GSourceFuncs vfunc_table_;

  static gboolean prepare_vfunc(GSource* source, int* timeout);
  static gboolean check_vfunc(GSource* source);
  static gboolean dispatch_vfunc(GSource* source, GSourceFunc callback, void* user_data);
public:
  static void destroy_notify_callback(void* data);
private:

#endif /* DOXGEN_SHOULD_SKIP_THIS */

  // noncopyable
  Source(const Source&);
  Source& operator=(const Source&);
};


class TimeoutSource : public Glib::Source
{
public:
  typedef Glib::TimeoutSource CppObjectType;

  static Glib::RefPtr<TimeoutSource> create(unsigned int interval);
  SigC::Connection connect(const SigC::Slot0<bool>& slot);

protected:
  explicit TimeoutSource(unsigned int interval);
  virtual ~TimeoutSource();

  virtual bool prepare(int& timeout);
  virtual bool check();
  virtual bool dispatch(SigC::SlotNode* slot_data);

private:
  Glib::TimeVal expiration_;
  unsigned int  interval_;
};


class IdleSource : public Glib::Source
{
public:
  typedef Glib::IdleSource CppObjectType;

  static Glib::RefPtr<IdleSource> create();
  SigC::Connection connect(const SigC::Slot0<bool>& slot);

protected:
  IdleSource();
  virtual ~IdleSource();

  virtual bool prepare(int& timeout);
  virtual bool check();
  virtual bool dispatch(SigC::SlotNode* slot_data);
};


class IOSource : public Glib::Source
{
public:
  typedef Glib::IOSource CppObjectType;

  static Glib::RefPtr<IOSource> create(int fd, IOCondition condition);
  static Glib::RefPtr<IOSource> create(const Glib::RefPtr<IOChannel>& channel, IOCondition condition);
  SigC::Connection connect(const SigC::Slot1<bool,IOCondition>& slot);

protected:
  IOSource(int fd, IOCondition condition);
  IOSource(const Glib::RefPtr<IOChannel>& channel, IOCondition condition);
  virtual ~IOSource();

  virtual bool prepare(int& timeout);
  virtual bool check();
  virtual bool dispatch(SigC::SlotNode* slot_data);

private:
  PollFD poll_fd_;
};

/** @} group MainLoop */

} // namespace Glib


#endif /* _GLIBMM_MAIN_H */

