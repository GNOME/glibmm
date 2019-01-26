#include <giomm.h>
#include <iostream>

const std::string FILENAME = "strings.txt";

int main (int argc, char** argv)
{
  Gio::init();
  Glib::RefPtr<Gio::File> file = Gio::File::create_for_path (FILENAME);
  g_assert (file);
  Glib::RefPtr<Gio::OutputStream> stream = file->replace ();
  g_assert (stream);
  stream << "Test string for << operator" << Gio::endl;
  Glib::RefPtr<Gio::InputStream> stream = file->replace ();
  g_assert (stream);
  stream << "Test string for >> operator" << Gio::endl;
  stream->close ();
  std::cout << "Wrote and Read file '" << FILENAME << "'" << std::endl;
  return 0;
}
