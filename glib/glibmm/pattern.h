#ifndef _GLIBMM_PATTERN_H
#define _GLIBMM_PATTERN_H

/* pattern.h
 *
 * Copyright (C) 2002 The gtkmm Development Team
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

extern "C" {
using GPatternSpec = struct _GPatternSpec;
}

#include <glibmm/ustring.h>

namespace Glib
{

/** @defgroup PatternMatching Glob-style Pattern Matching
 * Match strings against patterns containing '*' (wildcard) and '?' (joker).
 * @{
 */

class GLIBMM_API PatternSpec
{
public:
  explicit PatternSpec(const Glib::ustring& pattern);
  explicit PatternSpec(GPatternSpec* gobject);
  ~PatternSpec() noexcept;

  // noncopyable
  PatternSpec(const PatternSpec&) = delete;
  PatternSpec& operator=(const PatternSpec&) = delete;

  bool match(const Glib::ustring& str) const;
  bool match(const Glib::ustring& str, const Glib::ustring& str_reversed) const;

  bool operator==(const PatternSpec& rhs) const;
  bool operator!=(const PatternSpec& rhs) const;

  GPatternSpec* gobj() { return gobject_; }
  const GPatternSpec* gobj() const { return gobject_; }

private:
  GPatternSpec* gobject_;
};

/** @} group PatternMatching */

} // namespace Glib

#endif /* _GLIBMM_PATTERN_H */
