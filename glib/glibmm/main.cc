// -*- c++ -*-
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

#include <glibmm/main.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/thread.h>
#include <glibmm/wrap.h>
#include <glibmm/iochannel.h>

#include <glib/gmessages.h>
#include <algorithm>

GTKMM_USING_STD(min)


namespace
{

class SourceConnectionNode : public SigC::ConnectionNode
{
public:
  explicit inline SourceConnectionNode(const SigC::SlotBase& slot);

  virtual void notify(bool from_child);
  static  void destroy_notify_callback(void* data);

  inline void install(GSource* source);
  inline SigC::SlotNode* get_slot_node();

private:
  GSource* source_;
};

inline
SourceConnectionNode::SourceConnectionNode(const SigC::SlotBase& slot)
:
  SigC::ConnectionNode (static_cast<SigC::SlotNode*>(slot.impl())),
  source_              (0)
{}

void SourceConnectionNode::notify(bool from_child)
{
  SigC::ConnectionNode::notify(from_child);

  if(source_)
  {
    g_source_destroy(source_);
    source_ = 0;
  }
}

// static
void SourceConnectionNode::destroy_notify_callback(void* data)
{
  try
  {
    SourceConnectionNode *const self = static_cast<SourceConnectionNode*>(data);

    // The GLib side is disconnected now, thus the GSource* is no longer valid.
    self->source_ = 0;

    if(!self->notified_)
      self->notify(false);

    // Undo the reference made by install().
    self->unreference();
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
}

inline
void SourceConnectionNode::install(GSource* source)
{
  source_ = source;
  reference();
}

inline
SigC::SlotNode* SourceConnectionNode::get_slot_node()
{
  return static_cast<SigC::SlotNode*>(slot().impl());
}


/* We use the callback data member of GSource to store both a pointer to our
 * wrapper and a pointer to the connection node that is currently being used.
 * The one and only SourceCallbackData object of a Glib::Source is constructed
 * in the ctor of Glib::Source and destroyed after the GSource object when the
 * reference counter of the GSource object reaches zero!
 */
struct SourceCallbackData
{
  explicit inline SourceCallbackData(Glib::Source* wrapper_);

  void set_node(SourceConnectionNode* node_);

  static void destroy_notify_callback(void* data);

  Glib::Source* wrapper;
  SourceConnectionNode* node;
};

inline
SourceCallbackData::SourceCallbackData(Glib::Source* wrapper_)
:
  wrapper (wrapper_),
  node    (0)
{}

void SourceCallbackData::set_node(SourceConnectionNode* node_)
{
  if(node)
    SourceConnectionNode::destroy_notify_callback(node);

  node = node_;
}

// static
void SourceCallbackData::destroy_notify_callback(void* data)
{
  SourceCallbackData *const self = static_cast<SourceCallbackData*>(data);

  if(self->node)
    SourceConnectionNode::destroy_notify_callback(self->node);

  if(self->wrapper)
    Glib::Source::destroy_notify_callback(self->wrapper);

  delete self;
}


/* Retrieve the callback data from a wrapped GSource object.
 */
SourceCallbackData* glibmm_source_get_callback_data(GSource* source)
{
  g_return_val_if_fail(source->callback_funcs->get != 0, 0);

  GSourceFunc func;
  void* user_data = 0;

  // Retrieve the callback function and data.
  (*source->callback_funcs->get)(source->callback_data, source, &func, &user_data);

  return static_cast<SourceCallbackData*>(user_data);
}

/* Glib::Source doesn't use the callback function installed with
 * g_source_set_callback().  Instead, it invokes the sigc++ slot
 * directly from dispatch_vfunc(), which is both simpler and more
 * efficient.
 * For correctness, provide a pointer to this dummy callback rather
 * than some random pointer.  That also allows for sanity checks
 * here as well as in Source::dispatch_vfunc().
 */
gboolean glibmm_dummy_source_callback(void*)
{
  g_assert_not_reached();
  return 0;
}

/* Only used by SignalTimeout::connect() and SignalIdle::connect().
 * These don't use Glib::Source, to avoid the unnecessary overhead
 * of a completely unused wrapper object.
 */
gboolean glibmm_source_callback(void* data)
{
  try
  {
    // Recreate the specific slot from the generic slot node.
    SigC::Slot0<bool> slot (static_cast<SourceConnectionNode*>(data)->get_slot_node());
    return slot();
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

gboolean glibmm_iosource_callback(GIOChannel*, GIOCondition condition, void* data)
{
  SourceCallbackData *const callback_data = static_cast<SourceCallbackData*>(data);
  g_return_val_if_fail(callback_data->node != 0, 0);

  try
  {
    // Recreate the specific slot from the generic slot node.
    SigC::Slot1<bool,Glib::IOCondition> slot (callback_data->node->get_slot_node());
    return slot((Glib::IOCondition) condition);
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

} // anonymous namespace


namespace Glib
{

/**** Glib::PollFD *********************************************************/

PollFD::PollFD()
{
  gobject_.fd      = 0;
  gobject_.events  = 0;
  gobject_.revents = 0;
}

PollFD::PollFD(int fd)
{
  gobject_.fd      = fd;
  gobject_.events  = 0;
  gobject_.revents = 0;
}

PollFD::PollFD(int fd, IOCondition events)
{
  gobject_.fd      = fd;
  gobject_.events  = events;
  gobject_.revents = 0;
}


/**** Glib::SignalTimeout **************************************************/

inline
SignalTimeout::SignalTimeout(GMainContext* context)
:
  context_ (context)
{}

SigC::Connection SignalTimeout::connect(const SigC::Slot0<bool>& slot,
                                        unsigned int interval, int priority)
{
  SourceConnectionNode *const conn_node = new SourceConnectionNode(slot);
  const SigC::Connection connection (conn_node);

  GSource *const source = g_timeout_source_new(interval);

  if(priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
      source, &glibmm_source_callback, conn_node,
      &SourceConnectionNode::destroy_notify_callback);

  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  conn_node->install(source);
  return connection;
}

SignalTimeout signal_timeout()
{
  return SignalTimeout(0); // 0 means default context
}


/**** Glib::SignalIdle *****************************************************/

inline
SignalIdle::SignalIdle(GMainContext* context)
:
  context_ (context)
{}

SigC::Connection SignalIdle::connect(const SigC::Slot0<bool>& slot, int priority)
{
  SourceConnectionNode *const conn_node = new SourceConnectionNode(slot);
  const SigC::Connection connection (conn_node);

  GSource *const source = g_idle_source_new();

  if(priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
      source, &glibmm_source_callback, conn_node,
      &SourceConnectionNode::destroy_notify_callback);

  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  conn_node->install(source);
  return connection;
}

SignalIdle signal_idle()
{
  return SignalIdle(0); // 0 means default context
}


/**** Glib::SignalIO *******************************************************/

inline
SignalIO::SignalIO(GMainContext* context)
:
  context_ (context)
{}

SigC::Connection SignalIO::connect(const SigC::Slot1<bool,IOCondition>& slot,
                                   int fd, IOCondition condition, int priority)
{
  const Glib::RefPtr<IOSource> source = IOSource::create(fd, condition);

  if(priority != G_PRIORITY_DEFAULT)
    source->set_priority(priority);

  const SigC::Connection connection = source->connect(slot);

  g_source_attach(source->gobj(), context_);

  return connection;
}

SigC::Connection SignalIO::connect(const SigC::Slot1<bool,IOCondition>& slot,
                                   const Glib::RefPtr<IOChannel>& channel,
                                   IOCondition condition, int priority)
{
  const Glib::RefPtr<IOSource> source = IOSource::create(channel, condition);

  if(priority != G_PRIORITY_DEFAULT)
    source->set_priority(priority);

  const SigC::Connection connection = source->connect(slot);

  g_source_attach(source->gobj(), context_);

  return connection;
}

SignalIO signal_io()
{
  return SignalIO(0); // 0 means default context
}


/**** Glib::MainContext ****************************************************/

// static
Glib::RefPtr<MainContext> MainContext::create()
{
  return Glib::RefPtr<MainContext>(reinterpret_cast<MainContext*>(g_main_context_new()));
}

// static
Glib::RefPtr<MainContext> MainContext::get_default()
{
  return Glib::wrap(g_main_context_default(), true);
}

bool MainContext::iteration(bool may_block)
{
  return g_main_context_iteration(gobj(), may_block);
}

bool MainContext::pending()
{
  return g_main_context_pending(gobj());
}

void MainContext::wakeup()
{
  g_main_context_wakeup(gobj());
}

bool MainContext::acquire()
{
  return g_main_context_acquire(gobj());
}

bool MainContext::wait(Glib::Cond& cond, Glib::Mutex& mutex)
{
  return g_main_context_wait(gobj(), cond.gobj(), mutex.gobj());
}

void MainContext::release()
{
  g_main_context_release(gobj());
}

bool MainContext::prepare(int& priority)
{
  return g_main_context_prepare(gobj(), &priority);
}

bool MainContext::prepare()
{
  return g_main_context_prepare(gobj(), 0);
}

void MainContext::query(int max_priority, int& timeout, std::vector<PollFD>& fds)
{
  if(fds.empty())
    fds.resize(8); // rather bogus number, but better than 0

  for(;;)
  {
    const int size_before = fds.size();
    const int size_needed = g_main_context_query(
        gobj(), max_priority, &timeout, reinterpret_cast<GPollFD*>(&fds.front()), size_before);

    fds.resize(size_needed);

    if(size_needed <= size_before)
      break;
  }
}

bool MainContext::check(int max_priority, std::vector<PollFD>& fds)
{
  if(!fds.empty())
    return g_main_context_check(gobj(), max_priority, reinterpret_cast<GPollFD*>(&fds.front()), fds.size());
  else
    return false;
}

void MainContext::dispatch()
{
  g_main_context_dispatch(gobj());
}

void MainContext::set_poll_func(GPollFunc poll_func)
{
  g_main_context_set_poll_func(gobj(), poll_func);
}

GPollFunc MainContext::get_poll_func()
{
  return g_main_context_get_poll_func(gobj());
}

void MainContext::add_poll(PollFD& fd, int priority)
{
  g_main_context_add_poll(gobj(), fd.gobj(), priority);
}

void MainContext::remove_poll(PollFD& fd)
{
  g_main_context_remove_poll(gobj(), fd.gobj());
}

SignalTimeout MainContext::signal_timeout()
{
  return SignalTimeout(gobj());
}

SignalIdle MainContext::signal_idle()
{
  return SignalIdle(gobj());
}

SignalIO MainContext::signal_io()
{
  return SignalIO(gobj());
}

void MainContext::reference() const
{
  g_main_context_ref(reinterpret_cast<GMainContext*>(const_cast<MainContext*>(this)));
}

void MainContext::unreference() const
{
  g_main_context_unref(reinterpret_cast<GMainContext*>(const_cast<MainContext*>(this)));
}

GMainContext* MainContext::gobj()
{
  return reinterpret_cast<GMainContext*>(this);
}

const GMainContext* MainContext::gobj() const
{
  return reinterpret_cast<const GMainContext*>(this);
}

GMainContext* MainContext::gobj_copy() const
{
  reference();
  return const_cast<GMainContext*>(gobj());
}

Glib::RefPtr<MainContext> wrap(GMainContext* gobject, bool take_copy)
{
  if(take_copy && gobject)
    g_main_context_ref(gobject);

  return Glib::RefPtr<MainContext>(reinterpret_cast<MainContext*>(gobject));
}


/**** Glib::MainLoop *******************************************************/

Glib::RefPtr<MainLoop> MainLoop::create(bool is_running)
{
  return Glib::RefPtr<MainLoop>(
      reinterpret_cast<MainLoop*>(g_main_loop_new(0, is_running)));
}

Glib::RefPtr<MainLoop> MainLoop::create(const Glib::RefPtr<MainContext>& context, bool is_running)
{
  return Glib::RefPtr<MainLoop>(
      reinterpret_cast<MainLoop*>(g_main_loop_new(Glib::unwrap(context), is_running)));
}

void MainLoop::run()
{
  g_main_loop_run(gobj());
}

void MainLoop::quit()
{
  g_main_loop_quit(gobj());
}

bool MainLoop::is_running()
{
  return g_main_loop_is_running(gobj());
}

Glib::RefPtr<MainContext> MainLoop::get_context()
{
  return Glib::wrap(g_main_loop_get_context(gobj()), true);
}

void MainLoop::reference() const
{
  g_main_loop_ref(reinterpret_cast<GMainLoop*>(const_cast<MainLoop*>(this)));
}

void MainLoop::unreference() const
{
  g_main_loop_unref(reinterpret_cast<GMainLoop*>(const_cast<MainLoop*>(this)));
}

GMainLoop* MainLoop::gobj()
{
  return reinterpret_cast<GMainLoop*>(this);
}

const GMainLoop* MainLoop::gobj() const
{
  return reinterpret_cast<const GMainLoop*>(this);
}

GMainLoop* MainLoop::gobj_copy() const
{
  reference();
  return const_cast<GMainLoop*>(gobj());
}

Glib::RefPtr<MainLoop> wrap(GMainLoop* gobject, bool take_copy)
{
  if(take_copy && gobject)
    g_main_loop_ref(gobject);

  return Glib::RefPtr<MainLoop>(reinterpret_cast<MainLoop*>(gobject));
}


/**** Glib::Source *********************************************************/

// static
const GSourceFuncs Source::vfunc_table_ =
{
  &Source::prepare_vfunc,
  &Source::check_vfunc,
  &Source::dispatch_vfunc,
  0, // finalize_vfunc // We can't use finalize_vfunc because there is no way
                       // to store a pointer to our wrapper anywhere in GSource so
                       // that it persists until finalize_vfunc would be called from here.
  0, // closure_callback
  0, // closure_marshal
};

unsigned int Source::attach(const Glib::RefPtr<MainContext>& context)
{
  return g_source_attach(gobject_, Glib::unwrap(context));
}

unsigned int Source::attach()
{
  return g_source_attach(gobject_, 0);
}

void Source::destroy()
{
  g_source_destroy(gobject_);
}

void Source::set_priority(int priority)
{
  g_source_set_priority(gobject_, priority);
}

int Source::get_priority() const
{
  return g_source_get_priority(gobject_);
}

void Source::set_can_recurse(bool can_recurse)
{
  g_source_set_can_recurse(gobject_, can_recurse);
}

bool Source::get_can_recurse() const
{
  return g_source_get_can_recurse(gobject_);
}

unsigned int Source::get_id() const
{
  return g_source_get_id(gobject_);
}

Glib::RefPtr<MainContext> Source::get_context()
{
  return Glib::wrap(g_source_get_context(gobject_), true);
}

GSource* Source::gobj_copy() const
{
  return g_source_ref(gobject_);
}

void Source::reference() const
{
  g_source_ref(gobject_);
}

void Source::unreference() const
{
  g_source_unref(gobject_);
}

Source::Source()
:
  gobject_ (g_source_new(const_cast<GSourceFuncs*>(&vfunc_table_), sizeof(GSource)))
{
  g_source_set_callback(
      gobject_, &glibmm_dummy_source_callback,
      new SourceCallbackData(this), // our persistant callback data object
      &SourceCallbackData::destroy_notify_callback);
}

Source::Source(GSource* cast_item, GSourceFunc callback_func)
:
  gobject_ (cast_item)
{
  g_source_set_callback(
      gobject_, callback_func,
      new SourceCallbackData(this), // our persistant callback data object
      &SourceCallbackData::destroy_notify_callback);
}

Source::~Source()
{
  // The dtor should be invoked by destroy_notify_callback() only, which clears
  // gobject_ before deleting.  However, we might also get to this point if
  // a derived ctor threw an exception, and then we need to unref manually.

  if(gobject_)
  {
    SourceCallbackData *const data = glibmm_source_get_callback_data(gobject_);
    data->wrapper = 0;

    GSource *const tmp_gobject = gobject_;
    gobject_ = 0;

    g_source_unref(tmp_gobject);
  }
}

SigC::Connection Source::connect_generic(const SigC::SlotBase& slot)
{
  SourceConnectionNode *const conn_node = new SourceConnectionNode(slot);
  const SigC::Connection connection (conn_node);

  // Don't override the callback data.  Reuse the existing one
  // calling SourceCallbackData::set_node() to register conn_node.
  SourceCallbackData *const data = glibmm_source_get_callback_data(gobject_);
  data->set_node(conn_node);

  conn_node->install(gobject_);
  return connection;
}

void Source::add_poll(Glib::PollFD& poll_fd)
{
  g_source_add_poll(gobject_, poll_fd.gobj());
}

void Source::remove_poll(Glib::PollFD& poll_fd)
{
  g_source_remove_poll(gobject_, poll_fd.gobj());
}

void Source::get_current_time(Glib::TimeVal& current_time)
{
  g_source_get_current_time(gobject_, &current_time);
}

inline // static
Source* Source::get_wrapper(GSource* source)
{
  SourceCallbackData *const data = glibmm_source_get_callback_data(source);
  return data->wrapper;
}

// static
gboolean Source::prepare_vfunc(GSource* source, int* timeout)
{
  try
  {
    Source *const self = get_wrapper(source);
    return self->prepare(*timeout);
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

// static
gboolean Source::check_vfunc(GSource* source)
{
  try
  {
    Source *const self = get_wrapper(source);
    return self->check();
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

// static
gboolean Source::dispatch_vfunc(GSource*, GSourceFunc callback, void* user_data)
{
  SourceCallbackData *const callback_data = static_cast<SourceCallbackData*>(user_data);

  g_return_val_if_fail(callback == &glibmm_dummy_source_callback, 0);
  g_return_val_if_fail(callback_data != 0 && callback_data->node != 0, 0);

  try
  {
    Source *const self = callback_data->wrapper;
    return self->dispatch(callback_data->node->get_slot_node());
  }
  catch(...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

// static
void Source::destroy_notify_callback(void* data)
{
  if(data)
  {
    Source *const self = static_cast<Source*>(data);

    // gobject_ is already invalid at this point.
    self->gobject_ = 0;

    // No exception checking: if the dtor throws, you're out of luck anyway.
    delete self;
  }
}


/**** Glib::TimeoutSource **************************************************/

// static
Glib::RefPtr<TimeoutSource> TimeoutSource::create(unsigned int interval)
{
  return Glib::RefPtr<TimeoutSource>(new TimeoutSource(interval));
}

SigC::Connection TimeoutSource::connect(const SigC::Slot0<bool>& slot)
{
  return connect_generic(slot);
}

TimeoutSource::TimeoutSource(unsigned int interval)
:
  interval_ (interval)
{
  expiration_.assign_current_time();
  expiration_.add_milliseconds(std::min<unsigned long>(G_MAXLONG, interval_));
}

TimeoutSource::~TimeoutSource()
{}

bool TimeoutSource::prepare(int& timeout)
{
  Glib::TimeVal current_time;
  get_current_time(current_time);

  Glib::TimeVal remaining = expiration_;
  remaining.subtract(current_time);

  if(remaining.negative())
  {
    // Already expired.
    timeout = 0;
  }
  else
  {
    const unsigned long milliseconds =
        static_cast<unsigned long>(remaining.tv_sec)  * 1000U +
        static_cast<unsigned long>(remaining.tv_usec) / 1000U;

    // Set remaining milliseconds.
    timeout = std::min<unsigned long>(G_MAXINT, milliseconds);

    // Check if the system time has been set backwards. (remaining > interval)
    remaining.add_milliseconds(- std::min<unsigned long>(G_MAXLONG, interval_) - 1);
    if(!remaining.negative())
    {
      // Oh well.  Reset the expiration time to now + interval;
      // this at least avoids hanging for long periods of time.
      expiration_ = current_time;
      expiration_.add_milliseconds(interval_);
      timeout = std::min<unsigned int>(G_MAXINT, interval_);
    }
  }

  return (timeout == 0);
}

bool TimeoutSource::check()
{
  Glib::TimeVal current_time;
  get_current_time(current_time);

  return (expiration_ <= current_time);
}

bool TimeoutSource::dispatch(SigC::SlotNode* slot_data)
{
  SigC::Slot0<bool> slot (slot_data);
  const bool again = slot();

  if(again)
  {
    get_current_time(expiration_);
    expiration_.add_milliseconds(std::min<unsigned long>(G_MAXLONG, interval_));
  }

  return again;
}


/**** Glib::IdleSource *****************************************************/

// static
Glib::RefPtr<IdleSource> IdleSource::create()
{
  return Glib::RefPtr<IdleSource>(new IdleSource());
}

SigC::Connection IdleSource::connect(const SigC::Slot0<bool>& slot)
{
  return connect_generic(slot);
}

IdleSource::IdleSource()
{
  set_priority(PRIORITY_DEFAULT_IDLE);
}

IdleSource::~IdleSource()
{}

bool IdleSource::prepare(int& timeout)
{
  timeout = 0;
  return true;
}

bool IdleSource::check()
{
  return true;
}

bool IdleSource::dispatch(SigC::SlotNode* slot_data)
{
  SigC::Slot0<bool> slot (slot_data);
  return slot();
}


/**** Glib::IOSource *******************************************************/

// static
Glib::RefPtr<IOSource> IOSource::create(int fd, IOCondition condition)
{
  return Glib::RefPtr<IOSource>(new IOSource(fd, condition));
}

Glib::RefPtr<IOSource> IOSource::create(const Glib::RefPtr<IOChannel>& channel, IOCondition condition)
{
  return Glib::RefPtr<IOSource>(new IOSource(channel, condition));
}

SigC::Connection IOSource::connect(const SigC::Slot1<bool,IOCondition>& slot)
{
  return connect_generic(slot);
}

IOSource::IOSource(int fd, IOCondition condition)
:
  poll_fd_ (fd, condition)
{
  add_poll(poll_fd_);
}

IOSource::IOSource(const Glib::RefPtr<IOChannel>& channel, IOCondition condition)
:
  Source(g_io_create_watch(channel->gobj(), (GIOCondition) condition),
         (GSourceFunc) &glibmm_iosource_callback)
{}

IOSource::~IOSource()
{}

bool IOSource::prepare(int& timeout)
{
  timeout = -1;
  return false;
}

bool IOSource::check()
{
  return ((poll_fd_.get_revents() & poll_fd_.get_events()) != 0);
}

bool IOSource::dispatch(SigC::SlotNode* slot_data)
{
  SigC::Slot1<bool,IOCondition> slot (slot_data);
  return slot(poll_fd_.get_revents());
}

} // namespace Glib

