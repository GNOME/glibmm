#include "../glibmm_object/test_derived_object.h"
#include <glibmm.h>
#include <cassert>

struct Foo
{
  int bar = 1;
};

namespace Gtk
{

class Widget {
};

}

void
test()
{
  {
    Foo foo;

    // custom copyable
    Glib::Value<Foo> value;
    value.init(Glib::Value<Foo>::value_type()); // TODO: Avoid this step?
    value.set(foo);

    const auto v = value.get();
    assert(v.bar == 1);
  }

  {
    Foo foo;

    // custom pointer
    Glib::Value<Foo*> value;
    value.init(Glib::Value<Foo*>::value_type()); // TODO: Avoid this step?
    value.set(&foo);

    const auto v = value.get();
    assert(v);
  }

  {
    Foo foo;

    Glib::Value<const Foo*> value;
    value.init(Glib::Value<const Foo*>::value_type()); // TODO: Avoid this step?
    value.set(&foo);

    const auto v = value.get();
    assert(v);
  }

  {
    Gtk::Widget widget;

    // Glib::Object pointer
    Glib::Value<Gtk::Widget*> value;
    value.init(Glib::Value<Gtk::Widget*>::value_type()); // TODO: Avoid this step?
    value.set(&widget);

    const auto v = value.get();
    assert(v);
  }

  {
    Gtk::Widget widget;

    Glib::Value<const Gtk::Widget*> value;
    value.init(Glib::Value<const Gtk::Widget*>::value_type()); // TODO: Avoid this step?
    value.set(&widget);

    const auto v = value.get();
    assert(v);
  }

  Glib::init();

  // TODO: Put this test, of internal stuff, somewhere else.
  static_assert(Glib::Traits::HasGetBaseType<DerivedObject, GType()>::value,
    "DerivedObject has no get_base_type().");

  // RefPtr to Glib::ObjectBase-derived type:
  {
    GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
    auto derived = Glib::make_refptr_for_instance(new DerivedObject(gobject, 5));

    using ValueType = Glib::Value<Glib::RefPtr<DerivedObject>>;
    ValueType value;
    value.init(ValueType::value_type()); // TODO: Avoid this step?

    // Check that value_type() returns the type of the underlying GObjectBase,
    // not a custom GType for the Glib::RefPtr:
    assert(ValueType::value_type() == DerivedObject::get_base_type());

    value.set(derived);

    const auto v = value.get();
    assert(v);
  }

  {
    GObject* gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
    auto derived = Glib::make_refptr_for_instance(new DerivedObject(gobject, 5));

    using ValueType = Glib::Value<Glib::RefPtr<const DerivedObject>>;
    ValueType value;
    value.init(ValueType::value_type()); // TODO: Avoid this step?

    // Check that value_type() returns the type of the underlying GObjectBase,
    // not a custom GType for the Glib::RefPtr:
    assert(ValueType::value_type() == DerivedObject::get_base_type());

    value.set(derived);

    const auto v = value.get();
    assert(v);
  }

  {
    auto foo = std::make_shared<Foo>();

    // custom pointer
    Glib::Value<std::shared_ptr<Foo>> value;
    value.init(Glib::Value<std::shared_ptr<Foo>>::value_type()); // TODO: Avoid this step?
    value.set(foo);

    const auto v = value.get();
    assert(v);
  }

  {
    auto foo = std::make_shared<Foo>();

    Glib::Value<std::shared_ptr<const Foo>> value;
    value.init(Glib::Value<std::shared_ptr<const Foo>>::value_type()); // TODO: Avoid this step?
    value.set(foo);

    const auto v = value.get();
    assert(v);
  }
}

// Glib::Object RefPtr<>

// template Glib::Value< Glib::RefPtr<Gdk::Pixbuf> >;
// template Glib::Value< Glib::RefPtr<const Gdk::Pixbuf> >;
//

int main() {
  test();

  return EXIT_SUCCESS;
}
