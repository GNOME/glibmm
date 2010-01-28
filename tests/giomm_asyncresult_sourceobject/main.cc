#include <giomm.h>
#include <iostream>

void on_read_async(const Glib::RefPtr<Gio::AsyncResult>& result)
{
  std::cout << "Testing result ... "
            << (result ? "OK!" : "FAILED!") << std::endl;

  std::cout << "Testing get_source_object from gobj() ... "
            << (g_async_result_get_source_object(result->gobj()) ? "OK!" : "FAILED!") << std::endl;

  std::cout << "Testing Gio::AsyncResult's get_source_object ... "
            << (result->get_source_object_base() ? "OK!" : "FAILED!") << std::endl;

  exit(EXIT_SUCCESS);
}

int main(int, char**)
{
  Glib::init();
  Gio::init();

  Glib::RefPtr<Glib::MainLoop> mainloop = Glib::MainLoop::create();

  Glib::RefPtr<Gio::File> file = Gio::File::create_for_path("/etc/passwd");
  file->read_async(&on_read_async);

  mainloop->run();
  return 0;
}
