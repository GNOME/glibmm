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
 * See the "Memory Management" section in the "Programming with gtkmm"
 * book for further information.
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
