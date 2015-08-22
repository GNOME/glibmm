#include <glibmm.h>
#include <iostream>
#include <stdlib.h>

class Derived : Glib::Object
{
public:
  //A real application would never make the constructor public.
  //It would instead have a protectd constructor and a public create() method.
  Derived(int i)
  : Glib::Object(),
    i_(i)
  {
  }

  Derived(const Derived& src) = delete;
  Derived& operator=(const Derived& src) = delete;

  Derived(Derived&& src)
  : Glib::Object(std::move(src)),
    i_(std::move(src.i_))
  {}

  Derived& operator=(Derived&& src)
  {
    Glib::Object::operator=(std::move(src));
    i_ = std::move(src.i_);

    return *this;
  }

  int i_;
};

static
void test_object_move_constructor()
{
  Derived derived(5);
  Derived derived2 = std::move(derived);
  g_assert_cmpint(derived2.i_, ==, 5);
}

int main(int, char**)
{
  test_object_move_constructor();

  return EXIT_SUCCESS;
}
