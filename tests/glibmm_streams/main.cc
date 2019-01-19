#include <glibmm.h>

#include <iomanip>
#include <iostream>

int
main(int, char**)
{
  Glib::init();

  char test_obj[10] = "test_value";
  char* const test_ptr = test_obj;


  if (actual != expected)
  {
    std::cerr << "expected (" << expected.size() << "):\n" << expected << "\n\n"
              << "actual   (" << actual  .size() << "):\n" << actual   << "\n";

    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

