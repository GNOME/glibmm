
#
# --------------------------- Signal Decl----------------------------
#

dnl _SIGNAL_PROXY($1 = c_signal_name,
dnl               $2 = c_return_type,
dnl               $3 = `<c_arg_types_and_names>',
dnl               $4 = cpp_signal_name,
dnl               $5 = cpp_return_type,
dnl               $6 = `<cpp_arg_types>',
dnl               $7 = `<c_args_to_cpp>',
dnl               $8 = `refdoc_comment')

define(`_SIGNAL_PROXY',`
$8
  Glib::SignalProxy`'_NUM($6)<$5`'_COMMA_PREFIX($6)> signal_$4`'();
dnl
_PUSH(SECTION_ANONYMOUS_NAMESPACE)
dnl
ifelse($2`'_NUM($3)`'$5`'_NUM($6),`void0void0',`dnl
dnl
dnl Use predefined callback for SignalProxy0<void>, to reduce code size.

const Glib::SignalProxyInfo __CPPNAME__`'_signal_$4_info =
{
  "$1",
  (GCallback) &Glib::SignalProxyNormal::slot0_void_callback,
  (GCallback) &Glib::SignalProxyNormal::slot0_void_callback
};
',`dnl else

$2 __CPPNAME__`'_signal_$4_callback`'(__CNAME__`'* self, _COMMA_SUFFIX($3)`'void* data)
{
  using namespace __NAMESPACE__;
  typedef SigC::Slot`'_NUM($6)<$5`'_COMMA_PREFIX($6)> SlotType;

  // Do not try to call a signal on a disassociated wrapper.
  if(Glib::ObjectBase::_get_current_wrapper((GObject*) self))
  {
    try
    {
      if(SigC::SlotNode *const slot = Glib::SignalProxyNormal::data_to_slot`'(data))
ifelse(`$2',void,`dnl
        (*(SlotType::Proxy)(slot->proxy_))
            (_COMMA_SUFFIX($7) slot);
',`dnl else
        return _CONVERT($5,$2,`((*(SlotType::Proxy)(slot->proxy_))
            (_COMMA_SUFFIX($7) slot))');
')dnl endif
    }
    catch(...)
    {
      Glib::exception_handlers_invoke();
    }
  }
ifelse($2,void,,`dnl else

  typedef $2 RType;
  return RType`'();
')dnl
}
ifelse($2,void,,`dnl else

$2 __CPPNAME__`'_signal_$4_notify_callback`'(__CNAME__`'* self, _COMMA_SUFFIX($3)`' void* data)
{
  using namespace __NAMESPACE__;
  typedef SigC::Slot`'_NUM($6)<void`'_COMMA_PREFIX($6)> SlotType;

  // Do not try to call a signal on a disassociated wrapper.
  if(Glib::ObjectBase::_get_current_wrapper((GObject*) self))
  {
    try
    {
      if(SigC::SlotNode *const slot = Glib::SignalProxyNormal::data_to_slot`'(data))
        (*(SlotType::Proxy)(slot->proxy_))
            (_COMMA_SUFFIX($7) slot);
    }
    catch(...)
    {
      Glib::exception_handlers_invoke();
    }
  }

  typedef $2 RType;
  return RType`'();
}
')dnl endif

const Glib::SignalProxyInfo __CPPNAME__`'_signal_$4_info =
{
  "$1",
  (GCallback) &__CPPNAME__`'_signal_$4_callback,
  (GCallback) &__CPPNAME__`'_signal_$4_`'ifelse($2,void,,notify_)`'callback
};
')dnl endif

_SECTION(SECTION_CC_SIGNALPROXIES)
Glib::SignalProxy`'_NUM($6)<$5`'_COMMA_PREFIX($6)> __CPPNAME__::signal_$4`'()
{
  return Glib::SignalProxy`'_NUM($6)<$5`'_COMMA_PREFIX($6)>(this, &__CPPNAME__`'_signal_$4_info);
}

_POP()')


dnl
dnl _SIGNAL_PH(gname, crettype, cargs and names)
dnl Create a callback and set it in our derived G*Class.
dnl
define(`_SIGNAL_PH',`dnl
_PUSH(SECTION_PCC_CLASS_INIT_DEFAULT_SIGNAL_HANDLERS)
  klass->$1 = `&'$1_callback;
_SECTION(SECTION_PH_DEFAULT_SIGNAL_HANDLERS)
  static $2 $1_callback`'($3);
_POP()')



dnl                $1      $2       $3        $4
dnl _SIGNAL_PCC(cppname,gname,cpprettype,crettype,
dnl                        $5                $6          $7            $8
dnl                  `<cargs and names>',`<cnames>',`<cpparg names>',firstarg)
dnl
define(`_SIGNAL_PCC',`dnl
_PUSH(SECTION_PCC_DEFAULT_SIGNAL_HANDLERS)
$4 __CPPNAME__`'_Class::$2_callback`'($5)
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
      obj->on_$1`'($7);
',`dnl
      return _CONVERT($3,$4,`obj->on_$1`'($7)');
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


dnl                    $1      $2       $3 
dnl _SIGNAL_H(signame,rettype,`<cppargs>')
dnl
define(`_SIGNAL_H',`dnl
_PUSH(SECTION_H_DEFAULT_SIGNAL_HANDLERS)
  virtual $2 on_$1`'($3);
_POP()')

dnl              $1      $2     $3     $4         $5          $6
dnl _SIGNAL_CC(signame,gname,rettype,crettype,`<cppargs>',`<carg_names>')
dnl
define(`_SIGNAL_CC',`dnl
_PUSH(SECTION_CC_DEFAULT_SIGNAL_HANDLERS)
$3 __NAMESPACE__::__CPPNAME__::on_$1`'($5)
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
    (*base->$2)`'(gobj`'()`'_COMMA_PREFIX($6));
',`dnl
    return _CONVERT($4,$3,`(*base->$2)`'(gobj`'()`'_COMMA_PREFIX($6))');

  typedef $3 RType;
  return RType`'();
')dnl
}

_POP()')

