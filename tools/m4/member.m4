dnl
dnl --------------------------- Accessors ----------------------------
dnl


dnl Get:


dnl Creates accessors for simple types:
dnl _MEMBER_GET(cpp_name, c_name, cpp_type, c_type)
define(`_MEMBER_GET',`dnl
$3 get_$1() const;
_PUSH(SECTION_CC)
$3 __CPPNAME__::get_$1() const
{
  return _CONVERT($4,$3,`gobj()->$2');
}

_POP()')

dnl Creates two accessors for pointer types, one const and one non-const:
define(`_MEMBER_GET_PTR',`dnl
$3 get_$1();
  const $3 get_$1() const;
_PUSH(SECTION_CC)
$3 __CPPNAME__::get_$1()
{
  return _CONVERT($4,$3,`gobj()->$2');
}

const $3 __CPPNAME__::get_$1() const
{
  return _CONVERT($4,const $3,`gobj()->$2');
}

_POP()')

dnl Creates accessors for GObject-derived types that must be ref()ed.
define(`_MEMBER_GET_GOBJECT',`dnl
Glib::RefPtr<$3> get_$1();
  Glib::RefPtr<const $3> get_$1() const;
_PUSH(SECTION_CC)
Glib::RefPtr<$3> __CPPNAME__::get_$1()
{
  Glib::RefPtr<$3> ref_ptr(_CONVERT($4,Glib::RefPtr<$3>,`gobj()->$2'));

dnl We could use the bool with Glib::wrap(), but we want to share the m4 type-conversion map.
  if(ref_ptr)
    ref_ptr->reference();

  return ref_ptr;
}

Glib::RefPtr<const $3> __CPPNAME__::get_$1() const
{
  Glib::RefPtr<const $3> ref_ptr(_CONVERT($4,Glib::RefPtr<const $3>,`gobj()->$2'));

dnl We could use the bool with Glib::wrap(), but we want to share the m4 type-conversion map.
  if(ref_ptr)
    ref_ptr->reference();

  return ref_ptr;
}

_POP()')


dnl Set:

dnl Creates accessors for simple types:
define(`_MEMBER_SET',`dnl
void set_$1(const $3`'& value);
_PUSH(SECTION_CC)
void __CPPNAME__::set_$1(const $3`'& value)
{
  gobj()->$2 = _CONVERT($3,$4,`value');
}

_POP()')

dnl Creates accessors for pointer types:
define(`_MEMBER_SET_PTR',`dnl
void set_$1($3 value);
_PUSH(SECTION_CC)
void __CPPNAME__::set_$1($3 value)
{
  gobj()->$2 = _CONVERT($3,$4,`value');
}

_POP()')

dnl Creates accessors for GObject-derived types that must be ref()ed.
define(`_MEMBER_SET_GOBJECT',`dnl
void set_$1(const Glib::RefPtr<$3>& value);
_PUSH(SECTION_CC)
void __CPPNAME__::set_$1(const Glib::RefPtr<$3>& value)
{
  Glib::RefPtr<$3> valueOld(_CONVERT($4,Glib::RefPtr<$3>,`gobj()->$2')); //Take possession of the old one, unref-ing it in the destructor.

  if(value)
    value->reference(); //Ref once for the recipient.

  gobj()->$2 = _CONVERT(const Glib::RefPtr<$3>&,$4,`value');
}

_POP()')


