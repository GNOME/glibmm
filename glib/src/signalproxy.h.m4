// -*- c++ -*-
dnl 
dnl Glib SignalProxy Templates
dnl 
dnl  Copyright 2001 Free Software Foundation
dnl  Copyright 1999 Karl Nelson <kenelson@ece.ucdavis.edu>
dnl 
dnl  This library is free software; you can redistribute it and/or
dnl  modify it under the terms of the GNU Library General Public
dnl  License as published by the Free Software Foundation; either
dnl  version 2 of the License, or (at your option) any later version.
dnl 
dnl  This library is distributed in the hope that it will be useful,
dnl  but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl  Library General Public License for more details.
dnl 
dnl  You should have received a copy of the GNU Library General Public
dnl  License along with this library; if not, write to the Free
dnl  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
dnl 
dnl Ignore the next line
/* This is a generated file, do not edit.  Generated from __file__ */
include(template.macros.m4)
#ifndef __header__
#define __header__

extern "C"
{
  typedef void (*GCallback) (void);
  typedef struct _GObject GObject;
}

#include <sigc++/sigc++.h>


namespace Glib
{

// Forward declarations
class ObjectBase;

#ifndef DOXYGEN_SHOULD_SKIP_THIS

struct SignalProxyInfo
{
  const char* signal_name;
  GCallback   callback;
  GCallback   notify_callback;
};

#endif //DOXYGEN_SHOULD_SKIP_THIS

// This base class is used by SignalProxyNormal and SignalProxyProperty.
class SignalProxyBase
{
public:
  SignalProxyBase(Glib::ObjectBase* obj);

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  static inline SigC::SlotNode* data_to_slot(void* data)
  {
    // We store a ProxyConnection_ on the data slot of the closure.
    // But that type is not exposed, so we use the base type.
    SigC::ConnectionNode *const conn = static_cast<SigC::ConnectionNode*>(data);

    // Return 0 if the connection is blocked.
    return (!conn->blocked()) ? static_cast<SigC::SlotNode*>(conn->slot_.impl()) : 0;
  }
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

protected:
  ObjectBase* obj_;

private:
  SignalProxyBase& operator=(const SignalProxyBase&); // not implemented
};


// shared portion of a Signal
//   The proxy just serves to hold the name of the signal and the object
//   which is to be connected.  Actually, proxies are controlled by
//   the template derivatives, which serve as gatekeepers for the
//   types allowed on a particular signal.
class SignalProxyNormal : public SignalProxyBase
{
public:
  ~SignalProxyNormal();

  /// stops the current signal emmision (not in SigC++)
  void emission_stop();

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  // This callback for SignalProxy0<void>
  // is defined here to avoid code duplication.
  static void slot0_void_callback(GObject*, void* data);
#endif

protected:
  SignalProxyNormal(Glib::ObjectBase* obj, const SignalProxyInfo* info);

  SigC::ConnectionNode* connect_(const SigC::SlotBase& slot_base, bool after);
  SigC::ConnectionNode* connect_notify_(const SigC::SlotBase& slot_base, bool after);

private:
  const SignalProxyInfo* info_;

  SigC::ConnectionNode* connect_impl_(GCallback callback, const SigC::SlotBase& slot_base, bool after);

  // no copy assignment
  SignalProxyNormal& operator=(const SignalProxyNormal&);
};


dnl
dnl GLIB_SIGNAL_PROXY([P1, P2, ...],return type)
dnl
define([GLIB_SIGNAL_PROXY],[dnl
LINE(]__line__[)dnl

/**** Glib::[SignalProxy]NUM($1) ***************************************************/

/** Proxy for signals with NUM($1) arguments.
 * Use the connect() method, with SigC::slot() to connect signals to signal handlers.
 */
template <LIST(class R,ARG_CLASS($1))>
class [SignalProxy]NUM($1) : public SignalProxyNormal
{
public:
  typedef SigC::[Slot]NUM($1)<LIST(R,ARG_TYPE($1))>    SlotType;
  typedef SigC::[Slot]NUM($1)<LIST(void,ARG_TYPE($1))> VoidSlotType;

  [SignalProxy]NUM($1)(ObjectBase* obj, const SignalProxyInfo* info)
    : SignalProxyNormal(obj, info) {}

  SigC::Connection connect(const SlotType& slot, bool after = true)
    { return SigC::Connection(connect_(slot, after)); }

  SigC::Connection connect_notify(const VoidSlotType& slot, bool after = false)
    { return SigC::Connection(connect_notify_(slot, after)); }
};
])dnl

dnl Template forms of SignalProxy

GLIB_SIGNAL_PROXY(ARGS(P,0))
GLIB_SIGNAL_PROXY(ARGS(P,1))
GLIB_SIGNAL_PROXY(ARGS(P,2))
GLIB_SIGNAL_PROXY(ARGS(P,3))
GLIB_SIGNAL_PROXY(ARGS(P,4))
GLIB_SIGNAL_PROXY(ARGS(P,5))
GLIB_SIGNAL_PROXY(ARGS(P,6))

} // namespace Glib


#endif /* __header__ */

