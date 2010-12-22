#include <glibmm.h>
#include <iostream>

int main(int, char**)
{
  Glib::init();

  int int_list[] = {1, 2, 3, 4, 5, 6, 7, 8};

  std::vector<int> int_vector(int_list,
    int_list + sizeof(int_list) / sizeof(int));

  std::cout << "The elements of the original vector are:" << std::endl;

  for(guint i = 0; i < int_vector.size(); i++)
    std::cout << int_vector[i] << std::endl;

  Glib::Variant< std::vector<int> > integers_variant =
    Glib::Variant< std::vector<int> >::create(int_vector);

  std::vector<int> int_vector2 = integers_variant.get();

  std::cout << "The size of the copied vector is " << int_vector2.size() <<
    '.' << std::endl;

  std::cout << "The elements of the copied vector are:" << std::endl;

  for(guint i = 0; i < int_vector2.size(); i++)
    std::cout << int_vector2[i] << std::endl;

  std::cout << "The number of children in the iterator of the " <<
    "variant are " << integers_variant.get_iter().get_n_children() <<
    '.' << std::endl;

  int index = 4;
  std::cout << "Element number " << index + 1 << " in the copy is " <<
    integers_variant.get(index) << '.' << std::endl;

  return 0;
}
