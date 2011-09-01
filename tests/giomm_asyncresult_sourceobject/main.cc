#include <giomm.h>
#include <iostream>

void on_read_async(const Glib::RefPtr<Gio::AsyncResult>& result)
{
  if(!result)
  {
    std::cerr << G_STRFUNC << ": result is empty." << std::endl;
    exit(EXIT_FAILURE);
  }

  if(!g_async_result_get_source_object(result->gobj()))
  {
    std::cerr << G_STRFUNC << ": g_async_result_get_source_object() failed." << std::endl;
    exit(EXIT_FAILURE);
  }
  
  if(!result->get_source_object_base())
  {
    std::cerr << G_STRFUNC << ": result->get_source_object_base() failed." << std::endl;
    exit(EXIT_FAILURE);
  }
 
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
  return EXIT_SUCCESS;
}
