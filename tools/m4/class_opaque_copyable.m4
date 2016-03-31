dnl $Id$

dnl
dnl _CLASS_OPAQUE_COPYABLE(Region, GdkRegion, gdk_region_new, gdk_region_copy, gdk_region_destroy)
dnl

define(`_CLASS_OPAQUE_COPYABLE',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__OPAQUE_FUNC_NEW',`$3')
define(`__OPAQUE_FUNC_COPY',`$4')
define(`__OPAQUE_FUNC_FREE',`$5')

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
') dnl End of _CLASS_OPAQUE_COPYABLE.


dnl
dnl _END_CLASS_OPAQUE_COPYABLE()
dnl   denotes the end of a class
dnl
define(`_END_CLASS_OPAQUE_COPYABLE',`

_SECTION(SECTION_HEADER3)

__NAMESPACE_BEGIN__

/** @relates __NAMESPACE__::__CPPNAME__
 * @param lhs The left-hand side
 * @param rhs The right-hand side
 */
inline void swap(__CPPNAME__& lhs, __CPPNAME__& rhs) noexcept
  { lhs.swap(rhs); }

__NAMESPACE_END__

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

  /** A Glib::wrap() method for this object.
   * 
   * @param object The C instance.
   * @param take_copy False if the result should take ownership of the C instance. True if it should take a new copy or ref.
   * @result A C++ instance that wraps this C instance.
   *
   * @relates __NAMESPACE__::__CPPNAME__
   */
__NAMESPACE__::__CPPNAME__ wrap(__CNAME__* object, bool take_copy = false);

} // namespace Glib
')dnl endif __BOOL_NO_WRAP_FUNCTION__

_SECTION(SECTION_SRC_GENERATED)

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

__NAMESPACE__::__CPPNAME__ wrap(__CNAME__* object, bool take_copy /* = false */)
{
  return __NAMESPACE__::__CPPNAME__`'(object, take_copy);
}

} // namespace Glib
')dnl endif


__NAMESPACE_BEGIN__

dnl
dnl The implementation:
dnl

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',`dnl
',`dnl else
__CPPNAME__::__CPPNAME__`'()
:
ifelse(__OPAQUE_FUNC_NEW,NONE,`dnl
  gobject_ (nullptr) // Allows creation of invalid wrapper, e.g. for output arguments to methods.
',`dnl else
  gobject_ (__OPAQUE_FUNC_NEW`'())
')dnl
{}
')dnl endif __BOOL_CUSTOM_DEFAULT_CTOR__

__CPPNAME__::__CPPNAME__`'(const __CPPNAME__& src)
:
  gobject_ ((src.gobject_) ? __OPAQUE_FUNC_COPY`'(src.gobject_) : nullptr)
{}

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',,`dnl else
__CPPNAME__::__CPPNAME__`'(__CNAME__* castitem, bool make_a_copy /* = false */)
{
  if(!make_a_copy)
  {
    // It was given to us by a function which has already made a copy for us to keep.
    gobject_ = castitem;
  }
  else
  {
    // We are probably getting it via direct access to a struct,
    // so we can not just take it - we have to take a copy of it.
    if(castitem)
      gobject_ = __OPAQUE_FUNC_COPY`'(castitem);
    else
      gobject_ = nullptr;
  }
}
')

ifelse(__OPAQUE_FUNC_COPY,NONE,`dnl
',`dnl else
__CPPNAME__& __CPPNAME__::operator=(const __CPPNAME__`'& src)
{
  const auto new_gobject = (src.gobject_) ? __OPAQUE_FUNC_COPY`'(src.gobject_) : nullptr;

  if(gobject_)
    __OPAQUE_FUNC_FREE`'(gobject_);

  gobject_ = new_gobject;

  return *this;
}
')dnl

__CPPNAME__::__CPPNAME__`'(__CPPNAME__&& other) noexcept
:
  gobject_(other.gobject_)
{
  other.gobject_ = nullptr;
}

__CPPNAME__& __CPPNAME__::operator=(__CPPNAME__`'&& other) noexcept
{
  __CPPNAME__ temp (other);
  swap(temp);
  return *this;
}

__CPPNAME__::~__CPPNAME__`'() noexcept
{
  if(gobject_)
    __OPAQUE_FUNC_FREE`'(gobject_);
}

void __CPPNAME__::swap(__CPPNAME__& other) noexcept
{
  __CNAME__ *const temp = gobject_;
  gobject_ = other.gobject_;
  other.gobject_ = temp;
}

__CNAME__* __CPPNAME__::gobj_copy() const
{
  return __OPAQUE_FUNC_COPY`'(gobject_);
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

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',`dnl
',`dnl else
  /** Constructs an invalid object.
   * E.g. for output arguments to methods. There is not much you can do with
   * the object before it has been assigned a valid value.
   */
  __CPPNAME__`'();
')dnl

  // Use make_a_copy=true when getting it directly from a struct.
  explicit __CPPNAME__`'(__CNAME__* castitem, bool make_a_copy = false);

  __CPPNAME__`'(const __CPPNAME__& src);
  __CPPNAME__& operator=(const __CPPNAME__& src);

  __CPPNAME__`'(__CPPNAME__&& other) noexcept;
  __CPPNAME__& operator=(__CPPNAME__&& other) noexcept;

_IMPORT(SECTION_DTOR_DOCUMENTATION)
  ~__CPPNAME__`'() noexcept;

  void swap(__CPPNAME__& other) noexcept;

  __CNAME__*       gobj()       { return gobject_; }
  const __CNAME__* gobj() const { return gobject_; }

  ///Provides access to the underlying C instance. The caller is responsible for freeing it. Use when directly setting fields in structs.
  __CNAME__* gobj_copy() const;

protected:
  __CNAME__* gobject_;

private:
_IMPORT(SECTION_CLASS2)
')

