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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/class.h>
#include <glibmm/property.h>
#include <glibmm/ustring.h>
#include <glibmm/utility.h>
#include <glibmm/interface.h>
#include <glibmm/private/interface_p.h>

namespace
{
// C++ linkage
using BaseFinalizeFuncType = void (*)(void*);
using ClassInitFuncType = void (*)(void*, void*);

BaseFinalizeFuncType p_custom_class_base_finalize_function;
ClassInitFuncType p_custom_class_init_function;

extern "C"
{
// From functions with C linkage, to private static member functions with C++ linkage
static void Class_custom_class_base_finalize_function(void* g_class)
{
  p_custom_class_base_finalize_function(g_class);
}

static void Class_custom_class_init_function(void* g_class, void* class_data)
{
  p_custom_class_init_function(g_class, class_data);
}
} // extern "C"
} // anonymous namespace

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

#if GLIB_CHECK_VERSION(2,70,0)
  // Don't derive a type if the base type is a final type.
  if (G_TYPE_IS_FINAL(base_type))
  {
    gtype_ = base_type;
    return;
  }
#endif

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
Class::clone_custom_type(
  const char* custom_type_name, const interface_classes_type* interface_classes,
  const class_init_funcs_type* class_init_funcs, GInstanceInitFunc instance_init_func) const
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

    // Let the wrapper's class_init_function() be the first one to call.
    auto all_class_init_funcs = new class_init_funcs_type(
      1, std::tuple<GClassInitFunc, void*>(class_init_func_, nullptr));
    if (class_init_funcs)
      all_class_init_funcs->insert(all_class_init_funcs->end(),
        class_init_funcs->begin(), class_init_funcs->end());

    p_custom_class_base_finalize_function = &Class::custom_class_base_finalize_function;
    p_custom_class_init_function = &Class::custom_class_init_function;

    const GTypeInfo derived_info = {
      class_size,
      nullptr, // base_init
      &Class_custom_class_base_finalize_function, // base_finalize
      &Class_custom_class_init_function,
      nullptr, // class_finalize
      all_class_init_funcs, // class_data
      instance_size,
      0, // n_preallocs
      instance_init_func, // instance_init
      nullptr, // value_table
    };

    // custom_class_init_function() is called when the first object of the custom
    // class is created, which is after clone_custom_type() has returned.
    // Let custom_class_init_function() delete all_class_init_funcs.

    custom_type =
      g_type_register_static(base_type, full_name.c_str(), &derived_info, GTypeFlags(0));

    // Add derived versions of interfaces, if the C type implements any interfaces.
    // For instance, TreeModel_Class::add_interface().
    if (interface_classes)
    {
      for (auto interface_class : *interface_classes)
      {
        if (interface_class)
        {
          interface_class->add_interface(custom_type);
        }
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
  // clone_custom_type() sets the class data pointer to a pointer to a vector
  // of pointers to functions to be called.
  const class_init_funcs_type& class_init_funcs =
    *static_cast<class_init_funcs_type*>(class_data);

  g_return_if_fail(!class_init_funcs.empty() && std::get<GClassInitFunc>(class_init_funcs[0]) != nullptr);

  // Call the wrapper's class_init_function() to redirect
  // the vfunc and default signal handler callbacks.
  auto init_func = std::get<GClassInitFunc>(class_init_funcs[0]);
  (*init_func)(g_class, nullptr);

  GObjectClass* const gobject_class = static_cast<GObjectClass*>(g_class);
  gobject_class->get_property = &Glib::glibmm_custom_get_property_callback;
  gobject_class->set_property = &Glib::glibmm_custom_set_property_callback;

  // Call extra class init functions, if any.
  for (std::size_t i = 1; i < class_init_funcs.size(); ++i)
  {
    if (auto extra_init_func = std::get<GClassInitFunc>(class_init_funcs[i]))
    {
      auto extra_class_data = std::get<void*>(class_init_funcs[i]);
      (*extra_init_func)(g_class, extra_class_data);
    }
  }

  // Assume that this function is called exactly once for each type.
  // Delete the class_init_funcs_type that was created in clone_custom_type().
  delete static_cast<class_init_funcs_type*>(class_data);

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
    void* const g_iface = g_type_default_interface_get(iface_types[i]);

    guint n_iface_props = 0;
    GParamSpec** iface_props = g_object_interface_list_properties(g_iface, &n_iface_props);

    for (guint p = 0; p < n_iface_props; p++)
    {
      const gchar* prop_name = g_param_spec_get_name(iface_props[p]);

      // Override only properties which have not been overridden in a base class.
      // Store the default values belonging to the class.
      // They are copied to an object in glibmm_custom_set_property_callback()
      // in property.cc.
      if (!g_object_class_find_property(gobject_class, prop_name))
      {
        GValue* g_value = g_new0(GValue, 1);
        g_value_init(g_value, iface_props[p]->value_type);
        g_param_value_set_default(iface_props[p], g_value);
        props->emplace_back(g_value);

        g_object_class_override_property(gobject_class, props->size(), prop_name);
      }
    } // end for p

    g_free(iface_props);

  } // end for i

  g_free(iface_types);
}

} // namespace Glib
