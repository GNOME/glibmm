#ifndef _GLIBMM_CONTAINERS_H
#define _GLIBMM_CONTAINERS_H

/* containers.h
 *
 * Copyright (C) 1998-2002 The gtkmm Development Team
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
#include <glibmm/sarray.h> /* for backward compatibility */
#include <glibmm/wrap.h>
#include <glib.h>
#include <iterator>
#include <cstddef>

#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace Glib
{

template <class T>
class List_Iterator;
template <class T>
class List_ConstIterator;
template <class T>
class List_ReverseIterator;

// Most of these methods in the non-template classes needs to be moved
// to implementation.

// Daniel Elstner has ideas about generating these per-widget with m4. murrayc.

extern GLIBMM_API gpointer glibmm_null_pointer;

template <class T>
class List_Iterator_Base
{
public:
  using value_type = T;
  using pointer = T*;
  using reference = T&;
};

/// For instance, List_Iterator< Gtk::Widget >
template <class T>
class List_Iterator : public List_Iterator_Base<T>
{
public:
  using iterator_category = std::bidirectional_iterator_tag;
  using size_type = std::size_t;
  using difference_type = std::ptrdiff_t;

  using pointer = typename List_Iterator_Base<T>::pointer;
  using reference = typename List_Iterator_Base<T>::reference;

  GList* const* head_;
  GList* node_;

  using Self = List_Iterator<T>;

  List_Iterator(GList* const& head, GList* node) : head_(&head), node_(node) {}

  List_Iterator() : head_(nullptr), node_(nullptr) {}

  List_Iterator(const Self& src) : head_(src.head_), node_(src.node_) {}

  bool operator==(const Self& src) const { return node_ == src.node_; }
  bool operator!=(const Self& src) const { return node_ != src.node_; }

  Self& operator++()
  {
    if (!node_)
      node_ = g_list_first(*head_);
    else
      node_ = (GList*)g_list_next(node_);
    return *this;
  }

  Self operator++(int)
  {
    Self tmp = *this;
    ++*this;
    return tmp;
  }

  Self& operator--()
  {
    if (!node_)
      node_ = g_list_last(*head_);
    else
      node_ = (GList*)g_list_previous(node_);

    return *this;
  }

  Self operator--(int)
  {
    Self tmp = *this;
    --*this;
    return tmp;
  }

  reference operator*() const { return *(pointer)(node_ ? node_->data : glibmm_null_pointer); }

  pointer operator->() const { return &**this; }
};

/// For instance, SList_Iterator< Gtk::Widget >
template <class T>
class SList_Iterator : public List_Iterator_Base<T>
{
public:
  using iterator_category = std::forward_iterator_tag;
  using size_type = std::size_t;
  using difference_type = std::ptrdiff_t;

  using pointer = typename List_Iterator_Base<T>::pointer;
  using reference = typename List_Iterator_Base<T>::reference;

  GSList* node_;
  using Self = SList_Iterator<T>;

  SList_Iterator(GSList* node) : node_(node) {}

  SList_Iterator() : node_(nullptr) {}

  SList_Iterator(const Self& src) : node_(src.node_) {}

  bool operator==(const Self& src) const { return node_ == src.node_; }
  bool operator!=(const Self& src) const { return node_ != src.node_; }

  Self& operator++()
  {
    node_ = g_slist_next(node_);
    return *this;
  }

  Self operator++(int)
  {
    Self tmp = *this;
    ++*this;
    return tmp;
  }

  reference operator*() const
  {
    return reinterpret_cast<T&>(node_ ? node_->data : glibmm_null_pointer);
  }

  pointer operator->() const { return &**this; }
};

// This iterator variation returns T_IFace (wrapped from T_Impl)
// For instance,  List_Cpp_Iterator<GtkWidget, Gtk::Widget> is
// a little like std::list<Gtk::Widget>::iterator
template <class T_Impl, class T_IFace>
class List_Cpp_Iterator : public List_Iterator_Base<T_IFace>
{
public:
  using iterator_category = std::bidirectional_iterator_tag;
  using size_type = std::size_t;
  using difference_type = std::ptrdiff_t;

  using pointer = typename List_Iterator_Base<T_IFace>::pointer;
  using reference = typename List_Iterator_Base<T_IFace>::reference;

  using Self = List_Cpp_Iterator<T_Impl, T_IFace>;

  GList** head_;
  GList* node_;

  bool operator==(const Self& src) const { return node_ == src.node_; }
  bool operator!=(const Self& src) const { return node_ != src.node_; }

  List_Cpp_Iterator(GList*& head, GList* node) : head_(&head), node_(node) {}

  List_Cpp_Iterator() : head_(nullptr), node_(nullptr) {}

  List_Cpp_Iterator(const Self& src) : head_(src.head_), node_(src.node_) {}

  reference operator*() const
  {
    if (node_ && node_->data)
    {
      // We copy/paste the widget wrap() implementation here,
      // because we can not use a specific Glib::wrap(T_Impl) overload here,
      // because that would be "dependent", and g++ 3.4 does not allow that.
      // The specific Glib::wrap() overloads don't do anything special anyway.
      GObject* cobj = static_cast<GObject*>(node_->data);

#ifdef GLIBMM_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION
      return *dynamic_cast<pointer>(Glib::wrap_auto(cobj, false));
#else
      // We really do need to use dynamic_cast<>, so I expect problems if this code is used.
      // murrayc.
      return *static_cast<pointer>(Glib::wrap_auto(cobj, false));
#endif
    }
    return *static_cast<pointer>(nullptr); // boom!
  }

  pointer operator->() const { return &**this; }

  Self& operator++()
  {
    if (!node_)
      node_ = g_list_first(*head_);
    else
      node_ = (GList*)g_list_next(node_);

    return *this;
  }

  Self operator++(int)
  {
    Self tmp = *this;
    ++*this;
    return tmp;
  }

  Self& operator--()
  {
    if (!node_)
      node_ = g_list_last(*head_);
    else
      node_ = (GList*)g_list_previous(node_);

    return *this;
  }

  Self operator--(int)
  {
    Self tmp = *this;
    --*this;
    return tmp;
  }
};

template <class T_Base>
class List_ReverseIterator : private T_Base
{
public:
  using iterator_category = typename T_Base::iterator_category;
  using size_type = typename T_Base::size_type;
  using difference_type = typename T_Base::difference_type;

  using value_type = typename T_Base::value_type;
  using pointer = typename T_Base::pointer;
  using reference = typename T_Base::reference;

  using Self = List_ReverseIterator<T_Base>;

  bool operator==(const Self& src) const { return T_Base::operator==(src); }
  bool operator!=(const Self& src) const { return T_Base::operator!=(src); }

  List_ReverseIterator(GList* const& head, GList* node) : T_Base(head, node) {}

  List_ReverseIterator() : T_Base() {}

  List_ReverseIterator(const Self& src) : T_Base(src) {}

  List_ReverseIterator(const T_Base& src) : T_Base(src) { ++(*this); }

  Self& operator++()
  {
    T_Base::operator--();
    return *this;
  }
  Self& operator--()
  {
    T_Base::operator++();
    return *this;
  }
  Self operator++(int)
  {
    Self src = *this;
    T_Base::operator--();
    return src;
  }
  Self operator--(int)
  {
    Self src = *this;
    T_Base::operator++();
    return src;
  }

  reference operator*() const { return T_Base::operator*(); }
  pointer operator->() const { return T_Base::operator->(); }
};

template <class T_Base>
class List_ConstIterator : public T_Base
{
public:
  using iterator_category = typename T_Base::iterator_category;
  using size_type = typename T_Base::size_type;
  using difference_type = typename T_Base::difference_type;

  using value_type = const typename T_Base::value_type;
  using pointer = const typename T_Base::pointer;
  using reference = const typename T_Base::reference;

  using Self = List_ConstIterator<T_Base>;

  bool operator==(const Self& src) const { return T_Base::operator==(src); }
  bool operator!=(const Self& src) const { return T_Base::operator!=(src); }

  List_ConstIterator(GList* const& head, GList* node) : T_Base(head, node) {}

  List_ConstIterator() : T_Base() {}

  List_ConstIterator(const Self& src) : T_Base(src) {}

  List_ConstIterator(const T_Base& src) : T_Base(src) {}

  Self& operator++()
  {
    T_Base::operator++();
    return *this;
  }
  Self& operator--()
  {
    T_Base::operator--();
    return *this;
  }
  Self operator++(int)
  {
    Self src = *this;
    T_Base::operator++();
    return src;
  }
  Self operator--(int)
  {
    Self src = *this;
    T_Base::operator--();
    return src;
  }

  reference operator*() const { return T_Base::operator*(); }
  pointer operator->() const { return T_Base::operator->(); }
};

} // namespace Glib

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _GLIBMM_CONTAINERS_H */
