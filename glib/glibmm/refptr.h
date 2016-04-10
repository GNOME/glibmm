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

template <class T_CppObject>
void RefPtrDeleter(T_CppObject* object)
{
  if (!object)
    return;

  object->unreference();
}

template <class T_CppObject>
using RefPtr = std::shared_ptr<T_CppObject>;

template <class T_CppObject>
RefPtr<T_CppObject>
make_refptr_for_instance(T_CppObject* object)
{
  return RefPtr<T_CppObject>(object, &RefPtrDeleter<T_CppObject>);
}

} // namespace Glib

#endif /* _GLIBMM_REFPTR_H */
