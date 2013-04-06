#include <glibmm.h>
#include <giomm.h> //There are no Interfaces in glibmm, but there are in giomm.
#include <iostream>

//TODO: I also tried Glib::Action, but that needs us to implement interface properties. murrayc
class CustomConverter :
  public Glib::Object,
  public Gio::Converter
{
public:
  CustomConverter();

protected:
  //Implement a vfunc:
  virtual void reset_vfunc();
};

CustomConverter::CustomConverter()
: Glib::ObjectBase( typeid(CustomConverter) ),
  Glib::Object()
{
}

static bool reset_called = false;

void CustomConverter::reset_vfunc()
{
  reset_called = true;
}


int main(int, char**)
{
  Glib::init();

  CustomConverter converter;
  converter.reset();
  g_assert(reset_called);

  return EXIT_SUCCESS;
}
