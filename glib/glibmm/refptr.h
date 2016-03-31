#ifndef _GLIBMM_REFPTR_H
#define _GLIBMM_REFPTR_H

/* Copyright 2002 The gtkmm Development Team
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

#include <glibmmconfig.h>
#include <glib.h>
#include <utility>

namespace Glib
{

/** RefPtr<> is a reference-counting shared smartpointer.
 *
 * Some objects in gtkmm are obtained from a shared
 * store. Consequently you cannot instantiate them yourself. Instead they
 * return a RefPtr which behaves much like an ordinary pointer in that members
 * can be reached with the usual <code>object_ptr->member</code> notation.
 * Unlike most other smart pointers, RefPtr doesn't support dereferencing
 * through <code>*object_ptr</code>.
 *
 * Reference counting means that a shared reference count is incremented each
 * time a RefPtr is copied, and decremented each time a RefPtr is destroyed,
 * for instance when it leaves its scope. When the reference count reaches
 * zero, the contained object is deleted, meaning  you don't need to remember
 * to delete the object.
 *
 * RefPtr<> can store any class that has reference() and unreference() methods,
 * and whose destructor is noexcept (the default for destructors).
 * In gtkmm, that is anything derived from Glib::ObjectBase, such as
 * Gdk::Pixmap.
 *
 * See the "Memory Management" section in the "Programming with gtkmm"
 * book for further information.
 */
template <class T_CppObject>
class RefPtr
{
private:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  /** Helper class for disallowing use of Glib::RefPtr with certain classes.
   *
   * Disallow for instance in Gtk::Widget and its subclasses.
   * Glib::RefPtr<T>::is_allowed_type::value is false if
   * T:dont_allow_use_in_glib_refptr_ is a public type, else it's true.
   * Example:
   * @code
   * using dont_allow_use_in_glib_refptr_ = int;
   * @endcode
   */
  class is_allowed_type
  {
  private:
    struct big
    {
      int memory[64];
    };

    static big check(...);

    // If X::dont_allow_use_in_glib_refptr_ is not a type, this check() overload
    // is ignored because of the SFINAE rule (Substitution Failure Is Not An Error).
    template <typename X>
    static typename X::dont_allow_use_in_glib_refptr_ check(X* obj);

  public:
    static const bool value = sizeof(check(static_cast<T_CppObject*>(nullptr))) == sizeof(big);
  };

  static_assert(is_allowed_type::value, "Glib::RefPtr must not be used with this class.");
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

public:
  /** Default constructor
   *
   * Afterwards it will be null and use of -> will cause a segmentation fault.
   */
  inline RefPtr() noexcept;

  /// Destructor - decrements reference count.
  inline ~RefPtr() noexcept;

  /// For use only by the \::create() methods.
  explicit inline RefPtr(T_CppObject* pCppObject) noexcept;

  /** Copy constructor
   *
   * This increments the shared reference count.
   */
  inline RefPtr(const RefPtr& src) noexcept;

  /** Move constructor
   */
  inline RefPtr(RefPtr&& src) noexcept;

  /** Move constructor (from different, but castable type).
   */
  template <class T_CastFrom>
  inline RefPtr(RefPtr<T_CastFrom>&& src) noexcept;

  /** Copy constructor (from different, but castable type).
   *
   * Increments the reference count.
   */
  template <class T_CastFrom>
  inline RefPtr(const RefPtr<T_CastFrom>& src) noexcept;

  /** Swap the contents of two RefPtr<>.
   * This method swaps the internal pointers to T_CppObject.  This can be
   * done safely without involving a reference/unreference cycle and is
   * therefore highly efficient.
   */
  inline void swap(RefPtr& other) noexcept;

  /// Copy from another RefPtr:
  inline RefPtr& operator=(const RefPtr& src) noexcept;

  /// Move assignment operator:
  inline RefPtr& operator=(RefPtr&& src) noexcept;

  /// Move assignment operator (from different, but castable type):
  template <class T_CastFrom>
  inline RefPtr& operator=(RefPtr<T_CastFrom>&& src) noexcept;

  /** Copy from different, but castable type).
   *
   * Increments the reference count.
   */
  template <class T_CastFrom>
  inline RefPtr& operator=(const RefPtr<T_CastFrom>& src) noexcept;

  /// Tests whether the RefPtr<> point to the same underlying instance.
  inline bool operator==(const RefPtr& src) const noexcept;

  /// See operator==().
  inline bool operator!=(const RefPtr& src) const noexcept;

  /** Dereferencing.
   *
   * Use the methods of the underlying instance like so:
   * <code>refptr->memberfun()</code>.
   */
  inline T_CppObject* operator->() const noexcept;

  /** Test whether the RefPtr<> points to any underlying instance.
   *
   * Mimics usage of ordinary pointers:
   * @code
   *   if (ptr)
   *     do_something();
   * @endcode
   */
  inline operator bool() const noexcept;

#ifndef GLIBMM_DISABLE_DEPRECATED
  /// @deprecated Use reset() instead because this leads to confusion with clear() methods on the
  /// underlying class. For instance, people use .clear() when they mean ->clear().
  inline void clear() noexcept;
#endif // GLIBMM_DISABLE_DEPRECATED

  /** Set underlying instance to nullptr, decrementing reference count of existing instance
   * appropriately.
   * @newin{2,16}
   */
  inline void reset() noexcept;

  /** Release the ownership of underlying instance.
   *
   * RefPtr's underlying instance is set to nullptr, therefore underlying object can't be accessed
   * through this RefPtr anymore.
   * @return an underlying instance.
   *
   * Most users should not use release(). It can spoil the automatic destruction
   * of the managed object. A legitimate use is if you immediately give RefPtr's
   * reference to another object.
   */
  inline T_CppObject* release() noexcept G_GNUC_WARN_UNUSED_RESULT;

  /** Dynamic cast to derived class.
   *
   * The RefPtr can't be cast with the usual notation so instead you can use
   * @code
   *   ptr_derived = RefPtr<Derived>::cast_dynamic(ptr_base);
   * @endcode
   */
  template <class T_CastFrom>
  static inline RefPtr cast_dynamic(const RefPtr<T_CastFrom>& src) noexcept;

  /** Static cast to derived class.
   *
   * Like the dynamic cast; the notation is
   * @code
   *   ptr_derived = RefPtr<Derived>::cast_static(ptr_base);
   * @endcode
   */
  template <class T_CastFrom>
  static inline RefPtr cast_static(const RefPtr<T_CastFrom>& src) noexcept;

  /** Cast to non-const.
   *
   * The RefPtr can't be cast with the usual notation so instead you can use
   * @code
   *   ptr_unconst = RefPtr<UnConstType>::cast_const(ptr_const);
   * @endcode
   */
  template <class T_CastFrom>
  static inline RefPtr cast_const(const RefPtr<T_CastFrom>& src) noexcept;

  // TODO: Maybe remove these if we replace operator bool() with operator const void* after
  // an API/ABI break, as suggested by Daniel Elstner? murrayc.
  // See bug https://bugzilla.gnome.org/show_bug.cgi?id=626858

  /** Compare based on the underlying instance address.
   *
   * This is needed in code that requires an ordering on
   * RefPtr<T_CppObject> instances, e.g. std::set<RefPtr<T_CppObject> >.
   *
   * Without these, comparing two RefPtr<T_CppObject> instances
   * is still syntactically possible, but the result is semantically
   * wrong, as p1 REL_OP p2 is interpreted as (bool)p1 REL_OP (bool)p2.
   */
  inline bool operator<(const RefPtr& src) const noexcept;

  /// See operator<().
  inline bool operator<=(const RefPtr& src) const noexcept;

  /// See operator<().
  inline bool operator>(const RefPtr& src) const noexcept;

  /// See operator<().
  inline bool operator>=(const RefPtr& src) const noexcept;

private:
  T_CppObject* pCppObject_;
};

#ifndef DOXYGEN_SHOULD_SKIP_THIS

// RefPtr<>::operator->() comes first here since it's used by other methods.
// If it would come after them it wouldn't be inlined.

template <class T_CppObject>
inline T_CppObject* RefPtr<T_CppObject>::operator->() const noexcept
{
  return pCppObject_;
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::RefPtr() noexcept : pCppObject_(nullptr)
{
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::~RefPtr() noexcept
{
  if (pCppObject_)
    pCppObject_->unreference(); // This could cause pCppObject to be deleted.
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::RefPtr(T_CppObject* pCppObject) noexcept : pCppObject_(pCppObject)
{
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::RefPtr(const RefPtr& src) noexcept : pCppObject_(src.pCppObject_)
{
  if (pCppObject_)
    pCppObject_->reference();
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::RefPtr(RefPtr&& src) noexcept : pCppObject_(src.pCppObject_)
{
  src.pCppObject_ = nullptr;
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>::RefPtr(RefPtr<T_CastFrom>&& src) noexcept : pCppObject_(src.release())
{
}

// The templated ctor allows copy construction from any object that's
// castable.  Thus, it does downcasts:
//   base_ref = derived_ref
template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>::RefPtr(const RefPtr<T_CastFrom>& src) noexcept :
  // A different RefPtr<> will not allow us access to pCppObject_.  We need
  // to add a get_underlying() for this, but that would encourage incorrect
  // use, so we use the less well-known operator->() accessor:
  pCppObject_(src.operator->())
{
  if (pCppObject_)
    pCppObject_->reference();
}

template <class T_CppObject>
inline void
RefPtr<T_CppObject>::swap(RefPtr& other) noexcept
{
  T_CppObject* const temp = pCppObject_;
  pCppObject_ = other.pCppObject_;
  other.pCppObject_ = temp;
}

template <class T_CppObject>
inline RefPtr<T_CppObject>&
RefPtr<T_CppObject>::operator=(const RefPtr& src) noexcept
{
  // In case you haven't seen the swap() technique to implement copy
  // assignment before, here's what it does:
  //
  // 1) Create a temporary RefPtr<> instance via the copy ctor, thereby
  //    increasing the reference count of the source object.
  //
  // 2) Swap the internal object pointers of *this and the temporary
  //    RefPtr<>.  After this step, *this already contains the new pointer,
  //    and the old pointer is now managed by temp.
  //
  // 3) The destructor of temp is executed, thereby unreferencing the
  //    old object pointer.
  //
  // This technique is described in Herb Sutter's "Exceptional C++", and
  // has a number of advantages over conventional approaches:
  //
  // - Code reuse by calling the copy ctor.
  // - Strong exception safety for free.
  // - Self assignment is handled implicitely.
  // - Simplicity.
  // - It just works and is hard to get wrong; i.e. you can use it without
  //   even thinking about it to implement copy assignment whereever the
  //   object data is managed indirectly via a pointer, which is very common.

  RefPtr<T_CppObject> temp(src);
  this->swap(temp);
  return *this;
}

template <class T_CppObject>
inline RefPtr<T_CppObject>&
RefPtr<T_CppObject>::operator=(RefPtr&& src) noexcept
{
  RefPtr<T_CppObject> temp(std::move(src));
  this->swap(temp);
  src.pCppObject_ = nullptr;

  return *this;
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>&
RefPtr<T_CppObject>::operator=(RefPtr<T_CastFrom>&& src) noexcept
{
  if (pCppObject_)
    pCppObject_->unreference();
  pCppObject_ = src.release();

  return *this;
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>&
RefPtr<T_CppObject>::operator=(const RefPtr<T_CastFrom>& src) noexcept
{
  RefPtr<T_CppObject> temp(src);
  this->swap(temp);
  return *this;
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator==(const RefPtr& src) const noexcept
{
  return (pCppObject_ == src.pCppObject_);
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator!=(const RefPtr& src) const noexcept
{
  return (pCppObject_ != src.pCppObject_);
}

template <class T_CppObject>
inline RefPtr<T_CppObject>::operator bool() const noexcept
{
  return (pCppObject_ != nullptr);
}

#ifndef GLIBMM_DISABLE_DEPRECATED
template <class T_CppObject>
inline void
RefPtr<T_CppObject>::clear() noexcept
{
  reset();
}
#endif // GLIBMM_DISABLE_DEPRECATED

template <class T_CppObject>
inline void
RefPtr<T_CppObject>::reset() noexcept
{
  RefPtr<T_CppObject> temp; // swap with an empty RefPtr<> to clear *this
  this->swap(temp);
}

template <class T_CppObject>
inline T_CppObject*
RefPtr<T_CppObject>::release() noexcept
{
  T_CppObject* tmp = pCppObject_;
  pCppObject_ = nullptr;
  return tmp;
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>
RefPtr<T_CppObject>::cast_dynamic(const RefPtr<T_CastFrom>& src) noexcept
{
  T_CppObject* const pCppObject = dynamic_cast<T_CppObject*>(src.operator->());

  if (pCppObject)
    pCppObject->reference();

  return RefPtr<T_CppObject>(pCppObject);
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>
RefPtr<T_CppObject>::cast_static(const RefPtr<T_CastFrom>& src) noexcept
{
  T_CppObject* const pCppObject = static_cast<T_CppObject*>(src.operator->());

  if (pCppObject)
    pCppObject->reference();

  return RefPtr<T_CppObject>(pCppObject);
}

template <class T_CppObject>
template <class T_CastFrom>
inline RefPtr<T_CppObject>
RefPtr<T_CppObject>::cast_const(const RefPtr<T_CastFrom>& src) noexcept
{
  T_CppObject* const pCppObject = const_cast<T_CppObject*>(src.operator->());

  if (pCppObject)
    pCppObject->reference();

  return RefPtr<T_CppObject>(pCppObject);
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator<(const RefPtr& src) const noexcept
{
  return (pCppObject_ < src.pCppObject_);
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator<=(const RefPtr& src) const noexcept
{
  return (pCppObject_ <= src.pCppObject_);
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator>(const RefPtr& src) const noexcept
{
  return (pCppObject_ > src.pCppObject_);
}

template <class T_CppObject>
inline bool
RefPtr<T_CppObject>::operator>=(const RefPtr& src) const noexcept
{
  return (pCppObject_ >= src.pCppObject_);
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** @relates Glib::RefPtr */
template <class T_CppObject>
inline void
swap(RefPtr<T_CppObject>& lhs, RefPtr<T_CppObject>& rhs) noexcept
{
  lhs.swap(rhs);
}

} // namespace Glib

#endif /* _GLIBMM_REFPTR_H */
