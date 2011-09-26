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

## GLIBMM_ARG_ENABLE_DEBUG_REFCOUNTING()
##
## Provide the --enable-debug-refcounting configure argument, disabled
## by default.  If enabled, #define GTKMM_DEBUG_REFCOUNTING.
##
AC_DEFUN([GLIBMM_ARG_ENABLE_DEBUG_REFCOUNTING],
[
  AC_ARG_ENABLE([debug-refcounting],
      [AS_HELP_STRING([--enable-debug-refcounting],
                      [Print a debug message on every ref/unref.@<:@default=no@:>@])],
      [glibmm_debug_refcounting="$enableval"],
      [glibmm_debug_refcounting='no'])

  AS_VAR_IF([glibmm_debug_refcounting], ['yes'],
            [AC_DEFINE([GLIBMM_DEBUG_REFCOUNTING], [1],
                       [Defined when the --enable-debug-refcounting configure argument was given])])[]dnl
])
