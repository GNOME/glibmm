#include <glibmm.h>

#include <iostream>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

int
main(int, char**)
{
  Glib::init();

  // TODO: Check the output?
  const char* constant_string = "constant string";
  ostr << Glib::ustring::compose("Compose strings: %1", constant_string) << std::endl;
  ostr << Glib::ustring::compose("Compose strings: %1 and %2", constant_string, "string_literal")
       << std::endl;

  ostr << Glib::ustring::compose("Compose strings: %1 and %2", 123, 123.4567) << std::endl;

  ostr << Glib::ustring::compose("Compose strings: %1 and %2", (int)123, (float)123.4567)
       << std::endl;

  ostr << Glib::ustring::compose(
            "Compose strings: %1 and %2", Glib::ustring("foo"), std::string("goo"))
       << std::endl;

  int i = 1;
  ostr << Glib::ustring::compose("Compose strings: %1 and %2", 'f', &i) << std::endl;

  ostr << Glib::ustring::compose("%1 is lower than 0x%2.", 12, Glib::ustring::format(std::hex, 16))
       << std::endl;

  // TODO: More tests.

  return EXIT_SUCCESS;
}
