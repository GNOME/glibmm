#include <glibmm.h>
#include <iostream>
#include <string.h>
#include <vector>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

#define DIR "/dir1/dir_2/dir-3"
#define FILE "dir/file.ext"

int
main(int, char**)
{
  gchar* dir_1 = g_strdup(DIR);
  std::string dir_2(DIR);
  Glib::ustring dir_3(DIR);
  gchar* file_1 = g_strdup(FILE);
  std::string file_2(FILE);
  Glib::ustring file_3(FILE);

  std::string path;

  path = Glib::build_filename(dir_1, file_3);
  ostr << "Path 1: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, FILE);
  ostr << "Path 2: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_3, FILE);
  ostr << "Path 3: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_3, file_1);
  ostr << "Path 4: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_1, dir_3, dir_2, dir_3, dir_1, dir_2, file_2);
  ostr << "Path 5: " << path << std::endl;

  path = Glib::build_filename(dir_2, file_2);
  ostr << "Path 6: " << path << std::endl;

  path = Glib::build_filename(dir_2, file_3);
  ostr << "Path 7: " << path << std::endl;

  path = Glib::build_filename(dir_3, file_3);
  ostr << "Path 8: " << path << std::endl;

  path = Glib::build_filename(dir_1);
  ostr << "Path 9: " << path << std::endl;

  path = Glib::build_filename(nullptr);
  ostr << "Path 10: " << path << std::endl;

  std::vector<std::string> pathv;
  pathv.push_back("vdir1");
  path = Glib::build_filename(pathv);
  ostr << "Path v1: " << path << std::endl;

  pathv.push_back("vdir2");
  path = Glib::build_filename(pathv);
  ostr << "Path v2: " << path << std::endl;

  return EXIT_SUCCESS;
}
