// Configuration-time test program, used in Meson build.
// Check for standard-conforming std::iterator_traits<>.
// Corresponds to the M4 macro GLIBMM_CXX_HAS_STD_ITERATOR_TRAITS.

#include <iterator>

int main()
{
  typedef std::iterator_traits<char*>::value_type ValueType;
  return 0;
}
