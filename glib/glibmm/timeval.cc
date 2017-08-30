/* timeval.cc
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

#include <glibmm/timeval.h>

namespace Glib
{

void
TimeVal::assign_current_time()
{
  g_get_current_time(this);
}

bool
TimeVal::assign_from_iso8601(const Glib::ustring& iso_date)
{
  return g_time_val_from_iso8601(iso_date.c_str(), this);
}

void
TimeVal::add(const TimeVal& rhs)
{
  g_return_if_fail(tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);
  g_return_if_fail(rhs.tv_usec >= 0 && rhs.tv_usec < G_USEC_PER_SEC);

  tv_usec += rhs.tv_usec;

  if (tv_usec >= G_USEC_PER_SEC)
  {
    tv_usec -= G_USEC_PER_SEC;
    ++tv_sec;
  }

  tv_sec += rhs.tv_sec;
}

void
TimeVal::subtract(const TimeVal& rhs)
{
  g_return_if_fail(tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);
  g_return_if_fail(rhs.tv_usec >= 0 && rhs.tv_usec < G_USEC_PER_SEC);

  tv_usec -= rhs.tv_usec;

  if (tv_usec < 0)
  {
    tv_usec += G_USEC_PER_SEC;
    --tv_sec;
  }

  tv_sec -= rhs.tv_sec;
}

void
TimeVal::add_seconds(long seconds)
{
  g_return_if_fail(tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);

  tv_sec += seconds;
}

void
TimeVal::subtract_seconds(long seconds)
{
  g_return_if_fail(tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);

  tv_sec -= seconds;
}

void
TimeVal::add_milliseconds(long milliseconds)
{
  g_return_if_fail(tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);

  tv_usec += (milliseconds % 1000) * 1000;

  if (tv_usec < 0)
  {
    tv_usec += G_USEC_PER_SEC;
    --tv_sec;
  }
  else if (tv_usec >= G_USEC_PER_SEC)
  {
    tv_usec -= G_USEC_PER_SEC;
    ++tv_sec;
  }

  tv_sec += milliseconds / 1000;
}

void
TimeVal::subtract_milliseconds(long milliseconds)
{
  add_milliseconds(-1 * milliseconds);
}

void
TimeVal::add_microseconds(long microseconds)
{
  g_time_val_add(this, microseconds);
}

void
TimeVal::subtract_microseconds(long microseconds)
{
  g_time_val_add(this, -1 * microseconds);
}

Glib::ustring
TimeVal::as_iso8601() const
{
  gchar* retval = g_time_val_to_iso8601(const_cast<Glib::TimeVal*>(this));
  if (retval)
  {
    Glib::ustring iso_date(retval);
    g_free(retval);
    return iso_date;
  }
  return Glib::ustring();
}

} // namespace Glib
