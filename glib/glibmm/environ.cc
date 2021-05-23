/* Copyright (C) 2021 The glibmm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/environ.h>
#include <glibmm/vectorutils.h>

namespace Glib
{

Environ::Environ()
: envp(g_get_environ(), &g_strfreev)
{}

Environ::Environ(const std::vector<std::string>& env_vec)
: envp(g_new(char*, env_vec.size() + 1), &g_strfreev)
{
  for (unsigned int i = 0; i < env_vec.size(); ++i)
    envp.get()[i] = g_strdup(env_vec[i].c_str());
  envp.get()[env_vec.size()] = nullptr;
}

std::optional<std::string> Environ::get(StdStringView variable) const
{
  const char* value = g_environ_getenv(envp.get(), variable.c_str());
  if (value)
    return std::optional<std::string>(std::in_place, value);
  return std::optional<std::string>();
}

void Environ::set(StdStringView variable, StdStringView value, bool overwrite)
{
  envp.reset(g_environ_setenv(envp.release(), variable.c_str(), value.c_str(), overwrite));
}

void Environ::unset(StdStringView variable)
{
  envp.reset(g_environ_unsetenv(envp.release(), variable.c_str()));
}

std::vector<std::string> Environ::to_vector() const
{
  return Glib::ArrayHandler<std::string>::array_to_vector(envp.get(), Glib::OWNERSHIP_NONE);
}

} // namespace Glib
