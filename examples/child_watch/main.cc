/* Copyright (C) 2005 The glibmm Development Team
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

#include <glibmm.h>
#include <iostream>
#include <sys/types.h>
#include <unistd.h>

using namespace std;

class ChildWatch : public sigc::trackable
{
public:
  explicit ChildWatch(const Glib::RefPtr<Glib::MainLoop>& mainLoop) : m_mainLoop(mainLoop) {}

  void on_child_exited(GPid pid, int status);
  void run(); // fork a child and call signal_child_watch

private:
  Glib::RefPtr<Glib::MainLoop> m_mainLoop;
};

void
ChildWatch::run()
{
  GPid pid = fork();

  if (!pid)
  {
    sleep(5);
    exit(0);
  }

  std::cout << "Child " << pid << " created" << std::endl;

  Glib::signal_child_watch().connect(sigc::mem_fun(*this, &ChildWatch::on_child_exited), pid);
}

void
ChildWatch::on_child_exited(GPid pid, int status)
{
  std::cout << "Child " << pid << " exited with status " << status << std::endl;
  m_mainLoop->quit();
}

int
main()
{
  auto mainLoop = Glib::MainLoop::create();

  ChildWatch cwatch(mainLoop);
  cwatch.run();
  mainLoop->run();

  return 0;
}
