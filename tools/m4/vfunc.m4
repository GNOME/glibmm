dnl
dnl _VFUNC_PH(gtkname, crettype, cargs and names)
dnl Create a callback and set it in our derived G*Class.
dnl
define(`_VFUNC_PH',`dnl
_PUSH(SECTION_PCC_CLASS_INIT_VFUNCS)
ifelse(`$4',,,`#ifdef $4'
)dnl
  klass->$1 = `&'$1_vfunc_callback;
ifelse(`$4',,,`#endif // $4
')dnl
_SECTION(SECTION_PH_VFUNCS)
ifelse(`$4',,,`#ifdef $4'
)dnl
  static $2 $1_vfunc_callback`'($3);
ifelse(`$4',,,`#endif // $4
')dnl
_POP()')


dnl              $1      $2       $3        $4
dnl _VFUNC_PCC(cppname,gtkname,cpprettype,crettype,
dnl                   $5               $6           $7            $8
dnl            `<cargs and names>',`<cnames>',`<cpparg names>',firstarg,
dnl                $9               $10        $11     $12
dnl             refreturn_ctype, keep_return, ifdef, errthrow,
dnl               $13           $14            $15             $16
dnl            slot_type, c_data_param_name, return_value, exception_handler)
dnl
dnl Note: _get_current_wrapper_inline() could be used throughout for performance instead of _get_current_wrapper(),
dnl and is_derived_() instead of is_derived_(),
dnl but it is not yet clear whether that would be a worthwhile performance optimization.
define(`_VFUNC_PCC',`dnl
_PUSH(SECTION_PCC_VFUNCS)
ifelse(`$11',,,`#ifdef $11'
)dnl
$4 __CPPNAME__`'_Class::$2_vfunc_callback`'($5)
{
ifelse(`$14',,,dnl
`  const auto slot = static_cast<$13*>($14);

')dnl
dnl  First, do a simple cast to ObjectBase. We will have to do a dynamic_cast
dnl  eventually, but it is not necessary to check whether we need to call
dnl  the vfunc.
  const auto obj_base = static_cast<Glib::ObjectBase*>(
      Glib::ObjectBase::_get_current_wrapper`'((GObject*)$8));

_IMPORT(SECTION_CHECK)
  // Non-gtkmmproc-generated custom classes implicitly call the default
  // Glib::ObjectBase constructor, which sets is_derived_. But gtkmmproc-
  // generated classes can use this optimisation, which avoids the unnecessary
  // parameter conversions if there is no possibility of the virtual function
  // being overridden:
  if(obj_base && obj_base->is_derived_())
  {
dnl  We need to do a dynamic cast to get the real object type, to call the
dnl  C++ vfunc on it.
    const auto obj = dynamic_cast<CppObjectType* const>(obj_base);
    if(obj) // This can be NULL during destruction.
    {
      try // Trap C++ exceptions which would normally be lost because this is a C callback.
      {
        // Call the virtual member method, which derived classes might override.
ifelse($4,void,`dnl
        obj->$1`'($7);
        return;
',`dnl not void
ifelse($9,refreturn_ctype,`dnl Assume Glib::unwrap_copy() is correct if refreturn_ctype is requested.
        return Glib::unwrap_copy`'(`obj->$1'($7));
',`dnl not refreturn_ctype
ifelse($10,keep_return,`dnl
        static auto quark_return_value = g_quark_from_static_string("__NAMESPACE__::__CPPNAME__::$1");

        auto return_value = static_cast<$3*>(g_object_get_qdata(obj_base->gobj(), quark_return_value));
        if (!return_value)
        {
          return_value = new $3`'();
          g_object_set_qdata_full(obj_base->gobj(), quark_return_value, return_value,
          &Glib::destroy_notify_delete<$3>);
        }
        // Keep a copy of the return value. The caller is not expected
        // to free the object that the returned pointer points to.
        *return_value = obj->$1`'($7);
        return _CONVERT($3,$4,`(*return_value)');
',`dnl not keep_return
        return _CONVERT($3,$4,`obj->$1`'($7)');
')dnl end keep_return
')dnl end refreturn_ctype
')dnl end void
      }
ifelse($16,,,`dnl if (exception_handler)
      catch(...)
      {
        try
        {
ifelse($9,refreturn_ctype,`dnl
          return Glib::unwrap_copy`'(obj->$16`'());
', `dnl
          return _CONVERT($3, $4, `obj->$16`'()');
')dnl
        }
')dnl end exception_handler
ifelse($12,errthrow,`dnl
      catch(Glib::Error& errormm)
      {
        errormm.propagate(error);
ifelse($4,void,`dnl
        return;
',`dnl
ifelse(`$15', `',`dnl
        using RType = $4;
        return RType`'();
',`dnl
        return _CONVERT($3,$4,`$15');
')dnl
')dnl
      }
')dnl end errthrow
      catch(...)
      {
        Glib::exception_handlers_invoke`'();
      }
ifelse($16,,,`dnl if (exception_handler)
      }
')dnl
    }
  }

  BaseClassType *const base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
      _IFACE_PARENT_FROM_OBJECT($8)dnl
',`dnl
      _PARENT_GCLASS_FROM_OBJECT($8)dnl
')  );
dnl  g_assert(base != nullptr);

  // Call the original underlying C function:
  if(base && base->$2)
    ifelse($4,void,,`return ')(*base->$2)`'($6);
ifelse($4,void,,`dnl

ifelse(`$15', `',`dnl
  using RType = $4;
  return RType`'();
',`dnl
  return _CONVERT($3,$4,`$15');
')dnl
')dnl
}
ifelse(`$11',,,`#endif // $11
')dnl
_POP()')

#               $1        $2          $3         $4          $5             $6          $7        $8        $9        $10         $11        $12          $13           $14
# _VFUNC_CC(vfunc_name, gtkname, cpp_rettype, c_rettype, `<cppargs>', `<carg_names>', is_const, refreturn, $ifdef, $errthrow, $slot_type, $slot_name, $no_slot_copy, $returnValue)
#
define(`_VFUNC_CC',`dnl
_PUSH(SECTION_CC_VFUNCS)
ifelse(`$9',,,`#ifdef $9'
)dnl
$3 __NAMESPACE__::__CPPNAME__::$1`'($5) ifelse($7,1,const,)
{
dnl If a slot type has been specified, insert code to create a copy of it.
ifelse(`$11',,,dnl
dnl See if the slot should or should not be copied
`ifelse(`$13',,dnl
`  // Create a copy of the slot.
  auto slot_copy = new $11($12); ',dnl
dnl
`  // Use the original slot (not a copy).
  auto slot_copy = const_cast<$11*>(&$12);')

')dnl
  const auto base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
      _IFACE_PARENT_FROM_OBJECT(gobject_)dnl
',`dnl
      _PARENT_GCLASS_FROM_OBJECT(gobject_)dnl
')  );
dnl  g_assert(base != nullptr);

  if(base && base->$2)
  {
ifelse($10,errthrow,`dnl
    GError* gerror = nullptr;
')dnl
ifelse($3,void,`dnl
    (*base->$2)`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'_COMMA_PREFIX($6));
  }
',`dnl
ifelse($8,refreturn,`dnl Assume Glib::wrap() is correct if refreturn is requested.
    $3 retval(Glib::wrap((*base->$2)`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'_COMMA_PREFIX($6)), true));
',`dnl
    $3 retval(_CONVERT($4,$3,`(*base->$2)`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'_COMMA_PREFIX($6))'));
')dnl
ifelse($10,errthrow,`dnl
    if(gerror)
      ::Glib::Error::throw_exception(gerror);
')dnl
    return retval;
  }

ifelse(`$14', `',`dnl
  using RType = $3;
  return RType`'();
',`dnl
  return $14;
')dnl
')dnl
}
ifelse(`$9',,,`#endif // $9
')dnl
_POP()')


#                $1      $2       $3           $4		$5
# _VFUNC_H(vfunc_name, rettype, `<cppargs>', is_const, ifndef)
# Only used for custom vfuncs.
#
define(`_VFUNC_H',`dnl
_PUSH(SECTION_H_VFUNCS)
ifelse(`$5',,,`#ifdef $5'
)dnl
ifelse($4,`1',`dnl
virtual $2 $1`'($3) const;
',`dnl
virtual $2 $1`'($3);
')
ifelse(`$5',,,`#endif // $5
')dnl
_POP()')

