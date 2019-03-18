#include <giomm.h>
#include <iostream>
#include <typeinfo>

void
on_read_async(const Glib::RefPtr<Gio::AsyncResult>& result)
{
  if (!result)
  {
    std::cerr << G_STRFUNC << ": result is empty." << std::endl;
    exit(EXIT_FAILURE);
  }

  auto cobj = g_async_result_get_source_object(result->gobj());
  if (!cobj)
  {
    std::cerr << G_STRFUNC << ": g_async_result_get_source_object() failed." << std::endl;
    exit(EXIT_FAILURE);
  }

  // Show why Glib::wrap(cobj) can't be used in Gio::AsyncResult::get_source_object_base().
  // cppobjbase is not a Glib::Object*, it's a Gio::File* which is a Glib::Interface*.
  std::cout << "GType name: " << G_OBJECT_TYPE_NAME(cobj) << std::endl;
  auto cppobjbase = Glib::wrap_auto(cobj); // Glib::ObjectBase::_get_current_wrapper(cobj);
  if (cppobjbase)
  {
    std::cout << "C++ type name: " << typeid(*cppobjbase).name() << std::endl;
    auto cppobj = dynamic_cast<Glib::Object*>(cppobjbase); // Part of Glib::wrap(GObject*, bool)
    auto cppiface = dynamic_cast<Glib::Interface*>(cppobjbase);
    std::cout << "dynamic_cast<Glib::Object*>: " << cppobj << std::endl;
    std::cout << "dynamic_cast<Glib::Interface*>: " << cppiface << std::endl;
  }

  if (!result->get_source_object_base())
  {
    std::cerr << G_STRFUNC << ": result->get_source_object_base() failed." << std::endl;
    exit(EXIT_FAILURE);
  }

  exit(EXIT_SUCCESS);
}

int
main(int, char**)
{
  Glib::init();
  Gio::init();

  auto mainloop = Glib::MainLoop::create();

  auto file = Gio::File::create_for_path("/etc/passwd");
  file->read_async(&on_read_async);

  mainloop->run();
  return EXIT_SUCCESS;
}
