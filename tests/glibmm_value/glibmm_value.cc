
#include <glibmm.h>
#include <gdkmm.h>
#include <gtkmm.h>

struct Foo { int bar; };

// custom copyable
template Glib::Value<Foo>;

// custom pointer
template Glib::Value<Foo*>;
template Glib::Value<const Foo*>;

// Glib::Object pointer
template Glib::Value<Gtk::Widget*>;
template Glib::Value<const Gtk::Widget*>;

// Glib::Object RefPtr<>
template Glib::Value< Glib::RefPtr<Gdk::Pixbuf> >;
template Glib::Value< Glib::RefPtr<const Gdk::Pixbuf> >;

