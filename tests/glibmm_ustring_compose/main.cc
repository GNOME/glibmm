#include <glibmm.h>

#include <iostream>

int main(int, char**)
{
  Glib::init();

  const char *constant_string = "constant string";
  std::cout << Glib::ustring::compose("Compose strings: %1", constant_string) << std::endl;
  std::cout << Glib::ustring::compose("Compose strings: %1 and %2", constant_string, "string_literal") << std::endl;

  std::cout << Glib::ustring::compose("Compose strings: %1 and %2", 123, 123.4567) << std::endl;

  std::cout << Glib::ustring::compose("Compose strings: %1 and %2", (int)123, (float)123.4567) << std::endl;

  std::cout << Glib::ustring::compose("Compose strings: %1 and %2", Glib::ustring("foo"), std::string("goo")) << std::endl;

  int i = 1;
  std::cout << Glib::ustring::compose("Compose strings: %1 and %2", 'f', &i) << std::endl;

  std::cout << Glib::ustring::compose("%1 is lower than 0x%2.", 12, Glib::ustring::format(std::hex, 16)) << std::endl;

  //TODO: More tests.

  return 0;
}

