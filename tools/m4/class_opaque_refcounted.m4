dnl
dnl _CLASS_OPAQUE_REFCOUNTED(Coverage, PangoCoverage, pango_coverage_new, pango_coverage_ref, pango_coverage_unref, api_decoration)
dnl

define(`_CLASS_OPAQUE_REFCOUNTED',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__OPAQUE_FUNC_NEW',`$3')
define(`__OPAQUE_FUNC_REF',`$4')
define(`__OPAQUE_FUNC_UNREF',`$5')
define(`__OPAQUE_FUNC_DECORATION',`$6')
undefine(`__OPAQUE_FUNC_GTYPE__')

_POP()
_SECTION(SECTION_CLASS2)
')dnl End of _CLASS_OPAQUE_REFCOUNTED.

dnl _IS_REFCOUNTED_BOXEDTYPE(gtype_func)
dnl
dnl Generates a *_get_type() function and a Glib::Value specialization.
dnl A Glib::Value specialization is required, if the C++ class is used in
dnl _WRAP_PROPERTY. The C class must have been registered in the GType system
dnl with g_boxed_type_register_static().
dnl
dnl Optional parameter gtype_func:
dnl 1. If not defined or an empty string, _GET_TYPE_FUNC() generates the
dnl    function name from the name of the C type, e.g.
dnl    GSettingsSchema -> g_settings_schema_get_type
dnl 2. If anything else, it's assumed to be the name of the *_get_type() function.
dnl
define(`_IS_REFCOUNTED_BOXEDTYPE',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__OPAQUE_FUNC_GTYPE__',`$1')
_POP()
')

dnl
dnl _END_CLASS_OPAQUE_REFCOUNTED()
dnl   denotes the end of a class
dnl
define(`_END_CLASS_OPAQUE_REFCOUNTED',`

_SECTION(SECTION_HEADER3)

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
__OPAQUE_FUNC_DECORATION
Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__CNAME__* object, bool take_copy = false);

ifdef(`__OPAQUE_FUNC_GTYPE__',`dnl
#ifndef DOXYGEN_SHOULD_SKIP_THIS
template <>
class __OPAQUE_FUNC_DECORATION Value<Glib::RefPtr<__NAMESPACE__::__CPPNAME__>> : public Glib::Value_RefPtrBoxed<__NAMESPACE__::__CPPNAME__>
{
public:
  CppType get() const { return Glib::wrap(static_cast<__CNAME__*>(get_boxed()), true); }
};
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

')dnl endif __OPAQUE_FUNC_GTYPE__
} // namespace Glib

_SECTION(SECTION_SRC_GENERATED)

/* Why reinterpret_cast<__CPPNAME__*>(gobject) is needed:
 *
 * A __CPPNAME__ instance is in fact always a __CNAME__ instance.
 * Unfortunately, __CNAME__ cannot be a member of __CPPNAME__,
 * because it is an opaque struct.  Also, the C interface does not provide
 * any hooks to install a destroy notification handler, thus we cannot
 * wrap it dynamically either.
 *
 * The cast works because __CPPNAME__ does not have any member data, and
 * it is impossible to derive from it.  This is ensured by using final on the
 * class and by using = delete on the default constructor.
 */

namespace Glib
{

Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__CNAME__* object, bool take_copy)
{
  if(take_copy && object)
    __OPAQUE_FUNC_REF`'(object);

  // See the comment at the top of this file, if you want to know why the cast works.
  return Glib::make_refptr_for_instance<__NAMESPACE__::__CPPNAME__>(reinterpret_cast<__NAMESPACE__::__CPPNAME__*>(object));
}

} // namespace Glib


__NAMESPACE_BEGIN__

dnl
dnl The implementation:
dnl
ifdef(`__OPAQUE_FUNC_GTYPE__',`dnl
// static
GType __CPPNAME__::get_type()
{
ifelse(__OPAQUE_FUNC_GTYPE__,,`dnl
  return _GET_TYPE_FUNC(__CNAME__);
',`dnl
  return __OPAQUE_FUNC_GTYPE__`'();
')dnl
}

')dnl endif __OPAQUE_FUNC_GTYPE__
ifelse(__OPAQUE_FUNC_NEW,NONE,`dnl
',`dnl else
// static
Glib::RefPtr<__CPPNAME__> __CPPNAME__::create()
{
  // See the comment at the top of this file, if you want to know why the cast works.
  return Glib::make_refptr_for_instance<__CPPNAME__>(reinterpret_cast<__CPPNAME__*>(__OPAQUE_FUNC_NEW`'()));
}

')dnl endif __OPAQUE_FUNC_NEW
void __CPPNAME__::reference() const
{
  // See the comment at the top of this file, if you want to know why the cast works.
  __OPAQUE_FUNC_REF`'(reinterpret_cast<__CNAME__*>(const_cast<__CPPNAME__*>(this)));
}

void __CPPNAME__::unreference() const
{
  // See the comment at the top of this file, if you want to know why the cast works.
  __OPAQUE_FUNC_UNREF`'(reinterpret_cast<__CNAME__*>(const_cast<__CPPNAME__*>(this)));
}

__CNAME__* __CPPNAME__::gobj()
{
  // See the comment at the top of this file, if you want to know why the cast works.
  return reinterpret_cast<__CNAME__*>(this);
}

const __CNAME__* __CPPNAME__::gobj() const
{
  // See the comment at the top of this file, if you want to know why the cast works.
  return reinterpret_cast<const __CNAME__*>(this);
}

__CNAME__* __CPPNAME__::gobj_copy() const
{
  // See the comment at the top of this file, if you want to know why the cast works.
  const auto gobject = reinterpret_cast<__CNAME__*>(const_cast<__CPPNAME__*>(this));
  __OPAQUE_FUNC_REF`'(gobject);
  return gobject;
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

ifdef(`__OPAQUE_FUNC_GTYPE__',`dnl
  /** Get the GType for this class, for use with the underlying GObject type system.
   */
  static GType get_type() G_GNUC_CONST;

')dnl endif __OPAQUE_FUNC_GTYPE__
ifelse(__OPAQUE_FUNC_NEW,NONE,`dnl
',`dnl else
  static Glib::RefPtr<__CPPNAME__> create();
')dnl endif __OPAQUE_FUNC_NEW

  /** Increment the reference count for this object.
   * You should never need to do this manually - use the object via a RefPtr instead.
   */
  void reference()   const;

  /** Decrement the reference count for this object.
   * You should never need to do this manually - use the object via a RefPtr instead.
   */
  void unreference() const;

  ///Provides access to the underlying C instance.
  __CNAME__*       gobj();

  ///Provides access to the underlying C instance.
  const __CNAME__* gobj() const;

  ///Provides access to the underlying C instance. The caller is responsible for unrefing it. Use when directly setting fields in structs.
  __CNAME__* gobj_copy() const;

  __CPPNAME__`'() = delete;

  // noncopyable
  __CPPNAME__`'(const __CPPNAME__&) = delete;
  __CPPNAME__& operator=(const __CPPNAME__&) = delete;

protected:
  // Do not derive this.  __NAMESPACE__::__CPPNAME__ can neither be constructed nor deleted.

  void operator delete(void*, std::size_t);

private:
_IMPORT(SECTION_CLASS2)
')

