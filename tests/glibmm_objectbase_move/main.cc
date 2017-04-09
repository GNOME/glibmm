#include "../glibmm_objectbase/test_derived_objectbase.h"
#include "../glibmm_object/test_derived_object.h"
#include <glibmm.h>
#include <iostream>
#include <stdlib.h>

static void
test_objectbase_move_constructor()
{
  GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  DerivedObjectBase derived(gobject, 5);
  // std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);

  DerivedObjectBase derived2(std::move(derived));
  g_assert_cmpint(derived2.i_, ==, 5);
  // std::cout << "debug: gobj(): " << derived2.gobj() << std::endl;
  g_assert(derived2.gobj() == gobject);
  g_assert(derived.gobj() == nullptr);
}

static void
test_objectbase_move_assignment_operator()
{
  GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  DerivedObjectBase derived(gobject, 5);
  // std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);

  GObject* gobject2 = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  DerivedObjectBase derived2(gobject2, 6);
  derived2 = std::move(derived);
  g_assert_cmpint(derived2.i_, ==, 5);
  // std::cout << "debug: gobj(): " << derived2.gobj() << std::endl;
  g_assert(derived2.gobj() == gobject);
  g_assert(derived.gobj() == nullptr);
}

int
main(int, char**)
{
  Glib::init();

  test_objectbase_move_constructor();
  test_objectbase_move_assignment_operator();

  return EXIT_SUCCESS;
}
