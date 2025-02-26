#include <giomm.h>
#include <iostream>
#include <cstring>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

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

    char buffer[1000]; // TODO: This is unpleasant.
    std::memset(buffer, 0, sizeof buffer);
    const gssize bytes_read = stream->read(buffer, sizeof buffer - 1);

    if (bytes_read)
      ostr << "File contents read: " << buffer << std::endl;
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

  // Test temporary file.
  try
  {
    auto [file, iostream] = Gio::File::create_tmp();
    if (!file || !iostream)
    {
      std::cerr << "Gio::File::create_tmp() returned an empty RefPtr." << std::endl;
      return EXIT_FAILURE;
    }
    ostr << "Tmp file parse name: " << file->get_parse_name() << std::endl;

    auto input_stream = iostream->get_input_stream();
    auto output_stream = iostream->get_output_stream();

    // Write to the temporary file.
    const std::string tmp_string = "This is a temporary file.";
    const gssize bytes_written = output_stream->write(tmp_string);
    if (bytes_written != static_cast<int>(tmp_string.size()))
    {
      std::cerr << "Gio::OutputStream::write() wrote: " << bytes_written
                << " bytes. Should write " << tmp_string.size() << " bytes."
                << std::endl;
      return EXIT_FAILURE;
    }
    output_stream->flush();
    iostream->seek(0, Glib::SeekType::SET);

    // Read what was written.
    char buffer[100];
    std::memset(buffer, 0, sizeof buffer);
    const gssize bytes_read = input_stream->read(buffer, sizeof buffer - 1);
    ostr << "Tmp file contents read: " << buffer << std::endl;
    if (bytes_read != bytes_written || buffer != tmp_string)
    {
      std::cerr << "Gio::InputStream::read() read: " << buffer << std::endl;
      return EXIT_FAILURE;
    }
    iostream->close();
    file->remove();
  }
  catch (const Glib::FileError& ex)
  {
    std::cerr << "Glib::FileError exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Glib::Error exception caught: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
