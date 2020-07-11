dnl $Id$

dnl
dnl _CLASS_BOXEDTYPE(Region, GdkRegion, gdk_region_new, gdk_region_copy, gdk_region_destroy, api_decoration)
dnl

define(`_CLASS_BOXEDTYPE',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__BOXEDTYPE_FUNC_NEW',`$3')
define(`__BOXEDTYPE_FUNC_COPY',`$4')
define(`__BOXEDTYPE_FUNC_FREE',`$5')
define(`__BOXEDTYPE_FUNC_DECORATION',`$6')

define(`_CUSTOM_DEFAULT_CTOR',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_DEFAULT_CTOR__',`$1')
_POP()
')

define(`_CUSTOM_CTOR_CAST',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_CTOR_CAST__',`$1')
_POP()
')

_POP()
_SECTION(SECTION_CLASS2)
') dnl End of _CLASS_BOXEDTYPE.

dnl Some of the Gdk types are unions - e.g. GdkEvent.
define(`_CUSTOM_STRUCT_PROTOTYPE',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_STRUCT_PROTOTYPE__',`$1')
_POP()
')

dnl
dnl _END_CLASS_BOXEDTYPE()
dnl   denotes the end of a class
dnl
define(`_END_CLASS_BOXEDTYPE',`
_SECTION(SECTION_HEADER1)
ifdef(`__BOOL_CUSTOM_STRUCT_PROTOTYPE__',`dnl
',`dnl
#ifndef DOXYGEN_SHOULD_SKIP_THIS
extern "C" { typedef struct _`'__CNAME__ __CNAME__; }
#endif
')dnl

_SECTION(SECTION_HEADER3)

__NAMESPACE_BEGIN__

/** @relates __NAMESPACE__::__CPPNAME__
 * @param lhs The left-hand side
 * @param rhs The right-hand side
 */
inline void swap(__CPPNAME__& lhs, __CPPNAME__& rhs) noexcept
  { lhs.swap(rhs); }

__NAMESPACE_END__

namespace Glib
{
ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else

/** A Glib::wrap() method for this object.
 *
 * @param object The C instance.
 * @param take_copy False if the result should take ownership of the C instance. True if it should take a new copy or ref.
 * @result A C++ instance that wraps this C instance.
 *
 * @relates __NAMESPACE__::__CPPNAME__
 */
__BOXEDTYPE_FUNC_DECORATION
__NAMESPACE__::__CPPNAME__ wrap(__CNAME__* object, bool take_copy = false);
')dnl endif __BOOL_NO_WRAP_FUNCTION__

#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <>
class __BOXEDTYPE_FUNC_DECORATION Value<__NAMESPACE__::__CPPNAME__> : public Glib::Value_Boxed<__NAMESPACE__::__CPPNAME__>
{};
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

_SECTION(SECTION_SRC_GENERATED)

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

__NAMESPACE__::__CPPNAME__ wrap(__CNAME__* object, bool take_copy)
{
  return __NAMESPACE__::__CPPNAME__`'(object, take_copy);
}

} // namespace Glib
')dnl endif


__NAMESPACE_BEGIN__

dnl
dnl The implementation:
dnl

// static
GType __CPPNAME__::get_type()
{
  return _GET_TYPE_FUNC(__CNAME__);
}

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',`dnl
',`dnl else
__CPPNAME__::__CPPNAME__`'()
:
ifelse(__BOXEDTYPE_FUNC_NEW,NONE,`dnl
  gobject_ (nullptr) // Allows creation of invalid wrapper, e.g. for output arguments to methods.
',`dnl else
  gobject_ (__BOXEDTYPE_FUNC_NEW`'())
')dnl
{}
')dnl endif __BOOL_CUSTOM_DEFAULT_CTOR__

__CPPNAME__::__CPPNAME__`'(const __CPPNAME__& other)
:
  gobject_ ((other.gobject_) ? __BOXEDTYPE_FUNC_COPY`'(other.gobject_) : nullptr)
{}

__CPPNAME__::__CPPNAME__`'(__CPPNAME__&& other) noexcept
:
  gobject_(other.gobject_)
{
  other.gobject_ = nullptr;
}

__CPPNAME__& __CPPNAME__::operator=(__CPPNAME__`'&& other) noexcept
{
  __CPPNAME__ temp (std::move(other));
  swap(temp);
  return *this;
}

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',,`dnl else
__CPPNAME__::__CPPNAME__`'(__CNAME__* gobject, bool make_a_copy)
:
  // For BoxedType wrappers, make_a_copy is true by default.  The static
  // BoxedType wrappers must always take a copy, thus make_a_copy = true
  // ensures identical behaviour if the default argument is used.
  gobject_ ((make_a_copy && gobject) ? __BOXEDTYPE_FUNC_COPY`'(gobject) : gobject)
{}
')dnl

__CPPNAME__& __CPPNAME__::operator=(const __CPPNAME__`'& other)
{
  __CPPNAME__ temp (other);
  swap(temp);
  return *this;
}

__CPPNAME__::~__CPPNAME__`'() noexcept
{
dnl This could be a free or an unref, we do not need to know.
  if(gobject_)
    __BOXEDTYPE_FUNC_FREE`'(gobject_);
}

void __CPPNAME__::swap(__CPPNAME__& other) noexcept
{
  std::swap(gobject_, other.gobject_);
}

__CNAME__* __CPPNAME__::gobj_copy() const
{
  return __BOXEDTYPE_FUNC_COPY`'(gobject_);
}

_IMPORT(SECTION_CC)

__NAMESPACE_END__


dnl
dnl
dnl
dnl
_POP()
dnl
dnl
dnl The actual class, e.g. Pango::FontDescription, declaration:
dnl
_IMPORT(SECTION_CLASS1)
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  using CppObjectType = __CPPNAME__;
  using BaseObjectType = __CNAME__;
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

  /** Get the GType for this class, for use with the underlying GObject type system.
   */
  static GType get_type() G_GNUC_CONST;

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',`dnl
',`dnl else
  __CPPNAME__`'();
')dnl

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',,`dnl else
  explicit __CPPNAME__`'(__CNAME__* gobject, bool make_a_copy = true);
')dnl

  __CPPNAME__`'(const __CPPNAME__& other);
  __CPPNAME__& operator=(const __CPPNAME__& other);

  __CPPNAME__`'(__CPPNAME__&& other) noexcept;
  __CPPNAME__& operator=(__CPPNAME__&& other) noexcept;

_IMPORT(SECTION_DTOR_DOCUMENTATION)
  ~__CPPNAME__`'() noexcept;

  void swap(__CPPNAME__& other) noexcept;

  ///Provides access to the underlying C instance.
  __CNAME__*       gobj()       { return gobject_; }

  ///Provides access to the underlying C instance.
  const __CNAME__* gobj() const { return gobject_; }

  ///Provides access to the underlying C instance. The caller is responsible for freeing it. Use when directly setting fields in structs.
  __CNAME__* gobj_copy() const;

protected:
  __CNAME__* gobject_;

private:
_IMPORT(SECTION_CLASS2)
')

