/* Copyright (C) 2017 The glibmm Development Team
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

#include <glibmm/extraclassinit.h>

namespace Glib
{

ExtraClassInit::ExtraClassInit(GClassInitFunc class_init_func, void* class_data,
  GInstanceInitFunc instance_init_func)
{
  if (class_init_func)
    add_custom_class_init_function(class_init_func, class_data);

  if (instance_init_func)
    set_custom_instance_init_function(instance_init_func);
}

} // namespace Glib
