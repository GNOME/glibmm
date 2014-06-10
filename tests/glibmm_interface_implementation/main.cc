#include <glibmm.h>
#include <giomm.h> //There are no Interfaces in glibmm, but there are in giomm.
#include <iostream>

class CustomAction :
  public Gio::Action,
  public Glib::Object
{
public:
  CustomAction();

  // A custom property.
  Glib::Property<Glib::ustring> property;

protected:
  //Implement a vfunc:
  virtual Glib::ustring get_name_vfunc() const;
};

CustomAction::CustomAction()
: Glib::ObjectBase( typeid(CustomAction) ),
  Glib::Object(),
  property(*this, "custom_property", "Initial value.")
{
}

static bool get_name_called = false;

Glib::ustring CustomAction::get_name_vfunc() const
{
  get_name_called = true;
  return "custom-name";
}


int main(int, char**)
{
  Glib::init();

  CustomAction action;
  Glib::ustring name = action.get_name();
  std::cout << "The name is '" << name << "'." << std::endl;
  std::cout << "The name property of the implemented interface is '"
            << action.property_name().get_value() << "'." << std::endl;
  std::cout << "The custom string property is '"
            << action.property.get_value() << "'." << std::endl;

  action.property = "A new value.";
  std::cout << "The custom string property (after changing it) is '"
            << action.property.get_value() << "'." << std::endl;

  gchar* prop_value = 0;
  g_object_set(action.gobj(), "custom_property", "Another value", NULL);
  g_object_get(action.gobj(), "custom_property", &prop_value, NULL);
  std::cout << "The custom property after g_object_get/set() is '"
            << prop_value << "'." << std::endl;
  std::cout << "The custom property through the Glib::Property<> is '"
            << action.property.get_value() << "'." << std::endl;
  std::cout << "The name property of the implemented interface is '"
            << action.property_name().get_value() << "'." << std::endl;
  g_assert(get_name_called);

  return EXIT_SUCCESS;
}
