/* Copyright 1998-2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/object.h>
#include <glibmm/private/object_p.h>
#include <glibmm/property.h>

#include <glib-object.h>
#include <gobject/gvaluecollector.h>

#include <cstdarg>
#include <cstring>

#include <string.h>

namespace Glib
{

ConstructParams::ConstructParams(const Glib::Class& glibmm_class_)
: glibmm_class(glibmm_class_), n_parameters(0), parameter_names(nullptr), parameter_values(nullptr)
{
}

/*
 * The implementation is mostly copied from gobject.c, with some minor tweaks.
 * Basically, it looks up each property name to get its GType, and then uses
 * G_VALUE_COLLECT() to store the varargs argument in a GValue of the correct
 * type.
 *
 * Note that the property name arguments are assumed to be static string
 * literals.  No attempt is made to copy the string content.  This is no
 * different from g_object_new().
 */
ConstructParams::ConstructParams(
  const Glib::Class& glibmm_class_, const char* first_property_name, ...)
: glibmm_class(glibmm_class_), n_parameters(0), parameter_names(nullptr), parameter_values(nullptr)
{
  va_list var_args;
  va_start(var_args, first_property_name);

  GObjectClass* const g_class =
    static_cast<GObjectClass*>(g_type_class_get(glibmm_class.get_type()));

  unsigned int n_alloced_params = 0;
  char* collect_error = nullptr; // output argument of G_VALUE_COLLECT()

  for (const char* name = first_property_name; name != nullptr; name = va_arg(var_args, char*))
  {
    GParamSpec* const pspec = g_object_class_find_property(g_class, name);

    if (!pspec)
    {
      g_warning("Glib::ConstructParams::ConstructParams(): "
                "object class \"%s\" has no property named \"%s\"",
        g_type_name(glibmm_class.get_type()), name);
      break;
    }

    if (n_parameters >= n_alloced_params) {
      n_alloced_params += 8;
      parameter_names = g_renew(const char*, parameter_names, n_alloced_params);
      parameter_values = g_renew(GValue, parameter_values, n_alloced_params);
    }

    auto& param_name = parameter_names[n_parameters];
    auto& param_value = parameter_values[n_parameters];
    param_name = name;
    param_value.g_type = 0;

    // Fill the GValue with the current vararg, and move on to the next one.
    g_value_init(&param_value, G_PARAM_SPEC_VALUE_TYPE(pspec));
    G_VALUE_COLLECT(&param_value, var_args, 0, &collect_error);

    if (collect_error)
    {
      g_warning("Glib::ConstructParams::ConstructParams(): %s", collect_error);
      g_free(collect_error);
      g_value_unset(&param_value);
      break;
    }

    ++n_parameters;
  }

  va_end(var_args);
}

ConstructParams::~ConstructParams() noexcept
{
  while (n_parameters > 0) {
    auto& param_value = parameter_values[--n_parameters];
    g_value_unset(&param_value);
  }

  g_free(parameter_names);
  g_free(parameter_values);
}

/**** Glib::Object_Class ***************************************************/

const Glib::Class&
Object_Class::init()
{
  if (!gtype_)
  {
    class_init_func_ = &Object_Class::class_init_function;
    register_derived_type(G_TYPE_OBJECT);
  }

  return *this;
}

void
Object_Class::class_init_function(void*, void*)
{
}

Object*
Object_Class::wrap_new(GObject* object)
{
  return new Object(object);
}

/**** Glib::Object *********************************************************/

// static data
Object::CppClassType Object::object_class_;

Object::Object()
{
  // This constructor is ONLY for derived classes that are NOT wrappers of
  // derived C objects.  For instance, Gtk::Object should NOT use this
  // constructor.

  // g_warning("Object::Object(): Did you really mean to call this?");

  // If Glib::ObjectBase has been constructed with a custom typeid, we derive
  // a new GType on the fly.  This works because ObjectBase is a virtual base
  // class, therefore its constructor is always executed first.

  GType object_type = G_TYPE_OBJECT; // the default -- not very useful

  if (custom_type_name_ && !is_anonymous_custom_())
  {
    object_class_.init();

    // This creates a type that is derived (indirectly) from GObject.
    object_type = object_class_.clone_custom_type(custom_type_name_,
      get_custom_interface_classes(), get_custom_class_init_functions(),
      get_custom_instance_init_function());
    custom_class_init_finished();
  }

  GObject* const new_object = g_object_new_with_properties(object_type, 0, nullptr, nullptr);

  // Connect the GObject and Glib::Object instances.
  ObjectBase::initialize(new_object);
}

Object::Object(const Glib::ConstructParams& construct_params)
{
  GType object_type = construct_params.glibmm_class.get_type();

  // If Glib::ObjectBase has been constructed with a custom typeid, we derive
  // a new GType on the fly.  This works because ObjectBase is a virtual base
  // class, therefore its constructor is always executed first.

  if (custom_type_name_ && !is_anonymous_custom_())
  {
    object_type =
      construct_params.glibmm_class.clone_custom_type(custom_type_name_,
      get_custom_interface_classes(), get_custom_class_init_functions(),
      get_custom_instance_init_function());
    custom_class_init_finished();
  }

  // Create a new GObject with the specified array of construct properties.
  // This works with custom types too, since those inherit the properties of
  // their base class.

  GObject* const new_object =
    g_object_new_with_properties(object_type, construct_params.n_parameters, construct_params.parameter_names, construct_params.parameter_values);

  // Connect the GObject and Glib::Object instances.
  ObjectBase::initialize(new_object);
}

Object::Object(GObject* castitem)
{
  // I disabled this check because libglademm really does need to do this.
  //(actually it tells libglade to instantiate "gtkmm_" types.
  // The 2nd instance bug will be caught elsewhere anyway.
  /*
    static const char gtkmm_prefix[] = "gtkmm__";
    const char *const type_name = G_OBJECT_TYPE_NAME(castitem);

    if(strncmp(type_name, gtkmm_prefix, sizeof(gtkmm_prefix) - 1) == 0)
    {
      g_warning("Glib::Object::Object(GObject*): "
                "An object of type '%s' was created directly via g_object_new(). "
                "The Object::Object(const Glib::ConstructParams&) constructor "
                "should be used instead.\n"
                "This could happen if the C instance lived longer than the C++ instance, so that "
                "a second C++ instance was created automatically to wrap it. That would be a gtkmm
    bug that you should report.",
                 type_name);
    }
  */

  // Connect the GObject and Glib::Object instances.
  ObjectBase::initialize(castitem);
}

Object::Object(Object&& src) noexcept
  : sigc::trackable(std::move(src)), // not actually called because it's a virtual base
    ObjectBase(std::move(src)) // not actually called because it's a virtual base
{
  // Perhaps trackable's move constructor has not been called. Do its job here.
  // (No harm is done if notify_callbacks() is called twice. The second call
  // won't do anything.)
  src.notify_callbacks();
  ObjectBase::initialize_move(src.gobject_, &src);
}

Object&
Object::operator=(Object&& src) noexcept
{
  ObjectBase::operator=(std::move(src));
  return *this;
}

Object::~Object() noexcept
{
  cpp_destruction_in_progress_ = true;
}

/*
RefPtr<Object> Object::create()
{
  // Derived classes will actually return RefPtr<>s that contain useful instances.
  return RefPtr<Object>();
}
*/

GType
Object::get_type()
{
  return object_class_.init().get_type();
}

GType
Object::get_base_type()
{
  return G_TYPE_OBJECT;
}

// Data services
void*
Object::get_data(const QueryQuark& id)
{
  return g_object_get_qdata(gobj(), id);
}

void
Object::set_data(const Quark& id, void* data)
{
  g_object_set_qdata(gobj(), id, data);
}

void
Object::set_data_with_c_callback(const Quark& id, void* data, GDestroyNotify destroy)
{
  g_object_set_qdata_full(gobj(), id, data, destroy);
}

#ifdef GLIBMM_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS
void
Object::set_data(const Quark& id, void* data, DestroyNotify destroy)
{
  g_object_set_qdata_full(gobj(), id, data, destroy);
}
#else
void
Object::set_data(const Quark& id, void* data, DestroyNotify)
{
  g_object_set_qdata(gobj(), id, data);
  g_critical("Can't assign a callback with C++ linkage to g_object_set_qdata_full().\n"
             "Use Glib::Object::set_data_with_c_callback().\n");
}
#endif

void
Object::remove_data(const QueryQuark& id)
{
  // missing in glib??
  g_return_if_fail(id.id() > 0);
  g_datalist_id_remove_data(&gobj()->qdata, id);
}

void*
Object::steal_data(const QueryQuark& id)
{
  return g_object_steal_qdata(gobj(), id);
}

} // namespace Glib
