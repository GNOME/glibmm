/* Copyright (C) 2004 The glibmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef GLIBMMEXAMPLE_FDSTREAM_H
#define GLIBMMEXAMPLE_FDSTREAM_H

#include <istream>
#include <ostream>
#include <streambuf>
#include <glibmm/iochannel.h>

class fdstreambuf : public std::streambuf
{
public:
  fdstreambuf(int fd, bool manage, bool convert);
  fdstreambuf();

  // see comments in fdstream class definition about the convert argument
  // in fdstreambuf::fdstreambuf() and fdstreambuf::create_iochannel
  void create_iochannel(int fd, bool manage, bool convert);
  void close_iochannel();
  void connect(const sigc::slot<bool, Glib::IOCondition>& callback, Glib::IOCondition condition);


protected:
  virtual int_type underflow();
  virtual std::streamsize xsgetn(char* dest, std::streamsize num);
  virtual int sync();
  virtual int_type overflow(int_type c);
  virtual std::streamsize xsputn(const char* source, std::streamsize num);

private:
  Glib::RefPtr<Glib::IOChannel> iochannel_;
  bool manage_;

  // pushback_buffer does not do any buffering: it reserves one character
  // for pushback and one character for a peek() and/or for bumping
  // with sbumpc/uflow()
  char_type pushback_buffer[2];

  void reset() {
    setg(pushback_buffer + 1, pushback_buffer + 1, pushback_buffer + 1);
  }
};

class fdstream : 
  public std::istream, 
  public std::ostream
{
public:

  explicit fdstream(int fd, bool manage = true, bool convert = false);
  fdstream();

  // NOTE: in fdstream::attach() and fdstream::fdstream()
  // you do not want to set convert to true if you are using
  // Glib::ustring, as operator << and >> for Glib::ustring
  // do their own conversion.  If it is set, the IOChannel buffer
  // will convert to the user's locale when writing to or reading
  // from the filedescriptor. If in doubt, leave the default
  // value of false.

  // If fdstream is managing a file descriptor, attaching a new
  // one will close the old one
  void attach(int fd, bool manage = true, bool convert = false);

  void close();
  void connect(const sigc::slot<bool, Glib::IOCondition>& callback,
	       Glib::IOCondition condition);

private:
  fdstreambuf buf;
};

#endif /*GLIBMMEXAMPLE_FDSTREAM_H*/
