#ifndef _GLIBMM_EXCEPTION_H
#define _GLIBMM_EXCEPTION_H

/* exception.h
 *
 * Copyright 2002 The gtkmm Development Team
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

#include <glibmm/ustring.h>

namespace Glib
{

class Exception
{
public:
  virtual ~Exception() noexcept = 0;
  virtual Glib::ustring what() const = 0;
};

} // namespace Glib

#endif /* _GLIBMM_EXCEPTION_H */
