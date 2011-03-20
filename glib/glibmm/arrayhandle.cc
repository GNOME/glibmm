/* Copyright (C) 2011 The glibmm Development Team
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

#include <glibmm/arrayhandle.h>

namespace Glib
{

ArrayHandle<bool,Container_Helpers::TypeTraits<bool> >::~ArrayHandle()
{
  if(parray_ && ownership_ != Glib::OWNERSHIP_NONE)
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

} // namespace Glib
