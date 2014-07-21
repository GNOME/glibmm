// -*- c++ -*-
/* $Id$ */

/* Copyright 2002 The gtkmm Development Team
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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm/property.h>


#include <glibmm/object.h>
#include <glibmm/class.h>
#include <cstddef>

// Temporary hack till GLib gets fixed.
#undef  G_STRLOC
#define G_STRLOC __FILE__ ":" G_STRINGIFY(__LINE__)


namespace
{

// OK guys, please don't kill me for that.  Let me explain what happens here.
//
// The task:
// ---------
// a) Autogenerate a property ID number for each custom property.  This is an
//    unsigned integer, which doesn't have to be assigned continuously.  I.e.,
//    it can be everything but 0.
// b) If more than one object of the same class is instantiated, then of course
//    the already installed properties must be used.  That means, a property ID
//    must not be associated with a single Glib::Property<> instance.  Rather,
//    the ID has to be associated with the class somehow.
// c) With only a GObject pointer and a property ID (and perhaps GParamSpec*
//    if necessary), it must be possible to acquire a reference to the property
//    wrapper instance.
//
// The current solution:
// ---------------------
// a) Assign an ID to a Glib::PropertyBase by calculating its offset in bytes
//    relative to the beginning of the object's memory.  dynamic_cast<void*>
//    is used to retrieve a pointer to the very beginning of an instance.
// b) Recalculate a specific PropertyBase pointer by adding the property ID
//    (i.e. the byte offset) to the object start pointer.  The result is then
//    just casted to PropertyBase*.
//
// Drawbacks:
// ----------
// a) It's a low-level hack.  Should be portable, yes, but we can only do very
//    limited error checking.
// b) All Glib::Property<> instances are absolutely required to be direct data
//    members of the class that implements the property.  That seems a natural
//    thing to do, but it's questionable whether it should be a requirement.
//
// Advantages:
// -----------
// a) Although low-level, it's extremely easy to implement.  The nasty code is
//    concentrated in only two non-exposed utility functions, and it works
//    just fine.
// b) It's efficient, and the memory footprint is very small too.
// c) I actually tried other ways, too, but ran into dead-ends everywhere.
//    It's probably possible to implement this without calculating offsets,
//    but it'll be very complicated, and involve a lot of qdata pointers to
//    property tables andwhatnot.
//
// We can reimplement this later if necessary.

static unsigned int property_to_id(Glib::ObjectBase& object, Glib::PropertyBase& property)
{
  void *const base_ptr = dynamic_cast<void*>(&object);
  void *const prop_ptr = &property;

  const std::ptrdiff_t offset = static_cast<guint8*>(prop_ptr) - static_cast<guint8*>(base_ptr);

  g_return_val_if_fail(offset > 0 && offset < G_MAXINT, 0);

  return static_cast<unsigned int>(offset);
}

Glib::PropertyBase& property_from_id(Glib::ObjectBase& object, unsigned int property_id)
{
  void *const base_ptr = dynamic_cast<void*>(&object);
  void *const prop_ptr = static_cast<guint8*>(base_ptr) + property_id;

  return *static_cast<Glib::PropertyBase*>(prop_ptr);
}

// Delete the interface property values when an object of a custom type is finalized.
void destroy_notify_obj_iface_props(void* data)
{
  Glib::Class::iface_properties_type* obj_iface_props =
    static_cast<Glib::Class::iface_properties_type*>(data);

  if (obj_iface_props)
  {
    for (Glib::Class::iface_properties_type::size_type i = 0; i < obj_iface_props->size(); i++)
    {
      g_value_unset((*obj_iface_props)[i]);
      g_free((*obj_iface_props)[i]);
    }
    delete obj_iface_props;
  }
}

} // anonymous namespace


namespace Glib
{

void custom_get_property_callback(GObject* object, unsigned int property_id,
                                  GValue* value, GParamSpec* param_spec)
{
  // If the id is zero there is no property to get.
  g_return_if_fail(property_id != 0);

  GType custom_type = G_OBJECT_TYPE(object);

  Class::iface_properties_type* iface_props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(custom_type, Class::iface_properties_quark));

  Class::iface_properties_type::size_type iface_props_size = 0;

  if (iface_props)
    iface_props_size = iface_props->size();

  if (property_id <= iface_props_size)
  {
    // Get the object's property value if there is one, else the class's default value.
    Class::iface_properties_type* obj_iface_props = static_cast<Class::iface_properties_type*>(
      g_object_get_qdata(object, Class::iface_properties_quark));
    if (obj_iface_props)
      g_value_copy((*obj_iface_props)[property_id - 1], value);
    else
      g_value_copy((*iface_props)[property_id - 1], value);
  }
  else
  {
    if(Glib::ObjectBase *const wrapper = Glib::ObjectBase::_get_current_wrapper(object))
    {
      PropertyBase& property =
        property_from_id(*wrapper, property_id - iface_props_size);

      if((property.object_ == wrapper) && (property.param_spec_ == param_spec))
        g_value_copy(property.value_.gobj(), value);
      else
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, param_spec);
    }
  }
}

void custom_set_property_callback(GObject* object, unsigned int property_id,
                                  const GValue* value, GParamSpec* param_spec)
{
  // If the id is zero there is no property to get.
  g_return_if_fail(property_id != 0);

  GType custom_type = G_OBJECT_TYPE(object);

  Class::iface_properties_type* iface_props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(custom_type, Class::iface_properties_quark));

  Class::iface_properties_type::size_type iface_props_size = 0;

  if (iface_props)
    iface_props_size = iface_props->size();

  if (property_id <= iface_props_size)
  {
    // If the object does not have interface property values,
    // copy the class's default values to the object.
    Class::iface_properties_type* obj_iface_props = static_cast<Class::iface_properties_type*>(
      g_object_get_qdata(object, Class::iface_properties_quark));
    if (!obj_iface_props)
    {
      obj_iface_props = new Class::iface_properties_type();
      g_object_set_qdata_full(object, Class::iface_properties_quark, obj_iface_props,
                              destroy_notify_obj_iface_props);
      for (Class::iface_properties_type::size_type p = 0; p < iface_props_size; ++p)
      {
        GValue* g_value = g_new0(GValue, 1);
        g_value_init(g_value, G_VALUE_TYPE((*iface_props)[p]));
        g_value_copy((*iface_props)[p], g_value);
        obj_iface_props->push_back(g_value);
      }
    }

    g_value_copy(value, (*obj_iface_props)[property_id - 1]);
    g_object_notify_by_pspec(object, param_spec);
  }
  else
  {
    if(Glib::ObjectBase *const wrapper = Glib::ObjectBase::_get_current_wrapper(object))
    {
      PropertyBase& property =
        property_from_id(*wrapper, property_id - iface_props_size);

      if((property.object_ == wrapper) && (property.param_spec_ == param_spec))
      {
        g_value_copy(value, property.value_.gobj());
        g_object_notify_by_pspec(object, param_spec);
      }
      else
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, param_spec);
    }
  }
}


/**** Glib::PropertyBase ***************************************************/

PropertyBase::PropertyBase(Glib::Object& object, GType value_type)
:
  object_     (&object),
  value_      (),
  param_spec_ (0)
{
  value_.init(value_type);
}

PropertyBase::~PropertyBase()
{
  if(param_spec_)
    g_param_spec_unref(param_spec_);
}

bool PropertyBase::lookup_property(const Glib::ustring& name)
{
  g_assert(param_spec_ == 0);

  param_spec_ = g_object_class_find_property(G_OBJECT_GET_CLASS(object_->gobj()), name.c_str());

  if(param_spec_)
  {
    g_assert(G_PARAM_SPEC_VALUE_TYPE(param_spec_) == G_VALUE_TYPE(value_.gobj()));
    g_param_spec_ref(param_spec_);
  }

  return (param_spec_ != 0);
}

void PropertyBase::install_property(GParamSpec* param_spec)
{
  g_return_if_fail(param_spec != 0);

  // Ensure that there would not be id clashes with possible existing
  // properties overridden from implemented interfaces if dealing with a custom
  // type by offsetting the generated id with the number of already existing
  // properties.

  GType gtype = G_OBJECT_TYPE(object_->gobj());
  Class::iface_properties_type* iface_props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(gtype, Class::iface_properties_quark));

  Class::iface_properties_type::size_type iface_props_size = 0;
  if (iface_props)
    iface_props_size = iface_props->size();

  const unsigned int property_id = property_to_id(*object_, *this) + iface_props_size;

  g_object_class_install_property(G_OBJECT_GET_CLASS(object_->gobj()), property_id, param_spec);

  param_spec_ = param_spec;
  g_param_spec_ref(param_spec_);
}

const char* PropertyBase::get_name_internal() const
{
  const char *const name = g_param_spec_get_name(param_spec_);
  g_return_val_if_fail(name != 0, "");
  return name;
}

Glib::ustring PropertyBase::get_name() const
{
  return Glib::ustring(get_name_internal());
}

void PropertyBase::notify()
{
  g_object_notify_by_pspec(object_->gobj(), param_spec_);
}

} // namespace Glib
