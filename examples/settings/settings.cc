/*******************************************************************************
 *
 *  Copyright (c) 2010 Jonathon Jongsma
 *
 *  This file is part of gtkmm
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, see <http://www.gnu.org/licenses/>
 *
 *******************************************************************************/

#include <giomm.h>
#include <iostream>

const char* const STRING_KEY = "test-string";
const char* const INT_KEY = "test-int";

static void
on_key_changed(const Glib::ustring& key, const Glib::RefPtr<Gio::Settings>& settings)
{
  std::cout << Glib::ustring::compose("'%1' changed\n", key);
  if (key == STRING_KEY)
  {
    Glib::ustring str = settings->get_string(key);
    std::cout << Glib::ustring::compose("New value of '%1': '%2'\n", key, str);

    // Or:
    Glib::Variant<Glib::ustring> variant;
    settings->get_value(key, variant);
    str = variant.get();
    std::cout << Glib::ustring::compose("New value, via variant, of '%1': '%2'\n", key, str);
  }
  else if (key == INT_KEY)
  {
    std::cout << Glib::ustring::compose("New value of '%1': '%2'\n", key, settings->get_int(key));
  }
  else
    std::cerr << "Unknown key\n";
}

static void
on_key_changed_all(const Glib::ustring& key)
{
  std::cout << "on_key_changed_all(" << key << ")\n";
}

static void
on_key_changed_int(const Glib::ustring& key)
{
  std::cout << "on_key_changed_int(" << key << ")\n";
  if (key != INT_KEY)
    std::cerr << "Unexpected key\n";
}

int
main(int, char**)
{
  Gio::init();

  // This is only a demo so we don't want to rely on an installed schema.
  // Instead we set some environment variables that allow us to test things
  // from the build directory where the gschemas.compiled file is stored.
  // Generally you would install your schemas to the system schema directory.
  Glib::setenv("GSETTINGS_SCHEMA_DIR", ".", true);
  Glib::setenv("GSETTINGS_BACKEND", "memory", true);

  const auto settings = Gio::Settings::create("org.gtkmm.demo");

  settings->signal_changed().connect(sigc::bind(sigc::ptr_fun(&on_key_changed), settings));
  settings->signal_changed("").connect(sigc::ptr_fun(&on_key_changed_all));
  settings->signal_changed(INT_KEY).connect(sigc::ptr_fun(&on_key_changed_int));

  std::cout << Glib::ustring::compose(
    "Initial value of '%1': '%2'\n", STRING_KEY, settings->get_string(STRING_KEY));
  settings->set_string(STRING_KEY, "Hoopoe");

  std::cout << Glib::ustring::compose(
    "Initial value of '%1': '%2'\n", INT_KEY, settings->get_int(INT_KEY));
  settings->set_int(INT_KEY, 18);

  return 0;
}
