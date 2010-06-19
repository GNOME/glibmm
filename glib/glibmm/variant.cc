/* $Id$ */

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

#include <glibmm/variant.h>
#include <glibmm/objectbase.h>
#include <glibmm/utility.h>
#include <glibmm/wrap.h>


namespace Glib
{

/**** Glib::VariantBase ****************************************************/

VariantBase::VariantBase()
  : gobject_(0)
{
}

VariantBase::VariantBase(GVariant *castitem)
  : gobject_(castitem)
{
  //TODO: It would be nice to remove a possible floating reference but the C
  //API makes it difficult.
  if(castitem)
    g_variant_ref(castitem);
}

VariantBase::VariantBase(const VariantBase& other)
{
  // The copy constructor simply copies the underlying GVariant* and increases
  // its reference.  The reference is decreased upon destruction.
  gobject_ = other.gobject_;

  if(gobject_)
    g_variant_ref(gobject_);
}

VariantBase& VariantBase::operator=(const VariantBase& other)
{
  // Check against self-assignment and simply copy the underlying GVariant*,
  // increasing its reference.
  if( this != &other)
  {
    gobject_ = other.gobject_;

    if(gobject_)
      g_variant_ref(gobject_);
  }
  return *this;
}

VariantBase::~VariantBase()
{
  if(gobject_)
    g_variant_unref(gobject_);
}

bool VariantBase::is_container() const
{
  return
    static_cast<bool>(g_variant_is_container(const_cast<GVariant*>(gobj())));
}

GVariantClass VariantBase::classify() const
{
  return g_variant_classify(const_cast<GVariant*>(gobj()));
}


/****************** Specializations ***********************************/

// static
const GVariantType* Variant<VariantBase>::variant_type()
{
  return G_VARIANT_TYPE_VARIANT;
}

Variant<VariantBase> Variant<VariantBase>::create(VariantBase& data)
{
  return Variant<VariantBase>(g_variant_new_variant(data.gobj()));
}

VariantBase Variant<VariantBase>::get() const
{
  return VariantBase(g_variant_get_variant(gobject_));
}

// static
const GVariantType* Variant<Glib::ustring>::variant_type()
{
  return G_VARIANT_TYPE_STRING;
}

Variant<Glib::ustring>
Variant<Glib::ustring>::create(const Glib::ustring& data)
{
  return Variant<Glib::ustring>(g_variant_new_string(data.c_str()));
}

Glib::ustring Variant<Glib::ustring>::get() const
{
  return Glib::ustring(g_variant_get_string(gobject_, 0));
}

} // namespace Glib
