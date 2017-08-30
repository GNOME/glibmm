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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/streamiochannel.h>
#include <glibmm/main.h> //For Source
#include <glib.h>
#include <fstream>
#include <iostream>

namespace Glib
{

#ifndef GLIBMM_DISABLE_DEPRECATED

// static
Glib::RefPtr<StreamIOChannel>
StreamIOChannel::create(std::istream& stream)
{
  return Glib::RefPtr<StreamIOChannel>(new StreamIOChannel(&stream, nullptr));
}

// static
Glib::RefPtr<StreamIOChannel>
StreamIOChannel::create(std::ostream& stream)
{
  return Glib::RefPtr<StreamIOChannel>(new StreamIOChannel(nullptr, &stream));
}

// static
Glib::RefPtr<StreamIOChannel>
StreamIOChannel::create(std::iostream& stream)
{
  return Glib::RefPtr<StreamIOChannel>(new StreamIOChannel(&stream, &stream));
}

StreamIOChannel::StreamIOChannel(std::istream* stream_in, std::ostream* stream_out)
: stream_in_(stream_in), stream_out_(stream_out)
{
  get_flags_vfunc(); // initialize GIOChannel flag bits
}

StreamIOChannel::~StreamIOChannel() noexcept
{
}

IOStatus
StreamIOChannel::read_vfunc(char* buf, gsize count, gsize& bytes_read)
{
  g_return_val_if_fail(stream_in_ != nullptr, IO_STATUS_ERROR);

  stream_in_->clear();
  stream_in_->read(buf, count);
  bytes_read = stream_in_->gcount();

  if (stream_in_->eof())
    return IO_STATUS_EOF;

  if (stream_in_->fail())
  {
    throw Glib::Error(G_IO_CHANNEL_ERROR, G_IO_CHANNEL_ERROR_FAILED, "Reading from stream failed");
  }

  return IO_STATUS_NORMAL;
}

IOStatus
StreamIOChannel::write_vfunc(const char* buf, gsize count, gsize& bytes_written)
{
  g_return_val_if_fail(stream_out_ != nullptr, IO_STATUS_ERROR);

  bytes_written = 0;

  stream_out_->clear();
  stream_out_->write(buf, count);

  if (stream_out_->fail())
  {
    throw Glib::Error(G_IO_CHANNEL_ERROR, G_IO_CHANNEL_ERROR_FAILED, "Writing to stream failed");
  }

  bytes_written = count; // all or nothing ;)

  return IO_STATUS_NORMAL;
}

IOStatus
StreamIOChannel::seek_vfunc(gint64 offset, SeekType type)
{
  std::ios::seekdir direction = std::ios::beg;

  switch (type)
  {
  case SEEK_TYPE_SET:
    direction = std::ios::beg;
    break;
  case SEEK_TYPE_CUR:
    direction = std::ios::cur;
    break;
  case SEEK_TYPE_END:
    direction = std::ios::end;
    break;
  }

  bool failed = false;

  if (stream_in_)
  {
    stream_in_->clear();
    stream_in_->seekg(offset, direction);
    failed = stream_in_->fail();
  }
  if (stream_out_)
  {
    stream_out_->clear();
    stream_out_->seekp(offset, direction);
    failed = (failed || stream_out_->fail());
  }

  if (failed)
  {
    throw Glib::Error(G_IO_CHANNEL_ERROR, G_IO_CHANNEL_ERROR_FAILED, "Seeking into stream failed");
  }

  return Glib::IO_STATUS_NORMAL;
}

IOStatus
StreamIOChannel::close_vfunc()
{
  bool failed = false;

  if (std::fstream* const fstream = dynamic_cast<std::fstream*>(stream_in_))
  {
    fstream->clear();
    fstream->close();
    failed = fstream->fail();
  }
  else if (std::ifstream* const ifstream = dynamic_cast<std::ifstream*>(stream_in_))
  {
    ifstream->clear();
    ifstream->close();
    failed = ifstream->fail();
  }
  else if (std::ofstream* const ofstream = dynamic_cast<std::ofstream*>(stream_out_))
  {
    ofstream->clear();
    ofstream->close();
    failed = ofstream->fail();
  }
  else
  {
    throw Glib::Error(
      G_IO_CHANNEL_ERROR, G_IO_CHANNEL_ERROR_FAILED, "Attempt to close non-file stream");
  }

  if (failed)
  {
    throw Glib::Error(G_IO_CHANNEL_ERROR, G_IO_CHANNEL_ERROR_FAILED, "Failed to close stream");
  }

  return IO_STATUS_NORMAL;
}

IOStatus StreamIOChannel::set_flags_vfunc(IOFlags)
{
  return IO_STATUS_NORMAL;
}

IOFlags
StreamIOChannel::get_flags_vfunc()
{
  gobj()->is_seekable = 1;
  gobj()->is_readable = (stream_in_ != nullptr);
  gobj()->is_writeable = (stream_out_ != nullptr);

  IOFlags flags = IO_FLAG_IS_SEEKABLE;

  if (stream_in_)
    flags |= IO_FLAG_IS_READABLE;
  if (stream_out_)
    flags |= IO_FLAG_IS_WRITEABLE;

  return flags;
}

Glib::RefPtr<Glib::Source> StreamIOChannel::create_watch_vfunc(IOCondition)
{
  g_warning("Glib::StreamIOChannel::create_watch_vfunc() not implemented");
  return Glib::RefPtr<Glib::Source>();
}

#endif // GLIBMM_DISABLE_DEPRECATED

} // namespace Glib
