dnl $Id$

dnl
dnl
dnl  Code generation sections for properties
dnl
dnl

dnl
dnl _PROPERTY_PROXY(name, cpp_type, proxy_suffix)
dnl proxy_suffix could be "_WriteOnly" or "_ReadOnly"
dnl The method will be const if the propertyproxy is _ReadOnly.
dnl
define(`_PROPERTY_PROXY',`dnl
dnl
dnl Put spaces around the template parameter if necessary.
pushdef(`__PROXY_TYPE__',`dnl
Glib::PropertyProxy$3<'ifelse(regexp(_QUOTE($2),`>$'),`-1',_QUOTE($2),` '_QUOTE($2)` ')`>'dnl
)dnl
  /** You rarely need to use properties because there are get_ and set_ methods for almost all of them.
   * @return A PropertyProxy that allows you to get or set the property of the value, or receive notification when
   * the value of the property changes.
   */
  __PROXY_TYPE__ property_$1`'() ifelse($3,_ReadOnly, const,);
_PUSH(SECTION_CC_PROPERTYPROXIES)
__PROXY_TYPE__ __CPPNAME__::property_$1`'() ifelse($3,_ReadOnly, const,)
{
  return __PROXY_TYPE__`'(this, "$1");
}

_POP()
popdef(`__PROXY_TYPE__')dnl
')dnl

