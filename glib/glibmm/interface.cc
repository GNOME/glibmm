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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/interface.h>
#include <glibmm/private/interface_p.h>

namespace Glib
{

/**** Glib::Interface_Class ************************************************/

void
Interface_Class::add_interface(GType instance_type) const
{
#if GLIB_CHECK_VERSION(2,70,0)
  // If instance_type is a final type, it has not been registered by
  // Glib::Class::register_derived_type(). Don't add an interface.
  if (G_TYPE_IS_FINAL(instance_type))
    return;
#endif

  // This check is disabled, because it checks whether any of the types's bases implement the
  // interface, not just the specific type.
  // if( !g_type_is_a(instance_type, gtype_) ) //For convenience, don't complain about calling this
  // twice.
  //{
  const GInterfaceInfo interface_info = {
    class_init_func_,
    nullptr, // interface_finalize
    nullptr, // interface_data
  };

  g_type_add_interface_static(instance_type, gtype_, &interface_info);
  //}
}

/**** Interface Glib::Interface ********************************************/

Interface::Interface(const Interface_Class& interface_class)
{
  // gobject_ will be set in the Object constructor.
  // Any instantiable class that derives from Interface should also inherit from Object.

  if (custom_type_name_ && !is_anonymous_custom_())
  {
    if (gobject_)
    {
      GObjectClass* const instance_class = G_OBJECT_GET_CLASS(gobject_);
      const GType iface_type = interface_class.get_type();

      if (!g_type_interface_peek(instance_class, iface_type))
      {
        void* const g_iface = g_type_default_interface_get(iface_type);

        // Override the properties of the derived interface, if any.

        const GType custom_type = G_OBJECT_CLASS_TYPE(instance_class);
        Class::iface_properties_type* props = static_cast<Class::iface_properties_type*>(
          g_type_get_qdata(custom_type, Class::iface_properties_quark));

        if (!props)
        {
          props = new Class::iface_properties_type();
          g_type_set_qdata(custom_type, Class::iface_properties_quark, props);
        }

        const guint n_existing_props = props->size();

        guint n_iface_props = 0;
        GParamSpec** iface_props = g_object_interface_list_properties(g_iface, &n_iface_props);

        for (guint p = 0; p < n_iface_props; p++)
        {
          GValue* g_value = g_new0(GValue, 1);
          g_value_init(g_value, iface_props[p]->value_type);
          g_param_value_set_default(iface_props[p], g_value);
          props->emplace_back(g_value);

          const gchar* prop_name = g_param_spec_get_name(iface_props[p]);
          GParamSpec* new_spec = g_param_spec_override(prop_name, iface_props[p]);
          g_object_class_install_property(instance_class, p + 1 + n_existing_props, new_spec);
        }

        interface_class.add_interface(custom_type);

        g_free(iface_props);
      }
    }
    else // gobject_ == nullptr
    {
      // The GObject is not instantiated yet. Add to the stored custom interface
      // classes, and add the interface to the GType in the Glib::Object constructor.
      add_custom_interface_class(&interface_class);
    }
  }
}

Interface::Interface(GObject* castitem)
{
  // Connect GObject and wrapper instances.
  ObjectBase::initialize(castitem);
}

Interface::Interface()
{
}

Interface::Interface(Interface&& src) noexcept
  : sigc::trackable(std::move(src)), // not actually called because it's a virtual base
    ObjectBase(std::move(src)) // not actually called because it's a virtual base
{
  // We don't call initialize_move() because we
  // want the derived move constructor to only cause it
  // to be called once, so we just let it be called
  // by the implementing class, such as Gtk::Entry (implementing Gtk::Editable
  // and Gtk::CellEditable), via the call to Object::Object(Object&& src).
  // ObjectBase::initialize_move(src.gobject_, &src);
}

Interface&
Interface::operator=(Interface&& /* src */) noexcept
{
  // We don't call ObjectBase::operator=(ObjectBase&& src) because we
  // want the derived move assignment operator to only cause it
  // to be called once, so we just let it be called
  // by the implementing class, such as Gtk::Entry (implementing Gtk::Editable
  // and Gtk::CellEditable), via the call to Object::operator=(Object&& src).
  // ObjectBase::operator=(std::move(src));
  return *this;
}

Interface::~Interface() noexcept
{
}

GType
Interface::get_type()
{
  return G_TYPE_INTERFACE;
}

GType
Interface::get_base_type()
{
  return G_TYPE_INTERFACE;
}

RefPtr<ObjectBase>
wrap_interface(GObject* object, bool take_copy)
{
  return Glib::make_refptr_for_instance<ObjectBase>(wrap_auto(object, take_copy));
}

} // namespace Glib
