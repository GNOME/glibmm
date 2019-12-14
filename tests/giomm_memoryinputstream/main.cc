#include <cstdlib>
#include <cstring>
#include <giomm.h>
#include <iostream>
#include <sstream>
#include <string>

namespace
{
// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::ostringstream debug;
std::ostream& ostr = debug;

std::string func1_output;
std::string func2_output;

void
destroy_func1(void* data)
{
  char* cdata = static_cast<char*>(data);
  func1_output += "Deleting ";
  func1_output += cdata;
  delete[] cdata;
}

void
destroy_func2(void* data, const std::string& intro)
{
  char* cdata = static_cast<char*>(data);
  func2_output += intro + cdata;
  delete[] cdata;
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();
  Gio::init();

  gchar buffer[1000];
  std::memset(buffer, 0, sizeof buffer);
  try
  {
    auto stream = Gio::MemoryInputStream::create();
    if (!stream)
    {
      std::cerr << "Could not create a MemoryInputStream." << std::endl;
      return EXIT_FAILURE;
    }

    // Add data that shall not be deleted by stream.
    static const char data1[] = "Data not owned by stream.\n";
    stream->add_data(data1, sizeof data1 - 1, nullptr);

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
  catch (const Glib::Error& ex)
  {
    std::cerr << "Exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }

  ostr << func1_output << std::endl;
  ostr << func2_output << std::endl;

  if (std::strcmp(buffer, "Data not owned by stream.\ndata2\ndata3\n") == 0 &&
      func1_output == "Deleting data2\n" && func2_output == "Now deleting data3\n")
    return EXIT_SUCCESS;

  std::cerr << "buffer: \"" << buffer << "\"" << std::endl;
  std::cerr << "func1_output: \"" << func1_output << "\"" << std::endl;
  std::cerr << "func2_output: \"" << func2_output << "\"" << std::endl;
  return EXIT_FAILURE;
}
