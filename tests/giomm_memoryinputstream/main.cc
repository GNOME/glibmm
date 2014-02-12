#include <giomm.h>
#include <iostream>
#include <cstring>

//Use this line if you want debug output:
//std::ostream& ostr = std::cout;

//This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

namespace
{
  int n_called1 = 0;
  int n_called2 = 0;

  void destroy_func1(void* data)
  {
    ++n_called1;
    char* cdata = static_cast<char*>(data);
    // cdata is not null-terminated.
    ostr << "Deleting " << std::string(cdata, cdata+6);
    delete[] cdata;
  }

  void destroy_func2(void* data, const Glib::ustring& intro)
  {
    ++n_called2;
    char* cdata = static_cast<char*>(data);
    // cdata is not null-terminated.
    ostr << intro << std::string(cdata, cdata+6);
    delete[] cdata;
  }
}

int main(int, char**)
{
  Glib::init();
  Gio::init();

  gchar buffer[1000];
  std::memset(buffer, 0, sizeof buffer);
  try
  {
    Glib::RefPtr<Gio::MemoryInputStream> stream = Gio::MemoryInputStream::create();
    if (!stream)
    {
      std::cerr << "Could not create a MemoryInputStream." << std::endl;
      return EXIT_FAILURE; 
    }

    // Add data that shall not be deleted by stream.
    static const char data1[] = "Data not owned by stream.\n";
    stream->add_data(data1, sizeof data1 - 1, 0);

    // Add data that shall be deleted by destroy_func1().
    char* data2 = new char[7];
    std::strcpy(data2, "data2\n");
    stream->add_data(data2, 6, destroy_func1);

    // Add data that shall be deleted by destroy_func2().
    char* data3 = new char[7];
    std::strcpy(data3, "data3\n");
    stream->add_data(data3, 6, sigc::bind(sigc::ptr_fun(destroy_func2), "Now deleting "));

    const gsize bytes_read = stream->read(buffer, sizeof buffer - 1);

    if (bytes_read)
      ostr << "Memory contents read: " << buffer << std::endl;
    else
    {
      std::cerr << "Gio::InputStream::read() read 0 bytes." << std::endl;
      return EXIT_FAILURE; 
    }
  }
  catch (const Glib::Exception& ex)
  {
    std::cerr << "Exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE; 
  }

  if (std::strcmp(buffer, "Data not owned by stream.\ndata2\ndata3\n") == 0 &&
      n_called1 == 1 && n_called2 == 1)
    return EXIT_SUCCESS;
  return EXIT_FAILURE; 
}
