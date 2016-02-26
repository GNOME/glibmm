#include <glibmm.h>
#include <iostream>
#include <string>

int
main()
{
  std::string glib_base64 = "R2xpYg==";
  std::string glibmm_base64 = "R2xpYm1t";
  std::string stallman_quote_base64 =
    "VmFsdWUgeW91ciBmcmVlZG9tIG9yIHlvdSB3aWxsIGxvc2UgaXQsIHRlYWNoZXMgaGlzdG9yeS4K\n"
    "J0Rvbid0IGJvdGhlciB1cyB3aXRoIHBvbGl0aWNzJywgcmVzcG9uZCB0aG9zZSB3aG8gZG9uJ3Qg\n"
    "d2FudCB0byBsZWFybi4KCi0tIFJpY2hhcmQgU3RhbGxtYW4=\n";

  // test that encodes the string "Glib" into base64
  std::cerr << Glib::Base64::encode("Glib") << std::endl;
  g_assert(Glib::Base64::encode("Glib") == glib_base64);

  // test that encodes the quote by Richard Stallman into base64 with linebreaks (the output has
  // line breaks)
  std::cerr << Glib::Base64::encode("Value your freedom or you will lose it, teaches history.\n"
                                    "'Don't bother us with politics', respond those who don't want "
                                    "to learn.\n\n-- Richard Stallman",
                 true)
            << std::endl;
  std::cerr << stallman_quote_base64 << std::endl;
  g_assert(Glib::Base64::encode("Value your freedom or you will lose it, teaches history.\n"
                                "'Don't bother us with politics', respond those who don't want to "
                                "learn.\n\n-- Richard Stallman",
             true) == stallman_quote_base64);

  // test that decodes the string "Glibmm" from base64
  std::cerr << Glib::Base64::decode(glibmm_base64) << std::endl;
  g_assert(Glib::Base64::decode(glibmm_base64) == "Glibmm");

  return EXIT_SUCCESS;
}
