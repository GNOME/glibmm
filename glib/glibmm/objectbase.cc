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

#include <glib-object.h>

#include <glibmm/quark.h>
#include <glibmm/objectbase.h>
#include <glibmm/propertyproxy_base.h> //For PropertyProxyConnectionNode
#include <glibmm/interface.h>
#include <glibmm/private/interface_p.h>
#include <utility> // For std::move()

namespace
{

// Used by the Glib::ObjectBase default ctor.  Using an explicitly defined
// char array rather than a string literal allows for fast pointer comparison,
// which is otherwise not guaranteed to work.

static const char anonymous_custom_type_name[] = "gtkmm__anonymous_custom_type";

using ObjectBaseDestroyNotifyFuncType = void (*)(void* data);
ObjectBaseDestroyNotifyFuncType ObjectBase_destroy_notify_funcptr;

// From function with C linkage, to protected static member function with C++ linkage
extern "C"
{
static void ObjectBase_destroy_notify_callback(void* data)
{
  ObjectBase_destroy_notify_funcptr(data);
}
} // extern "C"

} // anonymous namespace

namespace Glib
{

/**** Glib::ObjectBase *****************************************************/

// Used only during the construction of named custom types.
struct ObjectBase::PrivImpl
{
  // Pointers to the interfaces of custom types.
  Class::interface_classes_type custom_interface_classes;
  // Pointers to extra class init functions.
  Class::class_init_funcs_type custom_class_init_functions;
  // Pointer to the instance init function.
  GInstanceInitFunc custom_instance_init_function = nullptr;
};

ObjectBase::ObjectBase()
: gobject_(nullptr),
  custom_type_name_(anonymous_custom_type_name),
  cpp_destruction_in_progress_(false)
{
}

ObjectBase::ObjectBase(const char* custom_type_name)
: gobject_(nullptr), custom_type_name_(custom_type_name),
  cpp_destruction_in_progress_(false)
{
}

ObjectBase::ObjectBase(const std::type_info& custom_type_info)
: gobject_(nullptr), custom_type_name_(custom_type_info.name()),
  cpp_destruction_in_progress_(false)
{
}

// initialize() actually initializes the wrapper.  Glib::ObjectBase is used
// as virtual base class, which means the most-derived class' ctor invokes
// the Glib::ObjectBase ctor -- thus it's useless for Glib::Object.
//
void
ObjectBase::initialize(GObject* castitem)
{
  if (gobject_)
  {
    // initialize() might be called twice when used with MI, e.g. by the ctors
    // of Glib::Object and Glib::Interface.  However, they must both refer to
    // the same underlying GObject instance.
    //
    g_assert(gobject_ == castitem);

    // TODO: Think about it.  Will this really be called twice?
    g_printerr("ObjectBase::initialize() called twice for the same GObject\n");

    return; // Don't initialize the wrapper twice.
  }

  gobject_ = castitem;
  _set_current_wrapper(castitem);
}

void
ObjectBase::initialize_move(GObject* castitem, Glib::ObjectBase* previous_wrapper)
{
  if (gobject_)
  {
    g_assert(gobject_ == castitem);

    // TODO: Think about it.  Will this really be called twice?
    g_printerr("ObjectBase::initialize_move() called twice for the same GObject\n");

    return; // Don't initialize the wrapper twice.
  }

  gobject_ = castitem;
  _move_current_wrapper(castitem, previous_wrapper);
  custom_type_name_ = previous_wrapper->custom_type_name_;
  cpp_destruction_in_progress_ = previous_wrapper->cpp_destruction_in_progress_;

  // Clear the previous wrapper:
  previous_wrapper->custom_type_name_ = nullptr;
  previous_wrapper->cpp_destruction_in_progress_ = false;
}

ObjectBase::ObjectBase(ObjectBase&& src) noexcept
  : sigc::trackable(std::move(src)), // not actually called because it's a virtual base
    gobject_(nullptr),
    custom_type_name_(src.custom_type_name_),
    cpp_destruction_in_progress_(src.cpp_destruction_in_progress_)
{
}

ObjectBase&
ObjectBase::operator=(ObjectBase&& src) noexcept
{
  if (this == &src)
    return *this;

  sigc::trackable::operator=(std::move(src));

  if (gobject_)
  {
    // Remove the wrapper, without invoking destroy_notify_callback_():
    g_object_steal_qdata(gobject_, Glib::quark_);
    // Remove a reference, without deleting *this.
    unreference();
    gobject_ = nullptr;
  }
  initialize_move(src.gobject_, &src);

  return *this;
}

ObjectBase::~ObjectBase() noexcept
{
  // Normally, gobject_ should always be 0 at this point, because:
  //
  // a) Gtk::Object handles memory management on its own and always resets
  //    the gobject_ pointer in its destructor.
  //
  // b) Glib::Object instances that aren't Gtk::Objects will always be
  //    deleted by the destroy_notify_() virtual method.  Calling delete
  //    on a Glib::Object is a programming error.
  //
  // The *only* situation where gobject_ is validly not 0 at this point
  // happens if a derived class's ctor throws an exception.  In that case
  // we have to call g_object_unref() on our own.
  //

  if (GObject* const gobject = gobject_)
  {
#ifdef GLIBMM_DEBUG_REFCOUNTING
    g_warning("(Glib::ObjectBase::~ObjectBase): gobject_ = %p", (void*)gobject_);
#endif

    gobject_ = nullptr;

#ifdef GLIBMM_DEBUG_REFCOUNTING
    g_warning("(Glib::ObjectBase::~ObjectBase): before g_object_steal_qdata()");
#endif

    // Remove the pointer to the wrapper from the underlying instance.
    // This does _not_ cause invocation of the destroy_notify callback.
    g_object_steal_qdata(gobject, quark_);

#ifdef GLIBMM_DEBUG_REFCOUNTING
    g_warning("(Glib::ObjectBase::~ObjectBase): calling g_object_unref()");
#endif

    g_object_unref(gobject);
  }
}

void
ObjectBase::reference() const
{
  GLIBMM_DEBUG_REFERENCE(this, gobject_);
  g_object_ref(gobject_);
}

void
ObjectBase::unreference() const
{
  GLIBMM_DEBUG_UNREFERENCE(this, gobject_);
  g_object_unref(gobject_);
}

GObject*
ObjectBase::gobj_copy() const
{
  reference();
  return gobject_;
}

void
ObjectBase::_set_current_wrapper(GObject* object)
{
  // Store a pointer to this wrapper in the underlying instance, so that we
  // never create a second wrapper for the same underlying instance.  Also,
  // specify a callback that will tell us when it's time to delete this C++
  // wrapper instance:

  if (object)
  {
    if (!g_object_get_qdata(object, Glib::quark_))
    {
      ObjectBase_destroy_notify_funcptr = &destroy_notify_callback_;
      g_object_set_qdata_full(object, Glib::quark_, this, &ObjectBase_destroy_notify_callback);
    }
    else
    {
      g_warning("This object, of type %s, already has a wrapper.\n"
                "You should use wrap() instead of a constructor.",
        G_OBJECT_TYPE_NAME(object));
    }
  }
}

void
ObjectBase::_move_current_wrapper(GObject* object, Glib::ObjectBase* previous_wrapper) noexcept
{
  // See _set_current_wrapper().
  ObjectBase* current_wrapper = _get_current_wrapper(object);
  if (current_wrapper != previous_wrapper)
  {
    g_warning("%s: Unexpected previous wrapper, for object of type %s.\n"
              "previous_wrapper=%p, current_wrapper=%p",
      G_STRFUNC, G_OBJECT_TYPE_NAME(object), static_cast<void*>(previous_wrapper),
      static_cast<void*>(current_wrapper));
  }

  // Remove the previous wrapper, without invoking destroy_notify_callback_():
  g_object_steal_qdata(object, Glib::quark_);

  // Set the new wrapper:
  g_object_set_qdata_full(object, Glib::quark_, this, &ObjectBase_destroy_notify_callback);

  // Clear the previous wrapper:
  previous_wrapper->gobject_ = nullptr;
}

// static
ObjectBase*
ObjectBase::_get_current_wrapper(GObject* object)
{
  if (object)
    return static_cast<ObjectBase*>(g_object_get_qdata(object, Glib::quark_));
  else
    return nullptr;
}

// static
void
ObjectBase::destroy_notify_callback_(void* data)
{
  // GLIBMM_LIFECYCLE

  // This method is called (indirectly) from g_object_run_dispose().
  // Get the C++ instance associated with the C instance:
  ObjectBase* cppObject =
    static_cast<ObjectBase*>(data); // Previously set with g_object_set_qdata_full().

#ifdef GLIBMM_DEBUG_REFCOUNTING
  g_warning("ObjectBase::destroy_notify_callback_: cppObject = %p, gobject_ = %p, gtypename = %s\n",
    (void*)cppObject, (void*)cppObject->gobject_, G_OBJECT_TYPE_NAME(cppObject->gobject_));
#endif

  if (cppObject) // This will be nullptr if the C++ destructor has already run.
  {
    cppObject->destroy_notify_(); // Virtual - it does different things for Glib::ObjectBase and Gtk::Object.
  }
}

void
ObjectBase::destroy_notify_()
{
// The C instance is about to be disposed, making it unusable.  Now is a
// good time to delete the C++ wrapper of the C instance.  There is no way
// to force the disposal of the GObject (though Gtk::Object::destroy_notify_()
// can call g_object_run_dispose()), so this is the *only* place where we delete
// the C++ wrapper.
//
// This will only happen after the last unreference(), which will be done by
// the RefPtr<> destructor.  There should be no way to access the wrapper or
// the underlying object instance after that, so it's OK to delete this.

#ifdef GLIBMM_DEBUG_REFCOUNTING
  g_warning("Glib::ObjectBase::destroy_notify_: gobject_ = %p", (void*)gobject_);
#endif

  gobject_ = nullptr; // Make sure we don't unref it again in the dtor.

  delete this;
}

bool
ObjectBase::is_anonymous_custom_() const
{
  // Doing high-speed pointer comparison is OK here.
  return (custom_type_name_ == anonymous_custom_type_name);
}

bool
ObjectBase::is_derived_() const
{
  // gtkmmproc-generated classes initialize this to 0 by default.
  return (custom_type_name_ != nullptr);
}

void
ObjectBase::set_manage()
{
  // This is a private method and Gtk::manage() is a template function.
  // Thus this will probably never run, unless you do something like:
  //
  // manage(static_cast<Gtk::Object*>(refptr.operator->()));

  g_error("Glib::ObjectBase::set_manage(): "
          "only Gtk::Object instances can be managed");
}

bool
ObjectBase::_cpp_destruction_is_in_progress() const
{
  return cpp_destruction_in_progress_;
}

void
ObjectBase::set_property_value(const Glib::ustring& property_name, const Glib::ValueBase& value)
{
  g_object_set_property(gobj(), property_name.c_str(), value.gobj());
}

void
ObjectBase::get_property_value(const Glib::ustring& property_name, Glib::ValueBase& value) const
{
  g_object_get_property(const_cast<GObject*>(gobj()), property_name.c_str(), value.gobj());
}

sigc::connection
ObjectBase::connect_property_changed(
  const Glib::ustring& property_name, const sigc::slot<void()>& slot)
{
  // Create a proxy to hold our connection info
  // This will be deleted by destroy_notify_handler.
  auto pConnectionNode = new PropertyProxyConnectionNode(slot, gobj());

  // connect it to glib
  // pConnectionNode will be passed as the data argument to the callback.
  return pConnectionNode->connect_changed(property_name);
}

sigc::connection
ObjectBase::connect_property_changed(
  const Glib::ustring& property_name, sigc::slot<void()>&& slot)
{
  // Create a proxy to hold our connection info
  // This will be deleted by destroy_notify_handler.
  auto pConnectionNode = new PropertyProxyConnectionNode(std::move(slot), gobj());

  // connect it to glib
  // pConnectionNode will be passed as the data argument to the callback.
  return pConnectionNode->connect_changed(property_name);
}

void
ObjectBase::freeze_notify()
{
  g_object_freeze_notify(gobj());
}

void
ObjectBase::thaw_notify()
{
  g_object_thaw_notify(gobj());
}

GType ObjectBase::get_base_type()
{
  return G_TYPE_OBJECT;
}

void ObjectBase::add_custom_interface_class(const Interface_Class* iface_class)
{
  if (!priv_pimpl_)
    priv_pimpl_ = std::make_unique<PrivImpl>();
  priv_pimpl_->custom_interface_classes.emplace_back(iface_class);
}

void ObjectBase::add_custom_class_init_function(GClassInitFunc class_init_func, void* class_data)
{
  if (!priv_pimpl_)
    priv_pimpl_ = std::make_unique<PrivImpl>();
  priv_pimpl_->custom_class_init_functions.emplace_back(
    std::make_tuple(class_init_func, class_data));
}

void ObjectBase::set_custom_instance_init_function(GInstanceInitFunc instance_init_func)
{
  if (!priv_pimpl_)
    priv_pimpl_ = std::make_unique<PrivImpl>();
  priv_pimpl_->custom_instance_init_function = instance_init_func;
}

const Class::interface_classes_type* ObjectBase::get_custom_interface_classes() const
{
  return priv_pimpl_ ? &priv_pimpl_->custom_interface_classes : nullptr;
}

const Class::class_init_funcs_type* ObjectBase::get_custom_class_init_functions() const
{
  return priv_pimpl_ ? &priv_pimpl_->custom_class_init_functions : nullptr;
}

GInstanceInitFunc ObjectBase::get_custom_instance_init_function() const
{
  return priv_pimpl_ ? priv_pimpl_->custom_instance_init_function : nullptr;
}

void ObjectBase::custom_class_init_finished()
{
  priv_pimpl_.reset();
}

/**** Global function *****************************************************/
bool
_gobject_cppinstance_already_deleted(GObject* gobject)
{
  // This function is used to prevent calling wrap() on a GTK+ instance whose gtkmm instance has
  // been deleted.

  if (gobject)
    return (bool)g_object_get_qdata(
      gobject, Glib::quark_cpp_wrapper_deleted_); // true means that something is odd.
  else
    return false; // Nothing is particularly wrong.
}

} // namespace Glib
