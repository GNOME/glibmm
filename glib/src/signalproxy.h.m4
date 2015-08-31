dnl Glib SignalProxy Templates
dnl 
dnl  Copyright 2001 Free Software Foundation
dnl  Copyright 1999 Karl Nelson <kenelson@ece.ucdavis.edu>
dnl 
dnl  This library is free software; you can redistribute it and/or
dnl  modify it under the terms of the GNU Lesser General Public
dnl  License as published by the Free Software Foundation; either
dnl  version 2.1 of the License, or (at your option) any later version.
dnl 
dnl  This library is distributed in the hope that it will be useful,
dnl  but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl  Lesser General Public License for more details.
dnl 
dnl  You should have received a copy of the GNU Lesser General Public
dnl  License along with this library; if not, write to the Free
dnl  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
dnl 
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
#include <glibmm/signalproxy_connectionnode.h>
#include <glibmm/ustring.h>

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

// This base class is used by SignalProxyNormal, SignalProxyDetailed and SignalProxyProperty.
class SignalProxyBase
{
public:
  SignalProxyBase(Glib::ObjectBase* obj);

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  static inline sigc::slot_base* data_to_slot(void* data)
  {
    const auto pConnectionNode = static_cast<SignalProxyConnectionNode*>(data);

    // Return 0 if the connection is blocked.
    return (!pConnectionNode->slot_.blocked()) ? &pConnectionNode->slot_ : 0;
  }
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

protected:
  ObjectBase* obj_;

private:
  SignalProxyBase& operator=(const SignalProxyBase&); // not implemented
};


// Shared portion of a Signal without detail
/** The SignalProxy provides an API similar to sigc::signal that can be used to
 * connect sigc::slots to glib signals.
 *
 * This holds the name of the glib signal and the object
 * which might emit it. Actually, proxies are controlled by
 * the template derivatives, which serve as gatekeepers for the
 * types allowed on a particular signal.
 *
 * For signals with a detailed name (signal_name::detail_name) see SignalProxyDetailed.
 */
class SignalProxyNormal : public SignalProxyBase
{
public:
  ~SignalProxyNormal() noexcept;

  /// Stops the current signal emission (not in libsigc++)
  void emission_stop();

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  // This callback for SignalProxy0<void>
  // is defined here to avoid code duplication.
  static void slot0_void_callback(GObject*, void* data);
#endif

protected:

  /** Creates a proxy for a signal that can be emitted by @a obj.
   * @param obj The object that can emit the signal.
   * @param info Information about the signal, including its name, and the C callbacks that should be called by glib.
   */
  SignalProxyNormal(Glib::ObjectBase* obj, const SignalProxyInfo* info);

  /** Connects a generic signal handler to a signal.
   * This is called by connect() in derived SignalProxy classes.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal handler.
   */
  sigc::slot_base& connect_(const sigc::slot_base& slot, bool after);

  /** Connects a signal handler without a return value to a signal.
   * This is called by connect_notify() in derived SignalProxy classes.
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal handler.
   */
  sigc::slot_base& connect_notify_(const sigc::slot_base& slot, bool after);

private:
  const SignalProxyInfo* info_;

  //TODO: We could maybe replace both connect_() and connect_notify_() with this in future, because they don't do anything extra.
  /** This is called by connect_() and connect_notify_().
   */
  sigc::slot_base& connect_impl_(GCallback callback, const sigc::slot_base& slot, bool after);

  // no copy assignment
  SignalProxyNormal& operator=(const SignalProxyNormal&);
};

// Shared portion of a Signal with detail
/** The SignalProxy provides an API similar to sigc::signal that can be used to
 * connect sigc::slots to glib signals.
 *
 * This holds the name of the glib signal, including the detail name if any,
 * and the object which might emit it. Actually, proxies are controlled by
 * the template derivatives, which serve as gatekeepers for the
 * types allowed on a particular signal.
 */
class SignalProxyDetailed : public SignalProxyBase
{
public:
  ~SignalProxyDetailed() noexcept;

  /// Stops the current signal emission (not in libsigc++)
  void emission_stop();

protected:

  /** Creates a proxy for a signal that can be emitted by @a obj.
   * @param obj The object that can emit the signal.
   * @param info Information about the signal, including its name
   *             and the C callbacks that should be called by glib.
   * @param detail_name The detail name, if any.
   */
  SignalProxyDetailed(Glib::ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name);

  /** Connects a signal handler to a signal.
   * This is called by connect() and connect_notify() in derived SignalProxy classes.
   *
   * @param notify Whether this method is called by connect_notify() or by connect().
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal handler.
   */
  sigc::slot_base& connect_impl_(bool notify, const sigc::slot_base& slot, bool after);

private:
  const SignalProxyInfo* info_; // Pointer to statically allocated structure.
  const Glib::ustring detailed_name_; // signal_name[[::detail_name]]dnl one pair of [] in the generated .h file


  // no copy assignment
  SignalProxyDetailed& operator=(const SignalProxyDetailed&);
};

dnl
dnl GLIB_SIGNAL_PROXY([P1, P2, ...], Normal or Detailed)
dnl
define([GLIB_SIGNAL_PROXY],[dnl
LINE(]__line__[)dnl

/**** Glib::[SignalProxy]ifelse($2,Normal,,$2)[]NUM($1) ***************************************************/

/** Proxy for signals with NUM($1) arguments[]ifelse($2,Normal,,[ and possibly a detailed name]).
 * Use the connect() or connect_notify() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 */
template <LIST(class R,ARG_CLASS($1))>
class [SignalProxy]ifelse($2,Normal,,$2)[]NUM($1) : public SignalProxy$2
{
public:
  typedef sigc::slot<LIST(R,ARG_TYPE($1))>    SlotType;
  typedef sigc::slot<LIST(void,ARG_TYPE($1))> VoidSlotType;

ifelse($2,Normal,dnl
  [SignalProxy]NUM($1)[(ObjectBase* obj, const SignalProxyInfo* info)
    : SignalProxyNormal(obj, info) {}
],dnl Detailed
  [SignalProxyDetailed]NUM($1)[(ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name)
    : SignalProxyDetailed(obj, info, detail_name) {}
])dnl

  /** Connects a signal handler to a signal.
   *
   * For instance, connect( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal handler.
   */
  sigc::connection connect(const SlotType& slot, bool after = true)
    { return sigc::connection(ifelse($2,Normal,[connect_(slot, after)],[connect_impl_(false, slot, after)])); }

  /** Connects a signal handler without a return value to a signal.
   * By default, the signal handler will be called before the default signal handler.
   *
   * For instance, connect_notify( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * If the signal requires signal handlers with a @c void return type,
   * the only difference between connect() and connect_notify() is the default
   * value of @a after.
   *
   * If the signal requires signal handlers with a return value of type T,
   * connect_notify() binds <tt>return T()</tt> to the connected signal handler.
   * For instance, if the return type is @c bool, the following two calls are equivalent.
   * @code
   * connect_notify( sigc::mem_fun(*this, &TheClass::on_something) );
   * connect( sigc::bind_return<bool>(sigc::mem_fun(*this, &TheClass::on_something), false), false );
   * @endcode
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal handler.
   */
  sigc::connection connect_notify(const VoidSlotType& slot, bool after = false)
    { return sigc::connection(ifelse($2,Normal,[connect_notify_(slot, after)],[connect_impl_(true, slot, after)])); }
};
])dnl
dnl
dnl Template forms of SignalProxy
dnl
GLIB_SIGNAL_PROXY(ARGS(P,0), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,1), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,2), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,3), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,4), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,5), Normal)
GLIB_SIGNAL_PROXY(ARGS(P,6), Normal)
dnl
GLIB_SIGNAL_PROXY(ARGS(P,0), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,1), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,2), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,3), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,4), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,5), Detailed)
GLIB_SIGNAL_PROXY(ARGS(P,6), Detailed)
dnl
} // namespace Glib

#endif /* __header__ */

