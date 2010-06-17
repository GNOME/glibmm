#ifndef _GLIBMM_VARIANT_H
#define _GLIBMM_VARIANT_H

/* Copyright 2010 The gtkmm Development Team
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
#include <glibmm/ustring.h>
#include <glib-object.h>

namespace Glib
{

/** @defgroup glibmmVariant Variant Datatype
 *
 * Glib::Variant<> are specialized classes that deal with strongly typed
 * variant data.  They are used to wrap glib's GVariant API.  For more
 * information see the <a
 * href="http://library.gnome.org/devel/glib/stable/glib-GVariant.html">glib
 * variant
 * API</a>.
 */

/**
 * @ingroup glibmmVariant
 */
class VariantBase
{
public:
  /** Default constructor.
   * @newin{2,26}
   */
  VariantBase();

  /** Constructs a VariantBase from a GVariant.
   * @newin{2,26}
   */
  explicit VariantBase(GVariant* castitem);

  /** Copy constructor.  Since GVariant is reference counted, the copy
   * constructor simply copies the underlying GVariant* and increases its
   * reference count.
   * @newin{2,26}
   */
  VariantBase(const VariantBase& other);

  /** Assignment operator.  Since GVariant is reference counted, assignment
   * simply copies the underlying GVariant* and increases its reference count.
   * @newin{2,26}
   */
  VariantBase& operator=(const VariantBase& other);

  /** Get the underlying GVariant.
   * @return The underlying GVariant.
   * @newin{2,26}
   */
  GVariant*       gobj()       { return gobject_; }

  /** Get the underlying GVariant.
   * @return The underlying GVariant.
   * @newin{2,26}
   */
  const GVariant* gobj() const { return gobject_; }

  /** Tells if the variant contains another variant.
   * @return Whether the variant is container.
   * @newin{2,26}
   */
  bool is_container() const;
    
  /** Tells the class of the variant.
   * @return The class of the variant.
   * @newin{2,26}
   */
  GVariantClass classify() const;

  virtual ~VariantBase();

protected:
  GVariant* gobject_;
};

/** Template class from which other Glib::Variant<> specializations derive.
 * @ingroup glibmmVariant
 */
template <class T>
class Variant : public VariantBase
{
public:
  typedef T CppType;
};


/****************** Specializations ***********************************/

/// @ingroup glibmmVariant
template <>
class Variant<VariantBase> : public VariantBase
{
  typedef GVariant* CType;

  Variant<VariantBase>() : VariantBase() { }
  Variant<VariantBase>(GVariant* castitem) : VariantBase(castitem) { }
  static const GVariantType* variant_type() G_GNUC_CONST;
  static Variant<VariantBase> create(Glib::VariantBase& data);
  VariantBase get() const;
};

/// @ingroup glibmmVariant
template <>
class Variant<Glib::ustring> : public VariantBase
{
  typedef char* CType;

  Variant<Glib::ustring>() : VariantBase() { }
  Variant<Glib::ustring>(GVariant* castitem) : VariantBase(castitem) { }
  static const GVariantType* variant_type() G_GNUC_CONST;
  static Variant<Glib::ustring> create(const Glib::ustring& data);
  Glib::ustring get() const;
};

} // namespace Glib


/* Include generated specializations of Glib::Variant<> for fundamental types:
 */
#define _GLIBMM_VARIANT_H_INCLUDE_VARIANT_BASICTYPES_H
#include <glibmm/variant_basictypes.h>
#undef _GLIBMM_VARIANT_H_INCLUDE_VARIANT_BASICTYPES_H


#endif /* _GLIBMM_VARIANT_H */
