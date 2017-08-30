/* Copyright (C) 2004 The glibmm Development Team
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

#include "fdstream.h"

#include <glibmm/main.h>

fdstreambuf::fdstreambuf()
{
  reset();
}

fdstreambuf::fdstreambuf(int fd, bool manage)
{
  create_iochannel(fd, manage);
}

fdstreambuf::~fdstreambuf()
{
  sync();
}

void
fdstreambuf::reset()
{
  setg(putback_buffer + 1, putback_buffer + 1, putback_buffer + 1);
  error_condition.error = false;
}

void
fdstreambuf::create_iochannel(int fd, bool manage)
{
  sync();
  reset();

  if (fd >= 0)
  {
    iochannel_ = Glib::IOChannel::create_from_fd(fd);

    iochannel_->set_encoding("");

    iochannel_->set_buffered(true);
    iochannel_->set_close_on_unref(manage);
  }
}

void
fdstreambuf::detach_fd()
{
  iochannel_->set_close_on_unref(false);
}

void
fdstreambuf::connect(
  const sigc::slot<bool(Glib::IOCondition)>& callback, Glib::IOCondition condition)
{
  Glib::signal_io().connect(callback, iochannel_, condition);
}

fdstream_error
fdstreambuf::get_error() const
{
  return error_condition;
}

// the standard requires sync to return 0 for success and -1 for error
int
fdstreambuf::sync()
{
  if (!iochannel_)
    return -1;

  try
  {
    iochannel_->flush();
  }
  catch (Glib::IOChannelError& io_error)
  {
    error_condition.error = true;
    error_condition.code = io_error.code();
    return -1;
  }

  return 0;
}

void
fdstreambuf::close_iochannel()
{
  iochannel_->set_close_on_unref(false);
  reset();

  try
  {
    iochannel_->close(true);
  }
  catch (Glib::IOChannelError& io_error)
  {
    error_condition.error = true;
    error_condition.code = io_error.code();
  }
}

// the standard requires this to return either the character
// written on overflow or traits_type::eof() (= EOF with char_type == char)
fdstreambuf::traits_type::int_type
fdstreambuf::overflow(int_type c)
{
  if (!traits_type::eq_int_type(c, traits_type::eof()))
  {
    try
    {
      gsize result = 0;
      char write_char = c;
      iochannel_->write(&write_char, 1, result);
    }
    catch (Glib::IOChannelError& io_error)
    {
      error_condition.error = true;
      error_condition.code = io_error.code();
      return traits_type::eof();
    }
  }
  return traits_type::not_eof(c);
}

// the standard requires this to return the number of characters written
// (which will be 0 for stream failure - it is not correct to return EOF)
std::streamsize
fdstreambuf::xsputn(const char* source, std::streamsize num)
{
  gsize result = 0;

  // the documentation for Glib::IOChannel indicates that Glib::IOChannel::write()
  // will only do a short write in the event of stream failure, so there is no
  // need to check result and have a second bite (byte) at it as would be
  // necessary with Unix write()
  try
  {
    iochannel_->write(source, num, result);
  }
  catch (Glib::IOChannelError& io_error)
  {
    error_condition.error = true;
    error_condition.code = io_error.code();
    result = 0;
  }

  return result;
}

// the standard requires this to return the first character available
// on underflow or traits_type::eof() (= EOF with char_type == char)
fdstreambuf::traits_type::int_type
fdstreambuf::underflow()
{
  if (gptr() < egptr())
    return traits_type::to_int_type(*gptr());

  // copy the character in bump position (if any) to putback position
  if (gptr() - eback())
    *putback_buffer = *(gptr() - 1);

  // now insert a character into the bump position
  gsize result = 0;
  try
  {
    iochannel_->read(putback_buffer + 1, 1, result);
  }
  catch (Glib::IOChannelError& io_error)
  {
    error_condition.error = true;
    error_condition.code = io_error.code();
    return traits_type::eof();
  }

  // some other error - is this possible?  In case it is, cater for it
  if (result == 0)
    return traits_type::eof();

  // reset buffer pointers
  setg(putback_buffer, putback_buffer + 1, putback_buffer + 2);

  // return character in bump/peek position
  return traits_type::to_int_type(*gptr()); // == *(putback_buffer + 1)
}

// the standard requires this to return the number of characters fetched
// (which will be 0 for stream failure - it is not correct to return EOF)
std::streamsize
fdstreambuf::xsgetn(char* dest, std::streamsize num)
{
  std::streamsize chars_read = 0;

  // available would normally be 0, but could be up to 2 if there
  // have been putbacks or a peek and a putback
  std::streamsize available = egptr() - gptr();

  // if num is less than or equal to the characters already in the
  // putback buffer, extract from buffer
  if (num <= available)
  {
    traits_type::copy(dest, gptr(), num);
    gbump(num);
    chars_read = num;
  }
  else
  {
    // first copy out putback buffer
    if (available)
    {
      traits_type::copy(dest, gptr(), available);
      chars_read = available;
    }

    // read up to everything else we need with Glib::IOChannel::read()
    gsize result = 0;
    try
    {
      do
      {
        iochannel_->read(dest + chars_read, num - chars_read, result);

        if (result > 0)
          chars_read += result;
      } while (result > 0 && result < static_cast<gsize>(num - chars_read));
    }
    catch (Glib::IOChannelError& io_error)
    {
      error_condition.error = true;

      error_condition.code = io_error.code();
      return chars_read;
    }

    if (chars_read)
    {
      // now mimic extraction of all characters by sbumpc() by putting
      // two characters into the buffer (if available) and resetting the
      // buffer pointers
      int putback_count = 0;
      if (chars_read >= 2)
      {
        *putback_buffer = *(dest + (chars_read - 2));
        putback_count = 2;
      }
      else
      { // if we have reached here then we have only fetched
        // one character and it must have been read with
        // Glib::IOChannel::read() and not taken from the
        // putback buffer - otherwise we would have ended
        // at the first if block in this method
        // - and this also means that gptr() == egptr()
        if (gptr() - eback())
        {
          *putback_buffer = *(gptr() - 1);
          putback_count = 2;
        }
        else
          putback_count = 1;
      }

      *(putback_buffer + 1) = *(dest + (chars_read - 1));

      // reset buffer pointers
      this->setg(putback_buffer + (2 - putback_count), putback_buffer + 2, putback_buffer + 2);
    }
  }
  return chars_read;
}

fdstream::fdstream(int fd, bool manage)
: std::istream(nullptr), std::ostream(nullptr), buf(fd, manage)
{
  std::istream::rdbuf(&buf);
  std::ostream::rdbuf(&buf);
}

fdstream::fdstream() : std::istream(nullptr), std::ostream(nullptr)
{
  std::istream::rdbuf(&buf);
  std::ostream::rdbuf(&buf);
}

void
fdstream::attach(int fd, bool manage)
{
  buf.create_iochannel(fd, manage);
}

void
fdstream::detach()
{
  buf.detach_fd();
}

void
fdstream::close()
{
  buf.close_iochannel();
}

void
fdstream::connect(const sigc::slot<bool(Glib::IOCondition)>& callback, Glib::IOCondition condition)
{
  buf.connect(callback, condition);
}

fdstream_error
fdstream::get_error() const
{
  return buf.get_error();
}
