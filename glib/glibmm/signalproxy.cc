/* signalproxy.cc
 *
 * Copyright (C) 2002 The gtkmm Development Team
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

#include <glib-object.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/object.h>
#include <glibmm/signalproxy.h>

namespace
{
extern "C"
{
// From functions with C linkage to public static member functions with C++ linkage
static void SignalProxyNormal_slot0_void_callback(GObject* self, void* data)
{
  Glib::SignalProxyNormal::slot0_void_callback(self, data);
}

static void SignalProxyConnectionNode_destroy_notify_handler(gpointer data, GClosure* closure)
{
  Glib::SignalProxyConnectionNode::destroy_notify_handler(data, closure);
}
} // extern "C"
} // anonymous namespace

namespace Glib
{

// SignalProxyBase implementation:

SignalProxyBase::SignalProxyBase(Glib::ObjectBase* obj) : obj_(obj)
{
}

// SignalProxyNormal implementation:

SignalProxyNormal::SignalProxyNormal(Glib::ObjectBase* obj, const SignalProxyInfo* info)
: SignalProxyBase(obj), info_(info)
{
}

SignalProxyNormal::~SignalProxyNormal() noexcept
{
}

sigc::slot_base&
SignalProxyNormal::connect_impl_(bool notify, const sigc::slot_base& slot, bool after)
{
  GCallback c_handler = notify ? info_->notify_callback : info_->callback;
  if (c_handler == (GCallback)&slot0_void_callback)
    // Callback via a function with C linkage.
    c_handler = (GCallback)&SignalProxyNormal_slot0_void_callback;

  // create a proxy to hold our connection info
  auto pConnectionNode = new SignalProxyConnectionNode(slot, obj_->gobj());

  // connect it to glib
  // pConnectionNode will be passed in the data argument to the callback.
  pConnectionNode->connection_id_ = g_signal_connect_data(obj_->gobj(), info_->signal_name,
    c_handler, pConnectionNode, &SignalProxyConnectionNode_destroy_notify_handler,
    static_cast<GConnectFlags>(after ? G_CONNECT_AFTER : 0));

  return pConnectionNode->slot_;
}

sigc::slot_base&
SignalProxyNormal::connect_impl_(bool notify, sigc::slot_base&& slot, bool after)
{
  GCallback c_handler = notify ? info_->notify_callback : info_->callback;
  if (c_handler == (GCallback)&slot0_void_callback)
    // Callback via a function with C linkage.
    c_handler = (GCallback)&SignalProxyNormal_slot0_void_callback;

  // create a proxy to hold our connection info
  auto pConnectionNode = new SignalProxyConnectionNode(std::move(slot), obj_->gobj());

  // connect it to glib
  // pConnectionNode will be passed in the data argument to the callback.
  pConnectionNode->connection_id_ = g_signal_connect_data(obj_->gobj(), info_->signal_name,
    c_handler, pConnectionNode, &SignalProxyConnectionNode_destroy_notify_handler,
    static_cast<GConnectFlags>(after ? G_CONNECT_AFTER : 0));

  return pConnectionNode->slot_;
}

void
SignalProxyNormal::emission_stop()
{
  g_signal_stop_emission_by_name(obj_->gobj(), info_->signal_name);
}

// static
void
SignalProxyNormal::slot0_void_callback(GObject* self, void* data)
{
  // Do not try to call a signal on a disassociated wrapper.
  if (Glib::ObjectBase::_get_current_wrapper(self))
  {
    try
    {
      if (sigc::slot_base* const slot = data_to_slot(data))
        (*static_cast<sigc::slot<void()>*>(slot))();
    }
    catch (...)
    {
      Glib::exception_handlers_invoke();
    }
  }
}

// SignalProxyDetailedBase implementation:

SignalProxyDetailedBase::SignalProxyDetailedBase(
  Glib::ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name)
: SignalProxyBase(obj),
  info_(info),
  detailed_name_(Glib::ustring(info->signal_name) +
                 (detail_name.empty() ? Glib::ustring() : ("::" + detail_name)))
{
}

SignalProxyDetailedBase::~SignalProxyDetailedBase() noexcept
{
}

sigc::slot_base&
SignalProxyDetailedBase::connect_impl_(bool notify, const sigc::slot_base& slot, bool after)
{
  GCallback c_handler = notify ? info_->notify_callback : info_->callback;
  if (c_handler == (GCallback)&SignalProxyNormal::slot0_void_callback)
    // Callback via a function with C linkage.
    c_handler = (GCallback)&SignalProxyNormal_slot0_void_callback;

  // create a proxy to hold our connection info
  auto pConnectionNode = new SignalProxyConnectionNode(slot, obj_->gobj());

  // connect it to glib
  // pConnectionNode will be passed in the data argument to the callback.
  pConnectionNode->connection_id_ = g_signal_connect_data(obj_->gobj(), detailed_name_.c_str(),
    c_handler, pConnectionNode, &SignalProxyConnectionNode_destroy_notify_handler,
    static_cast<GConnectFlags>(after ? G_CONNECT_AFTER : 0));

  return pConnectionNode->slot_;
}

sigc::slot_base&
SignalProxyDetailedBase::connect_impl_(bool notify, sigc::slot_base&& slot, bool after)
{
  GCallback c_handler = notify ? info_->notify_callback : info_->callback;
  if (c_handler == (GCallback)&SignalProxyNormal::slot0_void_callback)
    // Callback via a function with C linkage.
    c_handler = (GCallback)&SignalProxyNormal_slot0_void_callback;

  // create a proxy to hold our connection info
  auto pConnectionNode = new SignalProxyConnectionNode(std::move(slot), obj_->gobj());

  // connect it to glib
  // pConnectionNode will be passed in the data argument to the callback.
  pConnectionNode->connection_id_ = g_signal_connect_data(obj_->gobj(), detailed_name_.c_str(),
    c_handler, pConnectionNode, &SignalProxyConnectionNode_destroy_notify_handler,
    static_cast<GConnectFlags>(after ? G_CONNECT_AFTER : 0));

  return pConnectionNode->slot_;
}

void
SignalProxyDetailedBase::emission_stop()
{
  g_signal_stop_emission_by_name(obj_->gobj(), detailed_name_.c_str());
}

} // namespace Glib
