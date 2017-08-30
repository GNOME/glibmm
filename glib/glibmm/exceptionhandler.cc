/* exceptionhandler.cc
 *
 * Copyright 2002 The gtkmm Development Team
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

#include <glibmmconfig.h>
#include <glibmm/error.h>
#include <glibmm/exceptionhandler.h>
#include <glib.h>
#include <exception>
#include <list>

namespace
{

using HandlerList = std::list<sigc::slot<void()>>;

// Each thread has its own list of exception handlers
// to avoid thread synchronization problems.
static thread_local HandlerList* thread_specific_handler_list = nullptr;

static void
glibmm_exception_warning(const GError* error)
{
  g_assert(error != nullptr);

  g_critical("\n"
             "unhandled exception (type Glib::Error) in signal handler:\n"
             "domain: %s\n"
             "code  : %d\n"
             "what  : %s\n",
    g_quark_to_string(error->domain), error->code, (error->message) ? error->message : "(null)");
}

static void
glibmm_unexpected_exception()
{
  try
  {
    throw; // re-throw current exception
  }
  catch (const Glib::Error& error)
  {
    // Access the GError directly, to avoid possible exceptions from C++ code.
    glibmm_exception_warning(error.gobj());

    // For most failures that cause a Glib::Error exception, aborting the
    // program seems too harsh.  Instead, give control back to the main loop.
    return;
  }
  catch (const std::exception& except)
  {
    g_error("\n"
            "unhandled exception (type std::exception) in signal handler:\n"
            "what: %s\n",
      except.what());
  }
  catch (...)
  {
    g_error("\nunhandled exception (type unknown) in signal handler\n");
  }
}

} // anonymous namespace

namespace Glib
{

sigc::connection
add_exception_handler(const sigc::slot<void()>& slot)
{
  HandlerList* handler_list = thread_specific_handler_list;

  if (!handler_list)
  {
    handler_list = new HandlerList();
    thread_specific_handler_list = handler_list;
  }

  handler_list->emplace_back(slot);
  auto& added_slot = handler_list->back();
  return sigc::connection(added_slot);
}

// internal
void
exception_handlers_invoke() noexcept
{
  // This function will be called from our GLib signal handler proxies
  // if an exception has been caught.  It's not possible to throw C++
  // exceptions through C signal handlers.  To handle this situation, the
  // programmer can install slots to global Reusable Exception Handlers.
  //
  // A handler has to re-throw the current exception in a try block, and then
  // catch the exceptions it knows about.  Any unknown exceptions should just
  // fall through, i.e. the handler must not do catch(...).
  //
  // We now invoke each of the installed slots until the exception has been
  // handled.  If there are no more handlers in the list and the exception
  // is still unhandled, call glibmm_unexpected_exception().

  if (HandlerList* const handler_list = thread_specific_handler_list)
  {
    HandlerList::iterator pslot = handler_list->begin();

    while (pslot != handler_list->end())
    {
      // Calling an empty slot would mean ignoring the exception,
      // thus we have to check for dead slots explicitly.
      if (pslot->empty())
      {
        pslot = handler_list->erase(pslot);
        continue;
      }

      // Call the Reusable Exception Handler, which should re-throw
      // the exception that's currently on the stack.
      try
      {
        (*pslot)();
      }
      catch (...) // unhandled, try next slot
      {
        ++pslot;
        continue;
      }

      // The exception has either been handled or ignored.
      // Give control back to the GLib main loop.
      return;
    }
  }

  // Critical: The exception is still unhandled.
  glibmm_unexpected_exception();
}

} // namespace Glib
