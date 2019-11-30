#include <glibmm.h>

#include <iostream>

// Helper class to check for non-existing overload
template<typename T>
struct Convertible
{
  Convertible(const T&){};
};

static bool expect_missing_overload = false;

void
operator==(Convertible<std::string> const&, Glib::ustring const&)
{
  g_assert_true(expect_missing_overload);
  expect_missing_overload = false;
}

int
main(int, char**)
{
  // allocating
  static_assert(std::is_convertible<const char*, Glib::ustring>::value, "");
  // non-allocating
  static_assert(std::is_convertible<const char*, Glib::UStringView>::value, "");
  static_assert(std::is_convertible<Glib::ustring, Glib::UStringView>::value, "");
  // deliberately omitted
  static_assert(!std::is_convertible<Glib::UStringView, Glib::ustring>::value, "");
  static_assert(!std::is_convertible<Glib::UStringView, const char *>::value, "");

  const char *cstr1 = "Hello";
  const char *cstr2 = "World";
  const char *cstr12 = "HelloWorld";
  const char *cstr12_25 = "lloWo"; // cstr12[2:2 + 5]

  Glib::ustring ustr1 = cstr1;
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

  std::string sstr1 = cstr1;

  // Would not compile without the helper overload
  expect_missing_overload = true;
  sstr1 == ustr1;
  g_assert_false(expect_missing_overload);

  // Doesn't compile because of missing Glib::ustring::compare overload (expected), but
  // unfortunately not testable like the other way round.
#if 0
  ustr1 == sstr1;
#endif

  return EXIT_SUCCESS;
}
