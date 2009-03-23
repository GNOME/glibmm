#include <giomm.h>
#include <iostream>
#include <string.h>

int main(int, char**)
{
  Glib::init();
  Gio::init();

#ifdef GLIBMM_EXCEPTIONS_ENABLED
  try
  {
    Glib::RefPtr<Gio::File> file = Gio::File::create_for_path("/etc/fstab");
    if(!file)
      std::cerr << "Gio::File::create_for_path() returned an empty RefPtr." << std::endl;

    Glib::RefPtr<Gio::FileInputStream> stream = file->read();
    if(!stream)
      std::cerr << "Gio::File::read() returned an empty RefPtr." << std::endl;

    gchar buffer[1000]; //TODO: This is unpleasant.
    memset(buffer, 0, sizeof buffer);
    const gsize bytes_read = stream->read(buffer, sizeof buffer - 1);

    if(bytes_read)
      std::cout << "File contents read: " << buffer << std::endl;
    else
      std::cerr << "Gio::InputStream::read() read 0 bytes." << std::endl;
  }
  catch(const Glib::Exception& ex)
  {
    std::cerr << "Exception caught: " << ex.what() << std::endl; 
  }
#else /* !GLIBMM_EXCEPTIONS_ENABLED */
  Glib::RefPtr<Gio::File> file = Gio::File::create_for_path("/home/murrayc/test.txt");
  if(!file)
    std::cerr << "Gio::File::create_for_path() returned an empty RefPtr." << std::endl;

  std::auto_ptr<Glib::Error> error;

  Glib::RefPtr<Gio::FileInputStream> stream = file->read(error);
  if(!stream)
    std::cerr << "Gio::File::read() returned an empty RefPtr." << std::endl;
  if(error.get())
  {
    std::cerr << "Exception caught: " << error->what() << std::endl;
    return 1;
  }
  gchar buffer[1000]; //TODO: This is unpleasant.
  memset(buffer, 0, sizeof buffer);
  const gsize bytes_read = stream->read(buffer, sizeof buffer - 1, error);

  if(bytes_read)
    std::cout << "File contents read: " << buffer << std::endl;
  else
    std::cerr << "Gio::InputStream::read() read 0 bytes." << std::endl;

  if(error.get())
  {
    std::cerr << "Exception caught: " << error->what() << std::endl;
    return 1;
  }
#endif /* !GLIBMM_EXCEPTIONS_ENABLED */

  return 0;
}

