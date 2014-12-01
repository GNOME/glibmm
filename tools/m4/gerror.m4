dnl
dnl  _GERROR(PixbufError,GdkPixbufError,GDK_PIXBUF_ERROR,`<enum_value_list>',[NO_GTYPE], `<enum_docs>')
dnl             $1             $2             $3                $4               $5           $6
dnl

m4_define(`_GERROR',`dnl
_PUSH()
dnl
dnl  Define the args for later macros
m4_define(`__CPPNAME__',`$1')
m4_define(`__CNAME__',`$2')
m4_define(`__CQUARK__',`$3')
m4_define(`__VALUE_BASE__',`Glib::Value_Enum<__NAMESPACE__::__CPPNAME__::Code>')
_POP()
class __CPPNAME__ : public Glib::Error
{
public:
  /** $6
   */
  enum Code
  {
$4
  };

  __CPPNAME__`'(Code error_code, const Glib::ustring& error_message);
  explicit __CPPNAME__`'(GError* gobject);
  Code code() const;

#ifndef DOXYGEN_SHOULD_SKIP_THIS
private:

  static void throw_func(GError* gobject);

  friend void wrap_init(); // uses throw_func()

  _IMPORT(SECTION_H_GERROR_PRIVATE)
#endif //DOXYGEN_SHOULD_SKIP_THIS
};

m4_ifelse($5,`NO_GTYPE',,`dnl else
__NAMESPACE_END__

#ifndef DOXYGEN_SHOULD_SKIP_THIS
namespace Glib
{

template <>
class Value<__NAMESPACE__::__CPPNAME__::Code> : public __VALUE_BASE__
{
public:
  static GType value_type() G_GNUC_CONST;
};

} // namespace Glib
#endif /* DOXYGEN_SHOULD_SKIP_THIS */


__NAMESPACE_BEGIN__
')dnl endif !NO_GTYPE
_PUSH(SECTION_SRC_GENERATED)

__NAMESPACE__::__CPPNAME__::__CPPNAME__`'(__NAMESPACE__::__CPPNAME__::Code error_code, const Glib::ustring& error_message)
:
  Glib::Error (__CQUARK__, error_code, error_message)
{}

__NAMESPACE__::__CPPNAME__::__CPPNAME__`'(GError* gobject)
:
  Glib::Error (gobject)
{}

__NAMESPACE__::__CPPNAME__::Code __NAMESPACE__::__CPPNAME__::code() const
{
  return static_cast<Code>(Glib::Error::code());
}

void __NAMESPACE__::__CPPNAME__::throw_func(GError* gobject)
{
  throw __NAMESPACE__::__CPPNAME__`'(gobject);
}

m4_ifelse($5,`NO_GTYPE',,`dnl else
// static
GType Glib::Value<__NAMESPACE__::__CPPNAME__::Code>::value_type()
{
  return _GET_TYPE_FUNC(__CNAME__);
}

')dnl endif !NO_GTYPE
_POP()
') dnl enddef _GERROR

