// Configuration-time test program, used in Meson build.
// Check whether std::wostringstream exists.
// Corresponds to some code in configure.ac.

#include <sstream>

int main()
{
  std::wostringstream s;
  (void) s.str();
  return 0;
}
