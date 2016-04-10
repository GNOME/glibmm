// Bug 564005 - Valgrind errors and crash on exit with Gtk::UIManager
// Bug 154498 - Unnecessary warning on console: signalproxy_connectionnode.cc

#include <glibmm.h>
#include <iostream>
#include <sigc++/sigc++.h>
#include <stdlib.h>

#define ACTIVATE_BUG 1

// A class with its own reference-count, for use with RefPtr.
class Something
{
public:
  Something() : ref_count_(1), max_ref_count_(ref_count_) {}

  void reference()
  {
    ++ref_count_;

    // Track the highest-ever max count.
    if (max_ref_count_ < ref_count_)
      max_ref_count_ = ref_count_;
  }

  void unreference()
  {
    if (--ref_count_ <= 0)
      delete this;
  }

  // Just so we can check it in our test.
  int ref_count() { return ref_count_; }

  // Just so we can check it in our test.
  int max_ref_count() { return max_ref_count_; }

private:
  int ref_count_;
  int max_ref_count_;
};

class SomethingDerived : public Something
{
};

class Parent
{
public:
  explicit Parent(const Glib::RefPtr<Something>& something)
  : something_(something),
    was_constructed_via_copy_constructor_(true),
    was_constructed_via_move_constructor_(false)
  {
  }

  explicit Parent(Glib::RefPtr<Something>&& something)
  : something_(std::move(something)),
    was_constructed_via_copy_constructor_(false),
    was_constructed_via_move_constructor_(true)
  {
  }

  // Non copyable
  Parent(const Parent& src) = delete;
  Parent& operator=(const Parent& src) = delete;

  bool was_constructed_via_copy_constructor() const
  {
    return was_constructed_via_copy_constructor_;
  }

  bool was_constructed_via_move_constructor() const
  {
    return was_constructed_via_move_constructor_;
  }

  int something_ref_count() const { return something_->ref_count(); }

  int something_max_ref_count() const { return something_->max_ref_count(); }

private:
  Glib::RefPtr<Something> something_;
  bool was_constructed_via_copy_constructor_;
  bool was_constructed_via_move_constructor_;
};

static void
test_initial_refcount()
{
  Glib::RefPtr<Something> refSomething(new Something());
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

static void
test_refptr_copy_constructor()
{
  Glib::RefPtr<Something> refSomething(new Something());
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);

  {
    //The reference count should not change,
    //because we only take and release a single reference:
    Glib::RefPtr<Something> refSomething2(refSomething);
    g_assert_cmpint(refSomething->ref_count(), ==, 1);
    g_assert_cmpint(refSomething2->ref_count(), ==, 1);
    g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
  }

  // Test the refcount after other references should have been released
  // when other RefPtrs went out of scope:
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

static void
test_refptr_assignment_operator()
{
  Glib::RefPtr<Something> refSomething(new Something());
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);

  {
    //The reference count should not change,
    //because we only take and release a single reference:
    Glib::RefPtr<Something> refSomething2 = refSomething;
    g_assert_cmpint(refSomething->ref_count(), ==, 1);
    g_assert_cmpint(refSomething2->ref_count(), ==, 1);
    g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
  }

  // Test the refcount after other references should have been released
  // when other RefPtrs went out of scope:
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

static Glib::RefPtr<Something>
get_something()
{
  static Glib::RefPtr<Something> something_to_get;

  // Reinitialize it each time:
  something_to_get = Glib::make_refptr_for_instance<Something>(new Something());

  return something_to_get;
}

static void
test_refptr_with_parent_copy_constructor()
{
  // We use get_something() because test_refptr_with_parent_move_constructor() does.
  //The reference count should not change,
  //because we only take and release a single reference:
  Glib::RefPtr<Something> refSomething = get_something();
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);

  {
    Parent parent(refSomething);
    g_assert(!parent.was_constructed_via_move_constructor());
    g_assert(parent.was_constructed_via_copy_constructor());
    g_assert_cmpint(
      parent.something_ref_count(), ==, 1);
    g_assert_cmpint(parent.something_max_ref_count(), ==, 1);
  }

  // Test the refcount after other references should have been released
  // when other RefPtrs went out of scope:
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

static void
test_refptr_with_parent_move_constructor()
{
  Parent parent(get_something());
  g_assert(parent.was_constructed_via_move_constructor());
  g_assert(!parent.was_constructed_via_copy_constructor());
  g_assert_cmpint(parent.something_ref_count(), ==, 1);
  g_assert_cmpint(parent.something_max_ref_count(), ==, 1);
}

static void
test_refptr_move_constructor()
{
  Glib::RefPtr<Something> refSomething(new Something());
  Glib::RefPtr<Something> refSomething2(std::move(refSomething));
  g_assert_cmpint(refSomething2->ref_count(), ==, 1);
  g_assert(!refSomething);
  g_assert_cmpint(refSomething2->max_ref_count(), ==, 1);
}

static void
test_refptr_move_assignment_operator()
{
  Glib::RefPtr<Something> refSomething(new Something());
  Glib::RefPtr<Something> refSomething2;
  refSomething2 = std::move(refSomething);
  g_assert_cmpint(refSomething2->ref_count(), ==, 1);
  g_assert(!refSomething);
  g_assert_cmpint(refSomething2->max_ref_count(), ==, 1);
}

static void
test_refptr_universal_reference_move_constructor()
{
  Glib::RefPtr<SomethingDerived> refSomethingDerived(new SomethingDerived());
  Glib::RefPtr<Something> refSomething(std::move(refSomethingDerived));
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert(!refSomethingDerived);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

static void
test_refptr_universal_reference_asignment_operator()
{
  Glib::RefPtr<SomethingDerived> refSomethingDerived(new SomethingDerived());
  Glib::RefPtr<Something> refSomething;
  refSomething = std::move(refSomethingDerived);
  g_assert_cmpint(refSomething->ref_count(), ==, 1);
  g_assert(!refSomethingDerived);
  g_assert_cmpint(refSomething->max_ref_count(), ==, 1);
}

int
main(int, char**)
{
  // Test initial refcount:
  test_initial_refcount();

  // Test refcount when using the RefPtr copy constructor:
  test_refptr_copy_constructor();

  // Test refcount when using the RefPtr assignment operator (operator=):
  test_refptr_assignment_operator();

  // Test the refcount when using the RefPtr move constuctor:
  test_refptr_move_constructor();

  // Test the refcount when using the RefPtr move asignment operator (operator=):
  test_refptr_move_assignment_operator();

  // Test the refcount when another class makes a copy via its constructor:
  test_refptr_with_parent_copy_constructor();

  // Test the refcount when another class makes a copy via its
  //(perfect-forwarding) move constructor, which should not involve a temporary
  // instance:
  test_refptr_with_parent_move_constructor();

  // Test the refcount when using the RefPtr move constructor with derived class
  // as an argument.
  test_refptr_universal_reference_move_constructor();

  // Test the refcount when using the RefPtr assignment operator (operator=)
  // with derived class as an argument.
  test_refptr_universal_reference_asignment_operator();

  return EXIT_SUCCESS;
}
