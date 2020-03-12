dnl $Id$

dnl
dnl _CLASS_BOXEDTYPE_STATIC(TreeIter, GtkTreeIter, api_decoration)
dnl
define(`_CLASS_BOXEDTYPE_STATIC',`dnl
_PUSH()
dnl
dnl Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__FUNC_DECORATION__',`$3')

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
') dnl End of _CLASS_BOXEDTYPE_STATIC.

dnl TreeIterBase shouldn't have a wrap() method - we'll custom implement them for TreeIter and TreeRow:
define(`_NO_WRAP_FUNCTION',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_NO_WRAP_FUNCTION__',`$1')
_POP()
')

dnl
dnl _END_CLASS_BOXEDTYPE_STATIC()
dnl denotes the end of a class
dnl
define(`_END_CLASS_BOXEDTYPE_STATIC',`

_SECTION(SECTION_HEADER3)

namespace Glib
{
ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else

/** @relates __NAMESPACE__::__CPPNAME__
 * @param object The C instance
 * @result A C++ instance that wraps this C instance.
 */
__FUNC_DECORATION__
__NAMESPACE__::__CPPNAME__& wrap(__CNAME__* object);

/** @relates __NAMESPACE__::__CPPNAME__
 * @param object The C instance
 * @result A C++ instance that wraps this C instance.
 */
__FUNC_DECORATION__
const __NAMESPACE__::__CPPNAME__& wrap(const __CNAME__* object);
')dnl endif __BOOL_NO_WRAP_FUNCTION__

#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <>
class __FUNC_DECORATION__ Value<__NAMESPACE__::__CPPNAME__> : public Glib::Value_Boxed<__NAMESPACE__::__CPPNAME__>
{};
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

_SECTION(SECTION_CC_INCLUDES)
#include <cstring> // std::memset`'()
_SECTION(SECTION_SRC_GENERATED)

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

__NAMESPACE__::__CPPNAME__& wrap(__CNAME__* object)
{
  return *reinterpret_cast<__NAMESPACE__::__CPPNAME__*>(object);
}

const __NAMESPACE__::__CPPNAME__& wrap(const __CNAME__* object)
{
  return *reinterpret_cast<const __NAMESPACE__::__CPPNAME__*>(object);
}

} // namespace Glib
')dnl endif __BOOL_NO_WRAP_FUNCTION__


__NAMESPACE_BEGIN__

dnl
dnl The implementation:
dnl

__CPPNAME__::__CPPNAME__`'(const __CPPNAME__& other) noexcept
:
  gobject_(other.gobject_)
{
}

__CPPNAME__& __CPPNAME__::operator=(const __CPPNAME__`'& other) noexcept
{
  gobject_ = other.gobject_;
  return *this;
}

__CPPNAME__::__CPPNAME__`'(__CPPNAME__&& other) noexcept
:
  gobject_(std::move(other.gobject_))
{
  //We could wipe other.gobject_ via memset,
  //but that is not really necessary:
  //other.gobject_ = nullptr;
}

__CPPNAME__& __CPPNAME__::operator=(__CPPNAME__`'&& other) noexcept
{
  gobject_ = std::move(other.gobject_);
  return *this;
}

dnl // static
dnl const __CNAME__ __CPPNAME__::gobject_initializer_ = { 0, };
dnl
// static
GType __CPPNAME__::get_type()
{
  return _GET_TYPE_FUNC(__CNAME__);
}

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',,`dnl else
__CPPNAME__::__CPPNAME__`'()
{
  std::memset`'(&gobject_, 0, sizeof(__CNAME__));
}
')dnl

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',,`dnl else
__CPPNAME__::__CPPNAME__`'(const __CNAME__* gobject)
{
  if(gobject)
    gobject_ = *gobject;
  else
    std::memset`'(&gobject_, 0, sizeof(__CNAME__));
}
')dnl

_IMPORT(SECTION_CC)

__NAMESPACE_END__

dnl
dnl
dnl
dnl
_POP()
dnl
dnl
dnl The actual class, e.g. Gtk::TreeIter, declaration:
dnl
_IMPORT(SECTION_CLASS1)
public:
#ifndef DOXYGEN_SHOULD_SKIP_THIS
  using CppObjectType = __CPPNAME__;
  using BaseObjectType = __CNAME__;
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

  __CPPNAME__`'(const __CPPNAME__& other) noexcept;
  __CPPNAME__& operator=(const __CPPNAME__& other) noexcept;

  __CPPNAME__`'(__CPPNAME__&& other) noexcept;
  __CPPNAME__& operator=(__CPPNAME__&& other) noexcept;

  /** Get the GType for this class, for use with the underlying GObject type system.
   */
  static GType get_type() G_GNUC_CONST;

ifdef(`__BOOL_CUSTOM_DEFAULT_CTOR__',,`dnl else
  __CPPNAME__`'();
')dnl

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',,`dnl else
  explicit __CPPNAME__`'(const __CNAME__* gobject); // always takes a copy
')dnl

  ///Provides access to the underlying C instance.
  __CNAME__*       gobj()       { return &gobject_; }

  ///Provides access to the underlying C instance.
  const __CNAME__* gobj() const { return &gobject_; }

protected:
  __CNAME__ gobject_;
dnl  static const __CNAME__ gobject_initializer_;

private:
  _IMPORT(SECTION_CLASS2)
')

