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

#include <glibmm/main.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/wrap.h>
#include <glibmm/iochannel.h>
#include <glibmm/utility.h>
#include <algorithm>

namespace
{
// Convert an interval from milliseconds to microseconds,
// suitable for adding to Source::get_time().
inline gint64 ms2us(unsigned int ms)
{
  return static_cast<gint64>(ms) * 1000;
}

class SourceConnectionNode : public sigc::notifiable
{
public:
  explicit inline SourceConnectionNode(const sigc::slot_base& slot);

  static void notify(sigc::notifiable* data);
  static void destroy_notify_callback(sigc::notifiable* data);

  inline void install(GSource* source);
  inline sigc::slot_base* get_slot();

private:
  sigc::slot_base slot_;
  GSource* source_;
};

inline SourceConnectionNode::SourceConnectionNode(const sigc::slot_base& slot)
: slot_(slot), source_(nullptr)
{
  slot_.set_parent(this, &SourceConnectionNode::notify);
}

void
SourceConnectionNode::notify(sigc::notifiable* data)
{
  SourceConnectionNode* const self = static_cast<SourceConnectionNode*>(data);

  // if there is no object, this call was triggered from destroy_notify_handler(),
  // because we set self->source_ to nullptr there:
  if (self->source_)
  {
    GSource* s = self->source_;
    self->source_ = nullptr;
    g_source_destroy(s);

    // Destroying the object triggers execution of destroy_notify_handler(),
    // either immediately or later, so we leave that to do the deletion.
  }
}

// static
void
SourceConnectionNode::destroy_notify_callback(sigc::notifiable* data)
{
  SourceConnectionNode* const self = static_cast<SourceConnectionNode*>(data);

  if (self)
  {
    // The GLib side is disconnected now, thus the GSource* is no longer valid.
    self->source_ = nullptr;

    delete self;
  }
}

inline void
SourceConnectionNode::install(GSource* source)
{
  source_ = source;
}

inline sigc::slot_base*
SourceConnectionNode::get_slot()
{
  return &slot_;
}

/* We use the callback data member of GSource to store both a pointer to our
 * wrapper and a pointer to the connection node that is currently being used.
 * The one and only SourceCallbackData object of a Glib::Source is constructed
 * in the ctor of Glib::Source and destroyed when the GSource object is destroyed,
 * which may occur before the reference counter of the GSource object reaches zero!
 */
struct SourceCallbackData
{
  explicit inline SourceCallbackData(Glib::Source* wrapper_);

  void set_node(SourceConnectionNode* node_);

  static void destroy_notify_callback(void* data);

  Glib::Source* wrapper;
  SourceConnectionNode* node;
};

inline SourceCallbackData::SourceCallbackData(Glib::Source* wrapper_)
: wrapper(wrapper_), node(nullptr)
{
}

void
SourceCallbackData::set_node(SourceConnectionNode* node_)
{
  if (node)
    SourceConnectionNode::destroy_notify_callback(node);

  node = node_;
}

// static
void
SourceCallbackData::destroy_notify_callback(void* data)
{
  SourceCallbackData* const self = static_cast<SourceCallbackData*>(data);

  if (self->node)
    SourceConnectionNode::destroy_notify_callback(self->node);

  // destroy_notify_callback2() does nothing if self->wrapper == nullptr.
  Glib::Source::destroy_notify_callback2(self->wrapper);

  delete self;
}

/* Retrieve the callback data from a wrapped GSource object.
 */
static SourceCallbackData*
glibmm_source_get_callback_data(GSource* source)
{
  /* There is race between iteration of sources in main loop
   * that checks whether they are still active and source
   * destruction happening in other threads.
   */
  gpointer callback_data = source->callback_data;
  GSourceCallbackFuncs* callback_funcs = source->callback_funcs;

  g_return_val_if_fail(callback_funcs != nullptr, nullptr);

  if (g_source_is_destroyed(source))
    return nullptr;

  GSourceFunc func;
  void* user_data = nullptr;

  // Retrieve the callback function and data.
  (*callback_funcs->get)(callback_data, source, &func, &user_data);

  return static_cast<SourceCallbackData*>(user_data);
}

// The function pointers, glibmm_source_*_vfuncptr, are set in the Source ctor
// that calls g_source_new(const_cast<GSourceFuncs*>(&vfunc_table_), sizeof(GSource)),
// making it possible to indirectly call the Source::*_vfunc() member functions
// from the glibmm_source_*_callback() functions with C linkage.
using SourcePrepareVFuncType = gboolean (*)(GSource* source, int* timeout);
using SourceCheckVFuncType = gboolean (*)(GSource* source);
using SourceDispatchVFuncType = gboolean (*)(GSource* source, GSourceFunc callback, void* user_data);
SourcePrepareVFuncType glibmm_source_prepare_vfuncptr;
SourceCheckVFuncType glibmm_source_check_vfuncptr;
SourceDispatchVFuncType glibmm_source_dispatch_vfuncptr;

extern "C"
{
static gboolean
glibmm_source_prepare_callback(GSource* source, int* timeout)
{
  return glibmm_source_prepare_vfuncptr(source, timeout);
}

static gboolean
glibmm_source_check_callback(GSource* source)
{
  return glibmm_source_check_vfuncptr(source);
}

static gboolean
glibmm_source_dispatch_callback(GSource* source, GSourceFunc callback, void* user_data)
{
  return glibmm_source_dispatch_vfuncptr(source, callback, user_data);
}

/* Glib::Source doesn't use the callback function installed with
 * g_source_set_callback().  Instead, it invokes the sigc++ slot
 * directly from dispatch_vfunc(), which is both simpler and more
 * efficient.
 * For correctness, provide a pointer to this dummy callback rather
 * than some random pointer.  That also allows for sanity checks
 * here as well as in Source::dispatch_vfunc().
 */
static gboolean
glibmm_dummy_source_callback(void*)
{
  g_assert_not_reached();
  return 0;
}

/* Only used by SignalTimeout::connect(), SignalTimeout::connect_seconds()
 * and SignalIdle::connect(). These don't use Glib::Source, to avoid the
 * unnecessary overhead of a completely unused wrapper object.
 */
static gboolean
glibmm_source_callback(void* data)
{
  SourceConnectionNode* const conn_data = static_cast<SourceConnectionNode*>(data);

  try
  {
    // Recreate the specific slot from the generic slot node.
    return (*static_cast<sigc::slot<bool()>*>(conn_data->get_slot()))();
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

/* Only used by SignalTimeout::connect_once(), SignalTimeout::connect_seconds_once()
 * and SignalIdle::connect_once(). These don't use Glib::Source, to avoid the
 * unnecessary overhead of a completely unused wrapper object.
 */
static gboolean
glibmm_source_callback_once(void* data)
{
  SourceConnectionNode* const conn_data = static_cast<SourceConnectionNode*>(data);

  try
  {
    // Recreate the specific slot from the generic slot node.
    (*static_cast<sigc::slot<void()>*>(conn_data->get_slot()))();
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0; // Destroy the event source after one call
}

static void
glibmm_source_destroy_notify_callback(void* data)
{
  SourceConnectionNode* const conn_data = static_cast<SourceConnectionNode*>(data);
  SourceConnectionNode::destroy_notify_callback(conn_data);
}

static gboolean
glibmm_iosource_callback(GIOChannel*, GIOCondition condition, void* data)
{
  SourceCallbackData* const callback_data = static_cast<SourceCallbackData*>(data);
  g_return_val_if_fail(callback_data->node != nullptr, 0);

  try
  {
    // Recreate the specific slot from the generic slot node.
    return (*static_cast<sigc::slot<bool(Glib::IOCondition)>*>(callback_data->node->get_slot()))(
      (Glib::IOCondition)condition);
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

/* Only used by SignalChildWatch::connect().
 * These don't use Glib::Source, to avoid the unnecessary overhead
 * of a completely unused wrapper object.
 */
static gboolean
glibmm_child_watch_callback(GPid pid, gint child_status, void* data)
{
  SourceConnectionNode* const conn_data = static_cast<SourceConnectionNode*>(data);

  try
  {
    // Recreate the specific slot from the generic slot node.
    (*static_cast<sigc::slot<void(GPid, int)>*>(conn_data->get_slot()))(pid, child_status);
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}
} // extern "C"

static void
glibmm_signal_connect_once(
  const sigc::slot<void()>& slot, int priority, GSource* source, GMainContext* context)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(source, &glibmm_source_callback_once, conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context);
  g_source_unref(source); // GMainContext holds a reference
}

extern "C"
{
static gboolean
glibmm_main_context_invoke_callback(void* data)
{
  sigc::slot_base* const slot = reinterpret_cast<sigc::slot_base*>(data);

  try
  {
    // Recreate the specific slot from the generic slot node.
    return (*static_cast<sigc::slot<bool()>*>(slot))();
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

static void
glibmm_main_context_invoke_destroy_notify_callback(void* data)
{
  sigc::slot_base* const slot = reinterpret_cast<sigc::slot_base*>(data);
  delete slot;
}

static void
glibmm_source_callback_data_destroy_notify_callback(void* data)
{
  SourceCallbackData::destroy_notify_callback(data);
}
} // extern "C"

} // anonymous namespace

namespace Glib
{

/**** Glib::PollFD *********************************************************/

PollFD::PollFD()
{
  gobject_.fd = 0;
  gobject_.events = 0;
  gobject_.revents = 0;
}

PollFD::PollFD(PollFD::fd_t fd)
{
  gobject_.fd = fd;
  gobject_.events = 0;
  gobject_.revents = 0;
}

PollFD::PollFD(PollFD::fd_t fd, IOCondition events)
{
  gobject_.fd = fd;
  gobject_.events = static_cast<decltype(gobject_.events)>(events);
  gobject_.revents = 0;
}

/**** Glib::SignalTimeout **************************************************/

inline SignalTimeout::SignalTimeout(GMainContext* context) : context_(context)
{
}

/* Note that this is our equivalent of g_timeout_add(). */
sigc::connection
SignalTimeout::connect(const sigc::slot<bool()>& slot, unsigned int interval, int priority)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  GSource* const source = g_timeout_source_new(interval);

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
    source, &glibmm_source_callback, conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  return connection;
}

void
SignalTimeout::connect_once(const sigc::slot<void()>& slot, unsigned int interval, int priority)
{
  GSource* const source = g_timeout_source_new(interval);
  glibmm_signal_connect_once(slot, priority, source, context_);
}

/* Note that this is our equivalent of g_timeout_add_seconds(). */
sigc::connection
SignalTimeout::connect_seconds(const sigc::slot<bool()>& slot, unsigned int interval, int priority)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  GSource* const source = g_timeout_source_new_seconds(interval);

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
    source, &glibmm_source_callback, conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  return connection;
}

void
SignalTimeout::connect_seconds_once(
  const sigc::slot<void()>& slot, unsigned int interval, int priority)
{
  GSource* const source = g_timeout_source_new_seconds(interval);
  glibmm_signal_connect_once(slot, priority, source, context_);
}

SignalTimeout
signal_timeout()
{
  return SignalTimeout(nullptr); // nullptr means default context
}

/**** Glib::SignalIdle *****************************************************/

inline SignalIdle::SignalIdle(GMainContext* context) : context_(context)
{
}

sigc::connection
SignalIdle::connect(const sigc::slot<bool()>& slot, int priority)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  GSource* const source = g_idle_source_new();

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
    source, &glibmm_source_callback, conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  return connection;
}

void
SignalIdle::connect_once(const sigc::slot<void()>& slot, int priority)
{
  GSource* const source = g_idle_source_new();
  glibmm_signal_connect_once(slot, priority, source, context_);
}

SignalIdle
signal_idle()
{
  return SignalIdle(nullptr); // nullptr means default context
}

/**** Glib::SignalIO *******************************************************/

inline SignalIO::SignalIO(GMainContext* context) : context_(context)
{
}

sigc::connection
SignalIO::connect(
  const sigc::slot<bool(IOCondition)>& slot, PollFD::fd_t fd, IOCondition condition, int priority)
{
  const auto source = IOSource::create(fd, condition);

  if (priority != G_PRIORITY_DEFAULT)
    source->set_priority(priority);

  const sigc::connection connection = source->connect(slot);

  g_source_attach(source->gobj(), context_);

  return connection;
}

sigc::connection
SignalIO::connect(const sigc::slot<bool(IOCondition)>& slot, const Glib::RefPtr<IOChannel>& channel,
  IOCondition condition, int priority)
{
  const auto source = IOSource::create(channel, condition);

  if (priority != G_PRIORITY_DEFAULT)
    source->set_priority(priority);

  const sigc::connection connection = source->connect(slot);

  g_source_attach(source->gobj(), context_);

  return connection;
}

SignalIO
signal_io()
{
  return SignalIO(nullptr); // nullptr means default context
}

/**** Glib::SignalChildWatch **************************************************/

inline SignalChildWatch::SignalChildWatch(GMainContext* context) : context_(context)
{
}

sigc::connection
SignalChildWatch::connect(const sigc::slot<void(GPid, int)>& slot, GPid pid, int priority)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  GSource* const source = g_child_watch_source_new(pid);

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(source, Glib::function_pointer_cast<GSourceFunc>(&glibmm_child_watch_callback),
    conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context_);
  g_source_unref(source); // GMainContext holds a reference

  return connection;
}

SignalChildWatch
signal_child_watch()
{
  return SignalChildWatch(nullptr); // nullptr means default context
}

/**** Glib::MainContext ****************************************************/

// static
Glib::RefPtr<MainContext>
MainContext::create()
{
  return Glib::make_refptr_for_instance<MainContext>(reinterpret_cast<MainContext*>(g_main_context_new()));
}

// static
Glib::RefPtr<MainContext>
MainContext::create(MainContextFlags flags)
{
  return Glib::make_refptr_for_instance<MainContext>(
    reinterpret_cast<MainContext*>(g_main_context_new_with_flags(static_cast<GMainContextFlags>(flags))));
}

// static
Glib::RefPtr<MainContext>
MainContext::get_default()
{
  return Glib::wrap(g_main_context_default(), true);
}

bool
MainContext::iteration(bool may_block)
{
  return g_main_context_iteration(gobj(), may_block);
}

bool
MainContext::pending()
{
  return g_main_context_pending(gobj());
}

void
MainContext::wakeup()
{
  g_main_context_wakeup(gobj());
}

bool
MainContext::acquire()
{
  return g_main_context_acquire(gobj());
}

void
MainContext::release()
{
  g_main_context_release(gobj());
}

bool
MainContext::prepare(int& priority)
{
  return g_main_context_prepare(gobj(), &priority);
}

bool
MainContext::prepare()
{
  return g_main_context_prepare(gobj(), nullptr);
}

void
MainContext::query(int max_priority, int& timeout, std::vector<PollFD>& fds)
{
  if (fds.empty())
    fds.resize(8); // rather bogus number, but better than 0

  for (;;)
  {
    const int size_before = fds.size();
    const int size_needed = g_main_context_query(
      gobj(), max_priority, &timeout, reinterpret_cast<GPollFD*>(&fds.front()), size_before);

    fds.resize(size_needed);

    if (size_needed <= size_before)
      break;
  }
}

bool
MainContext::check(int max_priority, std::vector<PollFD>& fds)
{
  if (!fds.empty())
    return g_main_context_check(
      gobj(), max_priority, reinterpret_cast<GPollFD*>(&fds.front()), fds.size());
  else
    return false;
}

void
MainContext::dispatch()
{
  g_main_context_dispatch(gobj());
}

void
MainContext::set_poll_func(GPollFunc poll_func)
{
  g_main_context_set_poll_func(gobj(), poll_func);
}

GPollFunc
MainContext::get_poll_func()
{
  return g_main_context_get_poll_func(gobj());
}

void
MainContext::add_poll(PollFD& fd, int priority)
{
  g_main_context_add_poll(gobj(), fd.gobj(), priority);
}

void
MainContext::remove_poll(PollFD& fd)
{
  g_main_context_remove_poll(gobj(), fd.gobj());
}

void
MainContext::push_thread_default()
{
  g_main_context_push_thread_default(gobj());
}

void
MainContext::pop_thread_default()
{
  g_main_context_pop_thread_default(gobj());
}

// static
Glib::RefPtr<MainContext>
MainContext::get_thread_default()
{
  // g_main_context_ref_thread_default() gives us a ref.
  return Glib::wrap(g_main_context_ref_thread_default(), false);
}

void
MainContext::invoke(const sigc::slot<bool()>& slot, int priority)
{
  // Make a copy of slot on the heap.
  sigc::slot_base* const slot_copy = new sigc::slot<bool()>(slot);

  g_main_context_invoke_full(gobj(), priority, glibmm_main_context_invoke_callback, slot_copy,
    glibmm_main_context_invoke_destroy_notify_callback);
}

SignalTimeout
MainContext::signal_timeout()
{
  return SignalTimeout(gobj());
}

SignalIdle
MainContext::signal_idle()
{
  return SignalIdle(gobj());
}

SignalIO
MainContext::signal_io()
{
  return SignalIO(gobj());
}

SignalChildWatch
MainContext::signal_child_watch()
{
  return SignalChildWatch(gobj());
}

void
MainContext::reference() const
{
  g_main_context_ref(reinterpret_cast<GMainContext*>(const_cast<MainContext*>(this)));
}

void
MainContext::unreference() const
{
  g_main_context_unref(reinterpret_cast<GMainContext*>(const_cast<MainContext*>(this)));
}

GMainContext*
MainContext::gobj()
{
  return reinterpret_cast<GMainContext*>(this);
}

const GMainContext*
MainContext::gobj() const
{
  return reinterpret_cast<const GMainContext*>(this);
}

GMainContext*
MainContext::gobj_copy() const
{
  reference();
  return const_cast<GMainContext*>(gobj());
}

Glib::RefPtr<MainContext>
wrap(GMainContext* gobject, bool take_copy)
{
  if (take_copy && gobject)
    g_main_context_ref(gobject);

  return Glib::make_refptr_for_instance<MainContext>(reinterpret_cast<MainContext*>(gobject));
}

/**** Glib::MainLoop *******************************************************/

Glib::RefPtr<MainLoop>
MainLoop::create(bool is_running)
{
  return Glib::make_refptr_for_instance<MainLoop>(reinterpret_cast<MainLoop*>(g_main_loop_new(nullptr, is_running)));
}

Glib::RefPtr<MainLoop>
MainLoop::create(const Glib::RefPtr<MainContext>& context, bool is_running)
{
  return Glib::make_refptr_for_instance<MainLoop>(
    reinterpret_cast<MainLoop*>(g_main_loop_new(Glib::unwrap(context), is_running)));
}

void
MainLoop::run()
{
  g_main_loop_run(gobj());
}

void
MainLoop::quit()
{
  g_main_loop_quit(gobj());
}

bool
MainLoop::is_running()
{
  return g_main_loop_is_running(gobj());
}

Glib::RefPtr<MainContext>
MainLoop::get_context()
{
  return Glib::wrap(g_main_loop_get_context(gobj()), true);
}

// static:
int
MainLoop::depth()
{
  return g_main_depth();
}

void
MainLoop::reference() const
{
  g_main_loop_ref(reinterpret_cast<GMainLoop*>(const_cast<MainLoop*>(this)));
}

void
MainLoop::unreference() const
{
  g_main_loop_unref(reinterpret_cast<GMainLoop*>(const_cast<MainLoop*>(this)));
}

GMainLoop*
MainLoop::gobj()
{
  return reinterpret_cast<GMainLoop*>(this);
}

const GMainLoop*
MainLoop::gobj() const
{
  return reinterpret_cast<const GMainLoop*>(this);
}

GMainLoop*
MainLoop::gobj_copy() const
{
  reference();
  return const_cast<GMainLoop*>(gobj());
}

Glib::RefPtr<MainLoop>
wrap(GMainLoop* gobject, bool take_copy)
{
  if (take_copy && gobject)
    g_main_loop_ref(gobject);

  return Glib::make_refptr_for_instance<MainLoop>(reinterpret_cast<MainLoop*>(gobject));
}

/**** Glib::Source *********************************************************/

// static
const GSourceFuncs Source::vfunc_table_ = {
  &glibmm_source_prepare_callback,
  &glibmm_source_check_callback,
  &glibmm_source_dispatch_callback,
  // We can't use finalize_vfunc because there is no way
  // to store a pointer to our wrapper anywhere in GSource so
  // that it persists until finalize_vfunc would be called from here.
  nullptr, // finalize_vfunc
  nullptr, // closure_callback
  nullptr, // closure_marshal
};

unsigned int
Source::attach(const Glib::RefPtr<MainContext>& context)
{
  return g_source_attach(gobject_, Glib::unwrap(context));
}

unsigned int
Source::attach()
{
  return g_source_attach(gobject_, nullptr);
}

void
Source::destroy()
{
  g_source_destroy(gobject_);
}

void
Source::set_priority(int priority)
{
  g_source_set_priority(gobject_, priority);
}

int
Source::get_priority() const
{
  return g_source_get_priority(gobject_);
}

void
Source::set_can_recurse(bool can_recurse)
{
  g_source_set_can_recurse(gobject_, can_recurse);
}

bool
Source::get_can_recurse() const
{
  return g_source_get_can_recurse(gobject_);
}

unsigned int
Source::get_id() const
{
  return g_source_get_id(gobject_);
}

Glib::RefPtr<MainContext>
Source::get_context()
{
  return Glib::wrap(g_source_get_context(gobject_), true);
}

GSource*
Source::gobj_copy() const
{
  return g_source_ref(gobject_);
}

void
Source::reference() const
{
  ++ref_count_;
}

void
Source::unreference() const
{
  if (--ref_count_ == 0)
  {
    GSource* const tmp_gobject = gobject_;

    destroy_notify_callback2(const_cast<Source*>(this));

    // Drop the one and only GSource reference held by the C++ wrapper.
    // If the GSource instance is attached to a main context, the GMainContext
    // holds a reference until the source is detached (destroyed).
    g_source_unref(tmp_gobject);
  }
}

Source::Source() : gobject_(g_source_new(const_cast<GSourceFuncs*>(&vfunc_table_), sizeof(GSource)))
{
  glibmm_source_prepare_vfuncptr = &prepare_vfunc;
  glibmm_source_check_vfuncptr = &check_vfunc;
  glibmm_source_dispatch_vfuncptr = &dispatch_vfunc;

  g_source_set_callback(gobject_, &glibmm_dummy_source_callback,
    new SourceCallbackData(this), // our persistent callback data object
    &glibmm_source_callback_data_destroy_notify_callback);
}

Source::Source(GSource* cast_item, GSourceFunc callback_func) : gobject_(cast_item)
{
  g_source_set_callback(gobject_, callback_func,
    new SourceCallbackData(this), // our persistent callback data object
    &glibmm_source_callback_data_destroy_notify_callback);
}

Source::~Source() noexcept
{
  // The dtor should be invoked by destroy_notify_callback() only, which clears
  // gobject_ before deleting.  However, we might also get to this point if
  // a derived ctor threw an exception, and then we need to unref manually.

  if (gobject_)
  {
    SourceCallbackData* const data = glibmm_source_get_callback_data(gobject_);

    if (data) {
      data->wrapper = nullptr;
    }

    GSource* const tmp_gobject = gobject_;
    gobject_ = nullptr;

    g_source_unref(tmp_gobject);

    // The constructor does not add this to extra_source_data. No need to erase.
  }
}

sigc::connection
Source::connect_generic(const sigc::slot_base& slot)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  // Don't override the callback data.  Reuse the existing one
  // calling SourceCallbackData::set_node() to register conn_node.
  SourceCallbackData* const data = glibmm_source_get_callback_data(gobject_);

  if (data) {
    data->set_node(conn_node);
  }

  conn_node->install(gobject_);
  return connection;
}

void
Source::add_poll(Glib::PollFD& poll_fd)
{
  g_source_add_poll(gobject_, poll_fd.gobj());
}

void
Source::remove_poll(Glib::PollFD& poll_fd)
{
  g_source_remove_poll(gobject_, poll_fd.gobj());
}

gint64
Source::get_time() const
{
  if (g_source_get_context(const_cast<GSource*>(gobject_)))
    return g_source_get_time(const_cast<GSource*>(gobject_));
  else
    return g_get_monotonic_time();
}

inline // static
  Source*
  Source::get_wrapper(GSource* source)
{
  SourceCallbackData* const data = glibmm_source_get_callback_data(source);
  return (data) ? data->wrapper : nullptr;
}

// static
gboolean
Source::prepare_vfunc(GSource* source, int* timeout)
{
  try
  {
    Source* const self = get_wrapper(source);
    return (self) ? self->prepare(*timeout) : 0;
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }

  return 0;
}

// static
gboolean
Source::check_vfunc(GSource* source)
{
  try
  {
    Source* const self = get_wrapper(source);
    return (self) ? self->check() : 0;
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }

  return 0;
}

// static
gboolean
Source::dispatch_vfunc(GSource*, GSourceFunc callback, void* user_data)
{
  SourceCallbackData* const callback_data = static_cast<SourceCallbackData*>(user_data);

  g_return_val_if_fail(callback == &glibmm_dummy_source_callback, 0);
  g_return_val_if_fail(callback_data != nullptr && callback_data->node != nullptr, 0);

  try
  {
    Source* const self = callback_data->wrapper;
    return self->dispatch(callback_data->node->get_slot());
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
  return 0;
}

// static
void
Source::destroy_notify_callback2(void* data)
{
  if (data)
  {
    Source* const self = static_cast<Source*>(data);
    if (--self->keep_wrapper_ == 0)
    {
      // gobject_ is already invalid at this point.
      self->gobject_ = nullptr;

      // No exception checking: if the dtor throws, you're out of luck anyway.
      delete self;
    }
  }
}

// static
sigc::connection
Source::attach_signal_source(const sigc::slot_base& slot, int priority, GSource* source,
  GMainContext* context, GSourceFunc callback_func)
{
  SourceConnectionNode* const conn_node = new SourceConnectionNode(slot);
  const sigc::connection connection(*conn_node->get_slot());

  if (priority != G_PRIORITY_DEFAULT)
    g_source_set_priority(source, priority);

  g_source_set_callback(
    source, callback_func, conn_node,
    &glibmm_source_destroy_notify_callback);

  conn_node->install(source);
  g_source_attach(source, context);
  g_source_unref(source); // GMainContext holds a reference

  return connection;
}

// static
sigc::slot_base*
Source::get_slot_from_connection_node(void* data)
{
  return static_cast<SourceConnectionNode*>(data)->get_slot();
}

// static
sigc::slot_base*
Source::get_slot_from_callback_data(void* data)
{
  SourceCallbackData* const callback_data = static_cast<SourceCallbackData*>(data);
  g_return_val_if_fail(callback_data->node != nullptr, nullptr);
  return callback_data->node->get_slot();
}

/**** Glib::TimeoutSource **************************************************/

// static
Glib::RefPtr<TimeoutSource>
TimeoutSource::create(unsigned int interval)
{
  return Glib::make_refptr_for_instance<TimeoutSource>(new TimeoutSource(interval));
}

sigc::connection
TimeoutSource::connect(const sigc::slot<bool()>& slot)
{
  return connect_generic(slot);
}

TimeoutSource::TimeoutSource(unsigned int interval) : interval_(interval)
{
  expiration_ = get_time() + ms2us(interval_);
}

TimeoutSource::~TimeoutSource() noexcept
{
}

bool
TimeoutSource::prepare(int& timeout)
{
  gint64 remaining = expiration_ - get_time();

  if (remaining <= 0)
  {
    // Already expired.
    timeout = 0;
  }
  else
  {
    // Set remaining milliseconds.
    timeout = std::min<gint64>(G_MAXINT, remaining / 1000);

    // Check if the system time has been set backwards. (remaining > interval)
    if (remaining > ms2us(interval_))
    {
      // Oh well.  Reset the expiration time to now + interval;
      // this at least avoids hanging for long periods of time.
      expiration_ = get_time() + ms2us(interval_);
      timeout = std::min<unsigned int>(G_MAXINT, interval_);
    }
  }

  return (timeout == 0);
}

bool
TimeoutSource::check()
{
  return expiration_ <= get_time();
}

bool
TimeoutSource::dispatch(sigc::slot_base* slot)
{
  const bool again = (*static_cast<sigc::slot<bool()>*>(slot))();

  if (again)
    expiration_ = get_time() + ms2us(interval_);

  return again;
}

/**** Glib::IdleSource *****************************************************/

// static
Glib::RefPtr<IdleSource>
IdleSource::create()
{
  return Glib::make_refptr_for_instance<IdleSource>(new IdleSource());
}

sigc::connection
IdleSource::connect(const sigc::slot<bool()>& slot)
{
  return connect_generic(slot);
}

IdleSource::IdleSource()
{
  set_priority(PRIORITY_DEFAULT_IDLE);
}

IdleSource::~IdleSource() noexcept
{
}

bool
IdleSource::prepare(int& timeout)
{
  timeout = 0;
  return true;
}

bool
IdleSource::check()
{
  return true;
}

bool
IdleSource::dispatch(sigc::slot_base* slot)
{
  return (*static_cast<sigc::slot<bool()>*>(slot))();
}

/**** Glib::IOSource *******************************************************/

// static
Glib::RefPtr<IOSource>
IOSource::create(PollFD::fd_t fd, IOCondition condition)
{
  return Glib::make_refptr_for_instance<IOSource>(new IOSource(fd, condition));
}

Glib::RefPtr<IOSource>
IOSource::create(const Glib::RefPtr<IOChannel>& channel, IOCondition condition)
{
  return Glib::make_refptr_for_instance<IOSource>(new IOSource(channel, condition));
}

Glib::RefPtr<IOSource>
IOSource::create(GIOChannel* channel, IOCondition condition)
{
  return Glib::make_refptr_for_instance<IOSource>(new IOSource(channel, condition));
}

sigc::connection
IOSource::connect(const sigc::slot<bool(IOCondition)>& slot)
{
  return connect_generic(slot);
}

IOSource::IOSource(PollFD::fd_t fd, IOCondition condition) : poll_fd_(fd, condition)
{
  add_poll(poll_fd_);
}

IOSource::IOSource(const Glib::RefPtr<IOChannel>& channel, IOCondition condition)
: Source(g_io_create_watch(channel->gobj(), (GIOCondition)condition),
    Glib::function_pointer_cast<GSourceFunc>(&glibmm_iosource_callback))
{
}

IOSource::IOSource(GIOChannel* channel, IOCondition condition)
: Source(g_io_create_watch(channel, (GIOCondition)condition),
    Glib::function_pointer_cast<GSourceFunc>(&glibmm_iosource_callback))
{
}

IOSource::IOSource(GSource* cast_item, GSourceFunc callback_func) : Source(cast_item, callback_func)
{
}

IOSource::~IOSource() noexcept
{
}

bool
IOSource::prepare(int& timeout)
{
  timeout = -1;
  return false;
}

bool
IOSource::check()
{
  return static_cast<int>(poll_fd_.get_revents() & poll_fd_.get_events()) != 0;
}

bool
IOSource::dispatch(sigc::slot_base* slot)
{
  return (*static_cast<sigc::slot<bool(IOCondition)>*>(slot))(poll_fd_.get_revents());
}

} // namespace Glib
