dnl
dnl _VFUNC_PH(gtkname, crettype, cargs and names)
dnl Create a callback and set it in our derived G*Class.
dnl
define(`_VFUNC_PH',`dnl
_PUSH(SECTION_PCC_CLASS_INIT_VFUNCS)
  klass->$1 = `&'$1_vfunc_callback;
_SECTION(SECTION_PH_VFUNCS)
  static $2 $1_vfunc_callback`'($3);
_POP()')


dnl               $1      $2       $3        $4
dnl _VFUNC_PCC(cppname,gtkname,cpprettype,crettype,
dnl                        $5                $6          $7            $8        $9
dnl                  `<cargs and names>',`<cnames>',`<cpparg names>',firstarg, refreturn_ctype)
dnl
define(`_VFUNC_PCC',`dnl
_PUSH(SECTION_PCC_VFUNCS)
$4 __CPPNAME__`'_Class::$2_vfunc_callback`'($5)
{
dnl  We cast twice to allow for multiple-inheritance casts, which might 
dnl  change the value.  We have to use a dynamic_cast because we do not 
dnl  know the actual type from which to cast up.
  CppObjectType *const obj = dynamic_cast<CppObjectType*>(
      Glib::ObjectBase::_get_current_wrapper`'((GObject*)$8));

_IMPORT(SECTION_CHECK)
  // Non-gtkmmproc-generated custom classes implicitly call the default
  // Glib::ObjectBase constructor, which sets is_derived_. But gtkmmproc-
  // generated classes can use this optimisation, which avoids the unnecessary
  // parameter conversions if there is no possibility of the virtual function
  // being overridden:
  if(obj && obj->is_derived_())
  {
    try // Trap C++ exceptions which would normally be lost because this is a C callback.
    {
      // Call the virtual member method, which derived classes might override.
ifelse($4,void,`dnl
      obj->$1`'($7);
',`dnl
ifelse($9,refreturn_ctype,`dnl Assume Glib::unwrap_copy() is correct if refreturn_ctype is requested.
      return Glib::unwrap_copy`'(`obj->$1'($7));
',`dnl
      return _CONVERT($3,$4,`obj->$1`'($7)');
')dnl
')dnl
    }
    catch(...)
    {
      Glib::exception_handlers_invoke`'();
    }
  }
  else
  {
    BaseClassType *const base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
        _IFACE_PARENT_FROM_OBJECT($8)dnl
',`dnl
        _PARENT_GCLASS_FROM_OBJECT($8)dnl
')    );
dnl    g_assert(base != 0);

    // Call the original underlying C function:
    if(base && base->$2)
      ifelse($4,void,,`return ')(*base->$2)`'($6);
  }
ifelse($4,void,,`dnl

  typedef $4 RType;
  return RType`'();
')dnl
}

_POP()')


#                $1      $2       $3
# _VFUNC_H(vfunc_name,rettype,`<cppargs>')
#
define(`_VFUNC_H',`dnl
_PUSH(SECTION_H_VFUNCS)
  virtual $2 $1`'($3);
_POP()')

#                $1        $2        $3           $4          $5            $6         $7
# _VFUNC_CC(vfunc_name, gtkname, cpp_rettype, c_rettype, `<cppargs>', `<carg_names>', refreturn)
#
define(`_VFUNC_CC',`dnl
_PUSH(SECTION_CC_VFUNCS)
$3 __NAMESPACE__::__CPPNAME__::$1`'($5)
{
  BaseClassType *const base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
      _IFACE_PARENT_FROM_OBJECT(gobject_)dnl
',`dnl
      _PARENT_GCLASS_FROM_OBJECT(gobject_)dnl
')  );
dnl  g_assert(base != 0);

  if(base && base->$2)
ifelse($3,void,`dnl
    (*base->$2)`'(gobj()`'_COMMA_PREFIX($6));
',`dnl
ifelse($7,refreturn,`dnl Assume Glib::wrap() is correct if refreturn is requested.
    return Glib::wrap((*base->$2)`'(gobj`'()`'_COMMA_PREFIX($6)), true);
',`dnl
    return _CONVERT($4,$3,`(*base->$2)`'(gobj`'()`'_COMMA_PREFIX($6))');
')dnl

  typedef $3 RType;
  return RType`'();
')dnl
}

_POP()')


