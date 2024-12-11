#ifndef _GLIBMM_USTRING_H
#define _GLIBMM_USTRING_H

/* Copyright (C) 2002 The gtkmm Development Team
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

#include <glibmmconfig.h>
#include <glibmm/unicode.h>
#include <glib.h>

#include <cstddef> // for std::size_t and optionally std::ptrdiff_t
#include <utility> // For std::move()
#include <initializer_list>
#include <iosfwd>
#include <iterator>
#include <sstream>
#include <string>
#include <type_traits>

/* work around linker error on Visual Studio if we don't have GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS */
#if defined(_MSC_VER) && _MSC_VER >= 1600 && !defined(GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS)
const std::basic_string<char>::size_type std::basic_string<char>::npos = (std::basic_string<char>::size_type) -1;
#endif

namespace Glib
{

class ustring;

//********** Glib::StdStringView and Glib::UStringView *************

// It would be possible to replace StdStringView and UStringView with a
// template class BasicStringView + two type aliases defining StdStringView
// and UStringView. But Doxygen don't generate links to type aliases.
//
// It would also be possible to replace StdStringView and UStringView with
// a StringView class with 3 constructors, taking const std::string&,
// const Glib::ustring& and const char*, respectively. The split into two classes
// is by design. Using the wrong string class shall not be as easy as using
// the right string class.

/** Helper class to avoid unnecessary string copying in function calls.
 *
 * A %Glib::StdStringView holds a const char pointer. It can be used as an argument
 * type in a function that passes a const char pointer to a C function.
 *
 * Unlike std::string_view, %Glib::StdStringView shall be used only for
 * null-terminated strings.
 * @code
 * std::string f1(Glib::StdStringView s1, Glib::StdStringView s2);
 * // can be used instead of
 * std::string f2(const std::string& s1, const std::string& s2);
 * @endcode
 * The strings are not copied when f1() is called with string literals.
 * @code
 * auto r1 = f1("string 1", "string 2");
 * @endcode
 * To pass a Glib::ustring to a function taking a %Glib::StdStringView, you may have
 * to use Glib::ustring::c_str().
 * @code
 * std::string str = "non-UTF8 string";
 * Glib::ustring ustr = "UTF8 string";
 * auto r1 = f1(str, ustr.c_str());
 * @endcode
 *
 * @newin{2,64}
 */
class GLIBMM_API StdStringView
{
public:
  StdStringView(const std::string& s) : pstring_(s.c_str()) {}
  StdStringView(const char* s) : pstring_(s) {}
  const char* c_str() const { return pstring_; }
private:
  const char* pstring_;
};

/** Helper class to avoid unnecessary string copying in function calls.
 *
 * A %Glib::UStringView holds a const char pointer. It can be used as an argument
 * type in a function that passes a const char pointer to a C function.
 *
 * Unlike std::string_view, %Glib::UStringView shall be used only for
 * null-terminated strings.
 * @code
 * Glib::ustring f1(Glib::UStringView s1, Glib::UStringView s2);
 * // can be used instead of
 * Glib::ustring f2(const Glib::ustring& s1, const Glib::ustring& s2);
 * @endcode
 * The strings are not copied when f1() is called with string literals.
 * @code
 * auto r1 = f1("string 1", "string 2");
 * @endcode
 * To pass a std::string to a function taking a %Glib::UStringView, you may have
 * to use std::string::c_str().
 * @code
 * std::string str = "non-UTF8 string";
 * Glib::ustring ustr = "UTF8 string";
 * auto r1 = f1(str.c_str(), ustr);
 * @endcode
 *
 * @newin{2,64}
 */
class GLIBMM_API UStringView
{
public:
  inline UStringView(const Glib::ustring& s);
  UStringView(const char* s) : pstring_(s) {}
  const char* c_str() const { return pstring_; }
private:
  const char* pstring_;
};

//***************************************************

#ifndef DOXYGEN_SHOULD_SKIP_THIS
#ifndef GLIBMM_HAVE_STD_ITERATOR_TRAITS

template <class T>
struct IteratorTraits
{
  using iterator_category = typename T::iterator_category;
  using value_type = typename T::value_type;
  using difference_type = typename T::difference_type;
  using pointer = typename T::pointer;
  using reference = typename T::reference;
};

template <class T>
struct IteratorTraits<T*>
{
  using iterator_category = std::random_access_iterator_tag;
  using value_type = T;
  using difference_type = std::ptrdiff_t;
  using pointer = T*;
  using reference = T&;
};

template <class T>
struct IteratorTraits<const T*>
{
  using iterator_category = std::random_access_iterator_tag;
  using value_type = T;
  using difference_type = std::ptrdiff_t;
  using pointer = const T*;
  using reference = const T&;
};

#endif /* GLIBMM_HAVE_STD_ITERATOR_TRAITS */
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** The iterator type of Glib::ustring.
 * Note this is not a random access iterator but a bidirectional one,
 * since all index operations need to iterate over the UTF-8 data.  Use
 * std::advance() to move to a certain position.  However, all of the
 * relational operators are available:
 * <tt>==&nbsp;!=&nbsp;<&nbsp;>&nbsp;<=&nbsp;>=</tt>
 *
 * A writeable iterator isn't provided because:  The number of bytes of
 * the old UTF-8 character and the new one to write could be different.
 * Therefore, any write operation would invalidate all other iterators
 * pointing into the same string.
 *
 * The Glib::ustring iterated over must contain only valid UTF-8 data.
 * If it does not, operator++(), operator\--() and operator*() may make
 * accesses outside the bounds of the string. A loop such as the following
 * one would not stop at the end of the string.
 * @code
 * // Bad code! Don't do this!
 * const char not_utf8[] = { '\x80', '\xef', '\x80', '\x80', '\xef', '\x80' };
 * const Glib::ustring s(not_utf8, not_utf8 + sizeof not_utf8);
 * for (Glib::ustring::const_iterator it = s.begin(); it != s.end(); ++it)
 *   std::cout << *it << std::endl;
 * @endcode
 *
 * @tparam T std::string::iterator or std::string::const_iterator
 */
template <class T>
class ustring_Iterator
{
public:
  using iterator_category = std::bidirectional_iterator_tag;
  using value_type = gunichar;
  using difference_type = std::string::difference_type;
  using reference = value_type;
  using pointer = void;

  inline ustring_Iterator();
  inline ustring_Iterator(const ustring_Iterator<std::string::iterator>& other);
  ustring_Iterator& operator=(const ustring_Iterator& other) = default;

  inline value_type operator*() const;

  inline ustring_Iterator<T>& operator++();
  inline const ustring_Iterator<T> operator++(int);
  inline ustring_Iterator<T>& operator--();
  inline const ustring_Iterator<T> operator--(int);

  explicit inline ustring_Iterator(T pos);
  inline T base() const;

private:
  T pos_;
};

/** Extract a UCS-4 character from UTF-8 data.
 * Convert a single UTF-8 (multibyte) character starting at @p pos to
 * a UCS-4 wide character.  This may read up to 6 bytes after the start
 * position, depending on the UTF-8 character width.  You have to make
 * sure the source contains at least one valid UTF-8 character.
 *
 * This is mainly used by the implementation of Glib::ustring::iterator,
 * but it might be useful as utility function if you prefer using
 * std::string even for UTF-8 encoding.
 */
GLIBMM_API
gunichar get_unichar_from_std_iterator(std::string::const_iterator pos) G_GNUC_PURE;

/** %Glib::ustring has much the same interface as std::string, but contains
 * %Unicode characters encoded as UTF-8.
 *
 * @par About UTF-8 and ASCII
 * @par
 * The standard character set ANSI_X3.4-1968&nbsp;-- more commonly known as
 * ASCII&nbsp;-- is a subset of UTF-8.  So, if you want to, you can use
 * %Glib::ustring without even thinking about UTF-8.
 * @par
 * Whenever ASCII is mentioned in this manual, we mean the @em real ASCII
 * (i.e. as defined in ANSI_X3.4-1968), which contains only 7-bit characters.
 * %Glib::ustring can @em not be used with ASCII-compatible extended 8-bit
 * charsets like ISO-8859-1.  It's a good idea to avoid string literals
 * containing non-ASCII characters (e.g. German umlauts) in source code,
 * or at least you should use UTF-8 literals.
 * @par
 * You can find a detailed UTF-8 and %Unicode FAQ here:
 * http://www.cl.cam.ac.uk/~mgk25/unicode.html
 *
 * @par Glib::ustring vs. std::string
 * @par
 * %Glib::ustring has implicit type conversions to and from std::string.
 * These conversions do @em not convert to/from the current locale (see
 * Glib::locale_from_utf8() and Glib::locale_to_utf8() if you need that).  You
 * can always use std::string instead of %Glib::ustring&nbsp;-- however, using
 * std::string with multi-byte characters is quite hard.  For instance,
 * <tt>std::string::operator[]</tt> might return a byte in the middle of a
 * character, and <tt>std::string::length()</tt> returns the number of bytes
 * rather than characters.  So don't do that without a good reason.
 * @par
 * You cannot always use %Glib::ustring instead of std::string.
 * @code
 * Glib::ustring u("a_string_with_underscores");
 * std::replace(u.begin(), u.end(), '_', ' ');  // does not compile
 * @endcode
 * You can't use a Glib::ustring::iterator for writing to a %Glib::ustring.
 * See the documentation of Glib::ustring_Iterator for differences between it
 * and std::string::iterator.
 * @par
 * Many member functions and operators of %Glib::ustring and Glib::ustring_Iterator
 * assume that the string contains only valid UTF-8 data. If it does not, memory
 * outside the bounds of the string can be accessed. If you're uncertain, use
 * validate() and/or make_valid().
 * @par
 * In a perfect world the C++ Standard Library would contain a UTF-8 string
 * class.  Unfortunately, the C++98 standard doesn't mention UTF-8 at all.
 * C++11 has UTF-8 literals but no UTF-8 string class. Note
 * that std::wstring is not a UTF-8 string class because it contains only
 * fixed-width characters (where width could be 32, 16, or even 8 bits).
 *
 * @par Glib::ustring and stream input/output
 * @par
 * The stream I/O operators, that is operator<<() and operator>>(), perform
 * implicit charset conversion to/from the current locale.  If that's not
 * what you intended (e.g. when writing to a configuration file that should
 * always be UTF-8 encoded) use ustring::raw() to override this behaviour.
 * @par
 * If you're using std::ostringstream to build strings for display in the
 * user interface, you must convert the result back to UTF-8 as shown below:
 * @code
 * std::locale::global(std::locale("")); // Set the global locale to the user's preferred locale.
 *                                       // Usually unnecessary here, because Glib::init()
 *                                       // does it for you.
 * std::ostringstream output;
 * output << percentage << " % done";
 * label->set_text(Glib::locale_to_utf8(output.str()));
 * @endcode
 *
 * @par Formatted output and internationalization
 * @par
 * The methods ustring::compose() and ustring::format() provide a convenient
 * and powerful alternative to string streams, as shown in the example below.
 * Refer to the method documentation of compose() and format() for details.
 * @code
 * using Glib::ustring;
 *
 * ustring message = ustring::compose("%1 is lower than 0x%2.",
 *                                    12, ustring::format(std::hex, 16));
 * @endcode
 *
 * @par %Glib::ustring as key in unordered associative containers
 * @par
 * To use e.g. std::unordered_map<Glib::ustring, int> there must be
 * a std::hash<Glib::ustring> specialization. Since glibmm 2.78 there is
 * such a specialization in glibmm, but it's available only if you include
 * the @ref ustringhash "ustring_hash.h" file.
 * @code
 * #include <glibmm/ustring_hash.h>
 * @endcode
 * This file is not included by #include <glibmm.h>, thereby saving some users
 * from an unpleasant surprise when they upgrade to glibmm 2.78 or later.
 * (If you have defined your own specialization of std::hash<Glib::ustring>,
 * the definition in glibmm/ustring_hash.h may clash with your definition.)
 *
 * @par Implementation notes
 * @par
 * %Glib::ustring does not inherit from std::string, because std::string was
 * intended to be a final class.  For instance, it does not have a virtual
 * destructor.  Also, a HAS-A relationship is more appropriate because
 * ustring can't just enhance the std::string interface.  Rather, it has to
 * reimplement the interface so that all operations are based on characters
 * instead of bytes.
 */
class ustring
{
public:
  using size_type = std::string::size_type;
  using difference_type = std::string::difference_type;

  using value_type = gunichar;
  using reference = gunichar&;
  using const_reference = const gunichar&;

  using iterator = ustring_Iterator<std::string::iterator>;
  using const_iterator = ustring_Iterator<std::string::const_iterator>;

#ifndef GLIBMM_HAVE_SUN_REVERSE_ITERATOR

  using reverse_iterator = std::reverse_iterator<iterator>;
  using const_reverse_iterator = std::reverse_iterator<const_iterator>;

#else

  typedef std::reverse_iterator<iterator, iterator::iterator_category, iterator::value_type,
    iterator::reference, iterator::pointer, iterator::difference_type>
    reverse_iterator;
  typedef std::reverse_iterator<const_iterator, const_iterator::iterator_category,
    const_iterator::value_type, const_iterator::reference, const_iterator::pointer,
    const_iterator::difference_type>
    const_reverse_iterator;

#endif /* GLIBMM_HAVE_SUN_REVERSE_ITERATOR */

#ifdef GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS
  GLIBMM_API static const size_type npos = std::string::npos;
#else
  // The IRIX MipsPro compiler says "The indicated constant value is not known",
  // so we need to initalize the static member data elsewhere.
  GLIBMM_API static const size_type npos;
#endif

  /*! Default constructor, which creates an empty string.
   */
  GLIBMM_API ustring();

  GLIBMM_API ~ustring() noexcept;

  /*! Construct a ustring as a copy of another ustring.
   * @param other A source string.
   */
  GLIBMM_API ustring(const ustring& other);

  /*! Construct a ustring by moving from another ustring.
   * @param other A source string.
   */
  GLIBMM_API ustring(ustring&& other);

  /*! Assign the value of another string by copying to this string.
   * @param other A source string.
   */
  GLIBMM_API ustring& operator=(const ustring& other);

  /*! Assign the value of another string by moving to this string.
   * @param other A source string.
   */
  GLIBMM_API ustring& operator=(ustring&& other);

  /*! Swap contents with another string.
   * @param other String to swap with.
   */
  GLIBMM_API void swap(ustring& other);

  /*! Construct a ustring as a copy of a std::string.
   * @param src A source <tt>std::string</tt> containing text encoded as UTF-8.
   */
  GLIBMM_API ustring(const std::string& src);

  /*! Construct a ustring by moving from a std::string.
   * @param src A source <tt>std::string</tt> containing text encoded as UTF-8.
   */
  GLIBMM_API ustring(std::string&& src);

  /*! Construct a ustring as a copy of a substring.
   * @param src %Source ustring.
   * @param i Index of first character to copy from.
   * @param n Number of UTF-8 characters to copy (defaults to copying the remainder).
   */
  GLIBMM_API ustring(const ustring& src, size_type i, size_type n = npos);

  /*! Construct a ustring as a partial copy of a C string.
   * @param src %Source C string encoded as UTF-8.
   * @param n Number of UTF-8 characters to copy.
   */
  GLIBMM_API ustring(const char* src, size_type n);

  /*! Construct a ustring as a copy of a C string.
   * @param src %Source C string encoded as UTF-8.
   */
  GLIBMM_API ustring(const char* src);

  /*! Construct a ustring as multiple characters.
   * @param n Number of characters.
   * @param uc UCS-4 code point to use.
   */
  GLIBMM_API ustring(size_type n, gunichar uc);

  /*! Construct a ustring as multiple characters.
   * @param n Number of characters.
   * @param c ASCII character to use.
   */
  GLIBMM_API ustring(size_type n, char c);

  /*! Construct a ustring as a copy of a range.
   * @param pbegin Start of range.
   * @param pend End of range.
   */
  template <class In>
  ustring(In pbegin, In pend);

  //! @name Assign new contents.
  //! @{

  GLIBMM_API ustring& operator=(const std::string& src);
  GLIBMM_API ustring& operator=(std::string&& src);
  GLIBMM_API ustring& operator=(const char* src);
  GLIBMM_API ustring& operator=(gunichar uc);
  GLIBMM_API ustring& operator=(char c);

  GLIBMM_API ustring& assign(const ustring& src);
  GLIBMM_API ustring& assign(ustring&& src);
  GLIBMM_API ustring& assign(const ustring& src, size_type i, size_type n);
  GLIBMM_API ustring& assign(const char* src, size_type n);
  GLIBMM_API ustring& assign(const char* src);
  GLIBMM_API ustring& assign(size_type n, gunichar uc);
  GLIBMM_API ustring& assign(size_type n, char c);
  template <class In>
  ustring& assign(In pbegin, In pend);

  //! @}
  //! @name Append to the string.
  //! @{

  GLIBMM_API ustring& operator+=(const ustring& src);
  GLIBMM_API ustring& operator+=(const char* src);
  GLIBMM_API ustring& operator+=(gunichar uc);
  GLIBMM_API ustring& operator+=(char c);
  GLIBMM_API void push_back(gunichar uc);
  GLIBMM_API void push_back(char c);

  GLIBMM_API ustring& append(const ustring& src);
  GLIBMM_API ustring& append(const ustring& src, size_type i, size_type n);
  GLIBMM_API ustring& append(const char* src, size_type n);
  GLIBMM_API ustring& append(const char* src);
  GLIBMM_API ustring& append(size_type n, gunichar uc);
  GLIBMM_API ustring& append(size_type n, char c);
  template <class In>
  ustring& append(In pbegin, In pend);

  //! @}
  //! @name Insert into the string.
  //! @{

  GLIBMM_API ustring& insert(size_type i, const ustring& src);
  GLIBMM_API ustring& insert(size_type i, const ustring& src, size_type i2, size_type n);
  GLIBMM_API ustring& insert(size_type i, const char* src, size_type n);
  GLIBMM_API ustring& insert(size_type i, const char* src);
  GLIBMM_API ustring& insert(size_type i, size_type n, gunichar uc);
  GLIBMM_API ustring& insert(size_type i, size_type n, char c);

  GLIBMM_API iterator insert(iterator p, gunichar uc);
  GLIBMM_API iterator insert(iterator p, char c);
  GLIBMM_API void insert(iterator p, size_type n, gunichar uc);
  GLIBMM_API void insert(iterator p, size_type n, char c);
  template <class In>
  void insert(iterator p, In pbegin, In pend);

  //! @}
  //! @name Replace sub-strings.
  //! @{

  GLIBMM_API ustring& replace(size_type i, size_type n, const ustring& src);
  GLIBMM_API ustring& replace(size_type i, size_type n, const ustring& src, size_type i2, size_type n2);
  GLIBMM_API ustring& replace(size_type i, size_type n, const char* src, size_type n2);
  GLIBMM_API ustring& replace(size_type i, size_type n, const char* src);
  GLIBMM_API ustring& replace(size_type i, size_type n, size_type n2, gunichar uc);
  GLIBMM_API ustring& replace(size_type i, size_type n, size_type n2, char c);

  GLIBMM_API ustring& replace(iterator pbegin, iterator pend, const ustring& src);
  GLIBMM_API ustring& replace(iterator pbegin, iterator pend, const char* src, size_type n);
  GLIBMM_API ustring& replace(iterator pbegin, iterator pend, const char* src);
  GLIBMM_API ustring& replace(iterator pbegin, iterator pend, size_type n, gunichar uc);
  GLIBMM_API ustring& replace(iterator pbegin, iterator pend, size_type n, char c);
  template <class In>
  ustring& replace(iterator pbegin, iterator pend, In pbegin2, In pend2);

  //! @}
  //! @name Erase sub-strings.
  //! @{

  GLIBMM_API void clear();
  GLIBMM_API ustring& erase(size_type i, size_type n = npos);
  GLIBMM_API ustring& erase();
  GLIBMM_API iterator erase(iterator p);
  GLIBMM_API iterator erase(iterator pbegin, iterator pend);

  //! @}
  //! @name Compare and collate.
  //! @{

  GLIBMM_API int compare(UStringView rhs) const;
  GLIBMM_API int compare(size_type i, size_type n, UStringView rhs) const;
  GLIBMM_API int compare(size_type i, size_type n, const ustring& rhs, size_type i2, size_type n2) const;
  GLIBMM_API int compare(size_type i, size_type n, const char* rhs, size_type n2) const;

  /*! Create a unique sorting key for the UTF-8 string.  If you need to
   * compare UTF-8 strings regularly, e.g. for sorted containers such as
   * <tt>std::set<></tt>, you should consider creating a collate key first
   * and compare this key instead of the actual string.
   *
   * The ustring::compare() methods as well as the relational operators
   * <tt>==&nbsp;!=&nbsp;<&nbsp;>&nbsp;<=&nbsp;>=</tt> are quite costly
   * because they have to deal with %Unicode and the collation rules defined by
   * the current locale.  Converting both operands to UCS-4 is just the first
   * of several costly steps involved when comparing ustrings.  So be careful.
   */
  GLIBMM_API std::string collate_key() const;

  /*! Create a unique key for the UTF-8 string that can be used for caseless
   * sorting.  <tt>ustr.casefold_collate_key()</tt> results in the same string
   * as <tt>ustr.casefold().collate_key()</tt>, but the former is likely more
   * efficient.
   */
  GLIBMM_API std::string casefold_collate_key() const;

  //! @}
  //! @name Extract characters and sub-strings.
  //! @{

  /*! No reference return; use replace() to write characters. */
  GLIBMM_API value_type operator[](size_type i) const;

  /*! No reference return; use replace() to write characters. @throw std::out_of_range */
  GLIBMM_API value_type at(size_type i) const;

  GLIBMM_API inline ustring substr(size_type i = 0, size_type n = npos) const;

  //! @}
  //! @name Access a sequence of characters.
  //! @{

  GLIBMM_API iterator begin();
  GLIBMM_API iterator end();
  GLIBMM_API const_iterator begin() const;
  GLIBMM_API const_iterator end() const;
  GLIBMM_API reverse_iterator rbegin();
  GLIBMM_API reverse_iterator rend();
  GLIBMM_API const_reverse_iterator rbegin() const;
  GLIBMM_API const_reverse_iterator rend() const;

  /**
   * @newin{2,52}
   */
  GLIBMM_API const_iterator cbegin() const;

  /**
   * @newin{2,52}
   */
  GLIBMM_API const_iterator cend() const;

  //! @}
  //! @name Find sub-strings.
  //! @{

  GLIBMM_API size_type find(const ustring& str, size_type i = 0) const;
  GLIBMM_API size_type find(const char* str, size_type i, size_type n) const;
  GLIBMM_API size_type find(const char* str, size_type i = 0) const;
  GLIBMM_API size_type find(gunichar uc, size_type i = 0) const;
  GLIBMM_API size_type find(char c, size_type i = 0) const;

  GLIBMM_API size_type rfind(const ustring& str, size_type i = npos) const;
  GLIBMM_API size_type rfind(const char* str, size_type i, size_type n) const;
  GLIBMM_API size_type rfind(const char* str, size_type i = npos) const;
  GLIBMM_API size_type rfind(gunichar uc, size_type i = npos) const;
  GLIBMM_API size_type rfind(char c, size_type i = npos) const;

  //! @}
  //! @name Match against a set of characters.
  //! @{

  GLIBMM_API size_type find_first_of(const ustring& match, size_type i = 0) const;
  GLIBMM_API size_type find_first_of(const char* match, size_type i, size_type n) const;
  GLIBMM_API size_type find_first_of(const char* match, size_type i = 0) const;
  GLIBMM_API size_type find_first_of(gunichar uc, size_type i = 0) const;
  GLIBMM_API size_type find_first_of(char c, size_type i = 0) const;

  GLIBMM_API size_type find_last_of(const ustring& match, size_type i = npos) const;
  GLIBMM_API size_type find_last_of(const char* match, size_type i, size_type n) const;
  GLIBMM_API size_type find_last_of(const char* match, size_type i = npos) const;
  GLIBMM_API size_type find_last_of(gunichar uc, size_type i = npos) const;
  GLIBMM_API size_type find_last_of(char c, size_type i = npos) const;

  GLIBMM_API size_type find_first_not_of(const ustring& match, size_type i = 0) const;
  GLIBMM_API size_type find_first_not_of(const char* match, size_type i, size_type n) const;
  GLIBMM_API size_type find_first_not_of(const char* match, size_type i = 0) const;
  GLIBMM_API size_type find_first_not_of(gunichar uc, size_type i = 0) const;
  GLIBMM_API size_type find_first_not_of(char c, size_type i = 0) const;

  GLIBMM_API size_type find_last_not_of(const ustring& match, size_type i = npos) const;
  GLIBMM_API size_type find_last_not_of(const char* match, size_type i, size_type n) const;
  GLIBMM_API size_type find_last_not_of(const char* match, size_type i = npos) const;
  GLIBMM_API size_type find_last_not_of(gunichar uc, size_type i = npos) const;
  GLIBMM_API size_type find_last_not_of(char c, size_type i = npos) const;

  //! @}
  //! @name Retrieve the string's size.
  //! @{

  /** Returns true if the string is empty. Equivalent to *this == "".
   * @result Whether the string is empty.
   */
  GLIBMM_API bool empty() const;

  /** Returns the number of characters in the string, not including any null-termination.
   * @result The number of UTF-8 characters.
   *
   * @see bytes(), empty()
   */
  GLIBMM_API size_type size() const;

  // We have length() as well as size(), because std::string has both.

  /** This is the same as size().
   */
  GLIBMM_API size_type length() const;

  /** Returns the number of bytes in the string, not including any null-termination.
   * @result The number of bytes.
   *
   * @see size(), empty()
   */
  GLIBMM_API size_type bytes() const;

  //! @}
  //! @name Change the string's size.
  //! @{

  GLIBMM_API void resize(size_type n, gunichar uc);
  GLIBMM_API void resize(size_type n, char c = '\0');

  //! @}
  //! @name Control the allocated memory.
  //! @{

  GLIBMM_API size_type capacity() const;
  GLIBMM_API size_type max_size() const;
  GLIBMM_API void reserve(size_type n = 0);

  //! @}
  //! @name Get a per-byte representation of the string.
  //! @{

  GLIBMM_API inline operator std::string() const; // e.g. std::string str = ustring();
  GLIBMM_API inline const std::string& raw() const;
  /*! Return the stored string, moved from the %ustring.
   * @newin{2,74}
   */
  GLIBMM_API inline std::string release();

  // Not necessarily an ASCII char*. Use g_utf8_*() where necessary.
  GLIBMM_API const char* data() const;
  GLIBMM_API const char* c_str() const;

  /*! @return Number of copied @em bytes, not characters. */
  GLIBMM_API size_type copy(char* dest, size_type n, size_type i = 0) const;

  //! @}
  //! @name UTF-8 utilities.
  //! @{

  /*! Check whether the string is valid UTF-8. */
  GLIBMM_API bool validate() const;

  /*! Check whether the string is valid UTF-8. */
  GLIBMM_API bool validate(iterator& first_invalid);

  /*! Check whether the string is valid UTF-8. */
  GLIBMM_API bool validate(const_iterator& first_invalid) const;

  /*! Return a copy that is a valid UTF-8 string replacing invalid bytes in the
   *  original with %Unicode replacement character (U+FFFD).
   *  If the string is valid, return a copy of it.
   */
  GLIBMM_API ustring make_valid() const;

  /*! Check whether the string is plain 7-bit ASCII. @par
   * Unlike any other ustring method, is_ascii() is safe to use on invalid
   * UTF-8 strings.  If the string isn't valid UTF-8, it cannot be valid
   * ASCII either, therefore is_ascii() will just return @c false then.
   * @return Whether the string contains only ASCII characters.
   */
  GLIBMM_API bool is_ascii() const;

  /*! "Normalize" the %Unicode character representation of the string. */
  GLIBMM_API ustring normalize(NormalizeMode mode = NormalizeMode::DEFAULT_COMPOSE) const;

  /*! Cuts off the middle of the string.
   *
   * Preserves half of @a truncate_length characters at the beginning
   * and half at the end.
   *
   * If the string is already short enough, this returns a copy of the string.
   * If @a truncate_length is 0, an empty string is returned.
   *
   * @newin{2,78}
   */
  GLIBMM_API ustring truncate_middle(gsize truncate_length) const;

  //! @}
  //! @name Character case conversion.
  //! @{

  /*! Returns a new UTF-8 string with all characters characters converted to
   * their uppercase equivalent, while honoring the current locale.  The
   * resulting string may change in the number of bytes as well as in the
   * number of characters.  For instance, the German sharp&nbsp;s
   * <tt>&quot;&szlig;&quot;</tt> will be replaced by two characters
   * <tt>"SS"</tt> because there is no capital <tt>&quot;&szlig;&quot;</tt>.
   */
  GLIBMM_API ustring uppercase() const;

  /*! Returns a new UTF-8 string with all characters characters converted to
   * their lowercase equivalent, while honoring the current locale.  The
   * resulting string may change in the number of bytes as well as in the
   * number of characters.
   */
  GLIBMM_API ustring lowercase() const;

  /*! Returns a caseless representation of the UTF-8 string.  The resulting
   * string doesn't correspond to any particular case, therefore the result
   * is only useful to compare strings and should never be displayed to the
   * user.
   */
  GLIBMM_API ustring casefold() const;

  //! @}
  //! @name Message formatting.
  //! @{

  /* Returns fmt as is, but checks for invalid references in the format string.
   * @newin{2,18}
   */
  GLIBMM_API static inline ustring compose(const ustring& fmt);

  /*! Substitute placeholders in a format string with the referenced arguments.
   *
   * The template string uses a similar format to Qt’s QString class, in that
   * <tt>%1</tt>, <tt>%2</tt>, and so on to <tt>%9</tt> are used as placeholders
   * to be substituted with the string representation of the @a args 1–9, while
   * <tt>%%</tt> inserts a literal <tt>%</tt> in the output. Placeholders do not
   * have to appear in the same order as their corresponding function arguments.
   *
   * @par Example:
   * @code
   * using Glib::ustring;
   * const int percentage = 50;
   * const ustring text = ustring::compose("%1%% done", percentage);
   * @endcode
   *
   * @param fmt The template string, in the format described above.
   * @param args 1 to 9 arguments to substitute for <tt>%1</tt> to <tt>%9</tt>
   * respectively.
   *
   * @return The substituted message string.
   *
   * @throw Glib::ConvertError
   *
   * @newin{2,58}
   */
  template <class... Ts>
  static inline ustring compose(const ustring& fmt, const Ts&... args);

  /*! Format the argument(s) to a string representation.
   *
   * Applies the arguments in order to an std::wostringstream and returns the
   * resulting string.  I/O manipulators may also be used as arguments.  This
   * greatly simplifies the common task of converting a number to a string, as
   * demonstrated by the example below.  The format() methods can also be used
   * in conjunction with compose() to facilitate localization of user-visible
   * messages.
   *
   * @code
   * using Glib::ustring;
   * double value = 22.0 / 7.0;
   * ustring text = ustring::format(std::fixed, std::setprecision(2), value);
   * @endcode
   *
   * @note The use of a wide character stream in the implementation of format()
   * is almost completely transparent.  However, one of the instances where the
   * use of wide streams becomes visible is when the std::setfill() stream
   * manipulator is used.  In order for std::setfill() to work the argument
   * must be of type <tt>wchar_t</tt>.  This can be achieved by using the
   * <tt>L</tt> prefix with a character literal, as shown in the example.
   *
   * @code
   * using Glib::ustring;
   * // Insert leading zeroes to fill in at least six digits
   * ustring text = ustring::format(std::setfill(L'0'), std::setw(6), 123);
   * @endcode
   *
   * @param args One or more streamable values or I/O manipulators.
   *
   * @return The string representation of the argument stream.
   *
   * @throw Glib::ConvertError
   *
   * @newin{2,58}
   */
  template <class... Ts>
  static inline ustring format(const Ts&... args);

  /*! Substitute placeholders in a format string with the referenced arguments.
   *
   * This function takes a template string in the format used by C’s
   * <tt>printf()</tt> family of functions and an arbitrary number of arguments,
   * replaces each placeholder in the template with the formatted version of its
   * corresponding argument at the same ordinal position in the list of
   * subsequent arguments, and returns the result in a new Glib::ustring.
   *
   * Note: You must pass the correct count/types/order of arguments to match
   * the format string, as when calling <tt>printf()</tt> directly. glibmm does
   * not check this for you. Breaking this contract invokes undefined behavior
   * and is a security risk.
   *
   * The exception is that glibmm special-cases std::string and Glib::ustring,
   * so you can pass them in positions corresponding to <tt>%s</tt> placeholders
   * without having to call their .c_str() functions; glibmm does that for you.
   * glibmm also overloads sprintf() with @p fmt but no @p args to avoid risks.
   *
   * Said restriction also makes sprintf() unsuitable for translatable strings,
   * as translators cannot reorder the placeholders to suit their language. If
   * you wish to support translation, you should instead use compose(), as its
   * placeholders are numbered rather than ordinal, so they can be moved freely.
   *
   * @par Example:
   * @code
   *
   * const auto greeting = std::string{"Hi"};
   * const auto name = Glib::ustring{"Dennis"};
   * const auto your_cows = 3;
   * const auto my_cows = 11;
   * const auto cow_percentage = 100.0 * your_cows / my_cows;
   *
   * const auto text = Glib::ustring::sprintf(
   *   "%s, %s! You have %d cows. That's about %0.2f%% of the %d cows I have.",
   *   greeting, name, your_cows, cow_percentage, my_cows);
   *
   * std::cout << text;
   * // Hi, Dennis! You have 3 cows. That's about 27.27% of the 11 cows I have.
   * @endcode
   *
   * @param fmt The template string, in the format used by <tt>printf()</tt> et al.
   * @param args A set of arguments having the count/types/order required by @a fmt.
   *
   * @return The substituted string.
   *
   * @newin{2,62}
   */
  template <class... Ts>
  static inline ustring sprintf(const ustring& fmt, const Ts&... args);

  /*! Overload of sprintf() taking a string literal.
   *
   * The main benefit of this is not constructing a temporary ustring if @p fmt
   * is a string literal. A secondary effect is that it might encourage compilers
   * to check if the given format @p fmt matches the variadic arguments @p args.
   * The latter effect is a convenience at best; you must not rely on it to find
   * errors in your code, as your compiler might not always be able to do so.
   *
   * @param fmt The template string, in the format used by <tt>printf()</tt> et al.
   * @param args A set of arguments having the count/types/order required by @a fmt.
   *
   * @return The substituted string.
   *
   * @newin{2,62}
   */
  template <class... Ts>
  static inline ustring sprintf(const char* fmt, const Ts&... args);

  /*! Overload of sprintf() for a format string only, which returns it unchanged.
   *
   * If no @p args to be substituted are given, there is nothing to do, so the
   * @p fmt string is returned as-is without substitution. This is an obvious
   * case of mismatched format/args that we can check. Not doing so causes
   * warnings/errors with common compiler options, as it is a security risk.
   *
   * @param fmt The string
   * @return The same string.
   *
   * @newin{2,62}
   */
  GLIBMM_API static inline ustring sprintf(const ustring& fmt);

  /*! Overload of sprintf() for a format string only, which returns it unchanged
   * and avoids creating a temporary ustring as the argument.
   *
   * @param fmt The string
   * @return The same string, as a ustring.
   *
   * @newin{2,62}
   */
  GLIBMM_API static inline ustring sprintf(const char* fmt);

  //! @}

private:
#ifndef DOXYGEN_SHOULD_SKIP_THIS

#ifdef GLIBMM_HAVE_STD_ITERATOR_TRAITS
  template <class In, class ValueType = typename std::iterator_traits<In>::value_type>
#else
  template <class In, class ValueType = typename Glib::IteratorTraits<In>::value_type>
#endif
  struct SequenceToString;

  // The Tru64 compiler needs these partial specializations to be declared here,
  // as well as defined later. That's probably correct. murrayc.
  template <class In>
  struct SequenceToString<In, char>;
  template <class In>
  struct SequenceToString<In, gunichar>;

  template <class T>
  class Stringify;

  GLIBMM_API static ustring compose_private(const ustring& fmt, std::initializer_list<const ustring*> ilist);

  class FormatStream;

  template<class T> static inline const T& sprintify(const T& arg);
  GLIBMM_API static inline const char* sprintify(const ustring& arg);
  GLIBMM_API static inline const char* sprintify(const std::string& arg);

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

  std::string string_;
};

#ifndef DOXYGEN_SHOULD_SKIP_THIS

template <class In, class ValueType>
struct ustring::SequenceToString
{
};

template <class In>
struct ustring::SequenceToString<In, char> : public std::string
{
  SequenceToString(In pbegin, In pend);
};

template <class In>
struct ustring::SequenceToString<In, gunichar> : public std::string
{
  SequenceToString(In pbegin, In pend);
};

template <>
struct ustring::SequenceToString<Glib::ustring::iterator, gunichar> : public std::string
{
  GLIBMM_API SequenceToString(Glib::ustring::iterator pbegin, Glib::ustring::iterator pend);
};

template <>
struct ustring::SequenceToString<Glib::ustring::const_iterator, gunichar> : public std::string
{
  GLIBMM_API SequenceToString(Glib::ustring::const_iterator pbegin, Glib::ustring::const_iterator pend);
};


class ustring::FormatStream
{
public:
  // noncopyable
  FormatStream(const ustring::FormatStream&) = delete;
  FormatStream& operator=(const ustring::FormatStream&) = delete;

private:
#ifdef GLIBMM_HAVE_WIDE_STREAM
  using StreamType = std::wostringstream;
#else
  using StreamType = std::ostringstream;
#endif
  StreamType stream_;

public:
  GLIBMM_API FormatStream();
  GLIBMM_API ~FormatStream() noexcept;

  template <class T>
  inline void stream(const T& value);

  GLIBMM_API inline void stream(const char* value);

  // This overload exists to avoid the templated stream() being called for non-const char*.
  GLIBMM_API inline void stream(char* value);

  // TODO: C++20: Replace const with &&
  GLIBMM_API ustring to_string() const;
};

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** Stream input operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
GLIBMM_API
std::istream& operator>>(std::istream& is, Glib::ustring& utf8_string);

/** Stream output operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
GLIBMM_API
std::ostream& operator<<(std::ostream& os, const Glib::ustring& utf8_string);

#ifdef GLIBMM_HAVE_WIDE_STREAM

/** Wide stream input operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
GLIBMM_API
 */
std::wistream& operator>>(std::wistream& is, ustring& utf8_string);

/** Wide stream output operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
GLIBMM_API
std::wostream& operator<<(std::wostream& os, const ustring& utf8_string);

#endif /* GLIBMM_HAVE_WIDE_STREAM */

/***************************************************************************/
/*  Inline implementation                                                  */
/***************************************************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::ustring_Iterator<> *********************************************/

template <class T>
inline ustring_Iterator<T>::ustring_Iterator(T pos) : pos_(pos)
{
}

template <class T>
inline T
ustring_Iterator<T>::base() const
{
  return pos_;
}

template <class T>
inline ustring_Iterator<T>::ustring_Iterator() : pos_()
{
}

template <class T>
inline ustring_Iterator<T>::ustring_Iterator(const ustring_Iterator<std::string::iterator>& other)
: pos_(other.base())
{
}

template <class T>
inline typename ustring_Iterator<T>::value_type ustring_Iterator<T>::operator*() const
{
  return Glib::get_unichar_from_std_iterator(pos_);
}

template <class T>
inline ustring_Iterator<T>& ustring_Iterator<T>::operator++()
{
  pos_ += g_utf8_skip[static_cast<unsigned char>(*pos_)];
  return *this;
}

template <class T>
inline const ustring_Iterator<T> ustring_Iterator<T>::operator++(int)
{
  const ustring_Iterator<T> temp(*this);
  this->operator++();
  return temp;
}

template <class T>
inline ustring_Iterator<T>& ustring_Iterator<T>::operator--()
{
  while ((static_cast<unsigned char>(*--pos_) & 0xC0u) == 0x80)
  {
    ;
  }

  return *this;
}

template <class T>
inline const ustring_Iterator<T> ustring_Iterator<T>::operator--(int)
{
  const ustring_Iterator<T> temp(*this);
  this->operator--();
  return temp;
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** @relates Glib::ustring_Iterator */
inline bool
operator==(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() == rhs.base());
}

/** @relates Glib::ustring_Iterator */
inline bool
operator!=(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() != rhs.base());
}

/** @relates Glib::ustring_Iterator */
inline bool
operator<(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() < rhs.base());
}

/** @relates Glib::ustring_Iterator */
inline bool
operator>(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() > rhs.base());
}

/** @relates Glib::ustring_Iterator */
inline bool
operator<=(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() <= rhs.base());
}

/** @relates Glib::ustring_Iterator */
inline bool
operator>=(const Glib::ustring::const_iterator& lhs, const Glib::ustring::const_iterator& rhs)
{
  return (lhs.base() >= rhs.base());
}

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::ustring::SequenceToString **************************************/

template <class In>
ustring::SequenceToString<In, char>::SequenceToString(In pbegin, In pend)
: std::string(pbegin, pend)
{
}

template <class In>
ustring::SequenceToString<In, gunichar>::SequenceToString(In pbegin, In pend)
{
  char utf8_buf[6]; // stores a single UTF-8 character

  for (; pbegin != pend; ++pbegin)
  {
    const std::string::size_type utf8_len = g_unichar_to_utf8(*pbegin, utf8_buf);
    this->append(utf8_buf, utf8_len);
  }
}

/**** Glib::ustring::FormatStream ******************************************/

template <class T>
inline void
ustring::FormatStream::stream(const T& value)
{
  stream_ << value;
}

inline void
ustring::FormatStream::stream(const char* value)
{
  stream_ << ustring(value);
}

inline void
ustring::FormatStream::stream(char* value)
{
  stream_ << ustring(value);
}

/**** Glib::ustring ********************************************************/

template <class In>
ustring::ustring(In pbegin, In pend) : string_(Glib::ustring::SequenceToString<In>(pbegin, pend))
{
}

template <class In>
ustring&
ustring::assign(In pbegin, In pend)
{
  Glib::ustring::SequenceToString<In> temp_string(pbegin, pend);
  string_.swap(temp_string); // constant-time operation
  return *this;
}

template <class In>
ustring&
ustring::append(In pbegin, In pend)
{
  string_.append(Glib::ustring::SequenceToString<In>(pbegin, pend));
  return *this;
}

template <class In>
void
ustring::insert(ustring::iterator p, In pbegin, In pend)
{
  size_type pos = p.base() - string_.begin();
  string_.insert(pos, Glib::ustring::SequenceToString<In>(pbegin, pend));
}

template <class In>
ustring&
ustring::replace(ustring::iterator pbegin, ustring::iterator pend, In pbegin2, In pend2)
{
  string_.replace(pbegin.base(), pend.base(), Glib::ustring::SequenceToString<In>(pbegin2, pend2));
  return *this;
}

// The ustring methods substr() and operator std::string() are inline,
// so that the compiler has a fair chance to optimize the copy ctor away.

inline ustring
ustring::substr(ustring::size_type i, ustring::size_type n) const
{
  return ustring(*this, i, n);
}

// TODO: When we can break ABI – replace with a const& overload returning const std::string&
// to avoid silent copies, and a corresponding && overload to move string out of rvalue this
inline ustring::operator std::string() const
{
  return string_;
}

inline const std::string&
ustring::raw() const
{
  return string_;
}

inline std::string
ustring::release()
{
  return std::move(string_);
}

template <class... Ts>
inline // static
  ustring
  ustring::format(const Ts&... args)
{
  ustring::FormatStream buf;
  (buf.stream(args), ...);
  // TODO: C++20: std::move(buf).to_string()
  return buf.to_string();
}

/** An inner class used by ustring.
 */
template <class T>
class ustring::Stringify
{
private:
  const ustring string_;

public:
  explicit inline Stringify(const T& arg) : string_(ustring::format(arg)) {}

  // noncopyable
  Stringify(const ustring::Stringify<T>&) = delete;
  Stringify<T>& operator=(const ustring::Stringify<T>&) = delete;

  inline const ustring& ref() const { return string_; }
};

/// A template specialization for Stringify<ustring>:
template <>
class ustring::Stringify<ustring>
{
private:
  const ustring& string_;

public:
  explicit inline Stringify(const ustring& arg) : string_(arg) {}

  // noncopyable
  Stringify(const ustring::Stringify<ustring>&) = delete;
  Stringify<ustring>& operator=(const ustring::Stringify<ustring>&) = delete;

  inline const ustring& ref() const { return string_; }
};

/** A template specialization for Stringify<const char*>,
 * because the regular template has ambiguous constructor overloads for char*.
 */
template <>
class ustring::Stringify<const char*>
{
private:
  const ustring string_;

public:
  explicit inline Stringify(const char* arg) : string_(arg) {}

  // noncopyable
  Stringify(const ustring::Stringify<const char*>&) = delete;
  Stringify<ustring>& operator=(const ustring::Stringify<const char*>&) = delete;

  inline const ustring& ref() const { return string_; }
};

/** A template specialization for Stringify<char[N]> (for string literals),
 * because the regular template has ambiguous constructor overloads for char*.
 */
template <std::size_t N>
class ustring::Stringify<char[N]>
{
private:
  const ustring string_;

public:
  explicit inline Stringify(const char arg[N]) : string_(arg) {}

  // noncopyable
  Stringify(const ustring::Stringify<char[N]>&) = delete;
  Stringify<ustring>& operator=(const ustring::Stringify<char[N]>&) = delete;

  inline const ustring& ref() const { return string_; }
};

/** A template specialization for Stringify<const char[N]> (for string literals),
 * because the regular template has ambiguous constructor overloads for char*
 * on later versions of Visual C++ (2008 and later at least).
 */
template <std::size_t N>
class ustring::Stringify<const char[N]>
{
private:
  const ustring string_;

public:
  explicit inline Stringify(const char arg[N]) : string_(arg) {}

  // noncopyable
  Stringify(const ustring::Stringify<const char[N]>&) = delete;
  Stringify<ustring>& operator=(const ustring::Stringify<const char[N]>&) = delete;

  inline const ustring& ref() const { return string_; }
};

/* These helper functions used by ustring::sprintf() let users pass C++ strings
 * to match %s placeholders, without the hassle of writing .c_str() in user code
 */
template<typename T>
inline // static
  const T&
  ustring::sprintify(const T& arg)
{
  return arg;
}

inline // static
  const char*
  ustring::sprintify(const ustring& arg)
{
  return arg.c_str();
}

inline // static
  const char*
  ustring::sprintify(const std::string& arg)
{
  return arg.c_str();
}

// Public methods

inline // static
  ustring
  ustring::compose(const ustring& fmt)
{
  return ustring::compose_private(fmt, {});
}

template <class... Ts>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const Ts&... args)
{
  static_assert(sizeof...(Ts) <= 9,
                "ustring::compose only supports up to 9 placeholders.");

  return compose_private(fmt, {&Stringify<Ts>(args).ref()...});
}

template <class... Ts>
inline // static
  ustring
  ustring::sprintf(const ustring& fmt, const Ts&... args)
{
  return sprintf(fmt.c_str(), args...);
}

template <class... Ts>
inline // static
  ustring
  ustring::sprintf(const char* fmt, const Ts&... args)
{
  auto c_str = g_strdup_printf(fmt, sprintify(args)...);
  Glib::ustring ustr(c_str);
  g_free(c_str);

  return ustr;
}

inline // static
  ustring
  ustring::sprintf(const ustring& fmt)
{
  return fmt;
}

inline // static
  ustring
  ustring::sprintf(const char* fmt)
{
  return ustring(fmt);
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** @relates Glib::ustring */
inline void
swap(ustring& lhs, ustring& rhs)
{
  lhs.swap(rhs);
}

/**** Glib::ustring -- comparison operators ********************************/

// See https://gitlab.gnome.org/GNOME/glibmm/-/issues/65
// and https://gitlab.gnome.org/GNOME/glibmm/-/issues/121

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator==(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) == 0);
}

/** @relates Glib::ustring */
inline bool
operator==(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) == 0);
}

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator!=(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) != 0);
}

/** @relates Glib::ustring */
inline bool
operator!=(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) != 0);
}

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator<(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) < 0);
}

/** @relates Glib::ustring */
inline bool
operator<(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) > 0);
}

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator>(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) > 0);
}

/** @relates Glib::ustring */
inline bool
operator>(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) < 0);
}

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator<=(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) <= 0);
}

/** @relates Glib::ustring */
inline bool
operator<=(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) >= 0);
}

/** @relates Glib::ustring */
template <typename T, typename = std::enable_if_t<std::is_convertible_v<T, UStringView>>>
inline bool
operator>=(const ustring& lhs, const T& rhs)
{
  return (lhs.compare(rhs) >= 0);
}

/** @relates Glib::ustring */
inline bool
operator>=(UStringView lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) <= 0);
}

#ifndef DOXYGEN_SHOULD_SKIP_THIS
// Don't allow implicit conversion of integer 0 to nullptr in the relational operators.
// If the int versions of the relational operators are not deleted, attempts to
// compare with other integer values than 0 can result in really unexpected behaviour.
// See https://bugzilla.gnome.org/show_bug.cgi?id=572978#c10
bool operator==(const ustring& lhs, int rhs) = delete;
bool operator==(int lhs, const ustring& rhs) = delete;
bool operator!=(const ustring& lhs, int rhs) = delete;
bool operator!=(int lhs, const ustring& rhs) = delete;
bool operator<(const ustring& lhs, int rhs) = delete;
bool operator<(int lhs, const ustring& rhs) = delete;
bool operator>(const ustring& lhs, int rhs) = delete;
bool operator>(int lhs, const ustring& rhs) = delete;
bool operator<=(const ustring& lhs, int rhs) = delete;
bool operator<=(int lhs, const ustring& rhs) = delete;
bool operator>=(const ustring& lhs, int rhs) = delete;
bool operator>=(int lhs, const ustring& rhs) = delete;
#endif // DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::ustring -- concatenation operators *****************************/

/** @relates Glib::ustring */
inline ustring
operator+(const ustring& lhs, const ustring& rhs)
{
  ustring temp(lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(const ustring& lhs, const char* rhs)
{
  ustring temp(lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(const char* lhs, const ustring& rhs)
{
  ustring temp(lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(const ustring& lhs, gunichar rhs)
{
  ustring temp(lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(gunichar lhs, const ustring& rhs)
{
  ustring temp(1, lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(const ustring& lhs, char rhs)
{
  ustring temp(lhs);
  temp += rhs;
  return temp;
}

/** @relates Glib::ustring */
inline ustring
operator+(char lhs, const ustring& rhs)
{
  ustring temp(1, lhs);
  temp += rhs;
  return temp;
}

//********** Glib::StdStringView and Glib::UStringView *************

inline UStringView::UStringView(const ustring& s) : pstring_(s.c_str()) {}

} // namespace Glib

#endif /* _GLIBMM_USTRING_H */
