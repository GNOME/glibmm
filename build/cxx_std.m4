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

## GLIBMM_CXX_HAS_STD_ITERATOR_TRAITS()
##
## Check for standard-conform std::iterator_traits<>, and
## #define GLIBMM_HAVE_STD_ITERATOR_TRAITS on success.
##
AC_DEFUN([GLIBMM_CXX_HAS_STD_ITERATOR_TRAITS],
[
  AC_CACHE_CHECK(
    [whether the C++ library supports std::iterator_traits],
    [glibmm_cv_cxx_has_std_iterator_traits],
  [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
    [[
      #include <iterator>
      using namespace std;
    ]],[[
      typedef iterator_traits<char*>::value_type ValueType;
    ]])],
      [glibmm_cv_cxx_has_std_iterator_traits='yes'],
      [glibmm_cv_cxx_has_std_iterator_traits='no']
    )
  ])

  AS_VAR_IF([glibmm_cv_cxx_has_std_iterator_traits], ['yes'],
            [AC_DEFINE([GLIBMM_HAVE_STD_ITERATOR_TRAITS], [1],
                       [Defined if std::iterator_traits<> is standard-conforming])])[]dnl
])


## GLIBMM_CXX_HAS_SUN_REVERSE_ITERATOR()
##
## Check for Sun libCstd style std::reverse_iterator,
## and #define GLIBMM_HAVE_SUN_REVERSE_ITERATOR if found.
##
AC_DEFUN([GLIBMM_CXX_HAS_SUN_REVERSE_ITERATOR],
[
  AC_CACHE_CHECK(
    [for non-standard Sun libCstd reverse_iterator],
    [glibmm_cv_cxx_has_sun_reverse_iterator],
  [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
    [[
      #include <iterator>
      using namespace std;
    ]],[[
      typedef reverse_iterator<char*,random_access_iterator_tag,char,char&,char*,int> ReverseIter;
    ]])],
      [glibmm_cv_cxx_has_sun_reverse_iterator='yes'],
      [glibmm_cv_cxx_has_sun_reverse_iterator='no']
    )
  ])

  AS_VAR_IF([glibmm_cv_cxx_has_sun_reverse_iterator], ['yes'],
            [AC_DEFINE([GLIBMM_HAVE_SUN_REVERSE_ITERATOR], [1],
                       [Defined if std::reverse_iterator is in Sun libCstd style])])[]dnl
])


## GLIBMM_CXX_HAS_TEMPLATE_SEQUENCE_CTORS()
##
## Check whether the STL containers have templated sequence ctors,
## and #define GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS on success.
##
AC_DEFUN([GLIBMM_CXX_HAS_TEMPLATE_SEQUENCE_CTORS],
[
  AC_CACHE_CHECK(
    [whether STL containers have templated sequence constructors],
    [glibmm_cv_cxx_has_template_sequence_ctors],
  [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
    [[
      #include <vector>
      #include <deque>
      #include <list>
      using namespace std;
    ]],[[
      const int array[8] = { 0, };
      vector<int>  test_vector (&array[0], &array[8]);
      deque<short> test_deque  (test_vector.begin(), test_vector.end());
      list<long>   test_list   (test_deque.begin(),  test_deque.end());
      test_vector.assign(test_list.begin(), test_list.end());
    ]])],
      [glibmm_cv_cxx_has_template_sequence_ctors='yes'],
      [glibmm_cv_cxx_has_template_sequence_ctors='no']
    )
  ])

  AS_VAR_IF([glibmm_cv_cxx_has_template_sequence_ctors], ['yes'],
            [AC_DEFINE([GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS], [1],
                       [Defined if the STL containers have templated sequence ctors])])[]dnl
])

## GLIBMM_CXX_ALLOWS_STATIC_INLINE_NPOS()
##
## Check whether the a static member variable may be initialized inline to std::string::npos.
## The MipsPro (IRIX) compiler does not like this.
## and #define GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS on success.
##
AC_DEFUN([GLIBMM_CXX_ALLOWS_STATIC_INLINE_NPOS],
[
  AC_CACHE_CHECK(
    [whether the compiler allows a static member variable to be initialized inline to std::string::npos],
    [glibmm_cv_cxx_has_allows_static_inline_npos],
  [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
    [[
      #include <string>
      #include <iostream>

      class ustringtest
      {
        public:
        //The MipsPro compiler (IRIX) says "The indicated constant value is not known",
        //so we need to initalize the static member data elsewhere.
        static const std::string::size_type ustringnpos = std::string::npos;
      };
    ]],[[
      std::cout << "npos=" << ustringtest::ustringnpos << std::endl;
    ]])],
      [glibmm_cv_cxx_has_allows_static_inline_npos='yes'],
      [glibmm_cv_cxx_has_allows_static_inline_npos='no']
    )
  ])

  AS_VAR_IF([glibmm_cv_cxx_has_allows_static_inline_npos], ['yes'],
            [AC_DEFINE([GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS], [1],
                       [Defined if a static member variable may be initialized inline to std::string::npos])])[]dnl
])
