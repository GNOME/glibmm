// Some libraries define HOST_NOT_FOUND.  Make sure we can still compile fine
// even if this is the case:
#define HOST_NOT_FOUND 1

#include <giomm.h>
#include <iostream>
#include <string.h>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

// This is just to test a workaround in the error.h header.  We save and #undef
// HOST_NOT_FOUND if it was defined by another header, and then restore it at
// the end of the header.  Here I'm just making sure that our temporary value
// doesn't remain set
#ifdef GIOMM_SAVED_HOST_NOT_FOUND
#error Forgot to #undef GIOMM_SAVED_HOST_NOT_FOUND
#endif

#ifdef G_OS_WIN32
#define TEST_FILE "c:/windows/notepad.exe"
#else
#define TEST_FILE "/etc/passwd"
#endif

int
main(int, char**)
{
  Glib::init();
  Gio::init();

  try
  {
    auto file = Gio::File::create_for_path(TEST_FILE);
    if (!file)
    {
      std::cerr << "Gio::File::create_for_path() returned an empty RefPtr." << std::endl;
      return EXIT_FAILURE;
    }

    auto stream = file->read();
    if (!stream)
    {
      std::cerr << "Gio::File::read() returned an empty RefPtr." << std::endl;
      return EXIT_FAILURE;
    }

    gchar buffer[1000]; // TODO: This is unpleasant.
    memset(buffer, 0, sizeof buffer);
    const gsize bytes_read = stream->read(buffer, sizeof buffer - 1);

    if (bytes_read)
      ostr << "File contents read: " << buffer << std::endl;
    else
    {
      std::cerr << "Gio::InputStream::read() read 0 bytes." << std::endl;
      return EXIT_FAILURE;
    }
  }
  catch (const Gio::Error& ex)
  {
    // This is just here to check that HOST_WAS_NOT_FOUND is still in our API,
    // because we hack it into our gio_enums.defs file and there is a risk of
    // losing it when we regenerate that file. murrayc.
    if (ex.code() == Gio::Error::HOST_WAS_NOT_FOUND)
    {
      std::cerr << "Host was not found." << std::endl;
    }
    else
      std::cerr << "Gio::Error exception caught: " << ex.what() << std::endl;
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Glib::Error exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
