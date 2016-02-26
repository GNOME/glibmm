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

#include <cstdlib> // EXIT_SUCCESS, EXIT_FAILURE
#include <glibmm.h>
#include <iostream>
#include <thread>

namespace
{
enum InvokeStatus
{
  NOT_INVOKED,
  INVOKED_IN_RIGHT_THREAD,
  INVOKED_IN_WRONG_THREAD
};

InvokeStatus invoked_in_thread[2] = { NOT_INVOKED, NOT_INVOKED };

void
quit_loop(const Glib::RefPtr<Glib::MainLoop>& mainloop)
{
  mainloop->quit();
}

bool
mark_and_quit(const std::thread::id& expected_thread_id, int thread_nr,
  const Glib::RefPtr<Glib::MainLoop>& mainloop)
{
  invoked_in_thread[thread_nr] = (std::this_thread::get_id() == expected_thread_id)
                                   ? INVOKED_IN_RIGHT_THREAD
                                   : INVOKED_IN_WRONG_THREAD;
  mainloop->get_context()->signal_idle().connect_once(
    sigc::bind(sigc::ptr_fun(quit_loop), mainloop));
  return false;
}

void
thread_function(
  const std::thread::id& first_thread_id, const Glib::RefPtr<Glib::MainLoop>& first_mainloop)
{
  auto second_context = Glib::MainContext::create();
  auto second_mainloop = Glib::MainLoop::create(second_context);

  // Show how Glib::MainContext::invoke() can be used for calling a function,
  // possibly executed in another thread.
  Glib::MainContext::get_default()->invoke(
    sigc::bind(sigc::ptr_fun(mark_and_quit), first_thread_id, 0, first_mainloop));

  // If this thread owns second_context, invoke() will call mark_and_quit() directly.
  bool is_owner = second_context->acquire();
  second_context->invoke(
    sigc::bind(sigc::ptr_fun(mark_and_quit), std::this_thread::get_id(), 1, second_mainloop));
  if (is_owner)
    second_context->release();

  // Start the second main loop.
  second_mainloop->run();
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();

  auto first_mainloop = Glib::MainLoop::create();

  // This thread shall be the owner of the default main context, when
  // thread_function() calls mark_and_quit() via Glib::MainContext::invoke(),
  // or else both calls to mark_and_quit() will execute in thread_function()'s
  // thread. Glib::MainLoop::run() acquires ownership, but that may be too late.
  bool is_owner = Glib::MainContext::get_default()->acquire();

  // Create a second thread.
  const std::thread::id first_thread_id = std::this_thread::get_id();
  std::thread second_thread(&thread_function, first_thread_id, first_mainloop);

  // Start the first main loop.
  first_mainloop->run();

  // Wait until the second thread has finished.
  second_thread.join();

  if (is_owner)
    Glib::MainContext::get_default()->release();

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
      std::cout << "Function that should be invoked in " << N[i] << " thread was not called."
                << std::endl;
      break;
    case INVOKED_IN_WRONG_THREAD:
      std::cout << "Function that should be invoked in " << N[i]
                << " thread was called in another thread." << std::endl;
      break;
    default:
      std::cout << "Unknown value: invoked_in_thread[" << i << "]=" << invoked_in_thread[i]
                << std::endl;
      break;
    }
  }

  return EXIT_FAILURE;
}
