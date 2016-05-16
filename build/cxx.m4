## Copyright (c) 2009, 2011  Openismus GmbH  <http://www.openismus.com/>
##
## This file is part of glibmm.
##
## glibmm is free software: you can redistribute it and/or modify it
## under the terms of the GNU Lesser General Public License as published
## by the Free Software Foundation, either version 2.1 of the License,
## or (at your option) any later version.
##
## glibmm is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.

#serial 20110910

## GLIBMM_CXX_MEMBER_FUNCTIONS_MEMBER_TEMPLATES
##
## Test whether the compiler allows member functions to refer to spezialized
## member function templates.  Some compilers have problems with this.  GCC
## 2.95.3 aborts with an internal compiler error.
##
AC_DEFUN([GLIBMM_CXX_MEMBER_FUNCTIONS_MEMBER_TEMPLATES],
[dnl
AC_CACHE_CHECK(
  [whether C++ member functions may refer to member templates],
  [glibmm_cv_cxx_member_functions_member_templates],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
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
]], [[
void (foo::*func)();
func = &foo::doit<int>;
(void)func;
]])],
    [glibmm_cv_cxx_member_functions_member_templates=yes],
    [glibmm_cv_cxx_member_functions_member_templates=no])])

AS_VAR_IF([glibmm_cv_cxx_member_functions_member_templates], ['yes'],
          [AC_DEFINE([GLIBMM_MEMBER_FUNCTIONS_MEMBER_TEMPLATES], [1],
                     [Define if C++ member functions may refer to member templates.])])[]dnl
])

## GLIBMM_CXX_CAN_DISAMBIGUATE_CONST_TEMPLATE_SPECIALIZATIONS
##
## Check whether the compiler finds it ambiguous to have both const and
## non-const template specializations.  The SUN Forte compiler has this
## problem, though we are not 100% sure that it's a C++ standard violation.
##
AC_DEFUN([GLIBMM_CXX_CAN_DISAMBIGUATE_CONST_TEMPLATE_SPECIALIZATIONS],
[dnl
AC_CACHE_CHECK(
  [whether the compiler disambiguates template specializations for const and non-const types],
  [glibmm_cv_cxx_can_disambiguate_const_template_specializations],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
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
]], [[
Traits<int> it;
Traits< Foo<int> > fit;
Traits< Foo<const int> > cfit;

(void) it.whoami();
(void) fit.whoami();
(void) cfit.whoami();
]])],
    [glibmm_cv_cxx_can_disambiguate_const_template_specializations=yes],
    [glibmm_cv_cxx_can_disambiguate_const_template_specializations=no])])

AS_VAR_IF([glibmm_cv_cxx_can_disambiguate_const_template_specializations], ['yes'],
          [AC_DEFINE([GLIBMM_HAVE_DISAMBIGUOUS_CONST_TEMPLATE_SPECIALIZATIONS], [1],
                     [Define if the compiler disambiguates template specializations for const and non-const types.])])[]dnl
])

## GLIBMM_CXX_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION
##
## Check whether the compiler allows us to define a template that uses
## dynamic_cast<> with an object whose type is not defined, even if we do
## not use that template before we have defined the type.  This should
## probably not be allowed anyway.
##
AC_DEFUN([GLIBMM_CXX_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION],
[dnl
AC_CACHE_CHECK(
  [whether the compiler allows dynamic_cast<> to undefined types in non-instantiated templates],
  [glibmm_cv_cxx_can_use_dynamic_cast_in_unused_template_without_definition],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
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
]], [])],
    [glibmm_cv_cxx_can_use_dynamic_cast_in_unused_template_without_definition=yes],
    [glibmm_cv_cxx_can_use_dynamic_cast_in_unused_template_without_definition=no])])

AS_VAR_IF([glibmm_cv_cxx_can_use_dynamic_cast_in_unused_template_without_definition], ['yes'],
          [AC_DEFINE([GLIBMM_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION], [1],
                     [Define if non-instantiated templates may dynamic_cast<> to an undefined type.])])[]dnl
])

## GLIBMM_CXX_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS
##
## Check whether the compiler allows us to use a non-extern "C" function,
## such as a static member function, to an extern "C" function pointer,
## such as a GTK+ callback.
##
AC_DEFUN([GLIBMM_CXX_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS],
[dnl
AC_CACHE_CHECK(
  [whether extern "C" and extern "C++" function pointers are compatible],
  [glibmm_cv_cxx_can_assign_non_extern_c_functions_to_extern_c_callbacks],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
extern "C"
{
struct somestruct
{
  void (*callback) (int);
};
} // extern "C"

void somefunction(int) {}
]], [[
somestruct something;
something.callback = &somefunction;
]])],
    [glibmm_cv_cxx_can_assign_non_extern_c_functions_to_extern_c_callbacks=yes],
    [glibmm_cv_cxx_can_assign_non_extern_c_functions_to_extern_c_callbacks=no])])

AS_VAR_IF([glibmm_cv_cxx_can_assign_non_extern_c_functions_to_extern_c_callbacks], ['yes'],
          [AC_DEFINE([GLIBMM_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS], [1],
                     [Define if extern "C" and extern "C++" function pointers are compatible.])])[]dnl
])

## GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC
##
## Check whether the compiler puts extern "C" functions in the global
## namespace, even inside a namespace declaration. The AIX xlC compiler does
## this, and also gets confused if we declare the namespace again inside the
## extern "C" block.  This seems like a compiler bug, but not a serious one.
##
## It is debatable whether it is a bug at all, since the namespace would only
## exist at the compiler level anyway, but not be a part of the exported
## symbol name.  (For the functions in question, it was my fault not to add
## the namespace prefix to the function name.  Sorry. --danielk)
##
AC_DEFUN([GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC],
[dnl
AC_CACHE_CHECK(
  [whether the compiler honors namespaces inside extern "C" blocks],
  [glibmm_cv_cxx_can_use_namespaces_inside_externc],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
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
]], [])],
    [glibmm_cv_cxx_can_use_namespaces_inside_externc=yes],
    [glibmm_cv_cxx_can_use_namespaces_inside_externc=no])])

AS_VAR_IF([glibmm_cv_cxx_can_use_namespaces_inside_externc], ['yes'],
          [AC_DEFINE([GLIBMM_CAN_USE_NAMESPACES_INSIDE_EXTERNC], [1],
                     [Define if the compiler honors namespaces inside extern "C" blocks.])])[]dnl
])

## GLIBMM_CXX_CAN_USE_THREAD_LOCAL
##
## Check for thread_local support
##
AC_DEFUN([GLIBMM_CXX_CAN_USE_THREAD_LOCAL],
[dnl
AC_CACHE_CHECK(
  [whether the thread_local keyword is supported],
  [glibmm_cv_cxx_can_use_thread_local],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
[[
thread_local int i=0;
]], [])],
    [glibmm_cv_cxx_can_use_thread_local=yes],
    [glibmm_cv_cxx_can_use_thread_local=no])])

AS_VAR_IF([glibmm_cv_cxx_can_use_thread_local], ['yes'],
          [AC_DEFINE([GLIBMM_CAN_USE_THREAD_LOCAL], [1],
                     [Define if the thread_local keyword is supported.])])[]dnl
])
