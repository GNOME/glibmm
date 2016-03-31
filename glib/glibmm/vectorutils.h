// -*- c++ -*-
#ifndef _GLIBMM_VECTORUTILS_H
#define _GLIBMM_VECTORUTILS_H

/* Copyright(C) 2011 The glibmm Development Team
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
#include <vector>
#include <glibmmconfig.h>
#include <glibmm/containerhandle_shared.h>
#include <cstddef>

/* There are three types of functions:
 * 1. Returning a container.
 * 2. Taking a container as a parameter.
 * 3. Returning a container as a parameter.
 *
 * Ad 1. When a function returns a container it can own:
 * a) a container and data, callers ownership - none (caller owns neither
 *    container nor data),
 * b) only data, callers ownership - shallow (caller owns only a container),
 * c) nothing, callers ownership - deep (caller owns both container and data).
 *
 * Above cases are simple - here we just create a vector with copies of returned
 * container's data and then, depending on ownership transfer, we destroy
 * nothing or container only or both container and data.
 *
 * Ad 2. When a function takes a container as a parameter it can take
 * an ownership of:
 * a) a container and data, callers ownership - none (caller loses ownership
 *    of both container and data),
 * b) only data, callers ownership - shallow (caller loses ownership of data),
 * c) nothing, callers ownership - deep (caller does not lose ownership
 *    to both container and data).
 *
 * Above cases are also simple - from given vector we create a C copy
 * of container and data, pass them to function and then, depending on ownership
 * transfer, we destroy nothing or container only or both container and data.
 * But note that a) and b) cases are probably wrong by design, so we don't cover
 * them here.
 *
 * Ad 3. Such functions are best wrapped by hand if we want to use a vector
 * here.
 */

namespace Glib
{

namespace Container_Helpers
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS

// TODO: docs!

/* Count the number of elements in a 0-terminated sequence.
 */
template <class T>
inline std::size_t
compute_array_size2(const T* array)
{
  if (array)
  {
    const T* pend(array);

    while (*pend)
    {
      ++pend;
    }
    return (pend - array);
  }

  return 0;
}

/* Allocate and fill a 0-terminated array.  The size argument
 * specifies the number of elements in the input sequence.
 */
template <class Tr>
typename Tr::CType*
create_array(typename std::vector<typename Tr::CppType>::const_iterator pbegin, std::size_t size)
{
  using CType = typename Tr::CType;

  CType* const array(static_cast<CType*>(g_malloc((size + 1) * sizeof(CType))));
  CType* const array_end(array + size);

  for (CType* pdest(array); pdest != array_end; ++pdest)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    *pdest = Tr::to_c_type(*&*pbegin);
    ++pbegin;
  }
  *array_end = CType();

  return array;
}

/* first class function for bools, because std::vector<bool> is a specialization
 * which does not conform to being an STL container.
 */
gboolean* create_bool_array(std::vector<bool>::const_iterator pbegin, std::size_t size);

/* Create and fill a GList as efficient as possible.
 * This requires bidirectional iterators.
 */
template <class Tr>
GList*
create_glist(const typename std::vector<typename Tr::CppType>::const_iterator pbegin,
  typename std::vector<typename Tr::CppType>::const_iterator pend)
{
  GList* head(nullptr);

  while (pend != pbegin)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    const void* const item(Tr::to_c_type(*&*--pend));
    head = g_list_prepend(head, const_cast<void*>(item));
  }

  return head;
}

/* Create and fill a GSList as efficient as possible.
 * This requires bidirectional iterators.
 */
template <class Tr>
GSList*
create_gslist(const typename std::vector<typename Tr::CppType>::const_iterator pbegin,
  typename std::vector<typename Tr::CppType>::const_iterator pend)
{
  GSList* head(nullptr);

  while (pend != pbegin)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    const void* const item(Tr::to_c_type(*&*--pend));
    head = g_slist_prepend(head, const_cast<void*>(item));
  }

  return head;
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

template <class Tr>
class ArrayIterator
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  using iterator_category = std::random_access_iterator_tag;
  using value_type = CppType;
  using difference_type = std::ptrdiff_t;
  using reference = value_type;
  using pointer = void;

  explicit inline ArrayIterator(const CType* pos);

  inline value_type operator*() const;
  inline value_type operator[](difference_type offset) const;

  inline ArrayIterator<Tr>& operator++();
  inline const ArrayIterator<Tr> operator++(int);

  // All this random access stuff is only there because STL algorithms
  // usually have optimized specializations for random access iterators,
  // and we don't want to give away efficiency for nothing.
  inline ArrayIterator<Tr>& operator+=(difference_type rhs);
  inline ArrayIterator<Tr>& operator-=(difference_type rhs);
  inline const ArrayIterator<Tr> operator+(difference_type rhs) const;
  inline const ArrayIterator<Tr> operator-(difference_type rhs) const;
  inline difference_type operator-(const ArrayIterator<Tr>& rhs) const;

  inline bool operator==(const ArrayIterator<Tr>& rhs) const;
  inline bool operator!=(const ArrayIterator<Tr>& rhs) const;
  inline bool operator<(const ArrayIterator<Tr>& rhs) const;
  inline bool operator>(const ArrayIterator<Tr>& rhs) const;
  inline bool operator<=(const ArrayIterator<Tr>& rhs) const;
  inline bool operator>=(const ArrayIterator<Tr>& rhs) const;

private:
  const CType* pos_;
};

template <class Tr>
class ListIterator
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  using iterator_category = std::forward_iterator_tag;
  using value_type = CppType;
  using difference_type = std::ptrdiff_t;
  using reference = value_type;
  using pointer = void;

  explicit inline ListIterator(const GList* node);

  inline value_type operator*() const;
  inline ListIterator<Tr>& operator++();
  inline const ListIterator<Tr> operator++(int);

  inline bool operator==(const ListIterator<Tr>& rhs) const;
  inline bool operator!=(const ListIterator<Tr>& rhs) const;

private:
  const GList* node_;
};

template <class Tr>
class SListIterator
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  using iterator_category = std::forward_iterator_tag;
  using value_type = CppType;
  using difference_type = std::ptrdiff_t;
  using reference = value_type;
  using pointer = void;

  explicit inline SListIterator(const GSList* node);

  inline value_type operator*() const;
  inline SListIterator<Tr>& operator++();
  inline const SListIterator<Tr> operator++(int);

  inline bool operator==(const SListIterator<Tr>& rhs) const;
  inline bool operator!=(const SListIterator<Tr>& rhs) const;

private:
  const GSList* node_;
};

/** A keeper class for C array.
 *
 * Primarily used by C++ wrappers like gtkmm.
 *
 * Its main purpose is to free its data when they are not needed. What will be
 * destroyed depends on passed ownership upon construction.
 *
 * The most common usage of Glib::ArrayKeeper is getting its data when converting
 * std::vector to a C array:
 * @code
 * void G::Temp::do_something(const std::vector<int>& v)
 * {
 *   g_temp_do_something(gobj(), Glib::ArrayHandler<int>::vector_to_array(v).data());
 * }
 * @endcode
 * Variables of this class are seldom defined directly - it is mostly used as
 * a temporary variable returned by Glib::ArrayHandler::vector_to_array().
 *
 * Note that the usage above is correct with regards to C++ standard point 12.2.3.
 * That means that data returned by data() method is valid through whole
 * g_temp_do_something function and is destroyed, when this function returns.
 */
template <typename Tr>
class ArrayKeeper
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  /** Constructs an ArrayKeeper holding @a array of size @a array_size.
   * @a ownership tells what should be destroyed with keeper destruction:
   * <ul>
   * <li>Glib::OWNERSHIP_NONE - keeper won't destroy data it holds.</li>
   * <li>Glib::OWNERSHIP_SHALLOW - keeper will destroy only container it holds.</li>
   * <li>Glib::OWNERSHIP_DEEP - keeper will destroy data and container it holds.</li>
   * </ul>
   *
   * @param array - C array to hold.
   * @param array_size - length of @a array.
   * @param ownership - ownership definition.
   */
  explicit inline ArrayKeeper(
    const CType* array, std::size_t array_size, Glib::OwnershipType ownership);
  inline ArrayKeeper(const ArrayKeeper& keeper);
  ~ArrayKeeper() noexcept;

  /** Gets data the keeper holds.
   *
   * Note that this data is owned by the keeper, so there is no need to free it.
   *
   * @return C array owned by ArrayKeeper.
   */
  inline CType* data() const;

private:
  CType* array_;
  std::size_t array_size_;
  mutable Glib::OwnershipType ownership_;
};

/** A keeper class for GList.
 *
 * Primarily used by C++ wrappers like gtkmm.
 *
 * Its main purpose is to free its data when they are not needed. What will be
 * destroyed depends on passed ownership upon construction.
 *
 * The most common usage of Glib::GListKeeper is getting its data when converting
 * std::vector to a GList*:
 * @code
 * void G::Temp::do_something(const std::vector<int>& v)
 * {
 *   g_temp_do_something(gobj(), Glib::ListHandler<int>::vector_to_list(v).data());
 * }
 * @endcode
 * Variables of this class are seldom defined directly - it is mostly used as
 * a temporary variable returned by Glib::ListHandler::vector_to_list().
 *
 * Note that the usage above is correct with regards to C++ standard point 12.2.3.
 * That means that data returned by data() method is valid through whole
 * g_temp_do_something function and is destroyed, when this function returns.
 */
template <typename Tr>
class GListKeeper
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  /** Constructs an GListKeeper holding @a glist.
   * @a ownership tells what should be destroyed with keeper destruction:
   * <ul>
   * <li>Glib::OWNERSHIP_NONE - keeper won't destroy data it holds.</li>
   * <li>Glib::OWNERSHIP_SHALLOW - keeper will destroy only container it holds.</li>
   * <li>Glib::OWNERSHIP_DEEP - keeper will destroy data and container it holds.</li>
   * </ul>
   *
   * @param glist - GList* to hold.
   * @param ownership - ownership definition.
   */
  explicit inline GListKeeper(const GList* glist, Glib::OwnershipType ownership);
  inline GListKeeper(const GListKeeper& keeper);
  ~GListKeeper() noexcept;

  /** Gets data the keeper holds.
   *
   * Note that this data is owned by the keeper, so there is no need to free it.
   *
   * @return GList* owned by GListKeeper.
   */
  inline GList* data() const;

private:
  GList* glist_;
  mutable Glib::OwnershipType ownership_;
};

/** A keeper class for GSList.
 *
 * Primarily used by C++ wrappers like gtkmm.
 *
 * Its main purpose is to free its data when they are not needed. What will be
 * destroyed depends on passed ownership upon construction.
 *
 * The most common usage of Glib::GSListKeeper is getting its data when converting
 * std::vector to a GSList*:
 * @code
 * void G::Temp::do_something(const std::vector<int>& v)
 * {
 *   g_temp_do_something(gobj(), Glib::SListHandler<int>::vector_to_slist(v).data());
 * }
 * @endcode
 * Variables of this class are seldom defined directly - it is mostly used as
 * a temporary variable returned by Glib::SListHandler::vector_to_slist().
 *
 * Note that the usage above is correct with regards to C++ standard point 12.2.3.
 * That means that data returned by data() method is valid through whole
 * g_temp_do_something function and is destroyed, when this function returns.
 */
template <typename Tr>
class GSListKeeper
{
public:
  using CppType = typename Tr::CppType;
  using CType = typename Tr::CType;

  /** Constructs an GSListKeeper holding @a gslist.
   * @a ownership tells what should be destroyed with keeper destruction:
   * <ul>
   * <li>Glib::OWNERSHIP_NONE - keeper won't destroy data it holds.</li>
   * <li>Glib::OWNERSHIP_SHALLOW - keeper will destroy only container it holds.</li>
   * <li>Glib::OWNERSHIP_DEEP - keeper will destroy data and container it holds.</li>
   * </ul>
   *
   * @param gslist - GList* to hold.
   * @param ownership - ownership definition.
   */
  explicit inline GSListKeeper(const GSList* gslist, Glib::OwnershipType ownership);
  inline GSListKeeper(const GSListKeeper& keeper);
  ~GSListKeeper() noexcept;

  /** Gets data the keeper holds.
   *
   * Note that this data is owned by the keeper, so there is no need to free it.
   *
   * @return GSList* owned by GSListKeeper.
   */
  inline GSList* data() const;

private:
  GSList* gslist_;
  mutable Glib::OwnershipType ownership_;
};

} // namespace Container_Helpers

// Note that this is a struct instead of templated functions because standard template arguments
// for function templates is a C++0x feature.
/** A utility for converting between std::vector and plain C arrays.
 * This would normally only be used by glibmm or gtkmm itself, or similar
 * libraries that wrap C APIs.
 *
 * For instance:
 * @code
 * std::vector<Glib::ustring> PixbufFormat::get_mime_types() const
 * {
 *   return
 * Glib::ArrayHandler<Glib::ustring>::array_to_vector(gdk_pixbuf_format_get_mime_types(const_cast<GdkPixbufFormat*>(gobj())),
 * Glib::OWNERSHIP_DEEP);
 * }
 * @endcode
 * or
 * @code
 * void Display::store_clipboard(const Glib::RefPtr<Gdk::Window>& clipboard_window, guint32 time_,
 * const std::vector<Glib::ustring>& targets)
 * {
 *   if (!targets.size ())
 *   {
 *     gdk_display_store_clipboard(gobj(),
 *                                 Glib::unwrap (clipboard_window),
 *                                 time_,
 *                                 Glib::ArrayHandler<Glib::ustring,
 * AtomUstringTraits>::vector_to_array(targets).data (),
 *                                 targets.size ());
 *   }
 * }
 * @endcode
 * Note that usage below is wrong - data() returns a pointer to data owned by
 * a temporary ArrayKeeper returned by vector_to_array(), which is destroyed at
 * the end of this instruction. For details, see Glib::ArrayKeeper.
 * @code
 * const char** array = Glib::ArrayHandler<Glib::ustring>::vector_to_array(vec).data ();
 * @endcode
 */
template <typename T, typename Tr = Glib::Container_Helpers::TypeTraits<T>>
class ArrayHandler
{
public:
  using CType = typename Tr::CType;
  using CppType = T;
  using VectorType = std::vector<CppType>;
  using ArrayKeeperType = typename Glib::Container_Helpers::ArrayKeeper<Tr>;
  using ArrayIteratorType = typename Glib::Container_Helpers::ArrayIterator<Tr>;

  // maybe think about using C++0x move constructors?
  static VectorType array_to_vector(
    const CType* array, std::size_t array_size, Glib::OwnershipType ownership);
  static VectorType array_to_vector(const CType* array, Glib::OwnershipType ownership);
  static ArrayKeeperType vector_to_array(const VectorType& vector);
};

template <>
class ArrayHandler<bool>
{
public:
  using CType = gboolean;
  using CppType = bool;
  using VectorType = std::vector<bool>;
  typedef Glib::Container_Helpers::ArrayKeeper<Glib::Container_Helpers::TypeTraits<bool>>
    ArrayKeeperType;
  typedef Glib::Container_Helpers::ArrayIterator<Glib::Container_Helpers::TypeTraits<bool>>
    ArrayIteratorType;

  // maybe think about using C++0x move constructors?
  static VectorType array_to_vector(
    const CType* array, std::size_t array_size, Glib::OwnershipType ownership);
  static VectorType array_to_vector(const CType* array, Glib::OwnershipType ownership);
  static ArrayKeeperType vector_to_array(const VectorType& vector);
};

/** A utility for converting between std::vector and GList.
 * This would normally only be used by glibmm or gtkmm itself, or similar
 * libraries that wrap C APIs.
 *
 * For instance:
 * @code
 * std::vector< Glib::RefPtr<Window> > Window::get_children()
 * {
 *   return Glib::ListHandler<Glib::RefPtr<Window>
 * >::list_to_vector(gdk_window_get_children(gobj()), Glib::OWNERSHIP_SHALLOW);
 * }
 * @endcode
 * or
 * @code
 * void Window::set_icon_list(const std::vector< Glib::RefPtr<Gdk::Pixbuf> >& pixbufs)
 * {
 *   gdk_window_set_icon_list(gobj(), Glib::ListHandler<Glib::RefPtr<Gdk::Pixbuf>
 * >::vector_to_list(pixbufs).data ());
 * }
 * @endcode
 * Note that usage below is wrong - data() returns a pointer to data owned by
 * a temporary ListKeeper returned by vector_to_list(), which is destroyed at
 * the end of this instruction. For details, see Glib::ListKeeper.
 * @code
 * GList* glist = Glib::ListHandler<Glib::RefPtr<Gdk::Pixbuf> >::vector_to_list(pixbufs).data();
 * @endcode
 */
template <typename T, typename Tr = Glib::Container_Helpers::TypeTraits<T>>
class ListHandler
{
public:
  using CType = typename Tr::CType;
  using CppType = T;
  using VectorType = std::vector<CppType>;
  using GListKeeperType = typename Glib::Container_Helpers::GListKeeper<Tr>;
  using ListIteratorType = typename Glib::Container_Helpers::ListIterator<Tr>;

  // maybe think about using C++0x move constructors?
  static VectorType list_to_vector(GList* glist, Glib::OwnershipType ownership);
  static GListKeeperType vector_to_list(const VectorType& vector);
};

/** A utility for converting between std::vector and GSList.
 * This would normally only be used by glibmm or gtkmm itself, or similar
 * libraries that wrap C APIs.
 *
 * For instance:
 * @code
 * std::vector< Glib::RefPtr<Display> > DisplayManager::list_displays()
 * {
 *   return Glib::SListHandler<Glib::RefPtr<Display>
 * >::slist_to_vector(gdk_display_manager_list_displays(gobj()), Glib::OWNERSHIP_SHALLOW);
 * }
 * @endcode
 * or
 * @code
 * void Stuff::set_slist(const std::vector<int>& ints)
 * {
 *   g_stuff_set_slist(gobj(), Glib::SListHandler<int>::vector_to_slist(ints).data ());
 * }
 * @endcode
 * Note that usage below is wrong - data() returns a pointer to data owned by
 * a temporary SListKeeper returned by vector_to_slist(), which is destroyed at
 * the end of this instruction. For details, see Glib::SListKeeper.
 * @code
 * GSList* gslist = Glib::SListHandler< Glib::RefPtr<Display> >::vector_to_slist(vec).data();
 * @endcode
 */
template <typename T, typename Tr = Glib::Container_Helpers::TypeTraits<T>>
class SListHandler
{
public:
  using CType = typename Tr::CType;
  using CppType = T;
  using VectorType = std::vector<CppType>;
  using GSListKeeperType = typename Glib::Container_Helpers::GSListKeeper<Tr>;
  using SListIteratorType = typename Glib::Container_Helpers::SListIterator<Tr>;

  // maybe think about using C++0x move constructors?
  static VectorType slist_to_vector(GSList* gslist, Glib::OwnershipType ownership);
  static GSListKeeperType vector_to_slist(const VectorType& vector);
};

/***************************************************************************/
/*  Inline implementation                                                  */
/***************************************************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Container_Helpers
{

/**** Glib::Container_Helpers::ArrayIterator<> ***********************/

template <class Tr>
inline ArrayIterator<Tr>::ArrayIterator(const CType* pos) : pos_(pos)
{
}

template <class Tr>
inline typename ArrayIterator<Tr>::value_type ArrayIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(*pos_);
}

template <class Tr>
inline
  typename ArrayIterator<Tr>::value_type ArrayIterator<Tr>::operator[](difference_type offset) const
{
  return Tr::to_cpp_type(pos_[offset]);
}

template <class Tr>
inline ArrayIterator<Tr>& ArrayIterator<Tr>::operator++()
{
  ++pos_;
  return *this;
}

template <class Tr>
inline const ArrayIterator<Tr> ArrayIterator<Tr>::operator++(int)
{
  return ArrayIterator<Tr>(pos_++);
}

template <class Tr>
inline ArrayIterator<Tr>&
ArrayIterator<Tr>::operator+=(typename ArrayIterator<Tr>::difference_type rhs)
{
  pos_ += rhs;
  return *this;
}

template <class Tr>
inline ArrayIterator<Tr>&
ArrayIterator<Tr>::operator-=(typename ArrayIterator<Tr>::difference_type rhs)
{
  pos_ -= rhs;
  return *this;
}

template <class Tr>
inline const ArrayIterator<Tr>
ArrayIterator<Tr>::operator+(typename ArrayIterator<Tr>::difference_type rhs) const
{
  return ArrayIterator<Tr>(pos_ + rhs);
}

template <class Tr>
inline const ArrayIterator<Tr>
ArrayIterator<Tr>::operator-(typename ArrayIterator<Tr>::difference_type rhs) const
{
  return ArrayIterator<Tr>(pos_ - rhs);
}

template <class Tr>
inline typename ArrayIterator<Tr>::difference_type
ArrayIterator<Tr>::operator-(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ - rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator==(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ == rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator!=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ != rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator<(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ < rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator>(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ > rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator<=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ <= rhs.pos_);
}

template <class Tr>
inline bool
ArrayIterator<Tr>::operator>=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ >= rhs.pos_);
}

/**** Glib::Container_Helpers::ListIterator<> ************************/

template <class Tr>
inline ListIterator<Tr>::ListIterator(const GList* node) : node_(node)
{
}

template <class Tr>
inline typename ListIterator<Tr>::value_type ListIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(static_cast<typename Tr::CTypeNonConst>(node_->data));
}

template <class Tr>
inline ListIterator<Tr>& ListIterator<Tr>::operator++()
{
  node_ = node_->next;
  return *this;
}

template <class Tr>
inline const ListIterator<Tr> ListIterator<Tr>::operator++(int)
{
  const ListIterator<Tr> tmp(*this);
  node_ = node_->next;
  return tmp;
}

template <class Tr>
inline bool
ListIterator<Tr>::operator==(const ListIterator<Tr>& rhs) const
{
  return (node_ == rhs.node_);
}

template <class Tr>
inline bool
ListIterator<Tr>::operator!=(const ListIterator<Tr>& rhs) const
{
  return (node_ != rhs.node_);
}

/**** Glib::Container_Helpers::SListIterator<> ************************/

template <class Tr>
inline SListIterator<Tr>::SListIterator(const GSList* node) : node_(node)
{
}

template <class Tr>
inline typename SListIterator<Tr>::value_type SListIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(static_cast<typename Tr::CTypeNonConst>(node_->data));
}

template <class Tr>
inline SListIterator<Tr>& SListIterator<Tr>::operator++()
{
  node_ = node_->next;
  return *this;
}

template <class Tr>
inline const SListIterator<Tr> SListIterator<Tr>::operator++(int)
{
  const ListIterator<Tr> tmp(*this);
  node_ = node_->next;
  return tmp;
}

template <class Tr>
inline bool
SListIterator<Tr>::operator==(const SListIterator<Tr>& rhs) const
{
  return (node_ == rhs.node_);
}

template <class Tr>
inline bool
SListIterator<Tr>::operator!=(const SListIterator<Tr>& rhs) const
{
  return (node_ != rhs.node_);
}

/**** Glib::Container_Helpers::ArrayKeeper<> ************************/

template <typename Tr>
inline ArrayKeeper<Tr>::ArrayKeeper(
  const CType* array, std::size_t array_size, Glib::OwnershipType ownership)
: array_(const_cast<CType*>(array)), array_size_(array_size), ownership_(ownership)
{
}

template <typename Tr>
inline ArrayKeeper<Tr>::ArrayKeeper(const ArrayKeeper& keeper)
: array_(keeper.array_), array_size_(keeper.array_size_), ownership_(keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
ArrayKeeper<Tr>::~ArrayKeeper() noexcept
{
  if (array_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      const CType* const array_end(array_ + array_size_);

      for (const CType* p(array_); p != array_end; ++p)
      {
        Tr::release_c_type(*p);
      }
    }
    g_free(const_cast<CType*>(array_));
  }
}

template <typename Tr>
inline typename Tr::CType*
ArrayKeeper<Tr>::data() const
{
  return array_;
}

/**** Glib::Container_Helpers::GListKeeper<> ************************/

template <typename Tr>
inline GListKeeper<Tr>::GListKeeper(const GList* glist, Glib::OwnershipType ownership)
: glist_(const_cast<GList*>(glist)), ownership_(ownership)
{
}

template <typename Tr>
inline GListKeeper<Tr>::GListKeeper(const GListKeeper& keeper)
: glist_(keeper.glist_), ownership_(keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
GListKeeper<Tr>::~GListKeeper() noexcept
{
  using CTypeNonConst = typename Tr::CTypeNonConst;

  if (glist_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      for (GList* node = glist_; node; node = node->next)
      {
        Tr::release_c_type(static_cast<CTypeNonConst>(node->data));
      }
    }
    g_list_free(glist_);
  }
}

template <typename Tr>
inline GList*
GListKeeper<Tr>::data() const
{
  return glist_;
}

/**** Glib::Container_Helpers::GSListKeeper<> ************************/

template <typename Tr>
inline GSListKeeper<Tr>::GSListKeeper(const GSList* gslist, Glib::OwnershipType ownership)
: gslist_(const_cast<GSList*>(gslist)), ownership_(ownership)
{
}

template <typename Tr>
inline GSListKeeper<Tr>::GSListKeeper(const GSListKeeper& keeper)
: gslist_(keeper.gslist_), ownership_(keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
GSListKeeper<Tr>::~GSListKeeper() noexcept
{
  using CTypeNonConst = typename Tr::CTypeNonConst;
  if (gslist_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      for (GSList* node = gslist_; node; node = node->next)
      {
        Tr::release_c_type(static_cast<CTypeNonConst>(node->data));
      }
    }
    g_slist_free(gslist_);
  }
}

template <typename Tr>
inline GSList*
GSListKeeper<Tr>::data() const
{
  return gslist_;
}

} // namespace Container_Helpers

/**** Glib::ArrayHandler<> ************************/

template <typename T, class Tr>
typename ArrayHandler<T, Tr>::VectorType
ArrayHandler<T, Tr>::array_to_vector(
  const CType* array, std::size_t array_size, Glib::OwnershipType ownership)
{
  if (array)
  {
    // it will handle destroying data depending on passed ownership.
    ArrayKeeperType keeper(array, array_size, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
    return VectorType(ArrayIteratorType(array), ArrayIteratorType(array + array_size));
#else
    VectorType temp;
    temp.reserve(array_size);
    Glib::Container_Helpers::fill_container(
      temp, ArrayIteratorType(array), ArrayIteratorType(array + array_size));
    return temp;
#endif
  }
  return VectorType();
}

template <typename T, class Tr>
typename ArrayHandler<T, Tr>::VectorType
ArrayHandler<T, Tr>::array_to_vector(const CType* array, Glib::OwnershipType ownership)
{
  return array_to_vector(array, Glib::Container_Helpers::compute_array_size2(array), ownership);
}

template <typename T, class Tr>
typename ArrayHandler<T, Tr>::ArrayKeeperType
ArrayHandler<T, Tr>::vector_to_array(const VectorType& vector)
{
  return ArrayKeeperType(Glib::Container_Helpers::create_array<Tr>(vector.begin(), vector.size()),
    vector.size(), Glib::OWNERSHIP_SHALLOW);
}

/**** Glib::ListHandler<> ************************/

template <typename T, class Tr>
typename ListHandler<T, Tr>::VectorType
ListHandler<T, Tr>::list_to_vector(GList* glist, Glib::OwnershipType ownership)
{
  // it will handle destroying data depending on passed ownership.
  GListKeeperType keeper(glist, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return VectorType(ListIteratorType(glist), ListIteratorType(nullptr));
#else
  VectorType temp;
  temp.reserve(g_list_length(glist));
  Glib::Container_Helpers::fill_container(temp, ListIteratorType(glist), ListIteratorType(nullptr));
  return temp;
#endif
}

template <typename T, class Tr>
typename ListHandler<T, Tr>::GListKeeperType
ListHandler<T, Tr>::vector_to_list(const VectorType& vector)
{
  return GListKeeperType(Glib::Container_Helpers::create_glist<Tr>(vector.begin(), vector.end()),
    Glib::OWNERSHIP_SHALLOW);
}

/**** Glib::SListHandler<> ************************/

template <typename T, class Tr>
typename SListHandler<T, Tr>::VectorType
SListHandler<T, Tr>::slist_to_vector(GSList* gslist, Glib::OwnershipType ownership)
{
  // it will handle destroying data depending on passed ownership.
  GSListKeeperType keeper(gslist, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return VectorType(SListIteratorType(gslist), SListIteratorType(nullptr));
#else
  VectorType temp;
  temp.reserve(g_slist_length(gslist));
  Glib::Container_Helpers::fill_container(
    temp, SListIteratorType(gslist), SListIteratorType(nullptr));
  return temp;
#endif
}

template <typename T, class Tr>
typename SListHandler<T, Tr>::GSListKeeperType
SListHandler<T, Tr>::vector_to_slist(const VectorType& vector)
{
  return GSListKeeperType(Glib::Container_Helpers::create_gslist<Tr>(vector.begin(), vector.end()),
    Glib::OWNERSHIP_SHALLOW);
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

#endif /* _GLIBMM_VECTORUTILS_H */
