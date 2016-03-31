#ifndef _GLIBMM_SIGNALPROXY_H
#define _GLIBMM_SIGNALPROXY_H

/* signalproxy.h
 *
 * Copyright (C) 2015 The gtkmm Development Team
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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

extern "C" {
typedef void (*GCallback)(void);
typedef struct _GObject GObject;
}

#include <sigc++/sigc++.h>
#include <glibmm/signalproxy_connectionnode.h>
#include <glibmm/ustring.h>
#include <utility> // std::move()

namespace Glib
{

// Forward declarations
class ObjectBase;

#ifndef DOXYGEN_SHOULD_SKIP_THIS

struct SignalProxyInfo
{
  const char* signal_name;
  GCallback callback;
  GCallback notify_callback;
};

#endif // DOXYGEN_SHOULD_SKIP_THIS

// This base class is used by SignalProxyNormal, SignalProxyDetailed and SignalProxyProperty.
class SignalProxyBase
{
public:
  SignalProxyBase(Glib::ObjectBase* obj);

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  static inline sigc::slot_base* data_to_slot(void* data)
  {
    const auto pConnectionNode = static_cast<SignalProxyConnectionNode*>(data);

    // Return null pointer if the connection is blocked.
    return (!pConnectionNode->slot_.blocked()) ? &pConnectionNode->slot_ : nullptr;
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
  // This callback for SignalProxy<void>
  // is defined here to avoid code duplication.
  static void slot0_void_callback(GObject*, void* data);
#endif

protected:
  /** Creates a proxy for a signal that can be emitted by @a obj.
   * @param obj The object that can emit the signal.
   * @param info Information about the signal, including its name, and the C callbacks that should
   * be called by glib.
   */
  SignalProxyNormal(Glib::ObjectBase* obj, const SignalProxyInfo* info);

  /** Connects a generic signal handler to a signal.
   * This is called by connect() in derived SignalProxy classes.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::slot_base& connect_(const sigc::slot_base& slot, bool after);

  /** Connects a signal handler without a return value to a signal.
   * This is called by connect_notify() in derived SignalProxy classes.
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::slot_base& connect_notify_(const sigc::slot_base& slot, bool after);

  /** Connects a signal handler to a signal.
   * @see connect_(const sigc::slot_base& slot, bool after) and
   * connect_notify_(const sigc::slot_base& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::slot_base& connect_impl_(bool notify, sigc::slot_base&& slot, bool after);

private:
  const SignalProxyInfo* info_;

  // TODO: We could maybe replace both connect_() and connect_notify_() with this in future, because
  // they don't do anything extra.
  /** This is called by connect_() and connect_notify_().
   */
  sigc::slot_base& connect_impl_(GCallback callback, const sigc::slot_base& slot, bool after);

  // no copy assignment
  SignalProxyNormal& operator=(const SignalProxyNormal&);
};

/**** Glib::SignalProxy ***************************************************/

/** Proxy for signals with any number of arguments.
 * Use the connect() or connect_notify() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 */
template <class R, class... T>
class SignalProxy : public SignalProxyNormal
{
public:
  using SlotType = sigc::slot<R, T...>;
  using VoidSlotType = sigc::slot<void, T...>;

  SignalProxy(ObjectBase* obj, const SignalProxyInfo* info) : SignalProxyNormal(obj, info) {}

  /** Connects a signal handler to a signal.
   *
   * For instance, connect( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::connection connect(const SlotType& slot, bool after = true)
  {
    return sigc::connection(connect_(slot, after));
  }

  /** Connects a signal handler to a signal.
   * @see connect(const SlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect(SlotType&& slot, bool after = true)
  {
    return sigc::connection(connect_impl_(false, std::move(slot), after));
  }

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
   * connect( sigc::bind_return<bool>(sigc::mem_fun(*this, &TheClass::on_something), false), false
   * );
   * @endcode
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::connection connect_notify(const VoidSlotType& slot, bool after = false)
  {
    return sigc::connection(connect_notify_(slot, after));
  }

  /** Connects a signal handler without a return value to a signal.
   * @see connect_notify(const VoidSlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect_notify(VoidSlotType&& slot, bool after = false)
  {
    return sigc::connection(connect_impl_(true, std::move(slot), after));
  }
};

/* Templates below has been added to avoid API break, and should not be
 * used in a newly created code. SignalProxy class should be used instead
 * of SignalProxy# class.
 */
template <typename R>
using SignalProxy0 = SignalProxy<R>;
template <typename R, typename T1>
using SignalProxy1 = SignalProxy<R, T1>;
template <typename R, typename T1, typename T2>
using SignalProxy2 = SignalProxy<R, T1, T2>;
template <typename R, typename T1, typename T2, typename T3>
using SignalProxy3 = SignalProxy<R, T1, T2, T3>;
template <typename R, typename T1, typename T2, typename T3, typename T4>
using SignalProxy4 = SignalProxy<R, T1, T2, T3, T4>;
template <typename R, typename T1, typename T2, typename T3, typename T4, typename T5>
using SignalProxy5 = SignalProxy<R, T1, T2, T3, T4, T5>;
template <typename R, typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
using SignalProxy6 = SignalProxy<R, T1, T2, T3, T4, T5, T6>;

// TODO: When we can break ABI, consider renaming
// SignalProxyDetailed => SignalProxyDetailedBase
// SignalProxyDetailedAnyType => SignalProxyDetailed

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
  SignalProxyDetailed(
    Glib::ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name);

  /** Connects a signal handler to a signal.
   * This is called by connect() and connect_notify() in derived SignalProxyDetailedAnyType classes.
   *
   * @param notify Whether this method is called by connect_notify() or by connect().
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::slot_base& connect_impl_(bool notify, const sigc::slot_base& slot, bool after);

  /** Connects a signal handler to a signal.
   * @see connect_impl_(bool notify, const sigc::slot_base& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::slot_base& connect_impl_(bool notify, sigc::slot_base&& slot, bool after);

private:
  const SignalProxyInfo* info_; // Pointer to statically allocated structure.
  const Glib::ustring detailed_name_; // signal_name[::detail_name]

  // no copy assignment
  SignalProxyDetailed& operator=(const SignalProxyDetailed&);
};

/** Proxy for signals with any number of arguments and possibly a detailed name.
 * Use the connect() or connect_notify() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 */
template <class R, class... T>
class SignalProxyDetailedAnyType : public SignalProxyDetailed
{
public:
  using SlotType = sigc::slot<R, T...>;
  using VoidSlotType = sigc::slot<void, T...>;

  SignalProxyDetailedAnyType(
    ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name)
  : SignalProxyDetailed(obj, info, detail_name)
  {
  }

  /** Connects a signal handler to a signal.
   *
   * For instance, connect( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::connection connect(const SlotType& slot, bool after = true)
  {
    return sigc::connection(connect_impl_(false, slot, after));
  }

  /** Connects a signal handler to a signal.
   * @see connect(const SlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect(SlotType&& slot, bool after = true)
  {
    return sigc::connection(connect_impl_(false, std::move(slot), after));
  }

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
   * connect( sigc::bind_return<bool>(sigc::mem_fun(*this, &TheClass::on_something), false), false
   * );
   * @endcode
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   */
  sigc::connection connect_notify(const VoidSlotType& slot, bool after = false)
  {
    return sigc::connection(connect_impl_(true, slot, after));
  }

  /** Connects a signal handler without a return value to a signal.
   * @see connect_notify(const VoidSlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect_notify(VoidSlotType&& slot, bool after = false)
  {
    return sigc::connection(connect_impl_(true, std::move(slot), after));
  }
};

/* Templates below has been added to avoid API break, and should not be
 * used in a newly created code. SignalProxyDetailedAnyType class should be
 * used instead of SignalProxyDetailed# class.
 */
template <typename R>
using SignalProxyDetailed0 = SignalProxyDetailedAnyType<R>;
template <typename R, typename T1>
using SignalProxyDetailed1 = SignalProxyDetailedAnyType<R, T1>;
template <typename R, typename T1, typename T2>
using SignalProxyDetailed2 = SignalProxyDetailedAnyType<R, T1, T2>;
template <typename R, typename T1, typename T2, typename T3>
using SignalProxyDetailed3 = SignalProxyDetailedAnyType<R, T1, T2, T3>;
template <typename R, typename T1, typename T2, typename T3, typename T4>
using SignalProxyDetailed4 = SignalProxyDetailedAnyType<R, T1, T2, T3, T4>;
template <typename R, typename T1, typename T2, typename T3, typename T4, typename T5>
using SignalProxyDetailed5 = SignalProxyDetailedAnyType<R, T1, T2, T3, T4, T5>;
template <typename R, typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
using SignalProxyDetailed6 = SignalProxyDetailedAnyType<R, T1, T2, T3, T4, T5, T6>;

} // namespace Glib

#endif /* _GLIBMM_SIGNALPROXY_H */
