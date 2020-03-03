// Configuration-time test program, used in Meson build.
// Check whether the compiler finds it ambiguous to have both const and
// non-const template specializations. The SUN Forte compiler has this
// problem, though we are not 100% sure that it's a C++ standard violation.
// Corresponds to the M4 macro GLIBMM_CXX_CAN_DISAMBIGUATE_CONST_TEMPLATE_SPECIALIZATIONS.

template <class T> class Foo {};

template <class T> class Traits
{
public:
  const char* whoami() { return "generic template"; }
};

template <class T> class Traits< Foo<T> >
{
public:
  const char* whoami() { return "partial specialization for Foo<T>"; }
};

template <class T> class Traits< Foo<const T> >
{
public:
  const char* whoami() { return "partial specialization for Foo<const T>"; }
};

int main()
{
  Traits<int> it;
  Traits< Foo<int> > fit;
  Traits< Foo<const int> > cfit;

  (void) it.whoami();
  (void) fit.whoami();
  (void) cfit.whoami();
  return 0;
}
