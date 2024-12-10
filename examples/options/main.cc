/* Copyright (C) 2004 The glibmm Development Team
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
#include <iomanip>
#include <iostream>

class ExampleOptionGroup : public Glib::OptionGroup
{
public:
  ExampleOptionGroup();

private:
  bool on_pre_parse(Glib::OptionContext& context) override;
  bool on_post_parse(Glib::OptionContext& context) override;
  void on_error(Glib::OptionContext& context, const Glib::Error& error) override;

  bool on_option_arg_string(
    const Glib::ustring& option_name, const Glib::ustring& value, bool has_value);
  bool on_option_arg_filename(
    const Glib::ustring& option_name, const std::string& value, bool has_value);

public:
  // These members should live as long as the OptionGroup to which they are added,
  // and as long as the OptionContext to which that OptionGroup is added.
  int m_arg_foo;
  std::string m_arg_filename;
  Glib::ustring m_arg_goo;
  bool m_arg_boolean;
  Glib::OptionGroup::vecustrings m_arg_list;
  Glib::OptionGroup::vecustrings m_remaining_list;
  Glib::ustring m_arg_x_string;
  Glib::ustring m_arg_x_filename;
};

ExampleOptionGroup::ExampleOptionGroup()
: Glib::OptionGroup(
    "example_group", "description of example group", "help description of example group"),
  m_arg_foo(0),
  m_arg_boolean(false)
{
  Glib::OptionEntry entry1;
  entry1.set_long_name("foo");
  entry1.set_short_name('f');
  entry1.set_description("The Foo");
  add_entry(entry1, m_arg_foo);

  Glib::OptionEntry entry2;
  entry2.set_long_name("file");
  entry2.set_short_name('F');
  entry2.set_description("The Filename");
  add_entry_filename(entry2, m_arg_filename);

  Glib::OptionEntry entry3;
  entry3.set_long_name("goo");
  entry3.set_short_name('g');
  entry3.set_description("The Goo");
  // We can choose a default to be used if the user doesn't specify
  // this option.
  m_arg_goo = "default-goo-value";
  add_entry(entry3, m_arg_goo);

  Glib::OptionEntry entry4;
  entry4.set_long_name("activate_something");
  entry4.set_description("Activate something");
  add_entry(entry4, m_arg_boolean);

  Glib::OptionEntry entry5;
  entry5.set_long_name("list");
  entry5.set_short_name('l');
  entry5.set_description("A List");
  add_entry(entry5, m_arg_list);

  Glib::OptionEntry entry6;
  entry6.set_long_name("x-string");
  entry6.set_short_name('x');
  entry6.set_description("A string with custom parsing");
  entry6.set_flags(Glib::OptionEntry::Flags::OPTIONAL_ARG);
  m_arg_x_string = "not specified";
  add_entry(entry6, sigc::mem_fun(*this, &ExampleOptionGroup::on_option_arg_string));

  Glib::OptionEntry entry7;
  entry7.set_long_name("x-filename");
  entry7.set_short_name('X');
  entry7.set_description("A filename with custom parsing");
  entry7.set_flags(Glib::OptionEntry::Flags::OPTIONAL_ARG);
  m_arg_x_filename = "not specified";
  add_entry_filename(entry7, sigc::mem_fun(*this, &ExampleOptionGroup::on_option_arg_filename));

  Glib::OptionEntry entry_remaining;
  entry_remaining.set_long_name(G_OPTION_REMAINING);

  add_entry(entry_remaining, m_remaining_list);
}

bool
ExampleOptionGroup::on_pre_parse(Glib::OptionContext& /* context */)
{
  // This is called before the m_arg_* instances are given their values.
  // You do not need to override this method. This is just here to show you how,
  // in case you want to do any extra processing.
  std::cout << "on_pre_parse called" << std::endl;
  return true;
}

bool
ExampleOptionGroup::on_post_parse(
  Glib::OptionContext& /* context */)
{
  // This is called after the m_arg_* instances are given their values.
  // You do not need to override this method. This is just here to show you how,
  // in case you want to do any extra processing.
  std::cout << "on_post_parse called" << std::endl;
  return true;
}

void
ExampleOptionGroup::on_error(Glib::OptionContext& /* context */, const Glib::Error& /* error */)
{
  std::cout << "on_error called" << std::endl;
}

bool
ExampleOptionGroup::on_option_arg_string(
  const Glib::ustring& option_name, const Glib::ustring& value, bool has_value)
{
  if (option_name != "-x" && option_name != "--x-string")
  {
    m_arg_x_string = "on_option_arg_string called with unexpected option_name: " + option_name;
    throw Glib::OptionError(Glib::OptionError::UNKNOWN_OPTION, m_arg_x_string);
  }

  if (!has_value)
  {
    m_arg_x_string = "no value";
    return true;
  }

  if (value.empty())
  {
    m_arg_x_string = "empty string";
    return true;
  }

  m_arg_x_string = value;
  if (value == "error")
  {
    throw Glib::OptionError(
      Glib::OptionError::BAD_VALUE, "on_option_arg_string called with value = " + m_arg_x_string);
  }
  return value != "false";
}

bool
ExampleOptionGroup::on_option_arg_filename(
  const Glib::ustring& option_name, const std::string& value, bool has_value)
{
  if (option_name != "-X" && option_name != "--x-filename")
  {
    m_arg_x_filename = "on_option_arg_filename called with unexpected option_name: " + option_name;
    throw Glib::OptionError(Glib::OptionError::UNKNOWN_OPTION, m_arg_x_filename);
  }

  if (!has_value)
  {
    m_arg_x_filename = "no value";
    return true;
  }

  if (value.empty())
  {
    m_arg_x_filename = "empty string";
    return true;
  }

  m_arg_x_filename = value;
  if (value == "error")
  {
    throw Glib::OptionError(Glib::OptionError::BAD_VALUE,
      "on_option_arg_filename called with value = " + m_arg_x_filename);
  }
  return value != "false";
}

int
main(int argc, char** argv)
{
  // This example should be executed like so:
  //./example --foo=1 --activate_something --goo=abc
  //./example --help

  Glib::init();

  Glib::OptionContext context;

  ExampleOptionGroup group;
  context.set_main_group(group);

  try
  {
    context.parse(argc, argv);
  }
  catch (const Glib::Error& ex)
  {
    std::cout << "Exception: " << ex.what() << std::endl;
  }

  std::cout << "parsed values: " << std::endl
            << "  foo = " << group.m_arg_foo << std::endl
            << "  filename = " << group.m_arg_filename << std::endl
            << "  activate_something = " << (group.m_arg_boolean ? "enabled" : "disabled")
            << std::endl
            << "  goo = " << group.m_arg_goo << std::endl
            << "  x-string = " << group.m_arg_x_string << std::endl
            << "  x-filename = " << group.m_arg_x_filename << std::endl;

  // This one shows the results of multiple instance of the same option, such as --list=1 --list=a
  // --list=b
  std::cout << "  list = ";
  for (const auto& i : group.m_arg_list)

  {
    std::cout << i << ", ";
  }
  std::cout << std::endl;

  // This one shows the remaining arguments on the command line, which had no name= form:
  std::cout << "  remaining = ";
  for (const auto& i : group.m_remaining_list)
  {
    std::cout << i << ", ";
  }
  std::cout << std::endl;

  return 0;
}
