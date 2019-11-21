#include <glibmm/regex.h>

static void
test_match_string_literal()
{
  auto regex = Glib::Regex::create("(\\S+)");
  Glib::MatchInfo matchInfo;

  regex->match("this is not a Glib::ustring const reference", matchInfo);

  for (const char* s : { "this", "is", "not", "a", "Glib::ustring", "const", "reference" })
  {
    g_assert_true(matchInfo.matches());
    g_assert_true(matchInfo.fetch(1) == s);
    matchInfo.next();
  }

  g_assert_false(matchInfo.matches());
}

int
main()
{
  // https://gitlab.gnome.org/GNOME/glibmm/issues/66
  test_match_string_literal();

  return EXIT_SUCCESS;
}
