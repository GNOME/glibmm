#include <giomm.h>
#include <iostream>
#include <string.h>

int main(int, char**)
{
  Glib::init();
  Gio::init();

  try
  {
    Glib::RefPtr<Gio::File> file = Gio::File::create_for_path("/etc/fstab");
    if(!file)
    {
      std::cerr << "Gio::File::create_for_path() returned an empty RefPtr." << std::endl;
      return EXIT_FAILURE; 
    }

    Glib::RefPtr<Gio::FileInputStream> stream = file->read();
    if(!stream)
    {
      std::cerr << "Gio::File::read() returned an empty RefPtr." << std::endl;
      return EXIT_FAILURE; 
    }

    gchar buffer[1000]; //TODO: This is unpleasant.
    memset(buffer, 0, sizeof buffer);
    const gsize bytes_read = stream->read(buffer, sizeof buffer - 1);

    if(bytes_read)
      std::cout << "File contents read: " << buffer << std::endl;
    else
    {
      std::cerr << "Gio::InputStream::read() read 0 bytes." << std::endl;
      return EXIT_FAILURE; 
    }
  }
  catch(const Glib::Exception& ex)
  {
    std::cerr << "Exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE; 
  }

  return EXIT_SUCCESS;
}

