// -*- c++ -*-

/* $Id$ */

/* signalproxy.cc
 *
 * Copyright (C) 2002 The gtkmm Development Team
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

#include <glib-object.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/object.h>
#include <glibmm/signalproxy.h>
#include <glibmm/signalproxy_connectionnode.h>


namespace Glib
{

// SignalProxyBase implementation:

SignalProxyBase::SignalProxyBase(Glib::ObjectBase* obj)
:
  obj_ (obj)
{}


// SignalProxyNormal implementation:

SignalProxyNormal::SignalProxyNormal(Glib::ObjectBase* obj, const SignalProxyInfo* info)
:
  SignalProxyBase (obj),
  info_           (info)
{}

SignalProxyNormal::~SignalProxyNormal()
{}

SigC::ConnectionNode*
SignalProxyNormal::connect_(const SigC::SlotBase& slot_base, bool after)
{
  return connect_impl_(info_->callback, slot_base, after);
}

SigC::ConnectionNode*
SignalProxyNormal::connect_notify_(const SigC::SlotBase& slot_base, bool after)
{
  return connect_impl_(info_->notify_callback, slot_base, after);
}

SigC::ConnectionNode*
SignalProxyNormal::connect_impl_(GCallback callback, const SigC::SlotBase& slot_base, bool after)
{
  // create a proxy to hold our connection info
  SignalProxyConnectionNode *const pConnectionNode =
      new SignalProxyConnectionNode(static_cast<SigC::SlotNode*>(slot_base.impl()), obj_->gobj());

  // glib will hold a reference to this object
  pConnectionNode->reference();

  // connect it to glib
  // pConnectionNode will be passed in the data argument to the callback.
  pConnectionNode->connection_id_ = g_signal_connect_data(
      obj_->gobj(), info_->signal_name, callback, pConnectionNode,
      &SignalProxyConnectionNode::destroy_notify_handler,
      static_cast<GConnectFlags>((after) ? G_CONNECT_AFTER : 0));

  return pConnectionNode;
}

void SignalProxyNormal::emission_stop()
{
  g_signal_stop_emission_by_name(obj_->gobj(), info_->signal_name);
}

// static
void SignalProxyNormal::slot0_void_callback(GObject* self, void* data)
{
  typedef SigC::Slot0<void> SlotType;

  // Do not try to call a signal on a disassociated wrapper.
  if(Glib::ObjectBase::_get_current_wrapper(self))
  {
    try
    {
      if(SigC::SlotNode *const slot = data_to_slot(data))
        (*(SlotType::Proxy)(slot->proxy_))(slot);
    }
    catch(...)
    {
      Glib::exception_handlers_invoke();
    }
  }
}

} // namespace Glib

