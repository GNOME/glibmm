/* Copyright (C) 2004 The glibmm Development Team
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

#include <glibmm.h>
#include <iomanip>
#include <iostream>


class ExampleOptionGroup : public Glib::OptionGroup
{ 
public:
  ExampleOptionGroup();

  virtual bool on_pre_parse(Glib::OptionContext& context, Glib::OptionGroup& group);
  virtual bool on_post_parse(Glib::OptionContext& context, Glib::OptionGroup& group);
  virtual void on_error(Glib::OptionContext& context, Glib::OptionGroup& group);
  
  //These int instances should live as long as the OptionGroup to which they are added, 
  //and as long as the OptionContext to which those OptionGroups are added.
  int m_arg_foo;
  int m_arg_bar;
  Glib::ustring m_arg_goo;
};

ExampleOptionGroup::ExampleOptionGroup()
: Glib::OptionGroup("example_group", "description of example group", "help description of example group"),
  m_arg_foo(0),
  m_arg_bar(0)
{
  Glib::OptionEntry entry1;
  entry1.set_long_name("foo");
  entry1.set_short_name('f');
  entry1.set_description("The Foo");
  add_entry(entry1, m_arg_foo);
      
  Glib::OptionEntry entry2;
  entry2.set_long_name("bar");
  entry2.set_short_name('b');
  entry2.set_description("The Bar");
  add_entry(entry2, m_arg_bar);
 
  Glib::OptionEntry entry3;
  entry3.set_long_name("goo");
  entry3.set_short_name('g');
  entry3.set_description("The Goo");
  add_entry(entry3, m_arg_goo);
}

bool ExampleOptionGroup::on_pre_parse(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  //This is called before m_arg_foo and m_arg_bar are given their values.
  return Glib::OptionGroup::on_pre_parse(context, group);
}

bool ExampleOptionGroup::on_post_parse(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  //This is called after m_arg_foo and m_arg_bar are given their values.
  return Glib::OptionGroup::on_post_parse(context, group);
}

void ExampleOptionGroup::on_error(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  Glib::OptionGroup::on_error(context, group);
}
  


int main(int argc, char** argv)
{
  //This example should be executed like so:
  //./example --foo=1 --bar=2 --goo=abc
  //./example --help
  
  Glib::init();
   
  Glib::OptionContext context;
  
  ExampleOptionGroup group;
  context.set_main_group(group);
  
  try
  {
    context.parse(argc, argv);
  }
  catch(const Glib::Error& ex)
  {
    std::cout << "Exception: " << ex.what() << std::endl;
  }

  std::cout << "parsed values: " << std::endl <<
    "  foo = " << group.m_arg_foo << std::endl << 
    "  bar = " << group.m_arg_bar << std::endl <<
    "  goo = " << group.m_arg_goo << std::endl;

  return 0;
}

