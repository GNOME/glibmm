/* Copyright (C) 2023 The gtkmm Development Team
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

#include <giomm.h>
#include <iostream>

namespace
{
int finish_pending = 0;

void on_communicate_finished(Glib::RefPtr<Gio::AsyncResult>& result,
  const Glib::RefPtr<Gio::Subprocess>& subprocess, const Glib::ustring& heading)
{
  try
  {
  std::cout << "\n" << heading << "\n";
  auto [stdout_buf, stderr_buf] = subprocess->communicate_utf8_finish(result);
  std::cout << "stdout_buf: " << stdout_buf << "\n"
            << "stderr_buf: " << stderr_buf << "\n";
  }
  catch (const Glib::Error& error)
  {
    std::cerr << "on_communicate_finished(), Glib::Error: " << error.what() << std::endl;
  }
  catch (const std::exception& error)
  {
    std::cerr << "on_communicate_finished(), std::exception: " << error.what() << std::endl;
  }
  --finish_pending;
}
} // anonymous namespace

int main(int argc, char** argv)
{
  Gio::init();

  if (argc < 3)
  {
    std::cerr << "Usage: " << argv[0] << " input-data command [arguments]...\n";
    return 1;
  }

  // Three character encodings can be involved:
  // 1. The encoding in the user's preferred locale.
  // 2. The filename encoding, used by GLib.
  // 3. UTF-8.
  // The encoding used in argv is determined by the operating system.
  // It's assumed to be the encoding in the user's preferred locale,
  // which is also the C and C++ global locale. See the documentation of
  // Glib::set_init_to_users_preferred_locale().
  try
  {
    const auto stdin_buf = Glib::locale_to_utf8(argv[1]);

    std::vector<std::string> arg_vector;
    for (int i = 2; i < argc; ++i)
      arg_vector.push_back(Glib::filename_from_utf8(Glib::locale_to_utf8(argv[i])));

    Gio::Subprocess::Flags flags =
      Gio::Subprocess::Flags::STDOUT_PIPE | Gio::Subprocess::Flags::STDERR_PIPE;
    if (!stdin_buf.empty())
      flags |= Gio::Subprocess::Flags::STDIN_PIPE;

    // This example would be easier with the synchronous communicate_utf8().

    // Without SubprocessLauncher.
    auto subprocess = Gio::Subprocess::create(arg_vector, flags);
    ++finish_pending;
    subprocess->communicate_utf8_async(stdin_buf,
      [&subprocess](Glib::RefPtr<Gio::AsyncResult>& result)
      {
        on_communicate_finished(result, subprocess, "Without SubprocessLauncher");
      });

    // With SubprocessLauncher.
    auto launcher = Gio::SubprocessLauncher::create(flags);
    auto spawned_subprocess = launcher->spawn(arg_vector);
    ++finish_pending;
    spawned_subprocess->communicate_utf8_async(stdin_buf,
      [&spawned_subprocess](Glib::RefPtr<Gio::AsyncResult>& result)
      {
        on_communicate_finished(result, spawned_subprocess, "With SubprocessLauncher");
      });
  }
  catch (const Glib::Error& error)
  {
    std::cerr << "Glib::Error: " << error.what() << std::endl;
    return 1;
  }
  catch (const std::exception& error)
  {
    std::cerr << "std::exception: " << error.what() << std::endl;
    return 1;
  }

  // Wait for on_communicate_finished() to finish.
  auto main_context = Glib::MainContext::get_thread_default();
  while (finish_pending > 0)
    main_context->iteration(true);
  return 0;
}
