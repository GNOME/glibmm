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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/property.h>

#include <glibmm/object.h>
#include <glibmm/class.h>
#include <cstddef>

// Temporary hack till GLib gets fixed.
#undef G_STRLOC
#define G_STRLOC __FILE__ ":" G_STRINGIFY(__LINE__)

namespace
{
// The task:
// ---------
// a) Autogenerate a property ID number for each custom property.  This is an
//    unsigned integer, which doesn't have to be assigned contiguously.  I.e.,
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
// a) Assign an ID to a Glib::PropertyBase by keeping track of the number of
//    properties that have been already installed. Since C++ always calls
//    the constructors of sub-objects in an object in the same order, we can
//    rely on the same ID being assigned to the same property.
// b) Store addresses to PropertyBase objects in a separate, per-object vector
//    and use the property ID as the index in that vector.
//
// Drawbacks:
// ----------
// a) An additional GQuark and a vector lookup need to be done to retrieve the
//    address of PropertyBase.
// b) In the given run of a program, all Glib::Property<> instances related to
//    a given Glib::Object must be constructed in the same order.
//
// Advantages:
// -----------
// a) Almost all conceivable use-cases are supported by this approach.
// b) It's comparatively efficient, and does not need a hash-table lookup.

// Delete the interface property values when an object of a custom type is finalized.
void
destroy_notify_obj_iface_props(void* data)
{
  auto obj_iface_props = static_cast<Glib::Class::iface_properties_type*>(data);
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

// The type that holds pointers to the custom properties of custom types.
using custom_properties_type = std::vector<Glib::PropertyBase*>;
// The quark used for storing/getting the custom properties of custom types.
static const GQuark custom_properties_quark =
  g_quark_from_string("gtkmm_CustomObject_custom_properties");

// Delete the vector of pointers to custom properties when an object of
// a custom type is finalized.
void
destroy_notify_obj_custom_props(void* data)
{
  // Shallow deletion. The vector does not own the objects pointed to.
  delete static_cast<custom_properties_type*>(data);
}

custom_properties_type*
get_obj_custom_props(GObject* obj)
{
  auto obj_custom_props =
    static_cast<custom_properties_type*>(g_object_get_qdata(obj, custom_properties_quark));
  if (!obj_custom_props)
  {
    obj_custom_props = new custom_properties_type();
    g_object_set_qdata_full(
      obj, custom_properties_quark, obj_custom_props, destroy_notify_obj_custom_props);
  }
  return obj_custom_props;
}

} // anonymous namespace

namespace Glib
{

void
custom_get_property_callback(
  GObject* object, unsigned int property_id, GValue* value, GParamSpec* param_spec)
{
  // If the id is zero there is no property to get.
  g_return_if_fail(property_id != 0);

  GType custom_type = G_OBJECT_TYPE(object);

  auto iface_props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(custom_type, Class::iface_properties_quark));

  Class::iface_properties_type::size_type iface_props_size = 0;

  if (iface_props)
    iface_props_size = iface_props->size();

  if (property_id <= iface_props_size)
  {
    // Get the object's property value if there is one, else the class's default value.
    auto obj_iface_props = static_cast<Class::iface_properties_type*>(
      g_object_get_qdata(object, Class::iface_properties_quark));
    if (obj_iface_props)
      g_value_copy((*obj_iface_props)[property_id - 1], value);
    else
      g_value_copy((*iface_props)[property_id - 1], value);
  }
  else
  {
    if (Glib::ObjectBase* const wrapper = Glib::ObjectBase::_get_current_wrapper(object))
    {
      auto obj_custom_props =
        static_cast<custom_properties_type*>(g_object_get_qdata(object, custom_properties_quark));
      const unsigned index = property_id - iface_props_size - 1;

      if (obj_custom_props && index < obj_custom_props->size() &&
          (*obj_custom_props)[index]->object_ == wrapper &&
          (*obj_custom_props)[index]->param_spec_ == param_spec)
        g_value_copy((*obj_custom_props)[index]->value_.gobj(), value);
      else
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, param_spec);
    }
  }
}

void
custom_set_property_callback(
  GObject* object, unsigned int property_id, const GValue* value, GParamSpec* param_spec)
{
  // If the id is zero there is no property to set.
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
      g_object_set_qdata_full(
        object, Class::iface_properties_quark, obj_iface_props, destroy_notify_obj_iface_props);
      for (Class::iface_properties_type::size_type p = 0; p < iface_props_size; ++p)
      {
        GValue* g_value = g_new0(GValue, 1);
        g_value_init(g_value, G_VALUE_TYPE((*iface_props)[p]));
        g_value_copy((*iface_props)[p], g_value);
        obj_iface_props->emplace_back(g_value);
      }
    }

    g_value_copy(value, (*obj_iface_props)[property_id - 1]);
    g_object_notify_by_pspec(object, param_spec);
  }
  else
  {
    if (Glib::ObjectBase* const wrapper = Glib::ObjectBase::_get_current_wrapper(object))
    {
      auto obj_custom_props =
        static_cast<custom_properties_type*>(g_object_get_qdata(object, custom_properties_quark));
      const unsigned index = property_id - iface_props_size - 1;

      if (obj_custom_props && index < obj_custom_props->size() &&
          (*obj_custom_props)[index]->object_ == wrapper &&
          (*obj_custom_props)[index]->param_spec_ == param_spec)
      {
        g_value_copy(value, (*obj_custom_props)[index]->value_.gobj());
        g_object_notify_by_pspec(object, param_spec);
      }
      else
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, param_spec);
    }
  }
}

/**** Glib::PropertyBase ***************************************************/

PropertyBase::PropertyBase(Glib::Object& object, GType value_type)
: object_(&object), value_(), param_spec_(nullptr)
{
  value_.init(value_type);
}

PropertyBase::~PropertyBase() noexcept
{
  if (param_spec_)
    g_param_spec_unref(param_spec_);
}

bool
PropertyBase::lookup_property(const Glib::ustring& name)
{
  g_assert(param_spec_ == nullptr);

  param_spec_ = g_object_class_find_property(G_OBJECT_GET_CLASS(object_->gobj()), name.c_str());

  if (param_spec_)
  {
    // This property has already been installed, when another instance
    // of the object_ class was constructed.
    g_assert(G_PARAM_SPEC_VALUE_TYPE(param_spec_) == G_VALUE_TYPE(value_.gobj()));
    g_param_spec_ref(param_spec_);

    get_obj_custom_props(object_->gobj())->emplace_back(this);
  }

  return (param_spec_ != nullptr);
}

void
PropertyBase::install_property(GParamSpec* param_spec)
{
  g_return_if_fail(param_spec != nullptr);

  // Ensure that there would not be id clashes with possible existing
  // properties overridden from implemented interfaces if dealing with a custom
  // type by offsetting the generated id with the number of already existing
  // properties.

  GType gtype = G_OBJECT_TYPE(object_->gobj());
  auto iface_props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(gtype, Class::iface_properties_quark));

  Class::iface_properties_type::size_type iface_props_size = 0;
  if (iface_props)
    iface_props_size = iface_props->size();

  auto obj_custom_props = get_obj_custom_props(object_->gobj());

  const unsigned int pos_in_obj_custom_props = obj_custom_props->size();
  obj_custom_props->emplace_back(this);

  // We need to offset by 1 as zero is an invalid property id.
  const unsigned int property_id = pos_in_obj_custom_props + iface_props_size + 1;

  g_object_class_install_property(G_OBJECT_GET_CLASS(object_->gobj()), property_id, param_spec);

  param_spec_ = param_spec;
  g_param_spec_ref(param_spec_);
}

const char*
PropertyBase::get_name_internal() const
{
  const char* const name = g_param_spec_get_name(param_spec_);
  g_return_val_if_fail(name != nullptr, "");
  return name;
}

Glib::ustring
PropertyBase::get_name() const
{
  return Glib::ustring(get_name_internal());
}

Glib::ustring
PropertyBase::get_nick() const
{
  return Glib::convert_const_gchar_ptr_to_ustring(
    g_param_spec_get_nick(param_spec_));
}

Glib::ustring
PropertyBase::get_blurb() const
{
  return Glib::convert_const_gchar_ptr_to_ustring(
    g_param_spec_get_blurb(param_spec_));
}

void
PropertyBase::notify()
{
  g_object_notify_by_pspec(object_->gobj(), param_spec_);
}

} // namespace Glib
