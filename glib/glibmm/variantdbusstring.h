#ifndef _GLIBMM_VARIANT_DBUS_STRING_H
#define _GLIBMM_VARIANT_DBUS_STRING_H
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

#include <glibmm/ustring.h>

namespace Glib
{

/** String class for D-Bus object paths in Glib::Variant.
 *
 * Use it if you want to create a Glib::Variant with D-Bus object paths.
 *
 * @code
 * using opstring_with_string_t =
 *   std::map<Glib::DBusObjectPathString, Glib::Variant<Glib::ustring>>;
 * opstring_with_string_t map1;
 * map1["/map1/path1"] = Glib::Variant<Glib::ustring>::create("value1");
 * auto variant1 = Glib::Variant<opstring_with_string_t>::create(map1);
 * @endcode
 *
 * @newin{2,54}
 * @ingroup Variant
*/
class GLIBMM_API DBusObjectPathString : public Glib::ustring
{
public:
  using Glib::ustring::ustring;
};

/** String class for D-Bus signatures in Glib::Variant.
 *
 * Use it if you want to create a Glib::Variant with a D-Bus signature.
 *
 * @code
 * auto variant = Glib::Variant<Glib::DBusSignatureString>::create("s");
 * @endcode
 *
 * @newin{2,54}
 * @ingroup Variant
*/
class GLIBMM_API DBusSignatureString : public Glib::ustring
{
public:
  using Glib::ustring::ustring;
};

} // namespace Glib

#endif /* _GLIBMM_VARIANT_DBUS_STRING_H */
