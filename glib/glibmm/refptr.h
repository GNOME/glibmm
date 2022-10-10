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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmmconfig.h>
#include <glib.h>
#include <memory>

namespace Glib
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <class T_CppObject>
void RefPtrDeleter(T_CppObject* object)
{
  if (!object)
    return;

  object->unreference();
}
#endif // DOXYGEN_SHOULD_SKIP_THIS

// RefPtr is put in a group, because a group (but not a 'using' alias)
// gets its own html file, which can be referred to from outside glibmm,
// for instance from the gtkmm tutorial.
// Without a group, Doxygen generates links to the 'using' alias such as
// .../html/namespaceGlib.html#afa2fecfa732e9ec1107ace03a2911d63
/** @defgroup RefPtr RefPtr
 * A reference-counting shared smartpointer
 */

/** RefPtr<> is a reference-counting shared smartpointer.
 *
 * Some objects in gtkmm are obtained from a shared
 * store. Consequently you cannot instantiate them yourself. Instead they
 * return a RefPtr which behaves much like an ordinary pointer in that members
 * can be reached with the usual <code>object_ptr->member</code> notation.
 *
 * Reference counting means that a shared reference count is incremented each
 * time a RefPtr is copied, and decremented each time a RefPtr is destroyed,
 * for instance when it leaves its scope. When the reference count reaches
 * zero, the contained object is deleted, meaning  you don't need to remember
 * to delete the object.
 *
 * RefPtr is a std::shared_ptr with a special deleter. To cast a RefPtr<SomeType>
 * to a RefPtr<SomeOtherType>, use one of the standard library functions that
 * apply a cast to the stored pointer, for instance std::dynamic_pointer_cast.
 *
 * Example:
 * @code
 * Glib::RefPtr<const Gio::ListModel> monitors = Gdk::Display::get_default()->get_monitors();
 * Glib::RefPtr<const Glib::ObjectBase> first_object = monitors->get_object(0);
 * Glib::RefPtr<const Gdk::Monitor> first_monitor =
 *  std::dynamic_pointer_cast<const Gdk::Monitor>(first_object);
 * @endcode
 *
 * See the "Memory Management" section in the "Programming with gtkmm"
 * book for further information.
 *
 * @see Glib::make_refptr_for_instance()
 * if you need to implement a create() method for a %Glib::ObjectBase-derived class.
 *
 * @ingroup RefPtr
 */
template <class T_CppObject>
using RefPtr = std::shared_ptr<T_CppObject>;

/* This would not be useful,
 * because application code should not new these objects anyway.
 * And it is not useful inside glibmm or gtkmm code because
 * the constructors are protected, so can't be called from this utilility
 * function.
 *
template <class T_CppObject, class... T_Arg>
RefPtr<T_CppObject>
make_refptr(T_Arg... arg)
{
  return RefPtr<T_CppObject>(new T_CppObject(arg...));
}
*/

/** Create a RefPtr<> to an instance of any class that has reference() and
 * unreference() methods, and whose destructor is noexcept (the default for destructors).
 *
 * In gtkmm, that is anything derived from Glib::ObjectBase, such as
 * Gdk::Pixbuf.
 *
 * Normal application code should not need to use this. However, this is necessary
 * when implementing create() methods for derived Glib::ObjectBase-derived
 * (not Gtk::Widget-derived) classes, such as derived Gtk::TreeModels.
 */
template <class T_CppObject>
RefPtr<T_CppObject>
make_refptr_for_instance(T_CppObject* object)
{
  return RefPtr<T_CppObject>(object, &RefPtrDeleter<T_CppObject>);
}

} // namespace Glib

#endif /* _GLIBMM_REFPTR_H */
