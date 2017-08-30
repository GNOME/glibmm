#ifndef _GLIBMM_TIMEVAL_H
#define _GLIBMM_TIMEVAL_H

/* timeval.h
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
#include <glibmm/ustring.h>

namespace Glib
{

/** Glib::TimeVal is a wrapper around the glib structure GTimeVal.
 * The glib structure GTimeVal itself is equivalent to struct timeval,
 * which is returned by the gettimeofday() UNIX call. Additionally
 * this wrapper provides an assortment of time manipulation functions.
 */
struct TimeVal : public GTimeVal
{
  inline TimeVal();
  inline TimeVal(long seconds, long microseconds);

  inline TimeVal(const GTimeVal& gtimeval);
  inline TimeVal& operator=(const GTimeVal& gtimeval);

  /** Assigns the current time to the TimeVal instance.
   * Equivalent to the UNIX gettimeofday() function, but is portable and
   * works also on Win32.
   */
  void assign_current_time();

  /** Converts a string containing an ISO 8601 encoded date and time
   * to a Glib::TimeVal and puts it in TimeVal instance.
   * @param iso_date ISO 8601 encoded string.
   * @return <tt>true</tt> if conversion was successful.
   *
   * @newin{2,22}
   */
  bool assign_from_iso8601(const Glib::ustring& iso_date);

  void add(const TimeVal& rhs);
  void subtract(const TimeVal& rhs);
  void add_seconds(long seconds);
  void subtract_seconds(long seconds);
  void add_milliseconds(long milliseconds);
  void subtract_milliseconds(long milliseconds);
  void add_microseconds(long microseconds);
  void subtract_microseconds(long microseconds);

  inline TimeVal& operator+=(const TimeVal& gtimeval);
  inline TimeVal& operator-=(const TimeVal& gtimeval);
  inline TimeVal& operator+=(long seconds);
  inline TimeVal& operator-=(long seconds);

  /** Returns a double representation of the time interval.
   * This member function converts the time interval, that is
   * internally stored as two long values for seconds and microseconds,
   * to a double representation, whose unit is seconds.
   */
  inline double as_double() const;

  /** Returns an ISO 8601 encoded string, relative to the Coordinated
   * Universal Time (UTC).
   *
   * @newin{2,22}
   */
  Glib::ustring as_iso8601() const;

  inline bool negative() const;

  /** Checks whether the stored time interval is positive.
   * Returns true if the stored time / time interval is positive.
   */
  inline bool valid() const;
};

inline TimeVal::TimeVal()
{
  tv_sec = 0;
  tv_usec = 0;
}

inline TimeVal::TimeVal(long seconds, long microseconds)
{
  tv_sec = seconds;
  tv_usec = microseconds;
}

inline TimeVal::TimeVal(const GTimeVal& gtimeval)
{
  tv_sec = gtimeval.tv_sec;
  tv_usec = gtimeval.tv_usec;
}

inline TimeVal&
TimeVal::operator=(const GTimeVal& gtimeval)
{
  tv_sec = gtimeval.tv_sec;
  tv_usec = gtimeval.tv_usec;
  return *this;
}

inline TimeVal&
TimeVal::operator+=(const TimeVal& gtimeval)
{
  add(gtimeval);

  return *this;
}

inline TimeVal&
TimeVal::operator-=(const TimeVal& gtimeval)
{
  subtract(gtimeval);

  return *this;
}

inline TimeVal&
TimeVal::operator+=(long seconds)
{
  add_seconds(seconds);

  return *this;
}

inline TimeVal&
TimeVal::operator-=(long seconds)
{
  subtract_seconds(seconds);

  return *this;
}

inline double
TimeVal::as_double() const
{
  return double(tv_sec) + double(tv_usec) / double(G_USEC_PER_SEC);
}

inline bool
TimeVal::negative() const
{
  return (tv_sec < 0);
}

inline bool
TimeVal::valid() const
{
  return (tv_usec >= 0 && tv_usec < G_USEC_PER_SEC);
}

/** @relates Glib::TimeVal */
inline TimeVal
operator+(const TimeVal& lhs, const TimeVal& rhs)
{
  return TimeVal(lhs) += rhs;
}

/** @relates Glib::TimeVal */
inline TimeVal
operator+(const TimeVal& lhs, long seconds)
{
  return TimeVal(lhs) += seconds;
}

/** @relates Glib::TimeVal */
inline TimeVal
operator-(const TimeVal& lhs, const TimeVal& rhs)
{
  return TimeVal(lhs) -= rhs;
}

/** @relates Glib::TimeVal */
inline TimeVal
operator-(const TimeVal& lhs, long seconds)
{
  return TimeVal(lhs) -= seconds;
}

/** @relates Glib::TimeVal */
inline bool
operator==(const TimeVal& lhs, const TimeVal& rhs)
{
  return (lhs.tv_sec == rhs.tv_sec && lhs.tv_usec == rhs.tv_usec);
}

/** @relates Glib::TimeVal */
inline bool
operator!=(const TimeVal& lhs, const TimeVal& rhs)
{
  return (lhs.tv_sec != rhs.tv_sec || lhs.tv_usec != rhs.tv_usec);
}

/** @relates Glib::TimeVal */
inline bool
operator<(const TimeVal& lhs, const TimeVal& rhs)
{
  return ((lhs.tv_sec < rhs.tv_sec) || (lhs.tv_sec == rhs.tv_sec && lhs.tv_usec < rhs.tv_usec));
}

/** @relates Glib::TimeVal */
inline bool
operator>(const TimeVal& lhs, const TimeVal& rhs)
{
  return ((lhs.tv_sec > rhs.tv_sec) || (lhs.tv_sec == rhs.tv_sec && lhs.tv_usec > rhs.tv_usec));
}

/** @relates Glib::TimeVal */
inline bool
operator<=(const TimeVal& lhs, const TimeVal& rhs)
{
  return ((lhs.tv_sec < rhs.tv_sec) || (lhs.tv_sec == rhs.tv_sec && lhs.tv_usec <= rhs.tv_usec));
}

/** @relates Glib::TimeVal */
inline bool
operator>=(const TimeVal& lhs, const TimeVal& rhs)
{
  return ((lhs.tv_sec > rhs.tv_sec) || (lhs.tv_sec == rhs.tv_sec && lhs.tv_usec >= rhs.tv_usec));
}

} // namespace Glib

#endif /* _GLIBMM_TIMEVAL_H */
