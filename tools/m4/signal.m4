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
dnl               $8 = `custom_c_callback (boolean)',
dnl               $9 = `deprecated' (boolean),
dnl               $10 = `refdoc_comment',
dnl               $11 = ifdef,
dnl               $12 = exceptionHandler,
dnl               $13 = detail_name,
dnl               $14 = two_signal_methods (boolean))

define(`_SIGNAL_PROXY',`
ifelse(`$11',,,`#ifdef $11'
)dnl
ifelse(`$9',,,`_DEPRECATE_IFDEF_START
')dnl
ifelse($13,,`dnl no detail_name
$10
  Glib::SignalProxy< $5`'_COMMA_PREFIX($6) > signal_$4`'();
',dnl detail_name
$14,0,`dnl
$10
  Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) > signal_$4`'(const Glib::ustring& $13 = Glib::ustring());
',`dnl detail_name and two_signal_methods
$10
  Glib::SignalProxy< $5`'_COMMA_PREFIX($6) > signal_$4`'();

$10
  Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) > signal_$4`'(const Glib::ustring& $13);
')dnl end detail_name
ifelse(`$9',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$11',,,`#endif // $11
')dnl
dnl
_PUSH(SECTION_ANONYMOUS_NAMESPACE)

ifelse(`$11',,,`#ifdef $11'
)dnl
ifelse(`$9',,,`_DEPRECATE_IFDEF_START
')dnl
dnl
ifelse($2`'_NUM($3)`'$5`'_NUM($6)`'$8`'_NUM($12),`void0void000',`dnl
dnl
dnl Use predefined callback for SignalProxy0<void>, to reduce code size,
dnl if custom_c_callback or exception_handler is not specified.

static const Glib::SignalProxyInfo __CPPNAME__`'_signal_$4_info =
{
  "$1",
  (GCallback) &Glib::SignalProxyNormal::slot0_void_callback,
  (GCallback) &Glib::SignalProxyNormal::slot0_void_callback
};
',`dnl else

ifelse($8,`1',,`dnl Do not generate the implementation if it should be custom:
static $2 __CPPNAME__`'_signal_$4_callback`'(__CNAME__`'* self, _COMMA_SUFFIX($3)`'void* data)
{
  using namespace __NAMESPACE__;
  using SlotType = sigc::slot< $5`'_COMMA_PREFIX($6) >;

  auto obj = dynamic_cast<__CPPNAME__*>(Glib::ObjectBase::_get_current_wrapper((GObject*) self));
  // Do not try to call a signal on a disassociated wrapper.
  if(obj)
  {
    try
    {
      if(const auto slot = Glib::SignalProxyNormal::data_to_slot`'(data))
ifelse(`$2',void,`dnl
        (*static_cast<SlotType*>(slot))($7);
',`dnl else
        return _CONVERT($5,$2,`(*static_cast<SlotType*>(slot))($7)');
')dnl endif
    }
    catch(...)
    {
ifelse($12, `', `dnl
       Glib::exception_handlers_invoke`'();
', `dnl
       try
       {
         return _CONVERT($5, $2, `obj->$12`'()');
       }
       catch(...)
       {
          Glib::exception_handlers_invoke`'();
       }
')dnl
    }
  }
ifelse($2,void,,`dnl else

  using RType = $2;
  return RType`'();
')dnl
}
ifelse($2,void,,`dnl else

static $2 __CPPNAME__`'_signal_$4_notify_callback`'(__CNAME__`'* self, _COMMA_SUFFIX($3)`' void* data)
{
  using namespace __NAMESPACE__;
  using SlotType = sigc::slot< void`'_COMMA_PREFIX($6) >;

  auto obj = dynamic_cast<__CPPNAME__*>(Glib::ObjectBase::_get_current_wrapper((GObject*) self));
  // Do not try to call a signal on a disassociated wrapper.
  if(obj)
  {
    try
    {
      if(const auto slot = Glib::SignalProxyNormal::data_to_slot`'(data))
        (*static_cast<SlotType*>(slot))($7);
    }
    catch(...)
    {
ifelse($12, `', `dnl
      Glib::exception_handlers_invoke`'();
', `dnl
      try
      {
        return _CONVERT($5, $2, `obj->$12`'()');
      }
      catch(...)
      {
        Glib::exception_handlers_invoke`'();
      }
')dnl
    }
  }

  using RType = $2;
  return RType`'();
}
')dnl endif
')dnl endif

static const Glib::SignalProxyInfo __CPPNAME__`'_signal_$4_info =
{
  "$1",
  (GCallback) &__CPPNAME__`'_signal_$4_callback,
  (GCallback) &__CPPNAME__`'_signal_$4_`'ifelse($2,void,,notify_)`'callback
};
')dnl endif

ifelse(`$9',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$11',,,`#endif // $11
')dnl

_SECTION(SECTION_CC_SIGNALPROXIES)

ifelse(`$11',,,`#ifdef $11'
)dnl
ifelse(`$9',,,`_DEPRECATE_IFDEF_START
')dnl
ifelse($13,,`dnl no detail_name
Glib::SignalProxy< $5`'_COMMA_PREFIX($6) > __CPPNAME__::signal_$4`'()
{
  return Glib::SignalProxy< $5`'_COMMA_PREFIX($6) >(this, &__CPPNAME__`'_signal_$4_info);
}
',dnl detail_name
$14,0,`dnl
Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) > __CPPNAME__::signal_$4`'(const Glib::ustring& $13)
{
  return Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) >(this, &__CPPNAME__`'_signal_$4_info, $13);
}
',`dnl detail_name and two_signal_methods
Glib::SignalProxy< $5`'_COMMA_PREFIX($6) > __CPPNAME__::signal_$4`'()
{
  return Glib::SignalProxy< $5`'_COMMA_PREFIX($6) >(this, &__CPPNAME__`'_signal_$4_info);
}

Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) > __CPPNAME__::signal_$4`'(const Glib::ustring& $13)
{
  return Glib::SignalProxyDetailedAnyType< $5`'_COMMA_PREFIX($6) >(this, &__CPPNAME__`'_signal_$4_info, $13);
}
')dnl end detail_name
ifelse(`$9',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$11',,,`#endif // $11
')dnl

_POP()')


dnl              $1      $2            $3          $4       $5           $6
dnl _SIGNAL_PH(gname, crettype, cargs and names, ifdef, deprecated, exceptionHandler)
dnl Create a callback and set it in our derived G*Class.
dnl
define(`_SIGNAL_PH',`dnl
_PUSH(SECTION_PCC_CLASS_INIT_DEFAULT_SIGNAL_HANDLERS)
ifelse(`$4',,,`#ifdef $4'
)dnl
ifelse(`$5',,,`_DEPRECATE_IFDEF_START
')dnl
  klass->$1 = `&'$1_callback;
ifelse(`$5',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$4',,,`#endif // $4
')dnl
_SECTION(SECTION_PH_DEFAULT_SIGNAL_HANDLERS)
ifelse(`$4',,,`#ifdef $4'
)dnl
ifelse(`$5',,,`_DEPRECATE_IFDEF_START
')dnl
  static $2 $1_callback`'($3);
ifelse(`$5',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$4',,,`#endif // $4
')dnl
_POP()')



dnl                $1      $2       $3        $4         $5               $6
dnl _SIGNAL_PCC(cppname,gname,cpprettype,crettype,`<cargs and names>',`<cnames>',
dnl                  $7            $8      $9       $10          $11
dnl            `<cpparg names>',firstarg,<ifdef>,deprecated,exceptionHandler)
dnl
define(`_SIGNAL_PCC',`dnl
_PUSH(SECTION_PCC_DEFAULT_SIGNAL_HANDLERS)
ifelse(`$9',,,`#ifdef $9'
)dnl
ifelse(`$10',,,`_DEPRECATE_IFDEF_START
')dnl
$4 __CPPNAME__`'_Class::$2_callback`'($5)
{
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
        obj->on_$1`'($7);
        return;
',`dnl
        return _CONVERT($3,$4,`obj->on_$1`'($7)');
')dnl
      }
      catch(...)
      {
ifelse($11, `', `dnl
        Glib::exception_handlers_invoke`'();
', `dnl
        try
        {
          return _CONVERT($3, $4, `obj->$11`'()');
        }
        catch(...)
        {
          Glib::exception_handlers_invoke`'();
        }
')dnl
      }
    }
  }

  const auto base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
        _IFACE_PARENT_FROM_OBJECT($8)dnl
',`dnl
        _PARENT_GCLASS_FROM_OBJECT($8)dnl
')    );
dnl    g_assert(base != nullptr);

  // Call the original underlying C function:
  if(base && base->$2)
    ifelse($4,void,,`return ')(*base->$2)`'($6);
ifelse($4,void,,`dnl

  using RType = $4;
  return RType`'();
')dnl
}
ifelse(`$10',,,`_DEPRECATE_IFDEF_END
')dnl
ifelse(`$9',,,`#endif // $9
')dnl
_POP()')


dnl               $1      $2       $3          $4
dnl _SIGNAL_H(signame, rettype, `<cppargs>', <ifdef>)
dnl
define(`_SIGNAL_H',`dnl
_PUSH(SECTION_H_DEFAULT_SIGNAL_HANDLERS)
ifelse(`$4',,,`#ifdef $4'
)dnl
  /// This is a default handler for the signal signal_$1`'().
  virtual $2 on_$1`'($3);
ifelse(`$4',,,`#endif // $4
')dnl
_POP()')

dnl              $1      $2     $3     $4         $5          $6            $7      $8			$9
dnl _SIGNAL_CC(signame,gname,rettype,crettype,`<cppargs>',`<carg_names>', const, refreturn, <ifdef>)
dnl
define(`_SIGNAL_CC',`dnl
_PUSH(SECTION_CC_DEFAULT_SIGNAL_HANDLERS)
ifelse(`$9',,,`#ifdef $9'
)dnl
$3 __NAMESPACE__::__CPPNAME__::on_$1`'($5)
{
  const auto base = static_cast<BaseClassType*>(
ifdef(`__BOOL_IS_INTERFACE__',`dnl
      _IFACE_PARENT_FROM_OBJECT(gobject_)dnl
',`dnl
      _PARENT_GCLASS_FROM_OBJECT(gobject_)dnl
')  );
dnl  g_assert(base != nullptr);

  if(base && base->$2)
ifelse($3,void,`dnl
    (*base->$2)`'(gobj`'()`'_COMMA_PREFIX($6));
',`dnl
ifelse($8,refreturn,`dnl Assume Glib::wrap() is correct if refreturn is requested.
    return Glib::wrap((*base->$2)`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'_COMMA_PREFIX($6)), true);
',`dnl
    return _CONVERT($4,$3,`(*base->$2)`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'_COMMA_PREFIX($6))');
')dnl

  using RType = $3;
  return RType`'();
')dnl
}
ifelse(`$9',,,`#endif // $9
')dnl
_POP()')

