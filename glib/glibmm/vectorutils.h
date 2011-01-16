// -*- c++ -*-
#ifndef _GLIBMM_VECTORUTILS_H
#define _GLIBMM_VECTORUTILS_H

/* Copyright (C) 2010 The gtkmm Development Team
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
 *
 * Ad 3. Such functions are best wrapped by hand if we want to use a vector
 * here.
 */

namespace Glib
{

namespace Container_Helpers
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/* Count the number of elements in a 0-terminated sequence.
 */
template <class T> inline
size_t compute_array_size2(const T* array)
{
  const T* pend = array;

  while(*pend)
    ++pend;

  return (pend - array);
}

/* Allocate and fill a 0-terminated array.  The size argument
 * specifies the number of elements in the input sequence.
 */
template <class Tr, class For>
typename Tr::CType* create_array2(For pbegin, size_t size)
{
  typedef typename Tr::CType CType;

  CType *const array = static_cast<CType*>(g_malloc((size + 1) * sizeof(CType)));
  CType *const array_end = array + size;

  for(CType* pdest = array; pdest != array_end; ++pdest)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    *pdest = Tr::to_c_type(*&*pbegin);
    ++pbegin;
  }

  *array_end = CType();
  return array;
}

/* Create and fill a GList as efficient as possible.
 * This requires bidirectional iterators.
 */
template <class Tr, class Bi>
GList* create_glist2(Bi pbegin, Bi pend)
{
  GList* head = 0;

  while(pend != pbegin)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    const void *const item = Tr::to_c_type(*&*--pend);
    head = g_list_prepend(head, const_cast<void*>(item));
  }

  return head;
}

/* Create and fill a GSList as efficient as possible.
 * This requires bidirectional iterators.
 */
template <class Tr, class Bi>
GSList* create_gslist2(Bi pbegin, Bi pend)
{
  GSList* head = 0;

  while(pend != pbegin)
  {
    // Use & to force a warning if the iterator returns a temporary object.
    const void *const item = Tr::to_c_type(*&*--pend);
    head = g_slist_prepend(head, const_cast<void*>(item));
  }

  return head;
}


/* Convert from any container that supports forward
 * iterators and has a size() method.
 */
 /*
template <class Tr, class Cont>
struct ArraySourceTraits
{
  typedef typename Tr::CType CType;

  static size_t get_size(const Cont& cont)
    { return cont.size(); }

  static const CType* get_data(const Cont& cont, size_t size)
    { return Glib::Container_Helpers::create_array(cont.begin(), size, Tr()); }

  static const Glib::OwnershipType initial_ownership = Glib::OWNERSHIP_SHALLOW;
};
*/

/* Convert from a 0-terminated array.  The Cont argument must be a pointer
 * to the first element.  Note that only arrays of the C type are supported.
 */
 /*
template <class Tr, class Cont>
struct ArraySourceTraits<Tr,Cont*>
{
  typedef typename Tr::CType CType;

  static size_t get_size(const CType* array)
    { return (array) ? Glib::Container_Helpers::compute_array_size(array) : 0; }

  static const CType* get_data(const CType* array, size_t)
    { return array; }

  static const Glib::OwnershipType initial_ownership = Glib::OWNERSHIP_NONE;
};

template <class Tr, class Cont>
struct ArraySourceTraits<Tr,const Cont*> : ArraySourceTraits<Tr,Cont*>
{};
*/

/* Convert from a 0-terminated array.  The Cont argument must be a pointer
 * to the first element.  Note that only arrays of the C type are supported.
 * For consistency, the array must be 0-terminated, even though the array
 * size is known at compile time.
 */
 /*
template <class Tr, class Cont, size_t N>
struct ArraySourceTraits<Tr,Cont[N]>
{
  typedef typename Tr::CType CType;

  static size_t get_size(const CType*)
    { return (N - 1); }

  static const CType* get_data(const CType* array, size_t)
    { return array; }

  static const Glib::OwnershipType initial_ownership = Glib::OWNERSHIP_NONE;
};

template <class Tr, class Cont, size_t N>
struct ArraySourceTraits<Tr,const Cont[N]> : ArraySourceTraits<Tr,Cont[N]>
{};
*/

#endif /* DOXYGEN_SHOULD_SKIP_THIS */


/**
 * @ingroup ContHelpers
 */
template <class Tr>
class ArrayIterator
{
public:
  typedef typename Tr::CppType              CppType;
  typedef typename Tr::CType                CType;

  typedef std::random_access_iterator_tag   iterator_category;
  typedef CppType                           value_type;
  typedef ptrdiff_t                         difference_type;
  typedef value_type                        reference;
  typedef void                              pointer;

  explicit inline ArrayIterator(const CType* pos);

  inline value_type operator*() const;
  inline value_type operator[](difference_type offset) const;

  inline ArrayIterator<Tr> &     operator++();
  inline const ArrayIterator<Tr> operator++(int);

  // All this random access stuff is only there because STL algorithms
  // usually have optimized specializations for random access iterators,
  // and we don't want to give away efficiency for nothing.
  //
  inline ArrayIterator<Tr> &     operator+=(difference_type rhs);
  inline ArrayIterator<Tr> &     operator-=(difference_type rhs);
  inline const ArrayIterator<Tr> operator+ (difference_type rhs) const;
  inline const ArrayIterator<Tr> operator- (difference_type rhs) const;
  inline difference_type operator-(const ArrayIterator<Tr>& rhs) const;

  inline bool operator==(const ArrayIterator<Tr>& rhs) const;
  inline bool operator!=(const ArrayIterator<Tr>& rhs) const;
  inline bool operator< (const ArrayIterator<Tr>& rhs) const;
  inline bool operator> (const ArrayIterator<Tr>& rhs) const;
  inline bool operator<=(const ArrayIterator<Tr>& rhs) const;
  inline bool operator>=(const ArrayIterator<Tr>& rhs) const;

private:
  const CType* pos_;
};

/**
 * @ingroup ContHelpers
 * If a method takes this as an argument, or has this as a return type, then you can use a standard
 * container such as std::list or std::vector.
 */
template <class Tr>
class ListIterator
{
public:
  typedef typename Tr::CppType        CppType;
  typedef typename Tr::CType          CType;

  typedef std::forward_iterator_tag   iterator_category;
  typedef CppType                     value_type;
  typedef ptrdiff_t                   difference_type;
  typedef value_type                  reference;
  typedef void                        pointer;

  explicit inline ListIterator(const GList* node);

  inline value_type                   operator*() const;
  inline ListIterator<Tr>&            operator++();
  inline const ListIterator<Tr>       operator++(int);

  inline bool operator==(const ListIterator<Tr>& rhs) const;
  inline bool operator!=(const ListIterator<Tr>& rhs) const;

private:
  const GList* node_;
};

/**
 * @ingroup ContHelpers
 * If a method takes this as an argument, or has this as a return type, then you can use a standard
 * container such as std::list or std::vector.
 */
template <class Tr>
class SListIterator
{
public:
  typedef typename Tr::CppType        CppType;
  typedef typename Tr::CType          CType;

  typedef std::forward_iterator_tag   iterator_category;
  typedef CppType                     value_type;
  typedef ptrdiff_t                   difference_type;
  typedef value_type                  reference;
  typedef void                        pointer;

  explicit inline SListIterator (const GSList* node);

  inline value_type                   operator*() const;
  inline SListIterator<Tr>&           operator++();
  inline const SListIterator<Tr>      operator++(int);

  inline bool operator== (const SListIterator<Tr>& rhs) const;
  inline bool operator!= (const SListIterator<Tr>& rhs) const;

private:
  const GSList* node_;
};

template <typename Tr>
class ArrayKeeper
{
public:
  typedef typename Tr::CppType        CppType;
  typedef typename Tr::CType          CType;

  explicit inline ArrayKeeper (const CType* array, size_t array_size, Glib::OwnershipType ownership);
  inline ArrayKeeper (const ArrayKeeper& keeper);
  ~ArrayKeeper ();

  inline operator CType* () const;

private:
  CType* array_;
  size_t array_size_;
  mutable Glib::OwnershipType ownership_;
};

template <typename Tr>
class GListKeeper
{
public:
  typedef typename Tr::CppType        CppType;
  typedef typename Tr::CType          CType;

  explicit inline GListKeeper (const GList* glist, Glib::OwnershipType ownership);
  inline GListKeeper (const GListKeeper& keeper);
  ~GListKeeper ();

  inline operator GList* () const;

private:
  GList* glist_;
  mutable Glib::OwnershipType ownership_;
};

template <typename Tr>
class GSListKeeper
{
public:
  typedef typename Tr::CppType        CppType;
  typedef typename Tr::CType          CType;

  explicit inline GSListKeeper (const GSList* gslist, Glib::OwnershipType ownership);
  inline GSListKeeper (const GSListKeeper& keeper);
  ~GSListKeeper ();

  inline operator GSList* () const;

private:
  GSList* gslist_;
  mutable Glib::OwnershipType ownership_;
};

} // namespace Container_Helpers

// a struct instead of templated functions because standard template arguments
// for function templates is a C++0x feature...
template <typename T, typename Tr = Glib::Container_Helpers::TypeTraits<T> >
class VectorHandler
{
public:
  typedef typename Tr::CType CType;
  typedef typename Tr::CppType CppType;
  typedef std::vector<CppType> VectorType;
  typedef typename Glib::Container_Helpers::ArrayKeeper<Tr> ArrayKeeperType;
  typedef typename Glib::Container_Helpers::GListKeeper<Tr> GListKeeperType;
  typedef typename Glib::Container_Helpers::GSListKeeper<Tr> GSListKeeperType;
  typedef typename Glib::Container_Helpers::ArrayIterator<Tr> ArrayIteratorType;
  typedef typename Glib::Container_Helpers::ListIterator<Tr> ListIteratorType;
  typedef typename Glib::Container_Helpers::SListIterator<Tr> SListIteratorType;

  static VectorType array_to_vector (const CType* array, size_t array_size, Glib::OwnershipType ownership);
  static VectorType array_to_vector (const CType* array, Glib::OwnershipType ownership);
  static VectorType list_to_vector (GList* glist, Glib::OwnershipType ownership);
  static VectorType slist_to_vector (GSList* gslist, Glib::OwnershipType ownership);
  static ArrayKeeperType vector_to_array (const VectorType& vector, Glib::OwnershipType ownership);
  static GListKeeperType vector_to_list (const VectorType& vector, Glib::OwnershipType ownership);
  static GSListKeeperType vector_to_slist (const VectorType& vector, Glib::OwnershipType ownership);
};

/** If a method takes this as an argument, or has this as a return type, then you can use a standard
 * container such as std::list or std::vector.
 * @ingroup ContHandles
 */
/*
template < class T, class Tr = Glib::Container_Helpers::TypeTraits<T> >
class ArrayHandle
{
public:
  typedef typename Tr::CppType  CppType;
  typedef typename Tr::CType    CType;

  typedef CppType               value_type;
  typedef size_t                size_type;
  typedef ptrdiff_t             difference_type;

  typedef Glib::Container_Helpers::ArrayIterator<Tr>   const_iterator;
  typedef Glib::Container_Helpers::ArrayIterator<Tr>   iterator;

  template <class Cont> inline
    ArrayHandle(const Cont& container);

  // Take over ownership of an array created by GTK+ functions.
  inline ArrayHandle(const CType* array, size_t array_size, Glib::OwnershipType ownership);
  inline ArrayHandle(const CType* array, Glib::OwnershipType ownership);

  // Copying clears the ownership flag of the source handle.
  inline ArrayHandle(const ArrayHandle<T,Tr>& other);

  ~ArrayHandle();

  inline const_iterator begin() const;
  inline const_iterator end()   const;

  template <class U> inline operator std::vector<U>() const;
  template <class U> inline operator std::deque<U>()  const;
  template <class U> inline operator std::list<U>()   const;

  template <class Cont> inline
    void assign_to(Cont& container) const;

  template <class Out> inline
    void copy(Out pdest) const;

  inline const CType* data()  const;
  inline size_t       size()  const;
  inline bool         empty() const;

private:
  size_t                      size_;
  const CType*                parray_;
  mutable Glib::OwnershipType ownership_;

  // No copy assignment.
  ArrayHandle<T, Tr>& operator=(const ArrayHandle<T,Tr>&);
};
*/

/** If a method takes this as an argument, or has this as a return type, then you can use a standard
 * container such as std::list<Glib::ustring> or std::vector<Glib::ustring>.
 * @ingroup ContHandles
 */
 /*
typedef ArrayHandle<Glib::ustring> StringArrayHandle;
*/

/***************************************************************************/
/*  Inline implementation                                                  */
/***************************************************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Container_Helpers
{

/**** Glib::Container_Helpers::ArrayIterator<> ***********************/

template <class Tr> inline
ArrayIterator<Tr>::ArrayIterator(const CType* pos)
:
  pos_ (pos)
{}

template <class Tr> inline
typename ArrayIterator<Tr>::value_type ArrayIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(*pos_);
}

template <class Tr> inline
typename ArrayIterator<Tr>::value_type
ArrayIterator<Tr>::operator[](difference_type offset) const
{
  return Tr::to_cpp_type(pos_[offset]);
}

template <class Tr> inline
ArrayIterator<Tr>& ArrayIterator<Tr>::operator++()
{
  ++pos_;
  return *this;
}

template <class Tr> inline
const ArrayIterator<Tr> ArrayIterator<Tr>::operator++(int)
{
  return ArrayIterator<Tr>(pos_++);
}

template <class Tr> inline
ArrayIterator<Tr>&
ArrayIterator<Tr>::operator+=(typename ArrayIterator<Tr>::difference_type rhs)
{
  pos_ += rhs;
  return *this;
}

template <class Tr> inline
ArrayIterator<Tr>&
ArrayIterator<Tr>::operator-=(typename ArrayIterator<Tr>::difference_type rhs)
{
  pos_ -= rhs;
  return *this;
}

template <class Tr> inline
const ArrayIterator<Tr>
ArrayIterator<Tr>::operator+(typename ArrayIterator<Tr>::difference_type rhs) const
{
  return ArrayIterator<Tr>(pos_ + rhs);
}

template <class Tr> inline
const ArrayIterator<Tr>
ArrayIterator<Tr>::operator-(typename ArrayIterator<Tr>::difference_type rhs) const
{
  return ArrayIterator<Tr>(pos_ - rhs);
}

template <class Tr> inline
typename ArrayIterator<Tr>::difference_type
ArrayIterator<Tr>::operator-(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ - rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator==(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ == rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator!=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ != rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator<(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ < rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator>(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ > rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator<=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ <= rhs.pos_);
}

template <class Tr> inline
bool ArrayIterator<Tr>::operator>=(const ArrayIterator<Tr>& rhs) const
{
  return (pos_ >= rhs.pos_);
}

/**** Glib::Container_Helpers::ListIterator<> ************************/

template <class Tr> inline
ListIterator<Tr>::ListIterator(const GList* node)
:
  node_ (node)
{}

template <class Tr> inline
typename ListIterator<Tr>::value_type ListIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(static_cast<typename Tr::CTypeNonConst>(node_->data));
}

template <class Tr> inline
ListIterator<Tr>& ListIterator<Tr>::operator++()
{
  node_ = node_->next;
  return *this;
}

template <class Tr> inline
const ListIterator<Tr> ListIterator<Tr>::operator++(int)
{
  const ListIterator<Tr> tmp (*this);
  node_ = node_->next;
  return tmp;
}

template <class Tr> inline
bool ListIterator<Tr>::operator==(const ListIterator<Tr>& rhs) const
{
  return (node_ == rhs.node_);
}

template <class Tr> inline
bool ListIterator<Tr>::operator!=(const ListIterator<Tr>& rhs) const
{
  return (node_ != rhs.node_);
}

/**** Glib::Container_Helpers::SListIterator<> ************************/

template <class Tr> inline
SListIterator<Tr>::SListIterator(const GSList* node)
:
  node_ (node)
{}

template <class Tr> inline
typename SListIterator<Tr>::value_type SListIterator<Tr>::operator*() const
{
  return Tr::to_cpp_type(static_cast<typename Tr::CTypeNonConst>(node_->data));
}

template <class Tr> inline
SListIterator<Tr>& SListIterator<Tr>::operator++()
{
  node_ = node_->next;
  return *this;
}

template <class Tr> inline
const SListIterator<Tr> SListIterator<Tr>::operator++(int)
{
  const ListIterator<Tr> tmp (*this);
  node_ = node_->next;
  return tmp;
}

template <class Tr> inline
bool SListIterator<Tr>::operator==(const SListIterator<Tr>& rhs) const
{
  return (node_ == rhs.node_);
}

template <class Tr> inline
bool SListIterator<Tr>::operator!=(const SListIterator<Tr>& rhs) const
{
  return (node_ != rhs.node_);
}

/**** Glib::Container_Helpers::ArrayKeeper<> ************************/

template <typename Tr>
inline ArrayKeeper<Tr>::ArrayKeeper (const CType* array, size_t array_size, Glib::OwnershipType ownership)
:
  array_ (const_cast<CType*> (array)),
  array_size_ (array_size),
  ownership_ (ownership)
{}

template <typename Tr>
inline ArrayKeeper<Tr>::ArrayKeeper (const ArrayKeeper& keeper)
:
  array_ (keeper.array_),
  array_size_ (keeper.array_size_),
  ownership_ (keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
ArrayKeeper<Tr>::~ArrayKeeper ()
{
  if (array_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      const CType *const array_end (array_ + array_size_);

      for (const CType* p (array_); p != array_end; ++p)
      {
        Tr::release_c_type (*p);
      }
    }
    g_free (const_cast<CType*> (array_));
  }
}

template <typename Tr>
inline ArrayKeeper<Tr>::operator CType* () const
{
  return array_;
}

/**** Glib::Container_Helpers::GListKeeper<> ************************/

template <typename Tr>
inline GListKeeper<Tr>::GListKeeper (const GList* glist, Glib::OwnershipType ownership)
:
  glist_ (const_cast<GList*> (glist)),
  ownership_ (ownership)
{}

template <typename Tr>
inline GListKeeper<Tr>::GListKeeper (const GListKeeper& keeper)
:
  glist_ (keeper.glist_),
  ownership_ (keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
GListKeeper<Tr>::~GListKeeper ()
{
  typedef typename Tr::CTypeNonConst CTypeNonConst;
  if (glist_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      for (GList* node = glist_; node; node = node->next)
      {
        Tr::release_c_type (static_cast<CTypeNonConst> (node->data));
      }
    }
    g_list_free (glist_);
  }
}

template <typename Tr>
inline GListKeeper<Tr>::operator GList* () const
{
  return glist_;
}

/**** Glib::Container_Helpers::GSListKeeper<> ************************/

template <typename Tr>
inline GSListKeeper<Tr>::GSListKeeper (const GSList* gslist, Glib::OwnershipType ownership)
:
  gslist_ (const_cast<GSList*> (gslist)),
  ownership_ (ownership)
{}

template <typename Tr>
inline GSListKeeper<Tr>::GSListKeeper (const GSListKeeper& keeper)
:
  gslist_ (keeper.gslist_),
  ownership_ (keeper.ownership_)
{
  keeper.ownership_ = Glib::OWNERSHIP_NONE;
}

template <typename Tr>
GSListKeeper<Tr>::~GSListKeeper ()
{
  typedef typename Tr::CTypeNonConst CTypeNonConst;
  if (gslist_ && ownership_ != Glib::OWNERSHIP_NONE)
  {
    if (ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      for (GSList* node = gslist_; node; node = node->next)
      {
        Tr::release_c_type (static_cast<CTypeNonConst> (node->data));
      }
    }
    g_slist_free (gslist_);
  }
}

template <typename Tr>
inline GSListKeeper<Tr>::operator GSList* () const
{
  return gslist_;
}

} // namespace Container_Helpers


/**** Glib::ArrayHandle<> **************************************************/
/*
template <class T, class Tr>
  template <class Cont>
inline
ArrayHandle<T,Tr>::ArrayHandle(const Cont& container)
:
  size_      (Glib::Container_Helpers::ArraySourceTraits<Tr,Cont>::get_size(container)),
  parray_    (Glib::Container_Helpers::ArraySourceTraits<Tr,Cont>::get_data(container, size_)),
  ownership_ (Glib::Container_Helpers::ArraySourceTraits<Tr,Cont>::initial_ownership)
{}

template <class T, class Tr> inline
ArrayHandle<T,Tr>::ArrayHandle(const typename ArrayHandle<T,Tr>::CType* array, size_t array_size,
                               Glib::OwnershipType ownership)
:
  size_      (array_size),
  parray_    (array),
  ownership_ (ownership)
{}

template <class T, class Tr> inline
ArrayHandle<T,Tr>::ArrayHandle(const typename ArrayHandle<T,Tr>::CType* array,
                               Glib::OwnershipType ownership)
:
  size_      ((array) ? Glib::Container_Helpers::compute_array_size(array) : 0),
  parray_    (array),
  ownership_ (ownership)
{}

template <class T, class Tr> inline
ArrayHandle<T,Tr>::ArrayHandle(const ArrayHandle<T,Tr>& other)
:
  size_      (other.size_),
  parray_    (other.parray_),
  ownership_ (other.ownership_)
{
  other.ownership_ = Glib::OWNERSHIP_NONE;
}

template <class T, class Tr>
ArrayHandle<T,Tr>::~ArrayHandle()
{
  if(ownership_ != Glib::OWNERSHIP_NONE)
  {
    if(ownership_ != Glib::OWNERSHIP_SHALLOW)
    {
      // Deep ownership: release each container element.
      const CType *const pend = parray_ + size_;
      for(const CType* p = parray_; p != pend; ++p)
        Tr::release_c_type(*p);
    }
    g_free(const_cast<CType*>(parray_));
  }
}

template <class T, class Tr> inline
typename ArrayHandle<T,Tr>::const_iterator ArrayHandle<T,Tr>::begin() const
{
  return Glib::Container_Helpers::ArrayIterator<Tr>(parray_);
}

template <class T, class Tr> inline
typename ArrayHandle<T,Tr>::const_iterator ArrayHandle<T,Tr>::end() const
{
  return Glib::Container_Helpers::ArrayIterator<Tr>(parray_ + size_);
}

template <class T, class Tr>
  template <class U>
inline
ArrayHandle<T,Tr>::operator std::vector<U>() const
{
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return std::vector<U>(this->begin(), this->end());
#else
  std::vector<U> temp;
  temp.reserve(this->size());
  Glib::Container_Helpers::fill_container(temp, this->begin(), this->end());
  return temp;
#endif
}

template <class T, class Tr>
  template <class U>
inline
ArrayHandle<T,Tr>::operator std::deque<U>() const
{
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return std::deque<U>(this->begin(), this->end());
#else
  std::deque<U> temp;
  Glib::Container_Helpers::fill_container(temp, this->begin(), this->end());
  return temp;
#endif
}

template <class T, class Tr>
  template <class U>
inline
ArrayHandle<T,Tr>::operator std::list<U>() const
{
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return std::list<U>(this->begin(), this->end());
#else
  std::list<U> temp;
  Glib::Container_Helpers::fill_container(temp, this->begin(), this->end());
  return temp;
#endif
}

template <class T, class Tr>
  template <class Cont>
inline
void ArrayHandle<T,Tr>::assign_to(Cont& container) const
{
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  container.assign(this->begin(), this->end());
#else
  Cont temp;
  Glib::Container_Helpers::fill_container(temp, this->begin(), this->end());
  container.swap(temp);
#endif
}

template <class T, class Tr>
  template <class Out>
inline
void ArrayHandle<T,Tr>::copy(Out pdest) const
{
  std::copy(this->begin(), this->end(), pdest);
}

template <class T, class Tr> inline
const typename ArrayHandle<T,Tr>::CType* ArrayHandle<T,Tr>::data() const
{
  return parray_;
}

template <class T, class Tr> inline
size_t ArrayHandle<T,Tr>::size() const
{
  return size_;
}

template <class T, class Tr> inline
bool ArrayHandle<T,Tr>::empty() const
{
  return (size_ == 0);
}
*/

template <typename T, class Tr>
typename VectorHandler<T, Tr>::VectorType
VectorHandler<T, Tr>::array_to_vector (const CType* array, size_t array_size, Glib::OwnershipType ownership)
{
  // it will handle destroying data depending on passed ownership.
  ArrayKeeperType keeper (array, array_size, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return VectorType (ArrayIteratorType (array), ArrayIteratorType (array + array_size));
#else
  VectorType temp;
  temp.reserve (array_size);
  Glib::Container_Helpers::fill_container (temp, ArrayIteratorType (array), ArrayIteratorType (array + array_size));
  return temp;
#endif
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::VectorType
VectorHandler<T, Tr>::array_to_vector(const CType* array, Glib::OwnershipType ownership)
{
  return array_to_vector (array, Glib::Container_Helpers::compute_array_size2 (array), ownership);
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::VectorType
VectorHandler<T, Tr>::list_to_vector (GList* glist, Glib::OwnershipType ownership)
{
  // it will handle destroying data depending on passed ownership.
  GListKeeperType keeper (glist, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return VectorType (ListIteratorType (glist), ListIteratorType (0));
#else
  VectorType temp;
  //temp.reserve (???);
  Glib::Container_Helpers::fill_container (temp, ListIteratorType (glist), ListIteratorType (0));
  return temp;
#endif
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::VectorType
VectorHandler<T, Tr>::slist_to_vector (GSList* gslist, Glib::OwnershipType ownership)
{
  // it will handle destroying data depending on passed ownership.
  GSListKeeperType keeper (gslist, ownership);
#ifdef GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS
  return VectorType (SListIteratorType (gslist), SListIteratorType (0));
#else
  VectorType temp;
  //temp.reserve (???);
  Glib::Container_Helpers::fill_container (temp, SListIteratorType (gslist), SListIteratorType (0));
  return temp;
#endif
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::ArrayKeeperType
VectorHandler<T, Tr>::vector_to_array (const VectorType& vector, Glib::OwnershipType ownership)
{
  return ArrayKeeperType (Glib::Container_Helpers::create_array2<Tr> (vector.begin (), vector.size ()), vector.size(), ownership);
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::GListKeeperType
VectorHandler<T, Tr>::vector_to_list (const VectorType& vector, Glib::OwnershipType ownership)
{
  return GListKeeperType (Glib::Container_Helpers::create_glist2<Tr> (vector.begin(), vector.end()), ownership);
}

template <typename T, class Tr>
typename VectorHandler<T, Tr>::GSListKeeperType
VectorHandler<T, Tr>::vector_to_slist (const VectorType& vector, Glib::OwnershipType ownership)
{
  return GSListKeeperType (Glib::Container_Helpers::create_gslist2<Tr> (vector.begin (), vector.end ()), ownership);
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib


#endif /* _GLIBMM_VECTORUTILS_H */

