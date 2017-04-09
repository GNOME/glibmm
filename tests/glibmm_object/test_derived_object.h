#ifndef _GLIBMM_TEST_DERIVED_OBJECT_H
#define _GLIBMM_TEST_DERIVED_OBJECT_H

#include <glibmm.h>

// A basic derived GObject, just to test Glib::Object.
typedef struct
{
  GObject parent;
} TestDerived;

typedef struct
{
  GObjectClass parent;
} TestDerivedClass;

#define TEST_TYPE_DERIVED (test_derived_get_type())
#define TEST_DERIVED(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), TEST_TYPE_DERIVED, TestDerived))
#define TEST_DERIVED_CLASS(cls) \
  (G_TYPE_CHECK_CLASS_CAST((cls), TEST_TYPE_DERIVED, TestDerivedClass))
#define TEST_DERIVED_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS((obj), TEST_TYPE_DERIVED, TestDerivedClass))

static void
test_derived_class_init(TestDerivedClass*)
{
}
static void
test_derived_init(TestDerived*)
{
}

G_DEFINE_TYPE(TestDerived, test_derived, G_TYPE_OBJECT)

class DerivedObject : public Glib::Object
{
public:
  // A real application would never make the constructor public.
  // It would instead have a protected constructor and a public create() method.
  DerivedObject(GObject* gobject, int i) : Glib::Object(gobject), i_(i) {}

  DerivedObject(const DerivedObject& src) = delete;
  DerivedObject& operator=(const DerivedObject& src) = delete;

  DerivedObject(DerivedObject&& src) noexcept : Glib::Object(std::move(src)), i_(std::move(src.i_))
  {
  }

  DerivedObject& operator=(DerivedObject&& src) noexcept
  {
    Glib::Object::operator=(std::move(src));
    i_ = std::move(src.i_);

    return *this;
  }

  int i_;
};

#endif // _GLIBMM_TEST_DERIVED_OBJECT_H
