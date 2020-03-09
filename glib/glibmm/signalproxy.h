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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
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
class GLIBMM_API ObjectBase;

#ifndef DOXYGEN_SHOULD_SKIP_THIS

struct SignalProxyInfo
{
  const char* signal_name;
  GCallback callback;
  GCallback notify_callback;
};

#endif // DOXYGEN_SHOULD_SKIP_THIS

// This base class is used by SignalProxyNormal, SignalProxyDetailedBase and SignalProxyProperty.
class GLIBMM_API SignalProxyBase
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
  SignalProxyBase& operator=(const SignalProxyBase&) = delete;
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
 * For signals with a detailed name (signal_name::detail_name) see SignalProxyDetailedBase.
 */
class GLIBMM_API SignalProxyNormal : public SignalProxyBase
{
public:
  ~SignalProxyNormal() noexcept;

  /// Stops the current signal emission (not in libsigc++)
  void emission_stop();

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  // This callback for SignalProxy<void()>
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

  /** Connects a signal handler to a signal.
   * This is called by connect() and connect_notify() in derived SignalProxy classes.
   *
   * @param notify Whether this method is called by connect_notify() or by connect().
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   *
   * @newin{2,58}
   */
  sigc::slot_base& connect_impl_(bool notify, const sigc::slot_base& slot, bool after);

  /** Connects a signal handler to a signal.
   * @see connect_impl_(bool notify, const sigc::slot_base& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::slot_base& connect_impl_(bool notify, sigc::slot_base&& slot, bool after);

private:
  const SignalProxyInfo* info_;

  // no copy assignment
  SignalProxyNormal& operator=(const SignalProxyNormal&) = delete;
};

/**** Glib::SignalProxy ***************************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <class R, class... T>
class SignalProxy;
#endif // DOXYGEN_SHOULD_SKIP_THIS

/** Proxy for signals with any number of arguments.
 * Use the connect() or connect_notify() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 *
 * This is the primary template. There is a specialization for signal handlers
 * that return @c void. The specialization has no %connect_notify() method, and
 * the @a after parameter in its %connect() method has a default value.
 */
template <class R, class... T>
class SignalProxy<R(T...)> : public SignalProxyNormal
{
public:
  using SlotType = sigc::slot<R(T...)>;
  using VoidSlotType = sigc::slot<void(T...)>;

  SignalProxy(ObjectBase* obj, const SignalProxyInfo* info) : SignalProxyNormal(obj, info) {}

  /** Connects a signal handler to a signal.
   *
   * For instance, connect(sigc::mem_fun(*this, &TheClass::on_something), false);
   *
   * For some signal handlers that return a value, it can make a big difference
   * whether you connect before or after the default signal handler.
   * Examples:
   * - Gio::Application::signal_command_line() calls only one signal handler.
   *   A handler connected after the default handler will never be called.
   * - X event signals, such as Gtk::Widget::signal_button_press_event(), stop
   *   calling signal handlers as soon as a called handler returns <tt>true</tt>.
   *   If the default handler returns <tt>true</tt>, a handler connected after it
   *   will not be called.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
   */
  sigc::connection connect(const SlotType& slot, bool after)
  {
    return sigc::connection(connect_impl_(false, slot, after));
  }

  /** Connects a signal handler to a signal.
   * @see connect(const SlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect(SlotType&& slot, bool after)
  {
    return sigc::connection(connect_impl_(false, std::move(slot), after));
  }

  /** Connects a signal handler without a return value to a signal.
   * By default, the signal handler will be called before the default signal handler.
   *
   * For instance, connect_notify( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * If the signal requires signal handlers with a return value of type T,
   * %connect_notify() binds <tt>return T()</tt> to the connected signal handler.
   * For instance, if the return type is @c bool, the following two calls are equivalent.
   * @code
   * connect_notify(sigc::mem_fun(*this, &TheClass::on_something));
   * connect(sigc::bind_return<bool>(sigc::mem_fun(*this, &TheClass::on_something), false), false);
   * @endcode
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
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

/** Proxy for signals with any number of arguments.
 * Use the connect() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 *
 * This is a specialization for signal handlers that return @c void.
 */
template <class... T>
class SignalProxy<void(T...)> : public SignalProxyNormal
{
public:
  using SlotType = sigc::slot<void(T...)>;

  SignalProxy(ObjectBase* obj, const SignalProxyInfo* info) : SignalProxyNormal(obj, info) {}

  /** Connects a signal handler to a signal.
   *
   * For instance, connect( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * By default, the signal handler will be called after the default signal handler.
   * This is usually fine for signal handlers that don't return a value.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
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
class GLIBMM_API SignalProxyDetailedBase : public SignalProxyBase
{
public:
  ~SignalProxyDetailedBase() noexcept;

  /// Stops the current signal emission (not in libsigc++)
  void emission_stop();

protected:
  /** Creates a proxy for a signal that can be emitted by @a obj.
   * @param obj The object that can emit the signal.
   * @param info Information about the signal, including its name
   *             and the C callbacks that should be called by glib.
   * @param detail_name The detail name, if any.
   */
  SignalProxyDetailedBase(
    Glib::ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name);

  /** Connects a signal handler to a signal.
   * This is called by connect() and connect_notify() in derived SignalProxyDetailed classes.
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
  SignalProxyDetailedBase& operator=(const SignalProxyDetailedBase&) = delete;
};

/**** Glib::SignalProxyDetailed **********************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <class R, class... T>
class SignalProxyDetailed;
#endif // DOXYGEN_SHOULD_SKIP_THIS

/** Proxy for signals with any number of arguments and possibly a detailed name.
 * Use the connect() or connect_notify() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 *
 * This is the primary template. There is a specialization for signal handlers
 * that return @c void. The specialization has no %connect_notify() method, and
 * the @a after parameter in its %connect() method has a default value.
 */
template <class R, class... T>
class SignalProxyDetailed<R(T...)> : public SignalProxyDetailedBase
{
public:
  using SlotType = sigc::slot<R(T...)>;
  using VoidSlotType = sigc::slot<void(T...)>;

  SignalProxyDetailed(
    ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name)
  : SignalProxyDetailedBase(obj, info, detail_name)
  {
  }

  /** Connects a signal handler to a signal.
   *
   * For instance, connect(sigc::mem_fun(*this, &TheClass::on_something), false);
   *
   * For some signal handlers that return a value, it can make a big difference
   * whether you connect before or after the default signal handler.
   * Examples:
   * - Gio::Application::signal_command_line() calls only one signal handler.
   *   A handler connected after the default handler will never be called.
   * - X event signals, such as Gtk::Widget::signal_button_press_event(), stop
   *   calling signal handlers as soon as a called handler returns <tt>true</tt>.
   *   If the default handler returns <tt>true</tt>, a handler connected after it
   *   will not be called.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
   */
  sigc::connection connect(const SlotType& slot, bool after)
  {
    return sigc::connection(connect_impl_(false, slot, after));
  }

  /** Connects a signal handler to a signal.
   * @see connect(const SlotType& slot, bool after).
   *
   * @newin{2,48}
   */
  sigc::connection connect(SlotType&& slot, bool after)
  {
    return sigc::connection(connect_impl_(false, std::move(slot), after));
  }

  /** Connects a signal handler without a return value to a signal.
   * By default, the signal handler will be called before the default signal handler.
   *
   * For instance, connect_notify( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * If the signal requires signal handlers with a return value of type T,
   * %connect_notify() binds <tt>return T()</tt> to the connected signal handler.
   * For instance, if the return type is @c bool, the following two calls are equivalent.
   * @code
   * connect_notify(sigc::mem_fun(*this, &TheClass::on_something));
   * connect(sigc::bind_return<bool>(sigc::mem_fun(*this, &TheClass::on_something), false), false);
   * @endcode
   *
   * @param slot The signal handler, which should have a @c void return type,
   *        usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
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

/** Proxy for signals with any number of arguments and possibly a detailed name.
 * Use the connect() method, with sigc::mem_fun() or sigc::ptr_fun()
 * to connect signal handlers to signals.
 *
 * This is a specialization for signal handlers that return @c void.
 */
template <class... T>
class SignalProxyDetailed<void(T...)> : public SignalProxyDetailedBase
{
public:
  using SlotType = sigc::slot<void(T...)>;

  SignalProxyDetailed(
    ObjectBase* obj, const SignalProxyInfo* info, const Glib::ustring& detail_name)
  : SignalProxyDetailedBase(obj, info, detail_name)
  {
  }

  /** Connects a signal handler to a signal.
   *
   * For instance, connect( sigc::mem_fun(*this, &TheClass::on_something) );
   *
   * By default, the signal handler will be called after the default signal handler.
   * This is usually fine for signal handlers that don't return a value.
   *
   * @param slot The signal handler, usually created with sigc::mem_fun() or sigc::ptr_fun().
   * @param after Whether this signal handler should be called before or after the default signal
   * handler.
   * @return A sigc::connection.
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
};

} // namespace Glib

#endif /* _GLIBMM_SIGNALPROXY_H */
