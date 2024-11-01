#include <glibmm.h>

int
main(int, char**)
{
  const char *cstr1 = "Hello";
  Glib::ustring ustr1 = cstr1;

#ifndef GLIBMM_TEST_THAT_COMPILATION_FAILS
  // allocating
  static_assert(std::is_convertible<const char*, Glib::ustring>::value, "");
  // non-allocating
  static_assert(std::is_convertible<const char*, Glib::UStringView>::value, "");
  static_assert(std::is_convertible<Glib::ustring, Glib::UStringView>::value, "");
  // deliberately omitted
  static_assert(!std::is_convertible<Glib::UStringView, Glib::ustring>::value, "");
  static_assert(!std::is_convertible<Glib::UStringView, const char *>::value, "");

  const char *cstr2 = "World";
  const char *cstr12 = "HelloWorld";
  const char *cstr12_25 = "lloWo"; // cstr12[2:2 + 5]

  Glib::ustring ustr2 = cstr2;
  Glib::ustring ustr12 = cstr12;
  Glib::ustring ustr12_25 = cstr12_25;

  Glib::UStringView vstr1 = cstr1;
  Glib::UStringView vstr2 = cstr2;
  Glib::UStringView vstr12_25 = cstr12_25;

  g_assert_true(ustr1.compare(ustr1) == 0);
  g_assert_true(ustr1.compare(cstr1) == 0);
  g_assert_true(ustr1.compare(vstr1) == 0);

  g_assert_true(ustr1.compare(ustr2) < 0);
  g_assert_true(ustr1.compare(cstr2) < 0);
  g_assert_true(ustr1.compare(vstr2) < 0);

  g_assert_true(ustr12.compare(2, 5, ustr12_25) == 0);
  g_assert_true(ustr12.compare(2, 5, cstr12_25) == 0);
  g_assert_true(ustr12.compare(2, 5, vstr12_25) == 0);

  g_assert_true(ustr1 == ustr1);
  g_assert_true(ustr1 == cstr1);
  g_assert_true(ustr1 == vstr1);
  g_assert_true(cstr1 == ustr1);
  g_assert_true(vstr1 == ustr1);

  g_assert_true(ustr2 != ustr1);
  g_assert_true(ustr2 != cstr1);
  g_assert_true(ustr2 != vstr1);
  g_assert_true(cstr2 != ustr1);
  g_assert_true(vstr2 != ustr1);

  g_assert_true(ustr2 > ustr1);
  g_assert_true(ustr2 > cstr1);
  g_assert_true(ustr2 > vstr1);
  g_assert_true(cstr2 > ustr1);
  g_assert_true(vstr2 > ustr1);

  g_assert_false(ustr2 < ustr1);
  g_assert_false(ustr2 < cstr1);
  g_assert_false(ustr2 < vstr1);
  g_assert_false(cstr2 < ustr1);
  g_assert_false(vstr2 < ustr1);

  g_assert_true(ustr2 >= ustr1);
  g_assert_true(ustr2 >= cstr1);
  g_assert_true(ustr2 >= vstr1);
  g_assert_true(cstr2 >= ustr1);
  g_assert_true(vstr2 >= ustr1);

  g_assert_false(ustr2 <= ustr1);
  g_assert_false(ustr2 <= cstr1);
  g_assert_false(ustr2 <= vstr1);
  g_assert_false(cstr2 <= ustr1);
  g_assert_false(vstr2 <= ustr1);

  // no conversions between std::string and UStringView and no comparison between
  // std::string and ustring/UStringView

  static_assert(!std::is_convertible<std::string, Glib::UStringView>::value, "");
  static_assert(!std::is_convertible<Glib::UStringView, std::string>::value, "");

#else // GLIBMM_TEST_THAT_COMPILATION_FAILS

  // It's now possible to compare Glib::ustring with std::string.
  // See https://gitlab.gnome.org/GNOME/glibmm/-/issues/121

  // By design some combinations of std::string and Glib::ustring are not allowed.
  // Copied from ustring.h: Using the wrong string class shall not be as easy as
  // using the right string class.

  std::string sstr1 = cstr1;

#if GLIBMM_TEST_THAT_COMPILATION_FAILS == 1
  sstr1 == ustr1; // Shall not compile
#else
  ustr1 == sstr1; // Shall not compile
#endif
#endif

  return EXIT_SUCCESS;
}
