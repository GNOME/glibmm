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
  if(const char *const application_name = g_get_application_name())
  {
    // Lets be a bit more strict than the original GLib function and ensure
    // we always return valid UTF-8.  gtkmm coders surely won't expect invalid
    // UTF-8 in a Glib::ustring returned by a glibmm function.

    if(g_utf8_validate(application_name, -1, 0))
      return Glib::ustring(application_name);

    char *const appname_utf8 = g_filename_to_utf8(application_name, -1, 0, 0, 0);
    g_return_val_if_fail(appname_utf8 != 0, "");

    return Glib::ustring(ScopedPtr<char>(appname_utf8).get());
  }

  return Glib::ustring();
}

void set_application_name(const Glib::ustring& application_name)
{
  g_set_application_name(application_name.c_str());
}

std::string get_prgname()
{
  const char *const prgname = g_get_prgname();
  return (prgname) ? std::string(prgname) : std::string();
}

void set_prgname(const std::string& prgname)
{
  g_set_prgname(prgname.c_str());
}

std::string getenv(const std::string& variable, bool& found)
{
  const char *const value = g_getenv(variable.c_str());
  found = (value != 0);
  return (value) ? std::string(value) : std::string();
}

std::string getenv(const std::string& variable)
{
  const char *const value = g_getenv(variable.c_str());
  return (value) ? std::string(value) : std::string();
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
  return std::string(g_get_home_dir());
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

bool path_is_absolute(const std::string& filename)
{
  return g_path_is_absolute(filename.c_str());
}

std::string path_skip_root(const std::string& filename)
{
  // g_path_skip_root() returns a pointer _into_ the argument string,
  // or NULL if there was no root component.

  if(const char *const ptr = g_path_skip_root(filename.c_str()))
    return std::string(ptr);
  else
    return std::string();
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
  return build_path(G_DIR_SEPARATOR_S, elements);
}

std::string build_filename(const std::string& elem1, const std::string& elem2)
{
  std::string result;
  result.reserve(elem1.size() + elem2.size() + 1);

  // Skip trailing '/'.
  std::string::size_type idx = elem1.find_last_not_of(G_DIR_SEPARATOR);

  if(idx != std::string::npos)
    result.append(elem1, 0, idx + 1);

  result += G_DIR_SEPARATOR;

  // Skip leading '/'.
  idx = elem2.find_first_not_of(G_DIR_SEPARATOR);

  if(idx != std::string::npos)
    result.append(elem2, idx, std::string::npos);

  return result;
}

/* Yes, this reimplements the functionality of g_build_path() -- because
 * it takes a varargs list, and calling it several times would it result
 * in different behaviour.
 */
std::string build_path(const std::string& separator,
                       const Glib::ArrayHandle<std::string>& elements)
{
  std::string result;

  const char *const sep = separator.c_str();
  const size_t seplen   = separator.length();

  const char *const *const elements_begin = elements.data();
  const char *const *const elements_end   = elements_begin + elements.size();

  for(const char *const * pelement = elements_begin; pelement != elements_end; ++pelement)
  {
    const char* start = *pelement;

    if((pelement != elements_begin) && (seplen != 0))
    {
      while(strncmp(start, sep, seplen) == 0)
        start += seplen;
    }

    size_t len = strlen(start);

    if((pelement != elements_end - 1) && (seplen != 0))
    {
      while((len >= seplen) && (strncmp(start + len - seplen, sep, seplen) == 0))
        len -= seplen;
    }

    if(len != 0)
    {
      if(!result.empty())
        result.append(sep, seplen);

      result.append(start, len);
    }
  }

  return result;
}

std::string find_program_in_path(const std::string& program)
{
  if(char *const buf = g_find_program_in_path(program.c_str()))
    return std::string(ScopedPtr<char>(buf).get());
  else
    return std::string();
}

} // namespace Glib

