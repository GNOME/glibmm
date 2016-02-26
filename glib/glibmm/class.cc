/* Copyright (C) 1998-2002 The gtkmm Development Team
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

#include <glibmm/class.h>
#include <glibmm/property.h>
#include <glibmm/ustring.h>
#include <glibmm/utility.h>
#include <glibmm/interface.h>
#include <glibmm/private/interface_p.h>

namespace Glib
{

void
Class::register_derived_type(GType base_type)
{
  return register_derived_type(base_type, nullptr);
}

void
Class::register_derived_type(GType base_type, GTypeModule* module)
{
  if (gtype_)
    return; // already initialized

  // 0 is not a valid GType.
  // It would lead to a crash later.
  // We allow this, failing silently, to make life easier for gstreamermm.
  if (base_type == 0)
    return; // already initialized

  GTypeQuery base_query = {
    0, nullptr, 0, 0,
  };
  g_type_query(base_type, &base_query);

  // GTypeQuery::class_size is guint but GTypeInfo::class_size is guint16.
  const guint16 class_size = (guint16)base_query.class_size;

  // GTypeQuery::instance_size is guint but GTypeInfo::instance_size is guint16.
  const guint16 instance_size = (guint16)base_query.instance_size;

  const GTypeInfo derived_info = {
    class_size,
    nullptr, // base_init
    nullptr, // base_finalize
    class_init_func_, // Set by the caller ( *_Class::init() ).
    nullptr, // class_finalize
    nullptr, // class_data
    instance_size,
    0, // n_preallocs
    nullptr, // instance_init
    nullptr, // value_table
  };

  if (!(base_query.type_name))
  {
    g_critical("Class::register_derived_type(): base_query.type_name is NULL.");
    return;
  }

  gchar* derived_name = g_strconcat("gtkmm__", base_query.type_name, nullptr);

  if (module)
    gtype_ =
      g_type_module_register_type(module, base_type, derived_name, &derived_info, GTypeFlags(0));
  else
    gtype_ = g_type_register_static(base_type, derived_name, &derived_info, GTypeFlags(0));

  g_free(derived_name);
}

GType
Class::clone_custom_type(const char* custom_type_name) const
{
  return clone_custom_type(custom_type_name, interface_class_vector_type());
}

GType
Class::clone_custom_type(
  const char* custom_type_name, const interface_class_vector_type& interface_classes) const
{
  std::string full_name("gtkmm__CustomObject_");
  Glib::append_canonical_typename(full_name, custom_type_name);

  GType custom_type = g_type_from_name(full_name.c_str());

  if (!custom_type)
  {
    g_return_val_if_fail(gtype_ != 0, 0);

    // Cloned custom types derive from the wrapper's parent type,
    // so that g_type_class_peek_parent() works correctly.
    const GType base_type = g_type_parent(gtype_);

    GTypeQuery base_query = {
      0, nullptr, 0, 0,
    };
    g_type_query(base_type, &base_query);

    // GTypeQuery::class_size is guint but GTypeInfo::class_size is guint16.
    const guint16 class_size = (guint16)base_query.class_size;

    // GTypeQuery::instance_size is guint but GTypeInfo::instance_size is guint16.
    const guint16 instance_size = (guint16)base_query.instance_size;

    const GTypeInfo derived_info = {
      class_size,
      nullptr, // base_init
      &Class::custom_class_base_finalize_function, // base_finalize
      &Class::custom_class_init_function,
      nullptr, // class_finalize
      this, // class_data
      instance_size,
      0, // n_preallocs
      nullptr, // instance_init
      nullptr, // value_table
    };

    custom_type =
      g_type_register_static(base_type, full_name.c_str(), &derived_info, GTypeFlags(0));

    // Add derived versions of interfaces, if the C type implements any interfaces.
    // For instance, TreeModel_Class::add_interface().
    for (interface_class_vector_type::size_type i = 0; i < interface_classes.size(); i++)
    {
      const Interface_Class* interface_class = interface_classes[i];
      if (interface_class)
      {
        interface_class->add_interface(custom_type);
      }
    }
  }

  return custom_type;
}

// Initialize the static quark to store/get custom type properties.
GQuark Class::iface_properties_quark = g_quark_from_string("gtkmm_CustomObject_iface_properties");

// static
void
Class::custom_class_base_finalize_function(void* g_class)
{
  const GType gtype = G_TYPE_FROM_CLASS(g_class);

  // Free the data related to the interface properties for the custom type, if any.
  iface_properties_type* props =
    static_cast<iface_properties_type*>(g_type_get_qdata(gtype, iface_properties_quark));

  if (props)
  {
    for (iface_properties_type::size_type i = 0; i < props->size(); i++)
    {
      g_value_unset((*props)[i]);
      g_free((*props)[i]);
    }
    delete props;
  }
}

// static
void
Class::custom_class_init_function(void* g_class, void* class_data)
{
  // The class_data pointer is set to 'this' by clone_custom_type().
  const Class* const self = static_cast<Class*>(class_data);

  g_return_if_fail(self->class_init_func_ != nullptr);

  // Call the wrapper's class_init_function() to redirect
  // the vfunc and default signal handler callbacks.
  (*self->class_init_func_)(g_class, nullptr);

  GObjectClass* const gobject_class = static_cast<GObjectClass*>(g_class);
  gobject_class->get_property = &Glib::custom_get_property_callback;
  gobject_class->set_property = &Glib::custom_set_property_callback;

  // Override the properties of implemented interfaces, if any.
  const GType object_type = G_TYPE_FROM_CLASS(g_class);

  Class::iface_properties_type* props = static_cast<Class::iface_properties_type*>(
    g_type_get_qdata(object_type, Class::iface_properties_quark));
  if (!props)
  {
    props = new Class::iface_properties_type();
    g_type_set_qdata(object_type, Class::iface_properties_quark, props);
  }

  guint n_interfaces = 0;
  GType* iface_types = g_type_interfaces(object_type, &n_interfaces);

  for (guint i = 0; i < n_interfaces; ++i)
  {
    void* const g_iface = g_type_default_interface_ref(iface_types[i]);

    guint n_iface_props = 0;
    GParamSpec** iface_props = g_object_interface_list_properties(g_iface, &n_iface_props);

    for (guint p = 0; p < n_iface_props; p++)
    {
      const gchar* prop_name = g_param_spec_get_name(iface_props[p]);

      // Override only properties which have not been overridden in a base class.
      // Store the default values belonging to the class.
      // They are copied to an object in custom_set_property_callback() in property.cc.
      if (!g_object_class_find_property(gobject_class, prop_name))
      {
        GValue* g_value = g_new0(GValue, 1);
        g_value_init(g_value, iface_props[p]->value_type);
        g_param_value_set_default(iface_props[p], g_value);
        props->emplace_back(g_value);

        g_object_class_override_property(gobject_class, props->size(), prop_name);
      }
    } // end for p

    g_type_default_interface_unref(g_iface);
    g_free(iface_props);

  } // end for i

  g_free(iface_types);
}

} // namespace Glib
