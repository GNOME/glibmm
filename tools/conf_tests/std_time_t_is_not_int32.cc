// Configuration-time test program, used in Meson build.
// Test whether std::time_t and gint32 are typedefs of the same builting type.
// If they aren't then they can be used for method overload.
// Corresponds to the M4 macro GLIBMM_C_STD_TIME_T_IS_NOT_INT32.

#include <ctime>

int main()
{
  typedef signed int gint32;
  class Test
  {
    void something(gint32 val)
    {}

    void something(std::time_t val)
    {}
  };
  return 0;
}
