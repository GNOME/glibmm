dnl $Id$


define(`_CLASS_INTERFACE',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
define(`__CPPNAME__',`$1')
define(`__CNAME__',`$2')
define(`__CCAST__',`$3')
define(`__CCLASS__',`$4') dnl SomethingIface or SomethingClass, both suffixes are used.
define(`__BASE__',_LOWER(__CPPNAME__))
define(`__CPPPARENT__',m4_ifelse($5,`',`Glib::Interface',$5)) #Optional parameter.
define(`__CPARENT__',m4_ifelse($6,`',`GObject',$6)) #Optional parameter.
define(`__PCAST__',`(__CPARENT__`'*)')
define(`__BOOL_IS_INTERFACE__',`1')

dnl $7 is for the optional api_decoration used for import/export
define(`__FUNC_DECORATION__',`$7')

dnl For classes that need custom code in their cast constructor.
define(`_CUSTOM_CTOR_CAST',`dnl
_PUSH()
dnl Define this macro to be tested for later.
define(`__BOOL_CUSTOM_CTOR_CAST__',`$1')
_POP()
')

_POP()
_SECTION(SECTION_CLASS2)
') dnl end of _CLASS_INTERFACE


dnl Some of the Gdk types are actually direct typedefs of their base type.
dnl This means that 2 wrap functions would have the same argument.
dnl define(`_NO_WRAP_FUNCTION',`dnl
dnl _PUSH()
dnl Define this macro to be tested for later.
dnl define(`__BOOL_NO_WRAP_FUNCTION__',`$1')
dnl _POP()
dnl ')

dnl
dnl
dnl
define(`_PH_CLASS_DECLARATION_INTERFACE',`dnl
class __FUNC_DECORATION__ __CPPNAME__`'_Class : public __CPPPARENT__`'_Class
{
public:
  using CppObjectType = __CPPNAME__;
  using BaseObjectType = __CNAME__;
  using BaseClassType = __CCLASS__;
  using CppClassParent = __CPPPARENT__`'_Class;

  friend class __CPPNAME__;

  const Glib::Interface_Class& init();

  static void iface_init_function(void* g_iface, void* iface_data);

  static Glib::ObjectBase* wrap_new(GObject*);

protected:

  //Callbacks (default signal handlers):
  //These will call the *_impl member methods, which will then call the existing default signal callbacks, if any.
  //You could prevent the original default signal handlers being called by overriding the *_impl method.
_IMPORT(SECTION_PH_DEFAULT_SIGNAL_HANDLERS)

  //Callbacks (virtual functions):
_IMPORT(SECTION_PH_VFUNCS)
};
')


dnl
dnl
dnl
define(`_PCC_CLASS_IMPLEMENTATION_INTERFACE',`dnl
const Glib::Interface_Class& __CPPNAME__`'_Class::init()
{
  if(!gtype_) // create the GType if necessary
  {
    // Glib::Interface_Class has to know the interface init function
    // in order to add interfaces to implementing types.
    class_init_func_ = &__CPPNAME__`'_Class::iface_init_function;

    // We can not derive from another interface, and it is not necessary anyway.
    gtype_ = _LOWER(__CCAST__)_get_type();
  }

  return *this;
}

void __CPPNAME__`'_Class::iface_init_function(void* g_iface, void*)
{
  const auto klass = static_cast<BaseClassType*>(g_iface);

  //This is just to avoid an "unused variable" warning when there are no vfuncs or signal handlers to connect.
  //This is a temporary fix until I find out why I can not seem to derive a GtkFileChooser interface. murrayc
  g_assert(klass != nullptr);

_IMPORT(SECTION_PCC_CLASS_INIT_VFUNCS)

_IMPORT(SECTION_PCC_CLASS_INIT_DEFAULT_SIGNAL_HANDLERS)
}

_IMPORT(SECTION_PCC_VFUNCS)

_IMPORT(SECTION_PCC_DEFAULT_SIGNAL_HANDLERS)
')


dnl
dnl _END_CLASS_INTERFACE()
dnl   denotes the end of a class
dnl
define(`_END_CLASS_INTERFACE',`
_SECTION(SECTION_HEADER1)
_STRUCT_PROTOTYPE()

#ifndef DOXYGEN_SHOULD_SKIP_THIS
__NAMESPACE_BEGIN__ class __FUNC_DECORATION__ __CPPNAME__`'_Class; __NAMESPACE_END__
#endif // DOXYGEN_SHOULD_SKIP_THIS

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
  Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__CNAME__`'* object, bool take_copy = false);

} // namespace Glib

')dnl
dnl
dnl
_SECTION(SECTION_PHEADER)

#include <glibmm/private/interface_p.h>

__NAMESPACE_BEGIN__

_PH_CLASS_DECLARATION_INTERFACE()

__NAMESPACE_END__

_SECTION(SECTION_SRC_GENERATED)

ifdef(`__BOOL_NO_WRAP_FUNCTION__',`dnl
',`dnl else
namespace Glib
{

Glib::RefPtr<__NAMESPACE__::__CPPNAME__> wrap(__CNAME__`'* object, bool take_copy)
{
  return Glib::make_refptr_for_instance<__NAMESPACE__::__CPPNAME__>( dynamic_cast<__NAMESPACE__::__CPPNAME__*> (Glib::wrap_auto_interface<__NAMESPACE__::__CPPNAME__> ((GObject*)(object), take_copy)) );
  //We use dynamic_cast<> in case of multiple inheritance.
}

} // namespace Glib
')dnl endif


__NAMESPACE_BEGIN__


/* The *_Class implementation: */

_PCC_CLASS_IMPLEMENTATION_INTERFACE()

Glib::ObjectBase* __CPPNAME__`'_Class::wrap_new(GObject* object)
{
  return new __CPPNAME__`'((__CNAME__*)`'(object));
}


/* The implementation: */

__CPPNAME__::__CPPNAME__`'()
:
  __CPPPARENT__`'(__BASE__`'_class_.init())
{}

ifdef(`__BOOL_CUSTOM_CTOR_CAST__',`dnl
',`dnl
__CPPNAME__::__CPPNAME__`'(__CNAME__* castitem)
:
  __CPPPARENT__`'(__PCAST__`'(castitem))
{}
')dnl

__CPPNAME__::__CPPNAME__`'(const Glib::Interface_Class& interface_class)
: __CPPPARENT__`'(interface_class)
{
}

__CPPNAME__::__CPPNAME__`'(__CPPNAME__&& src) noexcept
: __CPPPARENT__`'(std::move(src))
{}

__CPPNAME__& __CPPNAME__::operator=(__CPPNAME__&& src) noexcept
{
  __CPPPARENT__::operator=`'(std::move(src));
  return *this;
}

__CPPNAME__::~__CPPNAME__`'() noexcept
{}

// static
void __CPPNAME__`'::add_interface(GType gtype_implementer)
{
  __BASE__`'_class_.init().add_interface(gtype_implementer);
}

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
  using BaseClassType = __CCLASS__;

  // noncopyable
  __CPPNAME__`'(const __CPPNAME__&) = delete;
  __CPPNAME__& operator=(const __CPPNAME__&) = delete;

private:
  friend class __CPPNAME__`'_Class;
  static CppClassType `'__BASE__`'_class_;

#endif /* DOXYGEN_SHOULD_SKIP_THIS */
protected:
  /**
   * You should derive from this class to use it.
   */
  __CPPNAME__`'();

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  /** Called by constructors of derived classes. Provide the result of
   * the Class init() function to ensure that it is properly
   * initialized.
   *
   * @param interface_class The Class object for the derived type.
   */
  explicit __CPPNAME__`'(const Glib::Interface_Class& interface_class);

public:
  // This is public so that C++ wrapper instances can be
  // created for C instances of unwrapped types.
  // For instance, if an unexpected C type implements the C interface.
  explicit __CPPNAME__`'(__CNAME__* castitem);

protected:
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

public:

  __CPPNAME__`'(__CPPNAME__&& src) noexcept;
  __CPPNAME__& operator=(__CPPNAME__&& src) noexcept;

_IMPORT(SECTION_DTOR_DOCUMENTATION)
  ~__CPPNAME__`'() noexcept override;

  static void add_interface(GType gtype_implementer);

  /** Get the GType for this class, for use with the underlying GObject type system.
   */
  static GType get_type()      G_GNUC_CONST;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  static GType get_base_type() G_GNUC_CONST;
#endif

  ///Provides access to the underlying C GObject.
  __CNAME__*       gobj()       { return reinterpret_cast<__CNAME__*>(gobject_); }

  ///Provides access to the underlying C GObject.
  const __CNAME__* gobj() const { return reinterpret_cast<__CNAME__*>(gobject_); }

private:
_IMPORT(SECTION_CLASS2)

public:
_H_VFUNCS_AND_SIGNALS()

')

