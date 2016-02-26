// -*- Mode: C++; indent-tabs-mode: nil; c-basic-offset: 2 -*-

/* Copyright (C) 2008 The gtkmm Development Team
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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <giomm/contenttype.h>
#include <gio/gio.h>

namespace Gio
{

bool
content_type_equals(const Glib::ustring& type1, const Glib::ustring& type2)
{
  return g_content_type_equals(type1.c_str(), type2.c_str());
}

bool
content_type_is_a(const Glib::ustring& type, const Glib::ustring& supertype)
{
  return g_content_type_is_a(type.c_str(), supertype.c_str());
}

bool
content_type_is_unknown(const Glib::ustring& type)
{
  return g_content_type_is_unknown(type.c_str());
}

Glib::ustring
content_type_get_description(const Glib::ustring& type)
{
  return Glib::convert_return_gchar_ptr_to_ustring(g_content_type_get_description(type.c_str()));
}

Glib::ustring
content_type_get_mime_type(const Glib::ustring& type)
{
  return Glib::convert_return_gchar_ptr_to_ustring(g_content_type_get_mime_type(type.c_str()));
}

Glib::RefPtr<Gio::Icon>
content_type_get_icon(const Glib::ustring& type)
{
  auto retvalue = Glib::wrap(g_content_type_get_icon(type.c_str()));
  if (retvalue)
    retvalue->reference(); // The function does not do a ref for us.
  return retvalue;
}

#ifdef G_OS_UNIX
Glib::RefPtr<Gio::Icon>
content_type_get_symbolic_icon(const Glib::ustring& type)
{
  auto retvalue = Glib::wrap(g_content_type_get_symbolic_icon(type.c_str()));
  if (retvalue)
    retvalue->reference(); // The function does not do a ref for us.
  return retvalue;
}
#endif

bool
content_type_can_be_executable(const Glib::ustring& type)
{
  return g_content_type_can_be_executable(type.c_str());
}

Glib::ustring
content_type_from_mime_type(const Glib::ustring& mime_type)
{
  return Glib::convert_return_gchar_ptr_to_ustring(
    g_content_type_from_mime_type(mime_type.c_str()));
}

Glib::ustring
content_type_guess(
  const std::string& filename, const std::basic_string<guchar>& data, bool& result_uncertain)
{
  gboolean c_result_uncertain = FALSE;
  const gchar* c_filename = filename.empty() ? nullptr : filename.c_str();
  gchar* cresult = g_content_type_guess(c_filename, data.c_str(), data.size(), &c_result_uncertain);
  result_uncertain = c_result_uncertain;
  return Glib::convert_return_gchar_ptr_to_ustring(cresult);
}

Glib::ustring
content_type_guess(
  const std::string& filename, const guchar* data, gsize data_size, bool& result_uncertain)
{
  gboolean c_result_uncertain = FALSE;
  const gchar* c_filename = filename.empty() ? nullptr : filename.c_str();
  gchar* cresult = g_content_type_guess(c_filename, data, data_size, &c_result_uncertain);
  result_uncertain = c_result_uncertain;
  return Glib::convert_return_gchar_ptr_to_ustring(cresult);
}

Glib::ustring
content_type_guess(const std::string& filename, const std::string& data, bool& result_uncertain)
{
  gboolean c_result_uncertain = FALSE;
  const gchar* c_filename = filename.empty() ? nullptr : filename.c_str();
  gchar* cresult =
    g_content_type_guess(c_filename, (const guchar*)data.c_str(), data.size(), &c_result_uncertain);
  result_uncertain = c_result_uncertain;
  return Glib::convert_return_gchar_ptr_to_ustring(cresult);
}

Glib::StringArrayHandle
content_type_guess_for_tree(const Glib::RefPtr<const File>& root)
{
  return Glib::StringArrayHandle(
    g_content_type_guess_for_tree(const_cast<GFile*>(root->gobj())), Glib::OWNERSHIP_DEEP);
}

Glib::ListHandle<Glib::ustring>
content_types_get_registered()
{
  return Glib::ListHandle<Glib::ustring>(g_content_types_get_registered(), Glib::OWNERSHIP_DEEP);
}

} // namespace Gio
