#include <glibmm.h>
#include <iostream>
#include <string.h>

#define DIR "/dir1/dir_2/dir-3"
#define FILE "dir/file.ext"

int main(int, char**)
{
  gchar* dir_1 = g_strdup(DIR);
  std::string dir_2(DIR);
  Glib::ustring dir_3(DIR);
  gchar* file_1 = g_strdup(FILE);
  std::string file_2(FILE);
  Glib::ustring file_3(FILE);

  std::string path;

  path = Glib::build_filename(dir_1, file_3);
  std::cout << "Path 1: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, FILE);
  std::cout << "Path 2: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_3, FILE);
  std::cout << "Path 3: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_3, file_1);
  std::cout << "Path 4: " << path << std::endl;

  path = Glib::build_filename(dir_1, dir_2, dir_1, dir_3, dir_2, dir_3,
    dir_1, dir_2, file_2);
  std::cout << "Path 5: " << path << std::endl;

  return 0;
}

