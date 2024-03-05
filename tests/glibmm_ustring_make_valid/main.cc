#include <iostream>
#include <glibmm.h>

int
main()
{
  Glib::init();

    //                        0-1: bad character
  const char not_utf8[] = { '\x80',
    //                        1-4: good three bytes (one character)
    '\xef', '\x80', '\x80',
    //                        4-5: bad character
    '\xef',
    //                        5-6: bad character
    '\x80',
    //                        6-7: good character
    'a',
    //                        7-8: bad character
    '\0',
    //                        8-9: good character
    'd',
    //                        9-10: bad character
    '\x80',
    //                        10-13: good three bytes (one character)
    '\xef', '\x80', '\x80',
    //                        13-15: two bad characters
    '\xef', '\x80'
  };

  const char fixed_utf8[] = { '\xef', '\xbf', '\xbd',
    '\xef', '\x80', '\x80',
    '\xef', '\xbf', '\xbd',
    '\xef', '\xbf', '\xbd',
    'a',
    '\xef', '\xbf', '\xbd',
    'd',
    '\xef', '\xbf', '\xbd',
    '\xef', '\x80', '\x80',
    '\xef', '\xbf', '\xbd',
    '\xef', '\xbf', '\xbd'
  };

  // const char repl_character[] = {'\xef', '\xbf', '\xbd'};
  const Glib::ustring s(not_utf8, not_utf8 + sizeof not_utf8);
  g_assert(s.validate() == false);

  const Glib::ustring good_one = s.make_valid();
  g_assert(s.validate() == false); // we make a copy
  g_assert(good_one.validate());   // this one is good!

  const Glib::ustring correct_output(fixed_utf8,
      fixed_utf8 + sizeof fixed_utf8);
  g_assert(correct_output.validate());
  g_assert(correct_output == good_one);

  // A simple test of Glib::wide_from/to_utf8().
  Glib::ustring tobewide = "ABC åäöěèéêß";
  std::wstring wide = Glib::wide_from_utf8(tobewide);
  Glib::ustring waswide = Glib::wide_to_utf8(wide);
  g_assert(tobewide == waswide);
  /*
  // Can't use both std::cout and std::wcout.
  // The output is distorted, even though it's okay when only
  // one of std::cout and std::wcout is used.
  std::cout  << "waswide=\"" << waswide << "\", " << waswide.size()
    << " characters, " << waswide.bytes() << " bytes\n";
  std::wcout << "wide=   \"" << wide    << "\", " <<    wide.size()
    << " characters, " << wide.size() * sizeof(std::wstring::value_type) << " bytes\n";
  */
  return EXIT_SUCCESS;
}
