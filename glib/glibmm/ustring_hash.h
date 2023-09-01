#ifndef _GLIBMM_USTRING_HASH_H
#define _GLIBMM_USTRING_HASH_H

/* Copyright (C) 2023 The glibmm Development Team
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
#include <functional> // For std::hash

/** @page ustringhash File ustring_hash.h
 * Specialization of std::hash for Glib::ustring.
 *
 * Makes it possible to use Glib::ustring as the key in
 * std::unordered_map/multimap/set/multiset.
 *
 * This file is not included by #include <glibmm.h>.
 * If you need it, you must add #include <glibmm/ustring_hash.h>.
 *
 * @newin{2,78}
 */
#ifndef DOXYGEN_SHOULD_SKIP_THIS
namespace std
{
/* Specialization of std::hash for Glib::ustring.
 * Makes it possible to use Glib::ustring as the key in
 * std::unordered_map/multimap/set/multiset.
 * @newin{2,78}
 */
template <>
struct hash<Glib::ustring>
{
  size_t operator()(const Glib::ustring& k) const noexcept
  {
    return std::hash<std::string>{}(k.raw());
  }
};
} // namespace std
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _GLIBMM_USTRING_HASH_H */
