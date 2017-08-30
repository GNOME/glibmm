#ifndef _GLIBMM_QUARK_H
#define _GLIBMM_QUARK_H

/* quark.h
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

#include <glibmmconfig.h>
#include <glibmm/ustring.h>
#include <glib.h>

namespace Glib
{

/** Quarks are unique IDs in Glib for strings for use in
 * hash table lookups.  Each Quark is unique but may change
 * between runs.
 *
 * QueryQuark is a converter class for looking up but not
 * allocating an ID.  An id means the quark lookup failed.
 *
 * Quark is used for actions for which the id should live on
 * While QueryQuark should be used for queries.
 * ie.
 *   void set_data (const Quark&, void * data);
 *   void* get_data (const QueryQuark&);
 */
class QueryQuark
{
public:
  QueryQuark(const GQuark& q);
  QueryQuark(const ustring& s);
  QueryQuark(const char* s);
  ~QueryQuark() noexcept {}
  QueryQuark& operator=(const QueryQuark& q);
  operator ustring() const;

  operator GQuark() const { return quark_; }
  GQuark id() const { return quark_; }

private:
  GQuark quark_;
};

class Quark : public QueryQuark
{
public:
  Quark(const ustring& s);
  Quark(const char* s);
  ~Quark() noexcept;
};

/** @relates Glib::QueryQuark */
inline bool
operator==(const QueryQuark& a, const QueryQuark& b)
{
  return a.id() == b.id();
}

/** @relates Glib::QueryQuark */
inline bool
operator!=(const QueryQuark& a, const QueryQuark& b)
{
  return a.id() != b.id();
}

#ifndef DOXYGEN_SHOULD_SKIP_THIS
// TODO: Put this somewhere else.
// (internal) The quark for C++ wrappers.
extern GLIBMM_API GQuark quark_;
extern GLIBMM_API GQuark quark_cpp_wrapper_deleted_;
#endif

} /* namespace Glib */

#endif /* _GLIBMM_QUARK_H */
