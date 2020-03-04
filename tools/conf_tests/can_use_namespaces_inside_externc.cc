// Configuration-time test program, used in Meson build.
// Check whether the compiler puts extern "C" functions in the global
// namespace, even inside a namespace declaration. The AIX xlC compiler does
// this, and also gets confused if we declare the namespace again inside the
// extern "C" block.
// Corresponds to the M4 macro GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC.

namespace test
{

extern "C" { void do_something(); }

class Something
{
  int i;
  friend void do_something();
};

void do_something()
{
  Something something;
  something.i = 1;
}

} // namespace test
