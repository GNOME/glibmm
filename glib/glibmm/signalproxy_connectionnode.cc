// -*- c++ -*-

/* $Id$ */

/* signalproxy_connectionnode.cc
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

#include <glibmm/signalproxy_connectionnode.h>
#include <glibmm/object.h>


namespace Glib
{

SignalProxyConnectionNode::SignalProxyConnectionNode(SigC::SlotNode* slot_data, GObject* gobject)
:
  SigC::ConnectionNode(slot_data),
  connection_id_ (0),
  gsignal_disconnection_in_process_ (false),
  object_ (gobject)
{}

SignalProxyConnectionNode::~SignalProxyConnectionNode()
{
  object_ = 0;
}

// notify is a message coming up from the slot to be passed back to Gtk+
// disconnect is a message coming up from the Gtk+ to be passed down to SigC++
void SignalProxyConnectionNode::notify(bool from_child)
{
  if (object_)
  {
    GObject* o = object_;
    object_ = 0;

    gsignal_disconnection_in_process_ = true; //Prevent destroy_notify_handler() from calling notify() too.
    if(g_signal_handler_is_connected(o, connection_id_)) //During destruction, GTK+ sometimes seems to disconnect them for us, before we expect it to.  See bug #87912
      g_signal_handler_disconnect(o, connection_id_);
  }

  connection_id_ = 0;
  SigC::ConnectionNode::notify(from_child);
}

void SignalProxyConnectionNode::destroy_notify_handler(gpointer data, GClosure*)
{
  // notification from gtk+.
  SignalProxyConnectionNode* conn = static_cast<SignalProxyConnectionNode*>(data);

  // if there is no object, this call was reduntant.
  // (except for unreferencing the connection node. daniel.)
  if (conn->object_)
  {
     // the object has already lost track of this object.
     conn->object_ = 0;

     // inform sigc++ that the slot is of no further use.
     if(!conn->gsignal_disconnection_in_process_) //Prevent us from calling notify() twice. If it's in process then SignalProxyConnectionNode::notify() will do this.
       conn->notify(false); //TODO: What does false mean here?
  }

  if(!conn->gsignal_disconnection_in_process_)
    conn->unreference(); // remove the notice
}

} /* namespace Glib */

