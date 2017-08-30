/* Copyright (C) 2008 The gtkmm Development Team
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
#ifndef _GIOMM_CONTENTTYPE_H
#define _GIOMM_CONTENTTYPE_H

#include <glibmm/ustring.h>
#include <glibmm/listhandle.h>
#include <giomm/icon.h>
#include <giomm/file.h>
#include <string>

namespace Gio
{
/** @defgroup giommContentType Platform-specific content typing
 * A content type is a platform specific string that defines the type of a file.
 * On UNIX it is a <a href="http://www.wikipedia.org/wiki/Internet_media_type">mime type</a>
 * like "text/plain" or "image/png".
 * On Win32 it is an extension string like ".doc", ".txt" or a perceived
 * string like "audio". Such strings can be looked up in the registry at
 * HKEY_CLASSES_ROOT.
 * @{
 */

/**
 * Compares two content types for equality.
 *
 * @param type1 A content type string.
 * @param type2 A content type string.
 *
 * @return true if the two strings are identical or equivalent, false otherwise.
 */
bool content_type_equals(const Glib::ustring& type1, const Glib::ustring& type2);

/**
 * Determines if @a type is a subset of @a supertype.
 *
 * @param type A content type string.
 * @param supertype A content type string.
 *
 * @return true if @a type is a kind of @a supertype, false otherwise.
 */
bool content_type_is_a(const Glib::ustring& type, const Glib::ustring& supertype);

/**
 * Checks if the content type is the generic "unknown" type.
 * On unix this is the "application/octet-stream" mimetype,
 * while on win32 it is "*".
 *
 * @param type A content type string.
 *
 * @return true if the type is the unknown type.
 */
bool content_type_is_unknown(const Glib::ustring& type);

/**
 * Gets the human readable description of the content type.
 *
 * @param type A content type string.
 *
 * @return a short description of the content type @a type.
 */
Glib::ustring content_type_get_description(const Glib::ustring& type);

/**
 * Gets the mime-type for the content type, if one is registered.
 *
 * @param type A content type string.
 *
 * @return the registered mime-type for the given @a type, or an empty string if unknown.
 */
Glib::ustring content_type_get_mime_type(const Glib::ustring& type);

/**
 * Gets the icon for a content type.
 *
 * @param type A content type string.
 *
 * @return Icon corresponding to the content type.
 */
Glib::RefPtr<Icon> content_type_get_icon(const Glib::ustring& type);

#ifdef G_OS_UNIX
/**
 * Gets the symbolic icon for a content type.
 *
 * @param type A content type string.
 * @return symbolic Icon corresponding to the content type.
 *
 * @newin{2,34}
 */
Glib::RefPtr<Icon> content_type_get_symbolic_icon(const Glib::ustring& type);
#endif

/**
 * Checks if a content type can be executable. Note that for instance
 * things like text files can be executables (i.e. scripts and batch files).
 *
 * @param type a content type string.
 *
 * @return true if the file type corresponds to a type that can be executable,
 * false otherwise.
 */
bool content_type_can_be_executable(const Glib::ustring& type);

/** Tries to find a content type based on the mime type name.
 *
 * @param mime_type a mime type string.
 * @returns string with content type or empty when it does not know.
 *
 * @newin{2,20}
 */
Glib::ustring content_type_from_mime_type(const Glib::ustring& mime_type);

/**
 * Guesses the content type based on example data. If the function is uncertain,
 * @a result_uncertain will be set to true. Either @a filename may be an empty
 * string or @a data may be <tt>0</tt>, in which case the guess will be based
 * solely on the other argument.
 *
 * @param filename a string.
 * @param data A stream of data.
 * @param data_size The size of @a data.
 * @param[out] result_uncertain A flag indicating the certainty of the result.
 * @return A string indicating a guessed content type for the
 * given data.
 */
Glib::ustring content_type_guess(
  const std::string& filename, const guchar* data, gsize data_size, bool& result_uncertain);

/**
 * Guesses the content type based on example data. If the function is uncertain,
 * @a result_uncertain will be set to true. @a filename may be an empty string,
 * in which case the guess will be based solely on @a data.
 *
 * @param filename a string.
 * @param data A stream of data.
 * @param[out] result_uncertain A flag indicating the certainty of the result.
 * @return A string indicating a guessed content type for the
 * given data.
 */
Glib::ustring content_type_guess(
  const std::string& filename, const std::string& data, bool& result_uncertain);

/** Tries to guess the type of the tree with root @a root, by
 * looking at the files it contains. The result is a list
 * of content types, with the best guess coming first.
 *
 * The types returned all have the form x-content/foo, e.g.
 * x-content/audio-cdda (for audio CDs) or x-content/image-dcf
 * (for a camera memory card). See the <a
 * href="http://www.freedesktop.org/wiki/Specifications/shared-mime-info-spec">shared-mime-info</a>
 * specification for more on x-content types.
 *
 * @param root The root of the tree to guess a type for.
 * @return List of zero or more content types.
 *
 * @newin{2,18}
 */
Glib::StringArrayHandle content_type_guess_for_tree(const Glib::RefPtr<const File>& root);

/**
 * Gets a list of strings containing all the registered content types
 * known to the system.
 *
 * @return List of the registered content types.
 */
Glib::ListHandle<Glib::ustring> content_types_get_registered();

/** @} group giommContentType */

} // namespace Gio
#endif // _GIOMM_CONTENTTYPE_H
