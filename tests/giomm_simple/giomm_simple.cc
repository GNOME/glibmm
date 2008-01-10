#include <giomm.h>
#include <iostream>


int main(int argc, char** argv)
{
  Glib::init();
  Gio::init();
   
  Glib::RefPtr<Gio::File> file = Gio::File::create_for_path("/home/murrayc/test.txt");
 
  return 0;
}

