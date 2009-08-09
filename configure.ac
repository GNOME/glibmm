## Copyright (c) 2009  Openismus GmbH  <http://www.openismus.com/>
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

AC_INIT([glibmm], [2.21.3], [http://bugzilla.gnome.org/enter_bug.cgi?product=glibmm],
        [glibmm], [http://www.gtkmm.org/])
AC_PREREQ([2.59])
m4_pattern_forbid([^_?MM_])

AC_CONFIG_SRCDIR([glib/glibmm.h])
AC_CONFIG_AUX_DIR([build])
AC_CONFIG_MACRO_DIR([scripts])
AC_CONFIG_HEADERS([config.h glib/glibmmconfig.h gio/giommconfig.h])

AM_INIT_AUTOMAKE([1.9 -Wno-portability dist-bzip2 no-define nostdinc tar-ustar])
AM_MAINTAINER_MODE
AC_ARG_VAR([ACLOCAL_FLAGS], [aclocal flags, e.g. -I <macro dir>])

MM_INIT_MODULE([glibmm-2.4], m4_expand([AC_PACKAGE_VERSION]))
MM_INIT_MODULE([giomm-2.4],  m4_expand([AC_PACKAGE_VERSION]))

# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
AC_SUBST([LIBGLIBMM_SO_VERSION], [3:0:2])

AC_PROG_CXX
AC_DISABLE_STATIC
AC_LIBTOOL_WIN32_DLL
AC_PROG_LIBTOOL

AC_MSG_CHECKING([for Windows operating system])
AS_CASE([$host_os], [cygwin*|mingw*], [glibmm_platform_win32=yes], [glibmm_platform_win32=no])
AC_MSG_RESULT([$glibmm_platform_win32])
AM_CONDITIONAL([PLATFORM_WIN32], [test "x$glibmm_platform_win32" = xyes])

AC_MSG_CHECKING([for native Win32 host environment])
AS_CASE([$host_os], [mingw*], [glibmm_os_win32=yes], [glibmm_os_win32=no])
AC_MSG_RESULT([$glibmm_os_win32])
AM_CONDITIONAL([OS_WIN32], [test "x$glibmm_os_win32" = xyes])

AS_IF([test "x$enable_static" = xyes],
[
  AC_DEFINE([GLIBMM_STATIC_LIB], [1], [Defined when glibmm is built as a static library])
  AC_DEFINE([GIOMM_STATIC_LIB],  [1], [Defined when giomm is built as a static library])
])

AC_CHECK_FUNCS([flockfile funlockfile getc_unlocked mkfifo])

glibreq='2.0 >= 2.21.1'
GLIBMM_MODULES="sigc++-2.0 >= 2.0 glib-$glibreq gobject-$glibreq gmodule-$glibreq"
GIOMM_MODULES="$GLIBMM_MODULES gio-$glibreq"
test "x$glibmm_os_win32" = xyes || GIOMM_MODULES="$GIOMM_MODULES gio-unix-$glibreq"

PKG_CHECK_MODULES([GLIBMM], [$GLIBMM_MODULES])
PKG_CHECK_MODULES([GIOMM],  [$GIOMM_MODULES])

MM_PKG_CONFIG_SUBST([GTHREAD_CFLAGS], [--cflags-only-other gthread-2.0])
MM_PKG_CONFIG_SUBST([GTHREAD_LIBS], [--libs gthread-2.0])

# Location to install gmmproc tools
# TODO: There is no reason for this to be a substitution variable
AC_SUBST([GMMPROC_DIR], ['${libdir}/glibmm-2.4/proc'])

AC_CHECK_PROGS([M4], [gm4 m4], [m4])

# TODO: Temporary hack
AC_PATH_PROG([PERL_PATH], [perl], [perl])

# Check for the SUN Forte compiler, and define GLIBMM_COMPILER_SUN_FORTE in the header.
GLIBMM_PROG_CXX_SUN

# Ensure MSVC-compatible struct packing convention is used when
# compiling for Win32 with gcc.
# TODO: Disabled for now. I don't think this should be enabled by the
# libraries themselves on behalf of the user.  That makes no sense as
# it is a platform-wide ABI choice.

AC_LANG([C++])

# TODO: I think we can just get rid of these checks.
glibmm_config_error=no
AC_CXX_BOOL(,       [glibmm_config_error=yes])
AC_CXX_NAMESPACES(, [glibmm_config_error=yes])
AC_CXX_MUTABLE(,    [glibmm_config_error=yes])

AS_IF([test "x$glibmm_config_error" = xyes],
      [AC_MSG_FAILURE([[Your compiler is not powerful enough to compile glibmm.]])])

AC_CHECK_SIZEOF([wchar_t])
DK_CHECK_FEATURE([wide stream],
[
  AC_LANG_PROGRAM([[#include <sstream>]],
                  [[std::wostringstream s; (void) s.str();]])
])

GLIBMM_CXX_HAS_NAMESPACE_STD
GLIBMM_CXX_HAS_STD_ITERATOR_TRAITS
GLIBMM_CXX_HAS_SUN_REVERSE_ITERATOR
GLIBMM_CXX_HAS_TEMPLATE_SEQUENCE_CTORS
GLIBMM_CXX_MEMBER_FUNCTIONS_MEMBER_TEMPLATES
GLIBMM_CXX_CAN_DISAMBIGUATE_CONST_TEMPLATE_SPECIALIZATIONS
GLIBMM_CXX_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION
GLIBMM_CXX_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS
GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC
GLIBMM_CXX_ALLOWS_STATIC_INLINE_NPOS
GLIBMM_C_STD_TIME_T_IS_NOT_INT32

# Create a list of input directories for Doxygen.
# TODO: kill
GTKMM_DOXYGEN_INPUT_SUBDIRS([glib gio])

MM_ARG_ENABLE_DOCUMENTATION
MM_ARG_WITH_TAGFILE_DOC([libstdc++.tag], [mm-common-libstdc++])
MM_ARG_WITH_TAGFILE_DOC([libsigc++-2.0.tag], [sigc++-2.0])

# Check whether --enable-debug-refcounting was given.
GLIBMM_ARG_ENABLE_DEBUG_REFCOUNTING

# Evaluate the --enable-warnings=level option.
MM_ARG_ENABLE_WARNINGS([GLIBMM_WXXFLAGS],
                       [-Wall],
                       [-pedantic -Wall -Wextra],
                       [G])

# TODO: kill dummy
AC_SUBST([DISABLE_DEPRECATED_CFLAGS], [[]])

#Offer the ability to omit some API from the library, 
#to reduce the code size:
GLIBMM_ARG_ENABLE_API_DEPRECATED
GLIBMM_ARG_ENABLE_API_EXCEPTIONS
GLIBMM_ARG_ENABLE_API_PROPERTIES
GLIBMM_ARG_ENABLE_API_VFUNCS

# Offer the ability to omit some API from the library, 
# to reduce the code size:
GLIBMM_ARG_ENABLE_API_DEFAULT_SIGNAL_HANDLERS

# Dummy conditional just to make automake-1.4 happy.
# We need an always-false condition in docs/Makefile.am.
# TODO: kill
AM_CONDITIONAL(GTKMM_FALSE,[false])

AC_CONFIG_FILES([
  Makefile

  glib/glibmm-2.4.pc
    glib/src/Makefile
    glib/glibmm/Makefile
  
  gio/giomm-2.4.pc
    gio/src/Makefile
    gio/giomm/Makefile

  tools/Makefile
  tools/gmmproc
  tools/generate_wrap_init.pl
])

AC_CONFIG_FILES([
  tests/Makefile
  examples/Makefile

  docs/Makefile
    docs/images/Makefile
    docs/reference/Makefile
    docs/reference/Doxyfile
    docs/reference/beautify_docs.pl
    docs/internal/Makefile
])

AC_CONFIG_FILES([
  MSVC_Net2005/Makefile
    MSVC_Net2005/gendef/Makefile
    MSVC_Net2005/glibmm/Makefile
    MSVC_Net2005/glibmm/glibmm.rc
    MSVC_Net2005/giomm/Makefile
    MSVC_Net2005/giomm/giomm.rc
    MSVC_Net2005/examples/Makefile
      MSVC_Net2005/examples/dispatcher/Makefile
      MSVC_Net2005/examples/dispatcher2/Makefile
      MSVC_Net2005/examples/markup/Makefile
      MSVC_Net2005/examples/options/Makefile
      MSVC_Net2005/examples/thread/Makefile      
      MSVC_Net2005/examples/thread_pool/Makefile
    MSVC_Net2005/tests/Makefile
      MSVC_Net2005/tests/glibmm_value/Makefile
      MSVC_Net2005/tests/giomm_simple/Makefile

  MSVC_Net2008/Makefile
    MSVC_Net2008/gendef/Makefile
    MSVC_Net2008/glibmm/Makefile
    MSVC_Net2008/glibmm/glibmm.rc
    MSVC_Net2008/giomm/Makefile
    MSVC_Net2008/giomm/giomm.rc
    MSVC_Net2008/examples/Makefile
      MSVC_Net2008/examples/dispatcher/Makefile
      MSVC_Net2008/examples/dispatcher2/Makefile
      MSVC_Net2008/examples/markup/Makefile
      MSVC_Net2008/examples/options/Makefile
      MSVC_Net2008/examples/thread/Makefile      
      MSVC_Net2008/examples/thread_pool/Makefile
    MSVC_Net2008/tests/Makefile
      MSVC_Net2008/tests/glibmm_value/Makefile
      MSVC_Net2008/tests/giomm_simple/Makefile
])
AC_OUTPUT
