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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
 * See also the <a href="http://library.gnome.org/devel/gtkmm-tutorial/stable/">
 * Programming with gtkmm</a> book for a tutorial on programming with gtkmm and
 * glibmm.
 *
 * @section features Features
 *
 * - Glib::ustring: A UTF-8 string class that can be used interchangably with std::string. Plus @ref
 * StringUtils
 * - Glib::RefPtr: A reference-counting smartpointer, for use with Glib::ObjectBase or similar
 * - @ref CharsetConv
 * - Glib::Regex: Regular expression string matching.
 * - Glib::KeyFile: Parsing and writing of key files (similar to .ini files)
 * - Glib::Checksum
 * - Glib::Date, Glib::Timer, Glib::TimeVal
 * - Glib::Dispatcher: Inter-thread communication
 * - @ref FileUtils and @ref UriUtils
 * - @ref MainLoop
 * - @ref Spawn
 * - @ref Threads
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
 * g++ program.cc -o program  `pkg-config --cflags --libs glibmm-2.4 giomm-2.4`
 * @endcode
 *
 * Alternatively, if using autoconf, use the following in @c configure.ac:
 * @code
 * PKG_CHECK_MODULES([GLIBMM], [glibmm-2.4 giomm-2.4])
 * @endcode
 * Then use the generated @c GLIBMM_CFLAGS and @c GLIBMM_LIBS variables in the
 * project Makefile.am files. For example:
 * @code
 * program_CPPFLAGS = $(GLIBMM_CFLAGS)
 * program_LDADD = $(GLIBMM_LIBS)
 * @endcode
 */

#include <glibmmconfig.h>
//#include <glibmm/i18n.h> //This must be included by the application, after system headers such as
//<iostream>.

// Include this first because we need it to be the first thing to include <glib.h>,
// so we can do an undef trick to still use deprecated API in the header:
#include <glibmm/thread.h>

#include <glibmm/threads.h>

#include <glibmm/arrayhandle.h>
#include <glibmm/balancedtree.h>
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
#include <glibmm/error.h>
#include <glibmm/exception.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/fileutils.h>
#include <glibmm/helperlist.h>
#include <glibmm/interface.h>
#include <glibmm/iochannel.h>
#include <glibmm/init.h>
#include <glibmm/keyfile.h>
#include <glibmm/streamiochannel.h>
#include <glibmm/listhandle.h>
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
#include <glibmm/slisthandle.h>
#include <glibmm/spawn.h>
#include <glibmm/stringutils.h>
#include <glibmm/threadpool.h>
#include <glibmm/timer.h>
#include <glibmm/timeval.h>
#include <glibmm/timezone.h>
#include <glibmm/uriutils.h>
#include <glibmm/ustring.h>
#include <glibmm/value.h>
#include <glibmm/valuearray.h>
#include <glibmm/variant.h>
#include <glibmm/variantdict.h>
#include <glibmm/variantiter.h>
#include <glibmm/varianttype.h>
#include <glibmm/vectorutils.h>
#include <glibmm/weakref.h>
#include <glibmm/wrap.h>

#endif /* _GLIBMM_H */
