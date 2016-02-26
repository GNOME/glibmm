#include <glibmm.h>
#include <iostream>
#include <string>

int
main()
{
  Glib::RefPtr<Glib::ByteArray> array(Glib::ByteArray::create());
  guint8 data[] = { 1, 2, 3, 4, 5, 6 };

  array->append(data, sizeof(data));
  // |1, 2, 3, 4, 5, 6| = 6
  g_assert(array->size() == 6);

  array->prepend(data, sizeof(data));
  // |1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6| = 12
  g_assert(array->size() == 12);

  array->remove_index(0);
  // |2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6| = 11
  g_assert(array->size() == 11);

  array->remove_index_fast(0);
  // |6, 3, 4, 5, 6, 1, 2, 3, 4, 5| = 10
  g_assert(array->size() == 10);

  array->remove_range(0, 4);
  // |6, 1, 2, 3, 4, 5,| = 6
  g_assert(array->size() == 6);

  array->set_size(2);
  // |6, 1| = 2
  g_assert(array->size() == 2);

  guint8* array_data = array->get_data();
  g_assert(array_data[0] == 6);
  g_assert(array_data[1] == 1);
}
