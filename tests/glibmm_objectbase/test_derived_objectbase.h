#ifndef _GLIBMM_TEST_DERIVED_OBJECTBASE_H
#define _GLIBMM_TEST_DERIVED_OBJECTBASE_H

#include <glibmm.h>

class DerivedObjectBase : public Glib::ObjectBase
{
public:
  // A real application would never make the constructor public.
  // It would instead have a protected constructor and a public create() method.
  DerivedObjectBase(GObject* gobject, int i) : Glib::ObjectBase(nullptr), i_(i)
  {
    Glib::ObjectBase::initialize(gobject);
  }

  DerivedObjectBase(const DerivedObjectBase& src) = delete;
  DerivedObjectBase& operator=(const DerivedObjectBase& src) = delete;

  DerivedObjectBase(DerivedObjectBase&& src) noexcept : Glib::ObjectBase(std::move(src)),
                                                        i_(std::move(src.i_))
  {
    ObjectBase::initialize_move(src.gobject_, &src);
  }

  DerivedObjectBase& operator=(DerivedObjectBase&& src) noexcept
  {
    Glib::ObjectBase::operator=(std::move(src));
    i_ = std::move(src.i_);

    return *this;
  }

  int i_;
};

#endif // _GLIBMM_TEST_DERIVED_OBJECTBASE_H
