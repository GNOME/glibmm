#include <glibmm/init.h>
#include <glibmm/ustring.h>

#include <cstdlib>
#include <iostream>

namespace {

template <class... Ts>
void
test(const Glib::ustring& expected, const Glib::ustring& fmt, const Ts&... ts)
{
  const auto actual = Glib::ustring::sprintf(fmt, ts...);

  if (actual != expected)
  {
    std::cerr << "error testing Glib::ustring::sprintf():\n"
      "expected (" << expected.size() << "):\n" << expected << "\n\n"
      "actual   (" << actual  .size() << "):\n" << actual   << "\n";

    std::exit(EXIT_FAILURE);
  }
}

} // anonymous namespace

int
main(int, char**)
{
  // Don't use the user's preferred locale. The decimal delimiter may be ','
  // instead of the expected '.'.
  Glib::set_init_to_users_preferred_locale(false);

  Glib::init();

  test("No formatting here, just a boring string",
       "No formatting here, just a boring string");

  test("Interpolating another string: \"here it is\" and there it was gone.",
       "Interpolating another string: \"%s\" and there it was gone.", "here it is");

  test("some stuff and then an int: 42",
       "some stuff and then an int: %d", 42);

  const auto greeting = std::string{"Hi"};
  const auto name = Glib::ustring{"Dennis"};
  const auto your_cows = 3;
  const auto my_cows = 11;
  const auto cow_percentage = 100.0 * your_cows / my_cows;
  test("Hi, Dennis! You have 3 cows.\nThat's about 27.27% of the 11 cows I have.",
       "%s, %s! You have %d cows.\nThat's about %0.2f%% of the %d cows I have.",
       greeting, name, your_cows, cow_percentage, my_cows);

  return EXIT_SUCCESS;
}
