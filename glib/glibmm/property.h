#ifndef _GLIBMM_PROPERTY_H
#define _GLIBMM_PROPERTY_H

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

#include <glibmmconfig.h>
#include <glibmm/propertyproxy.h>
#include <glibmm/value.h>

namespace Glib
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS

#ifdef GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC
// For the AIX xlC compiler, I can not find a way to do this without putting the functions in the
// global namespace. murrayc
extern "C" {
#endif // GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC

void custom_get_property_callback(
  GObject* object, unsigned int property_id, GValue* value, GParamSpec* param_spec);

void custom_set_property_callback(
  GObject* object, unsigned int property_id, const GValue* value, GParamSpec* param_spec);

#ifdef GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC
} // extern "C"
#endif // GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/** This is the base class for Glib::Object properties.
 *
 * This class manages the generic parts of the object properties.
 * Derived (templated) classes handle the specific value types.
 */
class PropertyBase
{
public:
  // noncopyable
  PropertyBase(const PropertyBase&) = delete;
  PropertyBase& operator=(const PropertyBase&) = delete;

  /** Returns the name of the property.
   */
  Glib::ustring get_name() const;

  /** Notifies the object containing the property that the property has changed.
   * This emits the "notify" signal, passing the property name.
   */
  void notify();

protected:
  Glib::Object* object_;
  Glib::ValueBase value_;
  GParamSpec* param_spec_;

  /** This constructs a property of type @a value_type for the @a object.
   * The property is not registered in the GObject object system
   * until install_property() has been called. Derived classes do this in
   * their constructors.
   *
   * The properties are usually installed during the initialization of the
   * first instance of an object.
   */
  PropertyBase(Glib::Object& object, GType value_type);
  ~PropertyBase() noexcept;

  /**
   * Checks if the property has already been installed.
   */
  bool lookup_property(const Glib::ustring& name);

  /**
   * Installs the property specified by the given @a param_spec.
   */
  void install_property(GParamSpec* param_spec);

  /**
   * Returns the name of the property.
   */
  const char* get_name_internal() const;

private:
#ifndef DOXYGEN_SHOULD_SKIP_THIS

  friend void Glib::custom_get_property_callback(
    GObject* object, unsigned int property_id, GValue* value, GParamSpec* param_spec);

  friend void Glib::custom_set_property_callback(
    GObject* object, unsigned int property_id, const GValue* value, GParamSpec* param_spec);

#endif /* DOXYGEN_SHOULD_SKIP_THIS */
};

/** A Glib::Object property.
 *
 * This class wraps a GObject property, providing a C++ API to the GObject property
 * system, for use with classes derived from Glib::Object or Glib::Interface.
 *
 * A property is a value associated with each instance of a type and some
 * class data for each property:
 *  * Its unique name, used to identify the property.
 *  * A human-readable nick name.
 *  * A short description.
 *  * The default value and the minimum and maximum bounds (depending on the type of the property).
 *  * Flags, defining, among other things, whether the property can be read or written.
 *
 * This Property class currently supports only the name and default value. The
 * minimum and maximum bounds are set to the full range of the value. The nick
 * and the explanation are set to empty. The flags are set to indicate that the
 * property can be both read from and written to.
 *
 * The class information must be installed into the GObject system once per
 * property, but this is handled automatically.
 *
 * Each property belongs to an object, inheriting from Glib::Object.
 * A reference to the object must be passed to the constructor of the property.
 *
 * Each instance of a Glib::Object-derived type must construct the same properties
 * (same type, same name) in the same order. One way to achieve this is to
 * declare all properties as direct data members of the type.
 *
 * You may register new properties for your class (actually for the underlying GType)
 * simply by adding a Property instance as a class member.
 * However, your constructor must call the Glib::ObjectBase constructor with a new GType name,
 * in order to register a new GType.
 *
 * Example:
 * @code
 * class MyCellRenderer : public Gtk::CellRenderer
 * {
 * public:
 *   MyCellRenderer()
 *   :
 *   Glib::ObjectBase (typeid(MyCellRenderer)),
 *   Gtk::CellRenderer(),
 *   property_mybool  (*this, "mybool", true),
 *   property_myint_  (*this, "myint",    42)
 *   {}
 *
 *   virtual ~MyCellRenderer() {}
 *
 *   // Glib::Property<> can be public,
 *   Glib::Property<bool> property_mybool;
 *   // or private, and combined with Glib::PropertyProxy<>.
 *   Glib::PropertyProxy<int> property_myint() { return property_myint_.get_proxy(); }
 *
 * private:
 *   Glib::Property<int> property_myint_;
 * };
 * @endcode
 */
template <class T>
class Property : public PropertyBase
{
public:
  using PropertyType = T;
  using ValueType = Glib::Value<T>;

  /**  Constructs a property of the @a object with the specified @a name.
   * For each instance of the object, the same property must be constructed with the same name.
   */
  Property(Glib::Object& object, const Glib::ustring& name);

  /** Constructs a property of the @a object with the specified @a name and @a default_value.
   * For  each instance of the object, the same property must be constructed with the same name.
   */
  Property(Glib::Object& object, const Glib::ustring& name, const PropertyType& default_value);

  /** Sets the value of the property to @a data.
   * The object containing the property will be notified about the change.
   */
  inline void set_value(const PropertyType& data);

  /** Returns the value of the property.
   */
  inline PropertyType get_value() const;

  /** Sets the value of the property to @a data.
   * The object containing the property will be notified about the change.
   */
  inline Property<T>& operator=(const PropertyType& data);

  /** Returns the value of the property.
   */
  inline operator PropertyType() const;

  /** Returns a proxy object that can be used to manipulate this property.
   */
  inline Glib::PropertyProxy<T> get_proxy();
};

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::Property<T> ****************************************************/

template <class T>
Property<T>::Property(Glib::Object& object, const Glib::ustring& name)
: PropertyBase(object, ValueType::value_type())
{
  if (!lookup_property(name))
    install_property(static_cast<ValueType&>(value_).create_param_spec(name));
}

template <class T>
Property<T>::Property(Glib::Object& object, const Glib::ustring& name,
  const typename Property<T>::PropertyType& default_value)
: PropertyBase(object, ValueType::value_type())
{
  static_cast<ValueType&>(value_).set(default_value);

  if (!lookup_property(name))
    install_property(static_cast<ValueType&>(value_).create_param_spec(name));
}

template <class T>
inline void
Property<T>::set_value(const typename Property<T>::PropertyType& data)
{
  static_cast<ValueType&>(value_).set(data);
  this->notify();
}

template <class T>
inline typename Property<T>::PropertyType
Property<T>::get_value() const
{
  return static_cast<const ValueType&>(value_).get();
}

template <class T>
inline Property<T>&
Property<T>::operator=(const typename Property<T>::PropertyType& data)
{
  static_cast<ValueType&>(value_).set(data);
  this->notify();
  return *this;
}

template <class T>
inline Property<T>::operator T() const
{
  return static_cast<const ValueType&>(value_).get();
}

template <class T>
inline Glib::PropertyProxy<T>
Property<T>::get_proxy()
{
  return Glib::PropertyProxy<T>(object_, get_name_internal());
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

#endif /* _GLIBMM_PROPERTY_H */
