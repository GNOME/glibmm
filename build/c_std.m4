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

#serial 20120912

## GLIBMM_C_STD_TIME_T_IS_NOT_INT32
##
## Test whether std::time_t and gint32 are typedefs of the same builting type.
## If they aren't then they can be used for method overload.  In that case
## GLIBMM_HAVE_C_STD_TIME_T_IS_NOT_INT32 is defined to 1.
##
AC_DEFUN([GLIBMM_C_STD_TIME_T_IS_NOT_INT32],
[
  AC_CACHE_CHECK(
    [whether std::time_t is not equivalent to gint32, meaning that it can be used for a method overload],
    [glibmm_cv_c_std_time_t_is_not_int32],
  [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
    [[
      #include <ctime>
    ]],[[
      typedef signed int gint32;
      class Test
      {
        void something(gint32 val)
        {}

        void something(std::time_t val)
        {}
      };
    ]])],
      [glibmm_cv_c_std_time_t_is_not_int32='yes'],
      [glibmm_cv_c_std_time_t_is_not_int32='no']
    )
  ])

  AS_VAR_IF([glibmm_cv_c_std_time_t_is_not_int32], ['yes'],
            [AC_DEFINE([GLIBMM_HAVE_C_STD_TIME_T_IS_NOT_INT32], [1],
                       [Defined when std::time_t is not equivalent to gint32, meaning that it can be used for a method overload])])[]dnl
])
