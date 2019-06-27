/* Copyright (C) 2008 jonathon jongsma
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

// This example will not work without properties support
// A class that contains properties must inherit from Glib::Object (or a class
// that inherits from Glib::Object)
class Person : public Glib::Object
{
public:
  Person()
  : // to register custom properties, you must register a custom GType.  If
    // you don't know what that means, don't worry, just remember to add
    // this Glib::ObjectBase constructor call to your class' constructor
    Glib::ObjectBase(typeid(Person)),
    // register the properties with the object and give them names
    prop_firstname(*this, "firstname"),
    prop_lastname(*this, "lastname"),
    // this one has a default value
    prop_age(*this, "age", 10)
  {
  }

  // provide proxies for the properties.  The proxy allows you to connect to
  // the 'changed' signal, etc.
  Glib::PropertyProxy<Glib::ustring> property_firstname() { return prop_firstname.get_proxy(); }
  Glib::PropertyProxy<Glib::ustring> property_lastname() { return prop_lastname.get_proxy(); }
  Glib::PropertyProxy<int> property_age() { return prop_age.get_proxy(); }

private:
  Glib::Property<Glib::ustring> prop_firstname;
  Glib::Property<Glib::ustring> prop_lastname;
  Glib::Property<int> prop_age;
};

void
on_firstname_changed()
{
  std::cout << "- firstname changed!" << std::endl;
}
void
on_lastname_changed()
{
  std::cout << "- lastname changed!" << std::endl;
}
void
on_age_changed()
{
  std::cout << "- age changed!" << std::endl;
}

int
main(int, char**)
{
  Glib::init();
  Person p;
  // Register some handlers that will be called when the values of the
  // specified parameters are changed
  p.property_firstname().signal_changed().connect(sigc::ptr_fun(&on_firstname_changed));
  p.property_lastname().signal_changed().connect(sigc::ptr_fun(&on_lastname_changed));
  p.property_age().signal_changed().connect(sigc::ptr_fun(&on_age_changed));
  std::cout << "Name, age: " << p.property_firstname() << " " << p.property_lastname()
            << ", " << p.property_age() << std::endl;

  // now change the properties and see that the handlers get called
  std::cout << "Changing the properties of 'p'" << std::endl;
  p.property_firstname() = "John";
  p.property_lastname() = "Doe";
  p.property_age() = 43;
  std::cout << "Done changing the properties of 'p'" << std::endl;
  std::cout << "Name, age: " << p.property_firstname() << " " << p.property_lastname()
            << ", " << p.property_age() << std::endl;

  return 0;
}
