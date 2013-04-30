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

AC_INIT([glibmm], [2.36.2],
        [http://bugzilla.gnome.org/enter_bug.cgi?product=glibmm],
        [glibmm], [http://www.gtkmm.org/])
AC_PREREQ([2.59])

AC_CONFIG_SRCDIR([glib/glibmm.h])
AC_CONFIG_AUX_DIR([build])
AC_CONFIG_MACRO_DIR([build])
AC_CONFIG_HEADERS([config.h glib/glibmmconfig.h gio/giommconfig.h])

AM_INIT_AUTOMAKE([1.9 -Wno-portability no-dist-gzip dist-xz tar-ustar no-define nostdinc])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES])
AM_MAINTAINER_MODE
AC_ARG_VAR([ACLOCAL_FLAGS], [aclocal flags, e.g. -I <macro dir>])

MM_PREREQ([0.9.6])
MM_INIT_MODULE([glibmm-2.4])
MM_INIT_MODULE([giomm-2.4])

# Copy the mm-common .pl scripts into docs/,
# and use them from there,
# so we can dist them to avoid a tarball-build dependency.
MM_CONFIG_DOCTOOL_DIR([docs])

# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
AC_SUBST([LIBGLIBMM_SO_VERSION], [4:0:3])

AC_PROG_CXX
AC_DISABLE_STATIC
LT_INIT([win32-dll])
MM_PATH_PERL
AS_IF([test "x$USE_MAINTAINER_MODE" != xno], [MM_CHECK_PERL])

AC_MSG_CHECKING([for native Windows host])
AS_CASE([$host_os], [mingw*], [glibmm_host_windows=yes], [glibmm_host_windows=no])
AC_MSG_RESULT([$glibmm_host_windows])
AM_CONDITIONAL([HOST_WINDOWS_NATIVE], [test "x$glibmm_host_windows" = xyes])

# TODO: This makes no sense. --danielk
AS_IF([test "x$enable_static" = xyes],
[
  AC_DEFINE([GLIBMM_STATIC_LIB], [1], [Define if glibmm is built as a static library])
  AC_DEFINE([GIOMM_STATIC_LIB],  [1], [Define if giomm is built as a static library])
])

glibreq='2.0 >= 2.36.1'

GLIBMM_MODULES="sigc++-2.0 >= 2.2.10 glib-$glibreq gobject-$glibreq gmodule-$glibreq"
GIOMM_MODULES="$GLIBMM_MODULES gio-$glibreq"
test "x$glibmm_host_windows" = xyes || GIOMM_MODULES="$GIOMM_MODULES gio-unix-$glibreq"

PKG_CHECK_MODULES([GLIBMM], [$GLIBMM_MODULES])
PKG_CHECK_MODULES([GIOMM],  [$GIOMM_MODULES])

AC_CHECK_PROGS([M4], [gm4 m4], [m4])
GLIB_GSETTINGS

# Check for the SUN Forte compiler, and define GLIBMM_COMPILER_SUN_FORTE
# in the header.
GLIBMM_PROG_CXX_SUN

AC_CHECK_FUNCS([flockfile funlockfile getc_unlocked mkfifo])

# Ensure MSVC-compatible struct packing convention is used when
# compiling for Win32 with gcc.
# TODO: Disabled for now. I don't think this should be enabled by the
# libraries themselves on behalf of the user.  That makes no sense as
# it is a platform-wide ABI choice.

AC_LANG([C++])

AC_CHECK_SIZEOF([wchar_t])
DK_CHECK_FEATURE([wide stream],
[
  AC_LANG_PROGRAM([[#include <sstream>]],
                  [[std::wostringstream s; (void) s.str();]])
])

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

MM_ARG_ENABLE_DOCUMENTATION
MM_ARG_WITH_TAGFILE_DOC([libstdc++.tag], [mm-common-libstdc++])
MM_ARG_WITH_TAGFILE_DOC([libsigc++-2.0.tag], [sigc++-2.0])

# Check whether --enable-debug-refcounting was given.
GLIBMM_ARG_ENABLE_DEBUG_REFCOUNTING

# Evaluate the --enable-warnings=level option.
MM_ARG_ENABLE_WARNINGS([GLIBMM_WXXFLAGS],
                       [-Wall],
                       [-pedantic -Wall -Wextra -Wformat-security -Wno-long-long],
                       [G])

# Offer the ability to omit some API from the library,
# to reduce the code size:
MM_ARG_DISABLE_DEPRECATED_API([GLIBMM GIOMM])

# These are just defined to avoid breaking old code:
AC_DEFINE([GLIBMM_EXCEPTIONS_ENABLED],[1], [This is always set. This is only for backwards compatibility.])
AC_DEFINE([GLIBMM_PROPERTIES_ENABLED],[1], [This is always set. This is only for backwards compatibility.])
AC_DEFINE([GLIBMM_VFUNCS_ENABLED],[1], [This is always set. This is only for backwards compatibility.])
AC_DEFINE([GLIBMM_DEFAULT_SIGNAL_HANDLERS_ENABLED],[1], [This is always set. This is only for backwards compatibility.])

AC_CONFIG_FILES([Makefile
                 tools/Makefile
                 tools/gmmproc
                 tools/generate_wrap_init.pl
                 glib/${GLIBMM_MODULE_NAME}.pc:glib/glibmm.pc.in
                 glib/${GLIBMM_MODULE_NAME}-uninstalled.pc:glib/glibmm-uninstalled.pc.in
                 glib/src/Makefile
                 glib/glibmm/Makefile
                 gio/${GIOMM_MODULE_NAME}.pc:gio/giomm.pc.in
                 gio/${GIOMM_MODULE_NAME}-uninstalled.pc:gio/giomm-uninstalled.pc.in
                 gio/src/Makefile
                 gio/giomm/Makefile
                 tests/Makefile
                 examples/Makefile
                 docs/Makefile
                 docs/reference/Doxyfile
                 MSVC_Net2005/glibmm/glibmm.rc
                 MSVC_Net2005/giomm/giomm.rc
                 MSVC_Net2008/glibmm/glibmm.rc
                 MSVC_Net2008/giomm/giomm.rc
                 MSVC_Net2010/glibmm/glibmm.rc
                 MSVC_Net2010/giomm/giomm.rc])

# Copy the generated configuration headers into the MSVC project directories.
AC_CONFIG_COMMANDS([MSVC_Net2005/glibmm/glibmmconfig.h],
                   [cp -f glib/glibmmconfig.h MSVC_Net2005/glibmm/glibmmconfig.h])
AC_CONFIG_COMMANDS([MSVC_Net2005/giomm/giommconfig.h],
                   [cp -f gio/giommconfig.h MSVC_Net2005/giomm/giommconfig.h])
AC_CONFIG_COMMANDS([MSVC_Net2008/glibmm/glibmmconfig.h],
                   [cp -f glib/glibmmconfig.h MSVC_Net2008/glibmm/glibmmconfig.h])
AC_CONFIG_COMMANDS([MSVC_Net2008/giomm/giommconfig.h],
                   [cp -f gio/giommconfig.h MSVC_Net2008/giomm/giommconfig.h])
AC_CONFIG_COMMANDS([MSVC_Net2010/glibmm/glibmmconfig.h],
                   [cp -f glib/glibmmconfig.h MSVC_Net2010/glibmm/glibmmconfig.h])
AC_CONFIG_COMMANDS([MSVC_Net2010/giomm/giommconfig.h],
                   [cp -f gio/giommconfig.h MSVC_Net2010/giomm/giommconfig.h])
AC_OUTPUT
