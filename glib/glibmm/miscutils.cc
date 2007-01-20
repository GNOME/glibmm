// -*- c++ -*-
/* $Id$ */

/* Copyright (C) 2002 The gtkmm Development Team
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

#include <cstddef>
#include <cstring>

#include <glibmm/miscutils.h>
#include <glibmm/utility.h>
#include <glib.h>


namespace Glib
{

Glib::ustring get_application_name()
{
  const char *const value = g_get_application_name();
  return Glib::ustring((value) ? value : "");
}

void set_application_name(const Glib::ustring& application_name)
{
  g_set_application_name(application_name.c_str());
}

std::string get_prgname()
{
  const char *const value = g_get_prgname();
  return std::string((value) ? value : "");
}

void set_prgname(const std::string& prgname)
{
  g_set_prgname(prgname.c_str());
}

std::string getenv(const std::string& variable, bool& found)
{
  const char *const value = g_getenv(variable.c_str());
  found = (value != 0);
  return std::string((value) ? value : "");
}

std::string getenv(const std::string& variable)
{
  const char *const value = g_getenv(variable.c_str());
  return std::string((value) ? value : "");
}

bool setenv(const std::string& variable, const std::string& value, bool overwrite)
{
  return g_setenv(variable.c_str(), value.c_str(), overwrite);
}

void unsetenv(const std::string& variable)
{
  g_unsetenv(variable.c_str());
}

std::string get_user_name()
{
  return std::string(g_get_user_name());
}

std::string get_real_name()
{
  return std::string(g_get_real_name());
}

std::string get_home_dir()
{
  const char *const value = g_get_home_dir();
  return std::string((value) ? value : "");
}

std::string get_tmp_dir()
{
  return std::string(g_get_tmp_dir());
}

std::string get_current_dir()
{
  const ScopedPtr<char> buf (g_get_current_dir());
  return std::string(buf.get());
}

std::string get_user_data_dir()
{
  return std::string(g_get_user_data_dir());
}

std::string get_user_config_dir()
{
  return std::string(g_get_user_config_dir());
}

std::string get_user_cache_dir()
{
  return std::string(g_get_user_cache_dir());
}

bool path_is_absolute(const std::string& filename)
{
  return (g_path_is_absolute(filename.c_str()) != 0);
}

std::string path_skip_root(const std::string& filename)
{
  // g_path_skip_root() returns a pointer _into_ the argument string,
  // or NULL if there was no root component.
  const char *const value = g_path_skip_root(filename.c_str());
  return std::string((value) ? value : "");
}

std::string path_get_basename(const std::string& filename)
{
  const ScopedPtr<char> buf (g_path_get_basename(filename.c_str()));
  return std::string(buf.get());
}

std::string path_get_dirname(const std::string& filename)
{
  const ScopedPtr<char> buf (g_path_get_dirname(filename.c_str()));
  return std::string(buf.get());
}

std::string build_filename(const Glib::ArrayHandle<std::string>& elements)
{
  const ScopedPtr<char> buf (g_build_filenamev(const_cast<char**>(elements.data())));
  return std::string(buf.get());
}

std::string build_filename(const std::string& elem1, const std::string& elem2)
{
  const ScopedPtr<char> buf (g_build_filename(elem1.c_str(), elem2.c_str(), static_cast<char*>(0)));
  return std::string(buf.get());
}

std::string build_path(const std::string& separator, const Glib::ArrayHandle<std::string>& elements)
{
  const ScopedPtr<char> buf (g_build_pathv(separator.c_str(), const_cast<char**>(elements.data())));
  return std::string(buf.get());
}

std::string find_program_in_path(const std::string& program)
{
  if(char *const buf = g_find_program_in_path(program.c_str()))
    return std::string(ScopedPtr<char>(buf).get());
  else
    return std::string();
}

} // namespace Glib
