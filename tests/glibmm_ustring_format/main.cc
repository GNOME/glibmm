#include <glibmm.h>

#include <iomanip>
#include <iostream>

int
main(int, char**)
{
  // Don't use the user's preferred locale. The decimal delimiter may be ','
  // instead of the expected '.'.
  Glib::set_init_to_users_preferred_locale(false);

  Glib::init();

  char carr[10] = "Užduotys";
  char* const cptr = carr;

  /*
  std::wostringstream wsout;
  wsout << carr;
  const std::wstring& wstr = wsout.str();
  const gunichar * const data = reinterpret_cast<const gunichar *>(
                                  wstr.data());

  for(int i = 0; wstr.size() > i; ++i)
    std::cout << data[i] << std::endl;
  */

  // Check both the const char* and char* versions.
  Glib::ustring::format(carr);

  // This threw an exception before we added a ustring::FormatStream::stream(char*) overload.
  Glib::ustring::format(cptr);

  // Test substitution of various types and I/O manipulators
  Glib::ustring expected("The meaning of life is 42, or with 2 decimal places, 42.00.");
  auto the = "The";
  std::string meaning("meaning");
  Glib::ustring life("life");
  auto number = 42.0;
  auto places = 2;
  auto actual = Glib::ustring::format(the, ' ', meaning, " of ", life, " is ",
                                      number,
                                      ", or with ", places, " decimal places, ",
                                      std::fixed, std::setprecision(places), number,
                                      '.');

  if (actual != expected)
  {
    std::cerr << "expected (" << expected.size() << "):\n" << expected << "\n\n"
              << "actual   (" << actual  .size() << "):\n" << actual   << "\n";

    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
