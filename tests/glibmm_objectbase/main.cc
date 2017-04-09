#include "test_derived_objectbase.h"
#include "../glibmm_object/test_derived_object.h"
#include <glibmm.h>
#include <iostream>
#include <stdlib.h>

static void
test_objectbase()
{
  GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  DerivedObjectBase derived(gobject, 5);
  // std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);
}

int
main(int, char**)
{
  Glib::init();

  test_objectbase();

  return EXIT_SUCCESS;
}
