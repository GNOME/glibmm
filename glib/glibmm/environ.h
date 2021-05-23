#ifndef _GLIBMM_ENVIRON_H
#define _GLIBMM_ENVIRON_H
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

#include <glibmm/ustring.h>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace Glib
{

/** A convenience class for manipulating a copy of the environment variables.
 *
 * Useful for generating the @a envp parameter in calls to
 * Glib::spawn_async_with_pipes(), Glib::spawn_async() and Glib::spawn_sync().
 *
 * If you want to change the environment itself (i.e. not a copy of it),
 * see Glib::getenv(), Glib::setenv() and Glib::unsetenv().
 *
 * @newin{2,70}
 */
class Environ
{
public:
  /** Constructs a list of environment variables for the current process.
   *
   * Each item in the list is of the form 'NAME=VALUE'.
   */
  GLIBMM_API Environ();

  /** Constructs a %Glib::Environ instance from a vector.
   *
   * @param env_vec A vector with the environment variables. Each element in
   *                the vector must be of the form 'NAME=VALUE'.
   */
  GLIBMM_API explicit Environ(const std::vector<std::string>& env_vec);

  /** Gets the value of the environment variable @a variable.
   *
   * @param variable The environment variable to get, must not contain '='.
   * @return The value of the environment variable, or an empty std::optional
   *         if the environment variable is not set in this %Environ.
   */
  GLIBMM_API std::optional<std::string> get(StdStringView variable) const;

  /// Same as get().
  GLIBMM_API std::optional<std::string> operator[](StdStringView variable) const
  { return get(variable); }

  /** Sets the environment variable @a variable in the provided list to @a value.
   *
   * @param variable The environment variable to set, must not contain '='.
   * @param value The value to set the variable to.
   * @param overwrite Whether to change the variable if it already exists.
   */
  GLIBMM_API void set(StdStringView variable, StdStringView value, bool overwrite = true);

  /** Removes the environment variable @a variable from the provided list.
   *
   * @param variable The environment variable to remove, must not contain '='.
   */
  GLIBMM_API void unset(StdStringView variable);

  /** Get a vector with the environment variables.
   *
   * @return A vector with the environment variables. Each element in the vector
   *         is of the form 'NAME=VALUE'.
   */
  GLIBMM_API std::vector<std::string> to_vector() const;

private:
  std::unique_ptr<char*, decltype(&g_strfreev)> envp;
};

} // namespace Glib

#endif /* _GLIBMM_ENVIRON_H */
