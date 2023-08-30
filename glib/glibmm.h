/* glibmm - a C++ wrapper for the GLib toolkit
 *
 * Copyright 2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _GLIBMM_H
#define _GLIBMM_H

/** @mainpage glibmm Reference Manual
 *
 * @section description Description
 *
 * glibmm is the official C++ interface for the popular cross-platform library %Glib.
 * It provides non-UI API that is not available in standard C++ and makes it
 * possible for gtkmm to wrap GObject-based APIs.
 * See also the <a href="https://gnome.pages.gitlab.gnome.org/gtkmm-documentation/">
 * Programming with gtkmm</a> book for a tutorial on programming with gtkmm and
 * glibmm.
 *
 * @section features Features
 *
 * - Glib::ustring: A UTF-8 string class that can be used interchangably with std::string.
 *   Plus @ref StringUtils
 * - Glib::RefPtr: A reference-counting smartpointer, for use with Glib::ObjectBase or similar
 * - @ref CharsetConv
 * - Glib::Regex: Regular expression string matching.
 * - Glib::KeyFile: Parsing and writing of key files (similar to .ini files)
 * - Glib::Checksum
 * - Glib::Date, Glib::DateTime, Glib::Timer
 * - Glib::Dispatcher: Inter-thread communication
 * - @ref FileUtils and @ref UriUtils
 * - @ref MainLoop
 * - @ref Spawn
 * - @ref MiscUtils
 *
 * giomm (part of the glibmm project) also contains:
 * - Asynchronous IO. See Gio::File and the @ref Streams.
 * - @ref NetworkIO
 * - @ref DBus
 * - Gio::Settings for application settings.
 *
 * @section basics Basic Usage
 *
 * Include the glibmm header, plus giomm if necessary:
 * @code
 * #include <glibmm.h>
 * #include <giomm.h>
 * @endcode
 * (You may include individual headers, such as @c glibmm/ustring.h instead.)
 *
 * If your  source file is @c program.cc, you can compile it with:
 * @code
 * g++ program.cc -o program  `pkg-config --cflags --libs glibmm-2.68 giomm-2.68`
 * @endcode
 * If your version of g++ is not C++17-compliant by default,
 * add the @c -std=c++17 option.
 *
 * If you use <a href="https://mesonbuild.com/">Meson</a>, include the following
 * in @c meson.build:
 * @code
 * glibmm_dep = dependency('glibmm-2.68')
 * giomm_dep = dependency('giomm-2.68')
 * program_name = 'program'
 * cpp_sources = [ 'program.cc' ]
 * executable(program_name,
 *   cpp_sources,
 *   dependencies: [ glibmm_dep, giomm_dep ]
 * )
 * @endcode
 *
 * Alternatively, if using autoconf, use the following in @c configure.ac:
 * @code
 * PKG_CHECK_MODULES([GLIBMM], [glibmm-2.68 giomm-2.68])
 * @endcode
 * Then use the generated @c GLIBMM_CFLAGS and @c GLIBMM_LIBS variables in the
 * project Makefile.am files. For example:
 * @code
 * program_CPPFLAGS = $(GLIBMM_CFLAGS)
 * program_LDADD = $(GLIBMM_LIBS)
 * @endcode
 */

#include <glibmmconfig.h>
//#include <glibmm/i18n.h> //This must be included by the application, after system headers such as <iostream>.
//#include <glibmm/i18n-lib.h> //This must be included by the application, after system headers such as <iostream>.
//#include <glibmm/ustring_hash.h> //This is not included here because it may clash with user code.

#include <glibmm/base64.h>
#ifndef GLIBMM_INCLUDED_FROM_WRAP_INIT_CC
// wrap_init.cc includes this file after it has cleared G_GNUC_CONST.
#include <glibmm/binding.h>
#endif
#include <glibmm/bytearray.h>
#include <glibmm/bytes.h>
#include <glibmm/checksum.h>
#include <glibmm/class.h>
#include <glibmm/containerhandle_shared.h>
#include <glibmm/convert.h>
#include <glibmm/date.h>
#include <glibmm/datetime.h>
#include <glibmm/dispatcher.h>
#include <glibmm/enums.h>
#include <glibmm/environ.h>
#include <glibmm/error.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/fileutils.h>
#include <glibmm/interface.h>
#include <glibmm/iochannel.h>
#include <glibmm/init.h>
#include <glibmm/keyfile.h>
#include <glibmm/main.h>
#include <glibmm/markup.h>
#include <glibmm/miscutils.h>
#include <glibmm/module.h>
#include <glibmm/nodetree.h>
#include <glibmm/objectbase.h>
#include <glibmm/object.h>
#include <glibmm/optioncontext.h>
#include <glibmm/pattern.h>
#include <glibmm/property.h>
#include <glibmm/propertyproxy_base.h>
#include <glibmm/propertyproxy.h>
#include <glibmm/quark.h>
#include <glibmm/random.h>
#include <glibmm/regex.h>
#include <glibmm/refptr.h>
#include <glibmm/shell.h>
#include <glibmm/signalproxy_connectionnode.h>
#include <glibmm/signalproxy.h>
#include <glibmm/spawn.h>
#include <glibmm/stringutils.h>
#include <glibmm/timer.h>
#include <glibmm/timezone.h>
#include <glibmm/uriutils.h>
#include <glibmm/ustring.h>
#include <glibmm/value.h>
#include <glibmm/variant.h>
#include <glibmm/variantdict.h>
#include <glibmm/variantiter.h>
#include <glibmm/varianttype.h>
#include <glibmm/vectorutils.h>
#include <glibmm/version.h>
#include <glibmm/wrap.h>

#endif /* _GLIBMM_H */
