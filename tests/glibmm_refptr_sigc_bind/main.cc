// Bug 564005 - Valgrind errors and crash on exit with Gtk::UIManager
// Bug 154498 - Unnecessary warning on console: signalproxy_connectionnode.cc

#include <glibmm/refptr.h>
#include <iostream>
#include <sigc++/sigc++.h>
#include <stdlib.h>

#define ACTIVATE_BUG 1

class Action : public sigc::trackable
{
public:
  Action() : ref_count(1) {}

  void reference() { ++ref_count; }
  void unreference()
  {
    if (--ref_count <= 0)
      delete this;
  }

  void emit_sig1(int n) { sig1.emit(n); }

  sigc::signal<void(int)>& signal_sig1() { return sig1; }

private:
  sigc::signal<void(int)> sig1;
  int ref_count;
};

class Test : public sigc::trackable
{
public:
  Test() : action(new Action)
  {
// std::cout << "new Test" << std::endl;
#ifdef ACTIVATE_BUG // See https://bugzilla.gnome.org/show_bug.cgi?id=564005#c15s
    action->signal_sig1().connect(sigc::bind(sigc::mem_fun(*this, &Test::on_sig1), action));
#else
    Glib::RefPtr<Action> action2(new Action);
    action->signal_sig1().connect(sigc::bind(sigc::mem_fun(*this, &Test::on_sig1), action2));
#endif
  }

  ~Test()
  {
    // std::cout << "delete Test" << std::endl;
  }

  void on_sig1(int /* n */, Glib::RefPtr<Action> /* action */)
  {
    // std::cout << "Test::on_sig1, n=" << n << std::endl;
  }

  Glib::RefPtr<Action> action;

}; // end Test

int
main(int, char**)
{
  Test* test = new Test;

  test->action->emit_sig1(23);
  delete test;

  return EXIT_SUCCESS;
}
