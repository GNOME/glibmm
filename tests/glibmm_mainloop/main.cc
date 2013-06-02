/* Copyright (C) 2013 The glibmm Development Team
 *
 * This file is part of glibmm.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm.h>
#include <iostream>
#include <cstdlib> // EXIT_SUCCESS, EXIT_FAILURE

namespace
{
enum InvokeStatus
{
  NOT_INVOKED,
  INVOKED_IN_RIGHT_THREAD,
  INVOKED_IN_WRONG_THREAD
};

InvokeStatus invoked_in_thread[2] = { NOT_INVOKED, NOT_INVOKED };

void quit_loop(const Glib::RefPtr<Glib::MainLoop>& mainloop)
{
  mainloop->quit();
}

bool mark_and_quit(const Glib::Threads::Thread* expected_thread,
  int thread_nr, const Glib::RefPtr<Glib::MainLoop>& mainloop)
{
  invoked_in_thread[thread_nr] =
    (Glib::Threads::Thread::self() == expected_thread) ?
    INVOKED_IN_RIGHT_THREAD : INVOKED_IN_WRONG_THREAD;
  quit_loop(mainloop);
  return false;
}

void thread_function(const Glib::Threads::Thread* first_thread,
  const Glib::RefPtr<Glib::MainLoop>& first_mainloop)
{
  // Create a new MainContext.
  Glib::RefPtr<Glib::MainContext> context = Glib::MainContext::create();
  // Create a new MainLoop.
  Glib::RefPtr<Glib::MainLoop> second_mainloop = Glib::MainLoop::create(context);

  // Show how Glib::MainContext::invoke() can be used for calling a function,
  // possibly executed in another thread.
  Glib::MainContext::get_default()->invoke(sigc::bind(sigc::ptr_fun(mark_and_quit),
    first_thread, 0, first_mainloop));
  context->invoke(sigc::bind(sigc::ptr_fun(mark_and_quit),
    Glib::Threads::Thread::self(), 1, second_mainloop));

  // Connect a one-shot timer that quits the main loop after a while,
  // if mark_and_quit() is not called as expected.
  context->signal_timeout().connect_seconds_once(
    sigc::bind(sigc::ptr_fun(quit_loop), second_mainloop), 3);

  // Start the second main loop.
  second_mainloop->run();
}

} // anonymous namespace

int main(int, char**)
{
  Glib::init();

  Glib::RefPtr<Glib::MainLoop> first_mainloop = Glib::MainLoop::create();

  // Connect a one-shot timer that quits the main loop after a while,
  // if mark_and_quit() is not called as expected.
  Glib::signal_timeout().connect_seconds_once(
    sigc::bind(sigc::ptr_fun(quit_loop), first_mainloop), 3);

  // Create a second thread.
  Glib::Threads::Thread* second_thread = Glib::Threads::Thread::create(
    sigc::bind(sigc::ptr_fun(thread_function),
    Glib::Threads::Thread::self(), first_mainloop));

  // Start the first main loop.
  first_mainloop->run();

  // Wait until the second thread has finished.
  second_thread->join();

  if (invoked_in_thread[0] == INVOKED_IN_RIGHT_THREAD &&
      invoked_in_thread[1] == INVOKED_IN_RIGHT_THREAD)
    return EXIT_SUCCESS;

  const char* N[2] = { "first", "second" };
  for (int i = 0; i < 2; ++i)
  {
    switch (invoked_in_thread[i])
    {
    case INVOKED_IN_RIGHT_THREAD:
      break;
    case NOT_INVOKED:
      std::cout << "Function that should be invoked in " << N[i]
        << " thread was not called." << std::endl;
      break;
    case INVOKED_IN_WRONG_THREAD:
      std::cout << "Function that should be invoked in " << N[i]
        << " thread was called in another thread." << std::endl;
      break;
    default:
      std::cout << "Unknown value: invoked_in_thread[" << i << "]="
        << invoked_in_thread[i] << std::endl;
      break;
    }
  }

  return EXIT_FAILURE;
}
