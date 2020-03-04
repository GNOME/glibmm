// Configuration-time test program, used in Meson build.
// Test whether the compiler allows member functions to refer to spezialized
// member function templates.
// Corresponds to the M4 macro GLIBMM_CXX_MEMBER_FUNCTIONS_MEMBER_TEMPLATES.

struct foo
{
  template <class C> inline void doit();
  void thebug();
};

template <class C>
inline void foo::doit()
{}

struct bar
{
  void neitherabug();
};

void bar::neitherabug()
{
  void (foo::*func)();
  func = &foo::doit<int>;
  (void)func;
}

void foo::thebug()
{
  void (foo::*func)();
  func = &foo::doit<int>; // the compiler bugs usually show here
  (void)func;
}

int main()
{
  void (foo::*func)();
  func = &foo::doit<int>;
  (void)func;
  return 0;
}
