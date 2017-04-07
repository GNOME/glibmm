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
}

// Glib::Object RefPtr<>

// template Glib::Value< Glib::RefPtr<Gdk::Pixbuf> >;
// template Glib::Value< Glib::RefPtr<const Gdk::Pixbuf> >;
//

int main() {
  test();

  return EXIT_SUCCESS;
}
