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
  
  int m_arg_foo;
  int m_arg_bar;
  
protected:
  Glib::OptionEntry m_entry1, m_entry2; //TODO: This is just for memory-management, to make them live long enough.
};

ExampleOptionGroup::ExampleOptionGroup()
: Glib::OptionGroup("example_group", "description of example group", "help description of example group"),
  m_arg_foo(0),
  m_arg_bar(0)
{
  m_entry1.set_long_name("foo");
  m_entry1.set_short_name('f');
  m_entry1.set_arg_data(Glib::OPTION_ARG_INT, &m_arg_foo);

  add_entry(m_entry1);
      
  m_entry2.set_long_name("bar");
  m_entry2.set_short_name('b');
  m_entry2.set_arg_data(Glib::OPTION_ARG_INT, &m_arg_bar);
  
  add_entry(m_entry2);
}

bool ExampleOptionGroup::on_pre_parse(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  //This is called before m_arg_foo and m_arg_bar are given their values.
  return Glib::OptionGroup::on_pre_parse(context, group);
}

bool ExampleOptionGroup::on_post_parse(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  //This is called afetr m_arg_foo and m_arg_bar are given their values.
  return Glib::OptionGroup::on_post_parse(context, group);
}

void ExampleOptionGroup::on_error(Glib::OptionContext& context, Glib::OptionGroup& group)
{
  Glib::OptionGroup::on_error(context, group);
}
  


int main(int argc, char** argv)
{
  Glib::init();
   
  Glib::OptionContext context;
  
  ExampleOptionGroup group;
  context.set_main_group(group); //TODO: check memory management/copying.
  
  context.parse(argc, argv);

  std::cout << "parsed values: foo = " << group.m_arg_foo << ", bar = " << group.m_arg_bar << std::endl;

  return 0;
}

