#ifndef _GLIBMM_WEAKREF_H
#define _GLIBMM_WEAKREF_H

/* Copyright (C) 2015 The glibmm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <glib-object.h>
#include <glibmm/refptr.h>
#include <glibmm/objectbase.h>
#include <type_traits> // std::is_base_of<>
#include <utility> // std::swap<>, std::forward<>

namespace Glib
{

/** WeakRef<> is a weak reference smartpointer.
 *
 * WeakRef can store a pointer to any class that is derived from Glib::ObjectBase,
 * and whose reference() method is noexcept.
 * In glibmm and gtkmm, that is anything derived from Glib::ObjectBase.
 *
 * Unlike a RefPtr, a WeakRef does not contribute to the reference counting of
 * the underlying object.
 *
 * @newin{2,46}
 */
template <typename T_CppObject>
class WeakRef
{
  static_assert(std::is_base_of<Glib::ObjectBase, T_CppObject>::value,
    "Glib::WeakRef can be used only for classes derived from Glib::ObjectBase.");

public:
  /** Default constructor.
   *
   * Create an empty weak reference.
   */
  inline WeakRef() noexcept;

  /// Copy constructor.
  inline WeakRef(const WeakRef& src) noexcept;

  /// Move constructor.
  inline WeakRef(WeakRef&& src) noexcept;

  /// Copy constructor from different, but castable type.
  template <typename T_CastFrom>
  inline WeakRef(const WeakRef<T_CastFrom>& src) noexcept;

  /// Move constructor from different, but castable type.
  template <typename T_CastFrom>
  inline WeakRef(WeakRef<T_CastFrom>&& src) noexcept;

  /** Constructor from a RefPtr of the same or a castable type.
   *
   * Create a weak reference from a RefPtr of the same or a castable type.
   * If the RefPtr references nothing, an empty weak reference will be constructed.
   */
  template <typename T_CastFrom>
  inline WeakRef(const RefPtr<T_CastFrom>& src) noexcept;

  /// Destructor.
  inline ~WeakRef() noexcept;

  /// Swap the contents of two WeakRef<>.
  inline void swap(WeakRef& other) noexcept;

  /// Copy assignment operator.
  inline WeakRef& operator=(const WeakRef& src) noexcept;

  /// Move assignment operator.
  inline WeakRef& operator=(WeakRef&& src) noexcept;

  /// Copy assignment from different, but castable type.
  template <typename T_CastFrom>
  inline WeakRef& operator=(const WeakRef<T_CastFrom>& src) noexcept;

  /// Move assignment from different, but castable type.
  template <typename T_CastFrom>
  inline WeakRef& operator=(WeakRef<T_CastFrom>&& src) noexcept;

  /// Assignment from a RefPtr of the same or a castable type.
  template <typename T_CastFrom>
  inline WeakRef& operator=(const RefPtr<T_CastFrom>& src) noexcept;

  /** Test whether the WeakRef<> points to any underlying instance.
   *
   * Mimics usage of ordinary pointers:
   * @code
   * if (ptr)
   *   do_something();
   * @endcode
   *
   * In a multi-threaded program a <tt>true</tt> return value can become
   * obsolete at any time, even before the caller has a chance to test it,
   * because the underlying instance may lose its last reference in another
   * thread. Use get() if this is not acceptable.
   */
  inline explicit operator bool() const noexcept;

  /** Create a strong reference to the underlying object.
   *
   * This is a thread-safe way to acquire a strong reference to the underlying
   * object. If the WeakRef is empty, the returned RefPtr will reference nothing.
   */
  inline RefPtr<T_CppObject> get() const noexcept;

  /// Make this WeakRef empty.
  inline void reset() noexcept;

  /** Dynamic cast to derived class.
   *
   * The WeakRef can't be cast with the usual notation so instead you can use
   * @code
   * ptr_derived = Glib::WeakRef<Derived>::cast_dynamic(ptr_base);
   * @endcode
   */
  template <typename T_CastFrom>
  static inline WeakRef cast_dynamic(const WeakRef<T_CastFrom>& src) noexcept;

  /** Static cast to derived class.
   *
   * The WeakRef can't be cast with the usual notation so instead you can use
   * @code
   * ptr_derived = Glib::WeakRef<Derived>::cast_static(ptr_base);
   * @endcode
   */
  template <typename T_CastFrom>
  static inline WeakRef cast_static(const WeakRef<T_CastFrom>& src) noexcept;

  /** Cast to non-const.
   *
   * The WeakRef can't be cast with the usual notation so instead you can use
   * @code
   * ptr_nonconst = Glib::WeakRef<NonConstType>::cast_const(ptr_const);
   * @endcode
   */
  template <typename T_CastFrom>
  static inline WeakRef cast_const(const WeakRef<T_CastFrom>& src) noexcept;

private:
  // Let all instantiations of WeakRef access private data.
  template <typename T_CastFrom>
  friend class WeakRef;

  // If pCppObject != nullptr && gobject == nullptr,
  // then the caller holds a strong reference.
  void set(T_CppObject* pCppObject, GWeakRef* gobject) noexcept;

  // WeakRef owns *gobject_, but it does not own *pCppObject_.
  // Invariant: (!pCppObject_ || gobject_),
  // i.e. if pCppObject_ != nullptr then also gobject_ != nullptr.
  T_CppObject* pCppObject_;
  GWeakRef* gobject_;

  // Some methods would be simpler if gobject_ were a GWeakRef instead of
  // a GWeakRef*, but then the move constructor and the move assignment
  // operation would not be efficient.

}; // end class WeakRef

#ifndef DOXYGEN_SHOULD_SKIP_THIS

template <typename T_CppObject>
WeakRef<T_CppObject>::WeakRef() noexcept : pCppObject_(nullptr), gobject_(nullptr)
{
}

template <typename T_CppObject>
WeakRef<T_CppObject>::WeakRef(const WeakRef& src) noexcept : pCppObject_(src.pCppObject_),
                                                             gobject_(nullptr)
{
  if (pCppObject_)
  {
    // We must own a strong reference to the underlying GObject while
    // calling g_weak_ref_init().
    gpointer ptr = g_weak_ref_get(src.gobject_);
    if (ptr)
    {
      gobject_ = new GWeakRef;
      g_weak_ref_init(gobject_, pCppObject_->gobj());
      g_object_unref(ptr);
    }
    else
      pCppObject_ = nullptr;
  }
}

template <typename T_CppObject>
WeakRef<T_CppObject>::WeakRef(WeakRef&& src) noexcept : pCppObject_(src.pCppObject_),
                                                        gobject_(src.gobject_)
{
  src.pCppObject_ = nullptr;
  src.gobject_ = nullptr;
}

// The templated ctor allows copy construction from any object that's
// castable. Thus, it does downcasts:
//   base_ref = derived_ref
template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>::WeakRef(const WeakRef<T_CastFrom>& src) noexcept
  : pCppObject_(src.pCppObject_),
    gobject_(nullptr)
{
  if (pCppObject_)
  {
    // We must own a strong reference to the underlying GObject while
    // calling g_weak_ref_init().
    gpointer ptr = g_weak_ref_get(src.gobject_);
    if (ptr)
    {
      gobject_ = new GWeakRef;
      g_weak_ref_init(gobject_, pCppObject_->gobj());
      g_object_unref(ptr);
    }
    else
      pCppObject_ = nullptr;
  }
}

// The templated ctor allows move construction from any object that's
// castable. Thus, it does downcasts:
//   base_ref = std::move(derived_ref)
template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>::WeakRef(WeakRef<T_CastFrom>&& src) noexcept : pCppObject_(src.pCppObject_),
                                                                    gobject_(src.gobject_)
{
  src.pCppObject_ = nullptr;
  src.gobject_ = nullptr;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>::WeakRef(const RefPtr<T_CastFrom>& src) noexcept
  : pCppObject_(src.operator->()),
    gobject_(nullptr)
{
  if (pCppObject_)
  {
    gobject_ = new GWeakRef;
    g_weak_ref_init(gobject_, pCppObject_->gobj());
  }
}

template <typename T_CppObject>
WeakRef<T_CppObject>::~WeakRef() noexcept
{
  if (gobject_)
  {
    g_weak_ref_clear(gobject_);
    delete gobject_;
  }
}

template <class T_CppObject>
void
WeakRef<T_CppObject>::swap(WeakRef& other) noexcept
{
  std::swap(pCppObject_, other.pCppObject_);
  std::swap(gobject_, other.gobject_);
}

template <typename T_CppObject>
WeakRef<T_CppObject>&
WeakRef<T_CppObject>::operator=(const WeakRef& src) noexcept
{
  set(src.pCppObject_, src.gobject_);
  return *this;
}

template <typename T_CppObject>
WeakRef<T_CppObject>&
WeakRef<T_CppObject>::operator=(WeakRef&& src) noexcept
{
  // See RefPtr for an explanation of the swap() technique to implement
  // copy assignment and move assignment.
  // This technique is inefficient for copy assignment of WeakRef,
  // because it involves copy construction + destruction, i.e. in a typical
  // case g_weak_ref_init() + g_weak_ref_clear(), when a g_weak_ref_set()
  // would be enough. For move assignment, the swap technique is fine.
  WeakRef<T_CppObject> temp(std::forward<WeakRef<T_CppObject>>(src));
  this->swap(temp);
  return *this;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>&
WeakRef<T_CppObject>::operator=(const WeakRef<T_CastFrom>& src) noexcept
{
  set(src.pCppObject_, src.gobject_);
  return *this;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>&
WeakRef<T_CppObject>::operator=(WeakRef<T_CastFrom>&& src) noexcept
{
  WeakRef<T_CppObject> temp(std::forward<WeakRef<T_CastFrom>>(src));
  this->swap(temp);
  return *this;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>&
WeakRef<T_CppObject>::operator=(const RefPtr<T_CastFrom>& src) noexcept
{
  T_CppObject* pCppObject = src.operator->();
  set(pCppObject, nullptr);
  return *this;
}

template <class T_CppObject>
WeakRef<T_CppObject>::operator bool() const noexcept
{
  if (!pCppObject_)
    return false;

  gpointer ptr = g_weak_ref_get(gobject_);
  if (!ptr)
    return false;

  g_object_unref(ptr);
  return true;
}

template <typename T_CppObject>
RefPtr<T_CppObject>
WeakRef<T_CppObject>::get() const noexcept
{
  RefPtr<T_CppObject> ret;

  if (!pCppObject_)
    return ret;

  gpointer ptr = g_weak_ref_get(gobject_);
  if (!ptr)
    return ret;

  // A RefPtr constructed from pointer expects reference to be done externally.
  pCppObject_->reference();
  ret = RefPtr<T_CppObject>(pCppObject_);

  g_object_unref(ptr);

  return ret;
}

template <typename T_CppObject>
void
WeakRef<T_CppObject>::reset() noexcept
{
  set(nullptr, nullptr);
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>
WeakRef<T_CppObject>::cast_dynamic(const WeakRef<T_CastFrom>& src) noexcept
{
  WeakRef<T_CppObject> ret;

  if (!src.pCppObject_)
    return ret;

  gpointer ptr = g_weak_ref_get(src.gobject_);
  if (!ptr)
    return ret;

  // Don't call dynamic_cast<>() unless we know that the referenced object
  // still exists.
  T_CppObject* const pCppObject = dynamic_cast<T_CppObject*>(src.pCppObject_);
  ret.set(pCppObject, nullptr);
  g_object_unref(ptr);

  return ret;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>
WeakRef<T_CppObject>::cast_static(const WeakRef<T_CastFrom>& src) noexcept
{
  T_CppObject* const pCppObject = static_cast<T_CppObject*>(src.pCppObject_);

  WeakRef<T_CppObject> ret;
  ret.set(pCppObject, src.gobject_);
  return ret;
}

template <typename T_CppObject>
template <typename T_CastFrom>
WeakRef<T_CppObject>
WeakRef<T_CppObject>::cast_const(const WeakRef<T_CastFrom>& src) noexcept
{
  T_CppObject* const pCppObject = const_cast<T_CppObject*>(src.pCppObject_);

  WeakRef<T_CppObject> ret;
  ret.set(pCppObject, src.gobject_);
  return ret;
}

template <typename T_CppObject>
void
WeakRef<T_CppObject>::set(T_CppObject* pCppObject, GWeakRef* gobject) noexcept
{
  // We must own a strong reference to the underlying GObject while
  // calling g_weak_ref_init() or g_weak_ref_set().
  // If pCppObject != nullptr && gobject == nullptr,
  // then the caller holds a strong reference.

  // An aim with this moderately complicated method is to keep the same
  // GWeakRef, calling g_weak_ref_set() when possible, instead of using swap(),
  // which implies creating a new WeakRef, swapping with *this, and deleting
  // the new WeakRef.

  gpointer ptr = nullptr;
  if (pCppObject && gobject)
    ptr = g_weak_ref_get(gobject);

  pCppObject_ = (ptr || !gobject) ? pCppObject : nullptr;
  if (pCppObject_ && !gobject_)
  {
    gobject_ = new GWeakRef;
    g_weak_ref_init(gobject_, pCppObject_->gobj());
  }
  else if (gobject_)
    g_weak_ref_set(gobject_, pCppObject_ ? pCppObject_->gobj() : nullptr);

  if (ptr)
    g_object_unref(ptr);
}

#endif // DOXYGEN_SHOULD_SKIP_THIS

/** Swap the contents of two WeakRef<>.
 * @relates Glib::WeakRef
 */
template <class T_CppObject>
inline void
swap(WeakRef<T_CppObject>& lhs, WeakRef<T_CppObject>& rhs) noexcept
{
  lhs.swap(rhs);
}

} // namespace Glib

#endif // _GLIBMM_WEAKREF_H
