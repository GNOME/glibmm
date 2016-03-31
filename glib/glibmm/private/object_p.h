// -*- c++ -*-

#ifndef _GLIBMM_OBJECT_P_H
#define _GLIBMM_OBJECT_P_H

#include <glibmm/class.h>

namespace Glib
{

class Object_Class : public Glib::Class
{
public:
  using CppObjectType = Object;
  using BaseObjectType = GObject;
  using BaseClassType = GObjectClass;

  static void class_init_function(void* g_class, void* class_data);

  const Glib::Class& init();

  static Glib::Object* wrap_new(GObject*);
};

} // namespace Glib

#endif /* _GLIBMM_OBJECT_P_H */
