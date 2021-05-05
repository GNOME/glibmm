/* pattern.cc
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

#include <glib.h>
#include <glibmm/pattern.h>

namespace Glib
{

PatternSpec::PatternSpec(const Glib::ustring& pattern)
: gobject_(g_pattern_spec_new(pattern.c_str()))
{
}

PatternSpec::PatternSpec(GPatternSpec* gobject) : gobject_(gobject)
{
}

PatternSpec::~PatternSpec() noexcept
{
  g_pattern_spec_free(gobject_);
}

// g_pattern_match() is deprecated in glib 2.70.
// Its replacement, g_pattern_spec_match(), is new in glib 2.70.
G_GNUC_BEGIN_IGNORE_DEPRECATIONS
bool
PatternSpec::match(const Glib::ustring& str) const
{
  return g_pattern_match(gobject_, str.bytes(), str.c_str(), nullptr);
}

bool
PatternSpec::match(const Glib::ustring& str, const Glib::ustring& str_reversed) const
{
  return g_pattern_match(gobject_, str.bytes(), str.c_str(), str_reversed.c_str());
}
G_GNUC_END_IGNORE_DEPRECATIONS

bool
PatternSpec::operator==(const PatternSpec& rhs) const
{
  return g_pattern_spec_equal(gobject_, rhs.gobject_);
}

bool
PatternSpec::operator!=(const PatternSpec& rhs) const
{
  return !g_pattern_spec_equal(gobject_, rhs.gobject_);
}

} // namespace Glib
