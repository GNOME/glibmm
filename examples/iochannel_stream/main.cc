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

#include <fcntl.h>
#include <glibmm.h>
#include <iostream>
#include <limits.h>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "fdstream.h"

fdstream input_stream;
Glib::RefPtr<Glib::MainLoop> mainloop;

/*
  send to the fifo with:
  echo "Hello" > testfifo

  quit the program with:
  echo "Q" > testfifo
*/

// this will be our signal handler for read operations
// it will print out the message sent to the fifo
// and quit the program if the message was, or began
// with, 'Q'
bool
MyCallback(Glib::IOCondition io_condition)
{
  if ((io_condition & Glib::IOCondition::IO_IN) != Glib::IOCondition::IO_IN)
  {
    std::cerr << "Invalid fifo response" << std::endl;
  }
  else
  {
    // stream for stdout (does the same as std::cout
    // - this is an example of using fdstream for output)
    fdstream out(1, false);
    std::string text;
    input_stream >> text;
    out << text << std::endl;

    if (text[0] == 'Q')
      mainloop->quit();
  }

  return true;
}

int main(/* int argc, char *argv[] */)
{
  Glib::init();

  // the usual Glib::Main object
  mainloop = Glib::MainLoop::create();

  if (access("testfifo", F_OK) == -1)
  {
    // fifo doesn't exit - create it
    if (mkfifo("testfifo", 0666) != 0)
    {
      std::cerr << "error creating fifo" << std::endl;
      return -1;
    }
  }

  const auto read_fd = open("testfifo", O_RDONLY);
  if (read_fd == -1)
  {
    std::cerr << "error opening fifo" << std::endl;
    return -1;
  }

  input_stream.attach(read_fd);
  input_stream.connect(sigc::ptr_fun(MyCallback), Glib::IOCondition::IO_IN);

  // and last but not least - run the application main loop
  mainloop->run();

  // now remove the temporary fifo
  if (unlink("testfifo"))
    std::cerr << "error removing fifo" << std::endl;

  return 0;
}
