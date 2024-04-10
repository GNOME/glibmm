// This program does not only test the implementation of an interface
// in a custom class. It also tests virtual functions that have leaked memory
// or printed unjustified critical messages in glibmm before version 2.44.
// See https://bugzilla.gnome.org/show_bug.cgi?id=705124.

#include <cstring>
#include <giomm.h> //There are no Interfaces in glibmm, but there are in giomm.
#include <glibmm.h>
#include <iostream>

class CustomAction : public Gio::Action, public Glib::Object
{
public:
  CustomAction();

  // A custom property.
  Glib::Property<Glib::ustring> property;

protected:
  // Implement vfuncs:
  Glib::ustring get_name_vfunc() const override;
  Glib::VariantType get_state_type_vfunc() const override;
  Glib::VariantBase get_state_hint_vfunc() const override;
};

CustomAction::CustomAction()
: Glib::ObjectBase(typeid(CustomAction)),
  Glib::Object(),
  property(*this, "custom_property", "Initial value.")
{
}

static bool get_name_called = false;

Glib::ustring
CustomAction::get_name_vfunc() const
{
  get_name_called = true;
  return "custom-name";
}

Glib::VariantType
CustomAction::get_state_type_vfunc() const
{
  return Glib::VariantType(G_VARIANT_TYPE_INT16);
}

Glib::VariantBase
CustomAction::get_state_hint_vfunc() const
{
  return Glib::Variant<gint16>::create(42);
}

int
main(int, char**)
{
  Glib::init();

  CustomAction action;
  bool success = true;

  Glib::ustring name = action.get_name();
  std::cout << "The name is '" << name << "'." << std::endl;
  success &= name == "custom-name";

  std::cout << "The name property of the implemented interface is '"
            << action.property_name().get_value() << "'." << std::endl;
  success &= action.property_name().get_value() == "";

  std::cout << "The custom string property is '" << action.property.get_value() << "'."
            << std::endl;
  success &= action.property.get_value() == "Initial value.";

  action.property = "A new value.";
  std::cout << "The custom string property (after changing it) is '" << action.property.get_value()
            << "'." << std::endl;
  success &= action.property.get_value() == "A new value.";

  gchar* prop_value = nullptr;
  g_object_set(action.gobj(), "custom_property", "Another value", nullptr);
  g_object_get(action.gobj(), "custom_property", &prop_value, nullptr);
  std::cout << "The custom property after g_object_set/get() is '" << prop_value << "'."
            << std::endl;
  success &= std::strcmp(prop_value, "Another value") == 0;
  g_free(prop_value);
  prop_value = nullptr;

  std::cout << "The custom property through the Glib::Property<> is '"
            << action.property.get_value() << "'." << std::endl;
  success &= action.property.get_value() == "Another value";

  std::cout << "The name property of the implemented interface is '"
            << action.property_name().get_value() << "'." << std::endl;
  success &= action.property_name().get_value() == "";
  success &= get_name_called;

  // Check if other vfuncs leak memory. Use valgrind!
  action.get_parameter_type();
  action.get_state_type();
  action.get_state_type();
  action.get_state_hint_variant();
  action.get_state_variant();
  action.get_enabled();

  return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
