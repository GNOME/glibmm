// -*- c++ -*-
#ifndef _GLIBMM_OBJECT_H
#define _GLIBMM_OBJECT_H
/* $Id$ */

/* Copyright 2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm/objectbase.h>
#include <glibmm/wrap.h>
#include <glibmm/quark.h>
#include <glibmm/refptr.h>
#include <glibmm/utility.h> /* Could be private, but that would be tedious. */
#include <glibmm/value.h>

#ifndef DOXYGEN_SHOULD_SKIP_THIS
extern "C"
{
typedef struct _GObject GObject;
typedef struct _GObjectClass GObjectClass;
}
#endif /* DOXYGEN_SHOULD_SKIP_THIS */


namespace Glib
{

#ifndef DOXYGEN_SHOULD_SKIP_THIS

class Class;
class Object_Class;
class GSigConnectionNode;

/* ConstructParams::ConstructParams() takes a varargs list of properties
 * and values, like g_object_new() does.  This list will then be converted
 * to a GParameter array, for use with g_object_newv().  No overhead is
 * involved, since g_object_new() is just a wrapper around g_object_newv()
 * as well.
 *
 * The advantage of an auxilary ConstructParams object over g_object_new()
 * is that the actual construction is always done in the Glib::Object ctor.
 * This allows for neat tricks like easy creation of derived custom types,
 * without adding special support to each ctor of every class.
 *
 * The comments in object.cc and objectbase.cc should explain in detail
 * how this works.
 */
struct ConstructParams
{
  const Glib::Class&  glibmm_class;
  unsigned int        n_parameters;
  GParameter*         parameters;

  explicit ConstructParams(const Glib::Class& glibmm_class_);
  ConstructParams(const Glib::Class& glibmm_class_, const char* first_property_name, ...);
  ~ConstructParams();

private:
  // noncopyable
  ConstructParams(const ConstructParams&);
  ConstructParams& operator=(const ConstructParams&);
};

#endif /* DOXYGEN_SHOULD_SKIP_THIS */


class Object : virtual public ObjectBase
{
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  typedef Object       CppObjectType;
  typedef Object_Class CppClassType;
  typedef GObject      BaseObjectType;
  typedef GObjectClass BaseClassType;
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

protected:
  Object(); //For use by C++-only sub-types.
  explicit Object(const Glib::ConstructParams& construct_params);
  explicit Object(GObject* castitem);
  virtual ~Object(); //It should only be deleted by the callback.

public:
  //static RefPtr<Object> create(); //You must reimplement this in each derived class.

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  static GType get_type()      G_GNUC_CONST;
  static GType get_base_type() G_GNUC_CONST;
#endif

  //GObject* gobj_copy(); //Give a ref-ed copy to someone. Use for direct struct access.

  // Glib::Objects contain a list<Quark, pair<void*, DestroyNotify> >
  // to store run time data added to the object at run time.
  //TODO: Use slots instead:
  void* get_data(const QueryQuark &key);
  void set_data(const Quark &key, void* data);
  typedef void (*DestroyNotify) (gpointer data);
  void set_data(const Quark &key, void* data, DestroyNotify notify);
  void remove_data(const QueryQuark& quark);
  // same as remove without notifying
  void* steal_data(const QueryQuark& quark);

  // convenience functions
  //template <class T>
  //void set_data_typed(const Quark& quark, const T& data)
  //  { set_data(quark, new T(data), delete_typed<T>); }

  //template <class T>
  //T& get_data_typed(const QueryQuark& quark)
  //  { return *static_cast<T*>(get_data(quark)); }

#ifndef DOXYGEN_SHOULD_SKIP_THIS

private:
  friend class Glib::Object_Class;
  static CppClassType object_class_;

  // noncopyable
  Object(const Object&);
  Object& operator=(const Object&);

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

  // Glib::Object can not be dynamic because it lacks a float state.
  //virtual void set_manage();
};

} // namespace Glib

#endif /* _GLIBMM_OBJECT_H */

