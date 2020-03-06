// Configuration-time test program, used in Meson build.
// Check whether the compiler allows us to define a template that uses
// dynamic_cast<> with an object whose type is not defined, even if we do
// not use that template before we have defined the type. This should
// probably not be allowed anyway.
// Corresponds to the M4 macro GLIBMM_CXX_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION.

class SomeClass;

SomeClass* some_function();

template <class T>
class SomeTemplate
{
  static bool do_something()
  {
    // This does not compile with the MipsPro (IRIX) compiler
    // even if we don't use this template at all.
    return (dynamic_cast<T*>(some_function()) != 0);
  }
};
