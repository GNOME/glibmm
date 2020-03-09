dnl $Id$


define(`_CLASS_GOBJECT',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__CCAST__',`$3')
define(`__BASE__',_LOWER(__CPPNAME__))
define(`__CPPPARENT__',`$4')
define(`__CPARENT__',`$5')
define(`__PCAST__',`($5*)')

dnl Some C types, e.g. GdkWindow or GdkPixmap, are a typedef to their base type,
dnl rather than the real instance type.  That is really ugly, yes.  We get around
dnl the problem by supporting optional __REAL_* arguments to this macro.
define(`__REAL_CNAME__',ifelse(`$6',,__CNAME__,`$6'))
define(`__REAL_CPARENT__',ifelse(`$7',,__CPARENT__,`$7'))

dnl $8 is for the optional api_decoration used for import/export
define(`__FUNC_DECORATION__',`$8')

_POP()
_SECTION(SECTION_CLASS2)
') dnl end of _CLASS_GOBJECT

dnl Widget and Object, and some others, have custom-written destructor implementations:
define(`_CUSTOM_DTOR',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_DTOR__',`$1')
_POP()
')

dnl For classes that need custom code for move operations.
define(`_CUSTOM_MOVE_OPERATIONS', `dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_MOVE_OPERATIONS__',`$1')
_POP()
')

dnl For classes that need custom code in their cast and construct_params
dnl constructor.
define(`_CUSTOM_CTOR_CAST',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_CTOR_CAST__',`$1')
_POP()
')

dnl Gdk::Pixmap_Class::wrap_new() needs a custom implementation, in order
dnl to create a Gdk::Bitmap object if appropriate.  See comments there.
define(`_CUSTOM_WRAP_NEW',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_WRAP_NEW__',`1')
_POP()
')

dnl Gnome::Canvas::CanvasAA::CanvasAA() needs access to the
dnl normally-private canvas_class_ member variable. See comments there.
define(`_GMMPROC_PROTECTED_GCLASS',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_PROTECTED_GCLASS__',`1')
_POP()
')

dnl Some of the Gdk types are actually direct typedefs of their base type.
dnl This means that 2 wrap functions would have the same argument.
dnl define(`_NO_WRAP_FUNCTION',`dnl
dnl _PUSH()
dnl Define this macro to be tested for later.
dnl define(`__BOOL_NO_WRAP_FUNCTION__',`$1')
dnl _POP()
dnl ')

dnl In case a class needs to write its own implementation of its Glib::wrap()
dnl function.  The function will be declared in the header, but the body is not
dnl generated.
define(`_CUSTOM_WRAP_FUNCTION',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_WRAP_FUNCTION__',`$1')
_POP()
')

dnl Some gobjects actually derive from GInitiallyUnowned, which does some odd reference-counting that is useful to C coders.
dnl We don't want to expose that base class in our API,
dnl but we do want to reverse what it does:
define(`_DERIVES_INITIALLY_UNOWNED',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_DERIVES_INITIALLY_UNOWNED__',`$1')
_POP()
')


dnl
dnl _CREATE_METHOD(args_type_and_name_hpp, args_type_and_name_cpp,args_name_only);
dnl
define(`_CREATE_METHOD',`
  static Glib::RefPtr<`'__CPPNAME__`'> create(`'$1`');
_PUSH(SECTION_CC)
Glib::RefPtr<`'__CPPNAME__`'> __CPPNAME__`'::create(`'$2`')
{
  return Glib::make_refptr_for_instance<`'__CPPNAME__`'>( new __CPPNAME__`'(`'$3`') );
}

_POP()
')


dnl
dnl _END_CLASS_GOBJECT()
dnl   denotes the end of a class
dnl
define(`_END_CLASS_GOBJECT',`
_SECTION(SECTION_HEADER1)
ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl
_STRUCT_PROTOTYPE()
')dnl

#ifndef DOXYGEN_SHOULD_SKIP_THIS
__NAMESPACE_BEGIN__ class __FUNC_DECORATION__ __CPPNAME__`'_Class; __NAMESPACE_END__
#endif //DOXYGEN_SHOULD_SKIP_THIS

_SECTION(SECTION_HEADER3)

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl
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
  __FUNC_DECORATION__
  Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__REAL_CNAME__`'* object, bool take_copy = false);
}
')dnl


dnl
dnl
_SECTION(SECTION_PHEADER)

#include <glibmm/class.h>

__NAMESPACE_BEGIN__

_PH_CLASS_DECLARATION()

__NAMESPACE_END__

_SECTION(SECTION_SRC_GENERATED)

ifdef(`__BOOL_CUSTOM_WRAP_FUNCTION__',`dnl
',`dnl else
ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__REAL_CNAME__`'* object, bool take_copy)
{
  return Glib::make_refptr_for_instance<__NAMESPACE__::__CPPNAME__>( dynamic_cast<__NAMESPACE__::__CPPNAME__*> (Glib::wrap_auto ((GObject*)(object), take_copy)) );
  //We use dynamic_cast<> in case of multiple inheritance.
}

} /* namespace Glib */
')dnl endif
')dnl endif




__NAMESPACE_BEGIN__


/* The *_Class implementation: */

_PCC_CLASS_IMPLEMENTATION()

m4_ifdef(`__BOOL_CUSTOM_WRAP_NEW__',,`dnl else
Glib::ObjectBase* __CPPNAME__`'_Class::wrap_new(GObject* object)
{
  return new __CPPNAME__`'((__CNAME__*)`'object);
}

')dnl endif

/* The implementation: */

__CNAME__* __CPPNAME__::gobj_copy()
{
  reference();
  return gobj();
}

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',`dnl
',`dnl
__CPPNAME__::__CPPNAME__`'(const Glib::ConstructParams& construct_params)
:
  __CPPPARENT__`'(construct_params)
{
_INITIALLY_UNOWNED_SINK
}

__CPPNAME__::__CPPNAME__`'(__CNAME__* castitem)
:
  __CPPPARENT__`'(__PCAST__`'(castitem))
{}

')dnl

ifdef(`__BOOL_CUSTOM_MOVE_OPERATIONS__',`dnl
',`dnl
__CPPNAME__::__CPPNAME__`'(__CPPNAME__&& src) noexcept
: __CPPPARENT__`'(std::move(src))
_IMPORT(SECTION_CC_MOVE_CONSTRUCTOR_INTERFACES)
{}

__CPPNAME__& __CPPNAME__::operator=(__CPPNAME__&& src) noexcept
{
  __CPPPARENT__::operator=`'(std::move(src));
_IMPORT(SECTION_CC_MOVE_ASSIGNMENT_OPERATOR_INTERFACES)
  return *this;
}

')dnl

ifdef(`__BOOL_CUSTOM_DTOR__',`dnl
',`dnl
__CPPNAME__::~__CPPNAME__`'() noexcept
{}

')dnl


_CC_CLASS_IMPLEMENTATION()

__NAMESPACE_END__

dnl
dnl
dnl
dnl
_POP()
dnl
dnl The actual class, e.g. Gtk::Widget, declaration:
dnl _IMPORT(SECTION_H_SIGNALPROXIES_CUSTOM)

_IMPORT(SECTION_CLASS1)

#ifndef DOXYGEN_SHOULD_SKIP_THIS

public:
  using CppObjectType = __CPPNAME__;
  using CppClassType = __CPPNAME__`'_Class;
  using BaseObjectType = __CNAME__;
  using BaseClassType = __REAL_CNAME__`'Class;

  // noncopyable
  __CPPNAME__`'(const __CPPNAME__&) = delete;
  __CPPNAME__& operator=(const __CPPNAME__&) = delete;

m4_ifdef(`__BOOL_PROTECTED_GCLASS__',
`protected:',`dnl else
private:')dnl endif
  friend class __CPPNAME__`'_Class;
  static CppClassType `'__BASE__`'_class_;

protected:
  explicit __CPPNAME__`'(const Glib::ConstructParams& construct_params);
  explicit __CPPNAME__`'(__CNAME__* castitem);

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

public:

ifdef(`__BOOL_CUSTOM_MOVE_OPERATIONS__',`dnl
',`dnl
  __CPPNAME__`'(__CPPNAME__&& src) noexcept;
  __CPPNAME__& operator=(__CPPNAME__&& src) noexcept;
')dnl

_IMPORT(SECTION_DTOR_DOCUMENTATION)
  ~__CPPNAME__`'() noexcept override;

  /** Get the GType for this class, for use with the underlying GObject type system.
   */
  static GType get_type()      G_GNUC_CONST;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
ifdef(`__BOOL_DYNAMIC_GTYPE_REGISTRATION__',`
  static GType get_type(GTypeModule* module)      G_GNUC_CONST;
',`')

  static GType get_base_type() G_GNUC_CONST;
#endif

  ///Provides access to the underlying C GObject.
  __CNAME__*       gobj()       { return reinterpret_cast<__CNAME__*>(gobject_); }

  ///Provides access to the underlying C GObject.
  const __CNAME__* gobj() const { return reinterpret_cast<__CNAME__*>(gobject_); }

  ///Provides access to the underlying C instance. The caller is responsible for unrefing it. Use when directly setting fields in structs.
  __CNAME__* gobj_copy();

private:
_IMPORT(SECTION_CLASS2)

public:
_H_VFUNCS_AND_SIGNALS()

')
