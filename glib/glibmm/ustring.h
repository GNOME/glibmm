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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmmconfig.h>
#include <glibmm/unicode.h>
#include <glib.h>

#include <iosfwd>
#include <iterator>
#include <sstream>
#include <string>
#ifndef GLIBMM_HAVE_STD_ITERATOR_TRAITS
#include <cstddef> /* for std::ptrdiff_t */
#endif

namespace Glib
{

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
 * If it does not, operator++(), operator-\-() and operator*() may make
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
gunichar get_unichar_from_std_iterator(std::string::const_iterator pos) G_GNUC_PURE;

/** Glib::ustring has much the same interface as std::string, but contains
 * %Unicode characters encoded as UTF-8.
 *
 * @par About UTF-8 and ASCII
 * @par
 * The standard character set ANSI_X3.4-1968&nbsp;-- more commonly known as
 * ASCII&nbsp;-- is a subset of UTF-8.  So, if you want to, you can use
 * Glib::ustring without even thinking about UTF-8.
 * @par
 * Whenever ASCII is mentioned in this manual, we mean the @em real ASCII
 * (i.e. as defined in ANSI_X3.4-1968), which contains only 7-bit characters.
 * Glib::ustring can @em not be used with ASCII-compatible extended 8-bit
 * charsets like ISO-8859-1.  It's a good idea to avoid string literals
 * containing non-ASCII characters (e.g. German umlauts) in source code,
 * or at least you should use UTF-8 literals.
 * @par
 * You can find a detailed UTF-8 and %Unicode FAQ here:
 * http://www.cl.cam.ac.uk/~mgk25/unicode.html
 *
 * @par Glib::ustring vs. std::string
 * @par
 * Glib::ustring has implicit type conversions to and from std::string.
 * These conversions do @em not convert to/from the current locale (see
 * Glib::locale_from_utf8() and Glib::locale_to_utf8() if you need that).  You
 * can always use std::string instead of Glib::ustring&nbsp;-- however, using
 * std::string with multi-byte characters is quite hard.  For instance,
 * <tt>std::string::operator[]</tt> might return a byte in the middle of a
 * character, and <tt>std::string::length()</tt> returns the number of bytes
 * rather than characters.  So don't do that without a good reason.
 * @par
 * Many member functions and operators of Glib::ustring and Glib::ustring_Iterator
 * assume that the string contains only valid UTF-8 data. If it does not, memory
 * outside the bounds of the string can be accessed.
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
 * std::locale::global(std::locale("")); // set the global locale to the user's preferred locale
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
 * @par Implementation notes
 * @par
 * Glib::ustring does not inherit from std::string, because std::string was
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
  static GLIBMM_API const size_type npos = std::string::npos;
#else
  // The IRIX MipsPro compiler says "The indicated constant value is not known",
  // so we need to initalize the static member data elsewhere.
  static GLIBMM_API const size_type npos;
#endif

  /*! Default constructor, which creates an empty string.
   */
  ustring();

  ~ustring() noexcept;

  /*! Construct a ustring as a copy of another ustring.
   * @param other A source string.
   */
  ustring(const ustring& other);

  /*! Construct a ustring by moving from another ustring.
   * @param other A source string.
   */
  ustring(ustring&& other);

  /*! Assign the value of another string by copying to this string.
   * @param other A source string.
   */
  ustring& operator=(const ustring& other);

  /*! Assign the value of another string by moving to this string.
   * @param other A source string.
   */
  ustring& operator=(ustring&& other);

  /*! Swap contents with another string.
   * @param other String to swap with.
   */
  void swap(ustring& other);

  /*! Construct a ustring as a copy of a std::string.
   * @param src A source <tt>std::string</tt> containing text encoded as UTF-8.
   */
  ustring(const std::string& src);

  /*! Construct a ustring by moving from a std::string.
   * @param src A source <tt>std::string</tt> containing text encoded as UTF-8.
   */
  ustring(std::string&& src);

  /*! Construct a ustring as a copy of a substring.
   * @param src %Source ustring.
   * @param i Index of first character to copy from.
   * @param n Number of UTF-8 characters to copy (defaults to copying the remainder).
   */
  ustring(const ustring& src, size_type i, size_type n = npos);

  /*! Construct a ustring as a partial copy of a C string.
   * @param src %Source C string encoded as UTF-8.
   * @param n Number of UTF-8 characters to copy.
   */
  ustring(const char* src, size_type n);

  /*! Construct a ustring as a copy of a C string.
   * @param src %Source C string encoded as UTF-8.
   */
  ustring(const char* src);

  /*! Construct a ustring as multiple characters.
   * @param n Number of characters.
   * @param uc UCS-4 code point to use.
   */
  ustring(size_type n, gunichar uc);

  /*! Construct a ustring as multiple characters.
   * @param n Number of characters.
   * @param c ASCII character to use.
   */
  ustring(size_type n, char c);

  /*! Construct a ustring as a copy of a range.
   * @param pbegin Start of range.
   * @param pend End of range.
   */
  template <class In>
  ustring(In pbegin, In pend);

  //! @name Assign new contents.
  //! @{

  ustring& operator=(const std::string& src);
  ustring& operator=(std::string&& src);
  ustring& operator=(const char* src);
  ustring& operator=(gunichar uc);
  ustring& operator=(char c);

  ustring& assign(const ustring& src);
  ustring& assign(ustring&& src);
  ustring& assign(const ustring& src, size_type i, size_type n);
  ustring& assign(const char* src, size_type n);
  ustring& assign(const char* src);
  ustring& assign(size_type n, gunichar uc);
  ustring& assign(size_type n, char c);
  template <class In>
  ustring& assign(In pbegin, In pend);

  //! @}
  //! @name Append to the string.
  //! @{

  ustring& operator+=(const ustring& src);
  ustring& operator+=(const char* src);
  ustring& operator+=(gunichar uc);
  ustring& operator+=(char c);
  void push_back(gunichar uc);
  void push_back(char c);

  ustring& append(const ustring& src);
  ustring& append(const ustring& src, size_type i, size_type n);
  ustring& append(const char* src, size_type n);
  ustring& append(const char* src);
  ustring& append(size_type n, gunichar uc);
  ustring& append(size_type n, char c);
  template <class In>
  ustring& append(In pbegin, In pend);

  //! @}
  //! @name Insert into the string.
  //! @{

  ustring& insert(size_type i, const ustring& src);
  ustring& insert(size_type i, const ustring& src, size_type i2, size_type n);
  ustring& insert(size_type i, const char* src, size_type n);
  ustring& insert(size_type i, const char* src);
  ustring& insert(size_type i, size_type n, gunichar uc);
  ustring& insert(size_type i, size_type n, char c);

  iterator insert(iterator p, gunichar uc);
  iterator insert(iterator p, char c);
  void insert(iterator p, size_type n, gunichar uc);
  void insert(iterator p, size_type n, char c);
  template <class In>
  void insert(iterator p, In pbegin, In pend);

  //! @}
  //! @name Replace sub-strings.
  //! @{

  ustring& replace(size_type i, size_type n, const ustring& src);
  ustring& replace(size_type i, size_type n, const ustring& src, size_type i2, size_type n2);
  ustring& replace(size_type i, size_type n, const char* src, size_type n2);
  ustring& replace(size_type i, size_type n, const char* src);
  ustring& replace(size_type i, size_type n, size_type n2, gunichar uc);
  ustring& replace(size_type i, size_type n, size_type n2, char c);

  ustring& replace(iterator pbegin, iterator pend, const ustring& src);
  ustring& replace(iterator pbegin, iterator pend, const char* src, size_type n);
  ustring& replace(iterator pbegin, iterator pend, const char* src);
  ustring& replace(iterator pbegin, iterator pend, size_type n, gunichar uc);
  ustring& replace(iterator pbegin, iterator pend, size_type n, char c);
  template <class In>
  ustring& replace(iterator pbegin, iterator pend, In pbegin2, In pend2);

  //! @}
  //! @name Erase sub-strings.
  //! @{

  void clear();
  ustring& erase(size_type i, size_type n = npos);
  ustring& erase();
  iterator erase(iterator p);
  iterator erase(iterator pbegin, iterator pend);

  //! @}
  //! @name Compare and collate.
  //! @{

  int compare(const ustring& rhs) const;
  int compare(const char* rhs) const;
  int compare(size_type i, size_type n, const ustring& rhs) const;
  int compare(size_type i, size_type n, const ustring& rhs, size_type i2, size_type n2) const;
  int compare(size_type i, size_type n, const char* rhs, size_type n2) const;
  int compare(size_type i, size_type n, const char* rhs) const;

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
  std::string collate_key() const;

  /*! Create a unique key for the UTF-8 string that can be used for caseless
   * sorting.  <tt>ustr.casefold_collate_key()</tt> results in the same string
   * as <tt>ustr.casefold().collate_key()</tt>, but the former is likely more
   * efficient.
   */
  std::string casefold_collate_key() const;

  //! @}
  //! @name Extract characters and sub-strings.
  //! @{

  /*! No reference return; use replace() to write characters. */
  value_type operator[](size_type i) const;

  /*! No reference return; use replace() to write characters. @throw std::out_of_range */
  value_type at(size_type i) const;

  inline ustring substr(size_type i = 0, size_type n = npos) const;

  //! @}
  //! @name Access a sequence of characters.
  //! @{

  iterator begin();
  iterator end();
  const_iterator begin() const;
  const_iterator end() const;
  reverse_iterator rbegin();
  reverse_iterator rend();
  const_reverse_iterator rbegin() const;
  const_reverse_iterator rend() const;

  //! @}
  //! @name Find sub-strings.
  //! @{

  size_type find(const ustring& str, size_type i = 0) const;
  size_type find(const char* str, size_type i, size_type n) const;
  size_type find(const char* str, size_type i = 0) const;
  size_type find(gunichar uc, size_type i = 0) const;
  size_type find(char c, size_type i = 0) const;

  size_type rfind(const ustring& str, size_type i = npos) const;
  size_type rfind(const char* str, size_type i, size_type n) const;
  size_type rfind(const char* str, size_type i = npos) const;
  size_type rfind(gunichar uc, size_type i = npos) const;
  size_type rfind(char c, size_type i = npos) const;

  //! @}
  //! @name Match against a set of characters.
  //! @{

  size_type find_first_of(const ustring& match, size_type i = 0) const;
  size_type find_first_of(const char* match, size_type i, size_type n) const;
  size_type find_first_of(const char* match, size_type i = 0) const;
  size_type find_first_of(gunichar uc, size_type i = 0) const;
  size_type find_first_of(char c, size_type i = 0) const;

  size_type find_last_of(const ustring& match, size_type i = npos) const;
  size_type find_last_of(const char* match, size_type i, size_type n) const;
  size_type find_last_of(const char* match, size_type i = npos) const;
  size_type find_last_of(gunichar uc, size_type i = npos) const;
  size_type find_last_of(char c, size_type i = npos) const;

  size_type find_first_not_of(const ustring& match, size_type i = 0) const;
  size_type find_first_not_of(const char* match, size_type i, size_type n) const;
  size_type find_first_not_of(const char* match, size_type i = 0) const;
  size_type find_first_not_of(gunichar uc, size_type i = 0) const;
  size_type find_first_not_of(char c, size_type i = 0) const;

  size_type find_last_not_of(const ustring& match, size_type i = npos) const;
  size_type find_last_not_of(const char* match, size_type i, size_type n) const;
  size_type find_last_not_of(const char* match, size_type i = npos) const;
  size_type find_last_not_of(gunichar uc, size_type i = npos) const;
  size_type find_last_not_of(char c, size_type i = npos) const;

  //! @}
  //! @name Retrieve the string's size.
  //! @{

  /** Returns true if the string is empty. Equivalent to *this == "".
   * @result Whether the string is empty.
   */
  bool empty() const;

  /** Returns the number of characters in the string, not including any null-termination.
   * @result The number of UTF-8 characters.
   *
   * @see bytes(), empty()
   */
  size_type size() const;

  // We have length() as well as size(), because std::string has both.

  /** This is the same as size().
   */
  size_type length() const;

  /** Returns the number of bytes in the string, not including any null-termination.
   * @result The number of bytes.
   *
   * @see size(), empty()
   */
  size_type bytes() const;

  //! @}
  //! @name Change the string's size.
  //! @{

  void resize(size_type n, gunichar uc);
  void resize(size_type n, char c = '\0');

  //! @}
  //! @name Control the allocated memory.
  //! @{

  size_type capacity() const;
  size_type max_size() const;
  void reserve(size_type n = 0);

  //! @}
  //! @name Get a per-byte representation of the string.
  //! @{

  inline operator std::string() const; // e.g. std::string str = ustring();
  inline const std::string& raw() const;

  // Not necessarily an ASCII char*. Use g_utf8_*() where necessary.
  const char* data() const;
  const char* c_str() const;

  /*! @return Number of copied @em bytes, not characters. */
  size_type copy(char* dest, size_type n, size_type i = 0) const;

  //! @}
  //! @name UTF-8 utilities.
  //! @{

  /*! Check whether the string is valid UTF-8. */
  bool validate() const;

  /*! Check whether the string is valid UTF-8. */
  bool validate(iterator& first_invalid);

  /*! Check whether the string is valid UTF-8. */
  bool validate(const_iterator& first_invalid) const;

  /*! Check whether the string is plain 7-bit ASCII. @par
   * Unlike any other ustring method, is_ascii() is safe to use on invalid
   * UTF-8 strings.  If the string isn't valid UTF-8, it cannot be valid
   * ASCII either, therefore is_ascii() will just return @c false then.
   * @return Whether the string contains only ASCII characters.
   */
  bool is_ascii() const;

  /*! "Normalize" the %Unicode character representation of the string. */
  ustring normalize(NormalizeMode mode = NORMALIZE_DEFAULT_COMPOSE) const;

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
  ustring uppercase() const;

  /*! Returns a new UTF-8 string with all characters characters converted to
   * their lowercase equivalent, while honoring the current locale.  The
   * resulting string may change in the number of bytes as well as in the
   * number of characters.
   */
  ustring lowercase() const;

  /*! Returns a caseless representation of the UTF-8 string.  The resulting
   * string doesn't correspond to any particular case, therefore the result
   * is only useful to compare strings and should never be displayed to the
   * user.
   */
  ustring casefold() const;

  //! @}
  //! @name Message formatting.
  //! @{

  /* Returns fmt as is, but checks for invalid references in the format string.
   * @newin{2,18}
   */
  template <class T1>
  static inline ustring compose(const ustring& fmt);

  /*! Substitute placeholders in a format string with the referenced arguments.
   * The template string should be in <tt>qt-format</tt>, that is
   * <tt>"%1"</tt>, <tt>"%2"</tt>, ..., <tt>"%9"</tt> are used as placeholders
   * and <tt>"%%"</tt> denotes a literal <tt>"%"</tt>.  Substitutions may be
   * reordered.
   * @par Example:
   * @code
   * using Glib::ustring;
   * const int percentage = 50;
   * const ustring text = ustring::compose("%1%% done", percentage);
   * @endcode
   * @param fmt A template string in <tt>qt-format</tt>.
   * @param a1 The argument to substitute for <tt>"%1"</tt>.
   * @return The substituted message string.
   * @throw Glib::ConvertError
   *
   * @newin{2,16}
   */
  template <class T1>
  static inline ustring compose(const ustring& fmt, const T1& a1);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4>
  static inline ustring compose(
    const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5>
  static inline ustring compose(
    const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3,
    const T4& a4, const T5& a5, const T6& a6);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6, class T7>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3,
    const T4& a4, const T5& a5, const T6& a6, const T7& a7);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3,
    const T4& a4, const T5& a5, const T6& a6, const T7& a7, const T8& a8);

  /* See the documentation for compose(const ustring& fmt, const T1& a1).
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8,
    class T9>
  static inline ustring compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3,
    const T4& a4, const T5& a5, const T6& a6, const T7& a7, const T8& a8, const T9& a9);

  /*! Format the argument to its string representation.
   * Applies the arguments in order to an std::wostringstream and returns the
   * resulting string.  I/O manipulators may also be used as arguments.  This
   * greatly simplifies the common task of converting a number to a string, as
   * demonstrated by the example below.  The format() methods can also be used
   * in conjunction with compose() to facilitate localization of user-visible
   * messages.
   * @code
   * using Glib::ustring;
   * double value = 22.0 / 7.0;
   * ustring text = ustring::format(std::fixed, std::setprecision(2), value);
   * @endcode
   * @note The use of a wide character stream in the implementation of format()
   * is almost completely transparent.  However, one of the instances where the
   * use of wide streams becomes visible is when the std::setfill() stream
   * manipulator is used.  In order for std::setfill() to work the argument
   * must be of type <tt>wchar_t</tt>.  This can be achieved by using the
   * <tt>L</tt> prefix with a character literal, as shown in the example.
   * @code
   * using Glib::ustring;
   * // Insert leading zeroes to fill in at least six digits
   * ustring text = ustring::format(std::setfill(L'0'), std::setw(6), 123);
   * @endcode
   *
   * @param a1 A streamable value or an I/O manipulator.
   * @return The string representation of the argument stream.
   * @throw Glib::ConvertError
   *
   * @newin{2,16}
   */
  template <class T1>
  static inline ustring format(const T1& a1);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2>
  static inline ustring format(const T1& a1, const T2& a2);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3>
  static inline ustring format(const T1& a1, const T2& a2, const T3& a3);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4>
  static inline ustring format(const T1& a1, const T2& a2, const T3& a3, const T4& a4);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5>
  static inline ustring format(
    const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6>
  static inline ustring format(
    const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5, const T6& a6);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6, class T7>
  static inline ustring format(const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5,
    const T6& a6, const T7& a7);

  /* See the documentation for format(const T1& a1).
   *
   * @newin{2,16}
   */
  template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8>
  static inline ustring format(const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5,
    const T6& a6, const T7& a7, const T8& a8);
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
  class FormatStream;

  static ustring compose_argv(const ustring& fmt, int argc, const ustring* const* argv);

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
  SequenceToString(Glib::ustring::iterator pbegin, Glib::ustring::iterator pend);
};

template <>
struct ustring::SequenceToString<Glib::ustring::const_iterator, gunichar> : public std::string
{
  SequenceToString(Glib::ustring::const_iterator pbegin, Glib::ustring::const_iterator pend);
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
  FormatStream();
  ~FormatStream() noexcept;

  template <class T>
  inline void stream(const T& value);

  inline void stream(const char* value);

  // This overload exists to avoid the templated stream() being called for non-const char*.
  inline void stream(char* value);

  ustring to_string() const;
};

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** Stream input operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
std::istream& operator>>(std::istream& is, Glib::ustring& utf8_string);

/** Stream output operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
std::ostream& operator<<(std::ostream& os, const Glib::ustring& utf8_string);

#ifdef GLIBMM_HAVE_WIDE_STREAM

/** Wide stream input operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
std::wistream& operator>>(std::wistream& is, ustring& utf8_string);

/** Wide stream output operator.
 * @relates Glib::ustring
 * @throw Glib::ConvertError
 */
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
    ;
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
  string_.insert(p.base(), Glib::ustring::SequenceToString<In>(pbegin, pend));
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

inline ustring::operator std::string() const
{
  return string_;
}

inline const std::string&
ustring::raw() const
{
  return string_;
}

template <class T1>
inline // static
  ustring
  ustring::format(const T1& a1)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  return buf.to_string();
}

template <class T1, class T2>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  return buf.to_string();
}

template <class T1, class T2, class T3>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2, const T3& a3)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  return buf.to_string();
}

template <class T1, class T2, class T3, class T4>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2, const T3& a3, const T4& a4)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  buf.stream(a4);
  return buf.to_string();
}

template <class T1, class T2, class T3, class T4, class T5>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  buf.stream(a4);
  buf.stream(a5);
  return buf.to_string();
}

template <class T1, class T2, class T3, class T4, class T5, class T6>
inline // static
  ustring
  ustring::format(
    const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5, const T6& a6)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  buf.stream(a4);
  buf.stream(a5);
  buf.stream(a6);
  return buf.to_string();
}

template <class T1, class T2, class T3, class T4, class T5, class T6, class T7>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5,
    const T6& a6, const T7& a7)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  buf.stream(a4);
  buf.stream(a5);
  buf.stream(a6);
  buf.stream(a7);
  return buf.to_string();
}

template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8>
inline // static
  ustring
  ustring::format(const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5,
    const T6& a6, const T7& a7, const T8& a8)
{
  ustring::FormatStream buf;
  buf.stream(a1);
  buf.stream(a2);
  buf.stream(a3);
  buf.stream(a4);
  buf.stream(a5);
  buf.stream(a6);
  buf.stream(a7);
  buf.stream(a8);
  return buf.to_string();
}

/** An inner class used by ustring.
 */
template <class T>
class ustring::Stringify
{
private:
  ustring string_;

public:
  explicit inline Stringify(const T& arg) : string_(ustring::format(arg)) {}

  // TODO: Why is this here? See the template specialization:
  explicit inline Stringify(const char* arg) : string_(arg) {}

  // noncopyable
  Stringify(const ustring::Stringify<T>&) = delete;
  Stringify<T>& operator=(const ustring::Stringify<T>&) = delete;

  inline const ustring* ptr() const { return &string_; }
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

  inline const ustring* ptr() const { return &string_; }
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

  inline const ustring* ptr() const { return &string_; }
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

  inline const ustring* ptr() const { return &string_; }
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

  inline const ustring* ptr() const { return &string_; }
};

template <class T1>
inline // static
  ustring
  ustring::compose(const ustring& fmt)
{
  return ustring::compose_argv(fmt, 0, nullptr);
}

template <class T1>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1)
{
  const ustring::Stringify<T1> s1(a1);

  const ustring* const argv[] = { s1.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);

  const ustring* const argv[] = { s1.ptr(), s2.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4, class T5>
inline // static
  ustring
  ustring::compose(
    const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4, const T5& a5)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);
  const ustring::Stringify<T5> s5(a5);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr(), s5.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4, class T5, class T6>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4,
    const T5& a5, const T6& a6)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);
  const ustring::Stringify<T5> s5(a5);
  const ustring::Stringify<T6> s6(a6);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr(), s5.ptr(), s6.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4, class T5, class T6, class T7>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4,
    const T5& a5, const T6& a6, const T7& a7)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);
  const ustring::Stringify<T5> s5(a5);
  const ustring::Stringify<T6> s6(a6);
  const ustring::Stringify<T7> s7(a7);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr(), s5.ptr(), s6.ptr(),
    s7.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4,
    const T5& a5, const T6& a6, const T7& a7, const T8& a8)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);
  const ustring::Stringify<T5> s5(a5);
  const ustring::Stringify<T6> s6(a6);
  const ustring::Stringify<T7> s7(a7);
  const ustring::Stringify<T8> s8(a8);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr(), s5.ptr(), s6.ptr(),
    s7.ptr(), s8.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

template <class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8, class T9>
inline // static
  ustring
  ustring::compose(const ustring& fmt, const T1& a1, const T2& a2, const T3& a3, const T4& a4,
    const T5& a5, const T6& a6, const T7& a7, const T8& a8, const T9& a9)
{
  const ustring::Stringify<T1> s1(a1);
  const ustring::Stringify<T2> s2(a2);
  const ustring::Stringify<T3> s3(a3);
  const ustring::Stringify<T4> s4(a4);
  const ustring::Stringify<T5> s5(a5);
  const ustring::Stringify<T6> s6(a6);
  const ustring::Stringify<T7> s7(a7);
  const ustring::Stringify<T8> s8(a8);
  const ustring::Stringify<T9> s9(a9);

  const ustring* const argv[] = { s1.ptr(), s2.ptr(), s3.ptr(), s4.ptr(), s5.ptr(), s6.ptr(),
    s7.ptr(), s8.ptr(), s9.ptr() };
  return ustring::compose_argv(fmt, G_N_ELEMENTS(argv), argv);
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** @relates Glib::ustring */
inline void
swap(ustring& lhs, ustring& rhs)
{
  lhs.swap(rhs);
}

/**** Glib::ustring -- comparison operators ********************************/

/** @relates Glib::ustring */
inline bool
operator==(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) == 0);
}

/** @relates Glib::ustring */
inline bool
operator==(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) == 0);
}

/** @relates Glib::ustring */
inline bool
operator==(const char* lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) == 0);
}

/** @relates Glib::ustring */
inline bool
operator!=(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) != 0);
}

/** @relates Glib::ustring */
inline bool
operator!=(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) != 0);
}

/** @relates Glib::ustring */
inline bool
operator!=(const char* lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) != 0);
}

/** @relates Glib::ustring */
inline bool
operator<(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) < 0);
}

/** @relates Glib::ustring */
inline bool
operator<(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) < 0);
}

/** @relates Glib::ustring */
inline bool
operator<(const char* lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) > 0);
}

/** @relates Glib::ustring */
inline bool
operator>(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) > 0);
}

/** @relates Glib::ustring */
inline bool
operator>(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) > 0);
}

/** @relates Glib::ustring */
inline bool
operator>(const char* lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) < 0);
}

/** @relates Glib::ustring */
inline bool
operator<=(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) <= 0);
}

/** @relates Glib::ustring */
inline bool
operator<=(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) <= 0);
}

/** @relates Glib::ustring */
inline bool
operator<=(const char* lhs, const ustring& rhs)
{
  return (rhs.compare(lhs) >= 0);
}

/** @relates Glib::ustring */
inline bool
operator>=(const ustring& lhs, const ustring& rhs)
{
  return (lhs.compare(rhs) >= 0);
}

/** @relates Glib::ustring */
inline bool
operator>=(const ustring& lhs, const char* rhs)
{
  return (lhs.compare(rhs) >= 0);
}

/** @relates Glib::ustring */
inline bool
operator>=(const char* lhs, const ustring& rhs)
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

} // namespace Glib

#endif /* _GLIBMM_USTRING_H */
