// Configuration-time test program, used in Meson build.
// Check for Sun libCstd style std::reverse_iterator,
// Corresponds to the M4 macro GLIBMM_CXX_HAS_SUN_REVERSE_ITERATOR.

#include <iterator>

int main()
{
  typedef std::reverse_iterator<char*, std::random_access_iterator_tag, char, char&, char*, int> ReverseIter;
  return 0;
}
