#include <glibmm.h>

#include <iostream>

int main(int, char**)
{
  Glib::init();

  char carr[10] = "Užduotys";
  char * const cptr = carr;

  /*
  std::wostringstream wsout;
  wsout << carr;
  const std::wstring& wstr = wsout.str();
  const gunichar * const data = reinterpret_cast<const gunichar *>(
                                  wstr.data());

  for(int i = 0; wstr.size() > i; ++i)
    std::cout << data[i] << std::endl;
  */

  //Check both the const char* and char* versions.
  Glib::ustring::format(carr);

  //This threw an exception before we added a ustring::FormatStream::stream(char*) overload.
  Glib::ustring::format(cptr);

  return EXIT_SUCCESS;
}
