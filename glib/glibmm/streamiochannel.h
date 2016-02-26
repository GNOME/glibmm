// -*- c++ -*-

/* Copyright (C) 2002 The gtkmm Development Team
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

#ifndef _GLIBMM_STREAMIOCHANNEL_H
#define _GLIBMM_STREAMIOCHANNEL_H

#include <glibmmconfig.h>
#include <glibmm/iochannel.h>
#include <iosfwd>

namespace Glib
{

#ifndef GLIBMM_DISABLE_DEPRECATED

/** @deprecated This whole class was deprecated in glibmm 2.2 - See the Glib::IOChannel
 * documentation for an explanation.
 */
class StreamIOChannel : public Glib::IOChannel
{
public:
  ~StreamIOChannel() noexcept override;

  static Glib::RefPtr<StreamIOChannel> create(std::istream& stream);
  static Glib::RefPtr<StreamIOChannel> create(std::ostream& stream);
  static Glib::RefPtr<StreamIOChannel> create(std::iostream& stream);

protected:
  std::istream* stream_in_;
  std::ostream* stream_out_;

  StreamIOChannel(std::istream* stream_in, std::ostream* stream_out);

  IOStatus read_vfunc(char* buf, gsize count, gsize& bytes_read) override;
  IOStatus write_vfunc(const char* buf, gsize count, gsize& bytes_written) override;
  IOStatus seek_vfunc(gint64 offset, SeekType type) override;
  IOStatus close_vfunc() override;
  IOStatus set_flags_vfunc(IOFlags flags) override;
  IOFlags get_flags_vfunc() override;
  Glib::RefPtr<Glib::Source> create_watch_vfunc(IOCondition cond) override;
};

#endif //#GLIBMM_DISABLE_DEPRECATED

} // namespace Glib

#endif /* _GLIBMM_STREAMIOCHANNEL_H */
