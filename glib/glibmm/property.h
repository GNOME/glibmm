// -*- c++ -*-
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
//For the AIX xlC compiler, I can not find a way to do this without putting the functions in the global namespace. murrayc
extern "C"
{
#endif //GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC

void custom_get_property_callback(GObject* object, unsigned int property_id,
                                  GValue* value, GParamSpec* param_spec);

void custom_set_property_callback(GObject* object, unsigned int property_id,
                                  const GValue* value, GParamSpec* param_spec);

#ifdef GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC
} //extern "C"
#endif //GLIBMM_CXX_CAN_USE_NAMESPACES_INSIDE_EXTERNC

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/**
 * Base class for object properties
 * 
 * This class manages the value type-agnostic bits of object properties. 
 */
class PropertyBase
{
public:

  /**
   * Returns the name of the property
   */
  Glib::ustring get_name() const;
  
  /**
   * Notifies the object containing the property that the property has changed.
   * In other words, emits "notify" signal with the property name.
   */
  void notify();

protected:
  Glib::Object*   object_;
  Glib::ValueBase value_;
  GParamSpec*     param_spec_;

  /**
   * Constructs the property of type @a value_type for @a object. The property
   * is not registered in the GObject object system, call install_property in
   * order to do that. The properties are usually installed on the 
   * initialization of the first instance of an object.
   */
  PropertyBase(Glib::Object& object, GType value_type);
  ~PropertyBase();

  /**
   * Checks if the property has already been installed
   */
  bool lookup_property(const Glib::ustring& name);
  
  /**
   * Installs the property specified by the given @a param_spec.
   */
  void install_property(GParamSpec* param_spec);

  /**
   * Returns the name of the property
   */
  const char* get_name_internal() const;

private:
  // noncopyable
  PropertyBase(const PropertyBase&);
  PropertyBase& operator=(const PropertyBase&);

#ifndef DOXYGEN_SHOULD_SKIP_THIS

  friend void Glib::custom_get_property_callback(GObject* object, unsigned int property_id,
                                                 GValue* value, GParamSpec* param_spec);

  friend void Glib::custom_set_property_callback(GObject* object, unsigned int property_id,
                                                 const GValue* value, GParamSpec* param_spec);

#endif /* DOXYGEN_SHOULD_SKIP_THIS */
};

/**
 * Represents an object property
 * 
 * This class maps one to one to a property of an object in GObject object 
 * system. A property is a value associated to each instancy of a type and some
 * global data for each property. The global data encompasses the following 
 * information about the property:
 *  * unique name, used to identify the property
 *  * human-readable nick
 *  * short explanation
 *  * default value, minimum and maximum bounds (applicable depending on the 
 *      type of the property)
 *  * flags, defining, among other things, whether the property can be read or
 *      written
 * 
 * The Property class currently supports only the name and default value. The
 * minimum and maximum bounds are set to the full range of the value. The nick
 * and the explanation are set to empty. The flags are set to indicate that the
 * property can be both read from and written to.
 * 
 * The global information must be installed into the GObject system once per 
 * property. This is handled automatically.
 * 
 * A property can be used only as direct data member of a type, inheriting from
 * Glib::Object. A reference to the object must be passed on the construction of
 * the property.
 */
template <class T>
class Property : public PropertyBase
{
public:
  typedef T PropertyType;
  typedef Glib::Value<T> ValueType;

  /**
   * Constructs a property of @a object with @a name. For each instance of the 
   * object, the same property must be constructed with the same name
   */
  Property(Glib::Object& object, const Glib::ustring& name);
  
  /**
   * Constructs a property of @a object with @a name and @a default_value. For 
   * each instance of the object, the same property must be constructed with the 
   * same name
   */
  Property(Glib::Object& object, const Glib::ustring& name, const PropertyType& default_value);

  /**
   * Sets the value of the property to @a data. The object containing the 
   * property is notified about the change.
   */
  inline void set_value(const PropertyType& data);
  
  /**
   * Returns the value of the property
   */
  inline PropertyType get_value() const;

  /**
   * Sets the value of the property to @a data. The object containing the 
   * property is notified about the change.
   */
  inline Property<T>& operator=(const PropertyType& data);
  
  /**
   * Returs the value of the property
   */
  inline operator PropertyType() const;

  /**
   * Returns a proxy object that can be used to manipulate this property
   */
  inline Glib::PropertyProxy<T> get_proxy();
};


#ifndef DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::Property<T> ****************************************************/

template <class T>
Property<T>::Property(Glib::Object& object, const Glib::ustring& name)
:
  PropertyBase(object, ValueType::value_type())
{
  if(!lookup_property(name))
    install_property(static_cast<ValueType&>(value_).create_param_spec(name));
}

template <class T>
Property<T>::Property(Glib::Object& object, const Glib::ustring& name,
                      const typename Property<T>::PropertyType& default_value)
:
  PropertyBase(object, ValueType::value_type())
{
  static_cast<ValueType&>(value_).set(default_value);

  if(!lookup_property(name))
    install_property(static_cast<ValueType&>(value_).create_param_spec(name));
}

template <class T> inline
void Property<T>::set_value(const typename Property<T>::PropertyType& data)
{
  static_cast<ValueType&>(value_).set(data);
  this->notify();
}

template <class T> inline
typename Property<T>::PropertyType Property<T>::get_value() const
{
  return static_cast<const ValueType&>(value_).get();
}

template <class T> inline
Property<T>& Property<T>::operator=(const typename Property<T>::PropertyType& data)
{
  static_cast<ValueType&>(value_).set(data);
  this->notify();
  return *this;
}

template <class T> inline
Property<T>::operator T() const
{
  return static_cast<const ValueType&>(value_).get();
}

template <class T> inline
Glib::PropertyProxy<T> Property<T>::get_proxy()
{
  return Glib::PropertyProxy<T>(object_, get_name_internal());
}

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib


#endif /* _GLIBMM_PROPERTY_H */

