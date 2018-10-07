#include <glibmm.h>

#include <cstdlib>
#include <iostream>

namespace {

template <class... Ts>
void
test(Glib::ustring const& expected, Glib::ustring const& fmt, const Ts&... ts)
{
  auto actual = Glib::ustring::sprintf(fmt, ts...);

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
  Glib::init();

  test("No formatting here, just a boring string",
       "No formatting here, just a boring string");

  test("Interpolating another string: \"here it is\" and there it was gone.",
       "Interpolating another string: \"%s\" and there it was gone.", "here it is");

  test("some stuff and then an int: 42",
       "some stuff and then an int: %d", 42);

  const auto name = Glib::ustring{"Dennis"};
  const auto your_cows = 3;
  const auto my_cows = 11;
  const auto cow_percentage = 100.0 * your_cows / my_cows;
  test("Hi, Dennis! You have 3 cows.\nThat's about 27.27% of the 11 cows I have.",
       "Hi, %s! You have %d cows.\nThat's about %0.2f%% of the %d cows I have.",
       name, your_cows, cow_percentage, my_cows);

  return EXIT_SUCCESS;
}
