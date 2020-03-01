// Configuration-time test program, used in Meson build.
// Check whether the STL containers have templated sequence ctors,
// Corresponds to the M4 macro GLIBMM_CXX_HAS_TEMPLATE_SEQUENCE_CTORS.

#include <vector>
#include <deque>
#include <list>

int main()
{
  const int array[8] = { 0, };
  std::vector<int>  test_vector(&array[0], &array[8]);
  std::deque<short> test_deque(test_vector.begin(), test_vector.end());
  std::list<long>   test_list(test_deque.begin(),  test_deque.end());
  test_vector.assign(test_list.begin(), test_list.end());
  return 0;
}
