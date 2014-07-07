// -*- c++ -*-
/* $Id$ */

/* Copyright (C) 2002 The gtkmm Development Team
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

#include <glibmm/threads.h> // Needed until the next ABI break.
#include <glibmm/interface.h>
#include <glibmm/private/interface_p.h>


namespace Glib
{

/**** Glib::Interface_Class ************************************************/

void Interface_Class::add_interface(GType instance_type) const
{
  //This check is disabled, because it checks whether any of the types's bases implement the interface, not just the specific type.
  //if( !g_type_is_a(instance_type, gtype_) ) //For convenience, don't complain about calling this twice.
  //{
    const GInterfaceInfo interface_info =
    {
      class_init_func_,
      0, // interface_finalize
      0, // interface_data
    };

    g_type_add_interface_static(instance_type, gtype_, &interface_info);
  //}
}


/**** Interface Glib::Interface ********************************************/

Interface::Interface(const Interface_Class& interface_class)
{
  //gobject_ will be set in the Object constructor.
  //Any instantiable class that derives from Interface should also inherit from Object.

  if(custom_type_name_ && !is_anonymous_custom_())
  {
    if (gobject_)
    {
      GObjectClass *const instance_class = G_OBJECT_GET_CLASS(gobject_);
      const GType iface_type = interface_class.get_type();

      if(!g_type_interface_peek(instance_class, iface_type))
      {
        void* const g_iface = g_type_default_interface_ref(iface_type);

        // Override the properties of the derived interface, if any.

        const GType custom_type = G_OBJECT_CLASS_TYPE(instance_class);
        Class::iface_properties_type* props = static_cast<Class::iface_properties_type*>(
          g_type_get_qdata(custom_type, Class::iface_properties_quark));

        if(!props)
        {
          props = new Class::iface_properties_type();
          g_type_set_qdata(custom_type, Class::iface_properties_quark, props);
        }

        const guint n_existing_props = props->size();

        guint n_iface_props = 0;
        GParamSpec** iface_props = g_object_interface_list_properties(g_iface, &n_iface_props);

        for(guint p = 0; p < n_iface_props; p++)
        {
          GValue* g_value = g_new0(GValue, 1);
          g_value_init(g_value, iface_props[p]->value_type);
          g_param_value_set_default(iface_props[p], g_value);
          props->push_back(g_value);

          const gchar* prop_name = g_param_spec_get_name(iface_props[p]);
          GParamSpec* new_spec = g_param_spec_override(prop_name, iface_props[p]);
          g_object_class_install_property(instance_class, p + 1 + n_existing_props, new_spec);
        }

        interface_class.add_interface(custom_type);

        g_type_default_interface_unref(g_iface);
        g_free(iface_props);
      }
    }
    else // gobject_ == 0
    {
      // The GObject is not instantiated yet. Add to the custom_interface_classes
      // and add the interface in the Glib::Object constructor.
      Threads::Mutex::Lock lock(*extra_object_base_data_mutex);
      extra_object_base_data[this].custom_interface_classes.push_back(&interface_class);
    }
  }
}

Interface::Interface(GObject* castitem)
{
  // Connect GObject and wrapper instances.
  ObjectBase::initialize(castitem);
}

Interface::Interface()
{}

Interface::~Interface()
{}

GType Interface::get_type()
{
  return G_TYPE_INTERFACE;
}

GType Interface::get_base_type()
{
  return G_TYPE_INTERFACE;
}

RefPtr<ObjectBase> wrap_interface(GObject* object, bool take_copy)
{
  return Glib::RefPtr<ObjectBase>( wrap_auto(object, take_copy) );
}

} // namespace Glib

