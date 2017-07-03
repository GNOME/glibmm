#include "test_derived_object.h"
#include <glibmm.h>
#include <iostream>
#include <stdlib.h>

static void
test_object()
{
  GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  DerivedObject derived(gobject, 5);
  // std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);
}

int
main(int, char**)
{
  Glib::init();

  test_object();

  return EXIT_SUCCESS;
}
