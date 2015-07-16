dnl
dnl
dnl  Code generation sections for making a method.
dnl
dnl

dnl
dnl method
dnl           $1       $2     $3         $4       $5        $6        $7         $8
dnl  _METHOD(cppname,cname,cpprettype,crettype,arglist,cdeclarations,cargs,cinitializations,
dnl           $9     $10       $11       $12         $13             $14             $15
dnl          const,refreturn,errthrow,deprecated,constversion,arglist_without_types,ifdef,
dnl             $16        $17              $18        $19        $20         $21
dnl          out_param,out_param_cpptype,slot_type,slot_name,no_slot_copy,wrap_line)
define(`_METHOD',`dnl
_PUSH(SECTION_CC)
ifelse(`$15',,,`#ifdef $15'
)dnl
ifelse(`$12',,,`_DEPRECATE_IFDEF_START`'dnl The expansion of _DEPRECATE_IFDEF_START ends with a newline
G_GNUC_BEGIN_IGNORE_DEPRECATIONS
')dnl
$3 __CPPNAME__::$1`'($5)ifelse(`$9',1,` const')
{
ifelse(`$13',,dnl
`ifelse(`$10'`$11',,dnl If it is not errthrow or refreturn
dnl If a slot type has been specified insert a slot copy declaration.
`ifelse(`$18',,,dnl
dnl See if the slot should or should not be copied
`ifelse(`$20',,dnl
`  // Create a copy of the slot.
  auto slot_copy = new $18($19); ',dnl
dnl
`  // Use the original slot (not a copy).
  auto slot_copy = const_cast<$18*>(&$19);')

')`'dnl
dnl Insert the declarations for C output parameters
ifelse(`$6',,,`$6
')`'dnl
ifelse(`$16',,dnl If no C++ output parameter is specified
`ifelse(`$3',void,dnl If the C function returns voids:
`  $2(ifelse(`$9',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$7',,,`, ')$7);
dnl Insert the initializations for the C output parameters
ifelse(`$8',,,`$8
')dnl
',dnl If the C function returns non-void:
dnl Store the return if there are C output parameters.
`ifelse(`$6',,`  return ',`  `$3' retvalue = ')_CONVERT($4,`$3',`$2`'(ifelse(`$9',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$7',,,`, ')$7)');
dnl Insert the initializations for the C output parameters
ifelse(`$8',,,`$8
')dnl
dnl return the value
ifelse(`$6',,,`  return retvalue;
')dnl
')'dnl End if it returns voids.
dnl A C++ output parameter is specified:
,`  _INITIALIZE($17,$4,`$16',`$2`'(ifelse(`$9',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$7',,,`, ')$7)',$21);
dnl
dnl Insert the initializations for the C output parameters
ifelse(`$8',,,`$8
')dnl
')',dnl End if a C++ output parameter is specified.
dnl If is errthrow or refreturn
`ifelse(`$11',,,`  GError* gerror = nullptr;
')dnl
dnl If a slot type has been specified insert a slot copy declaration.
ifelse(`$18',,,dnl
dnl See if the slot should or should not be copied
`ifelse(`$20',,dnl
`  // Create a copy of the slot.
  auto slot_copy = new $18($19); ',dnl
dnl
`  // Use the original slot (not a copy).
  auto slot_copy = const_cast<$18*>(&$19);')

')`'dnl
dnl Insert the declarations for C output parameters
ifelse(`$6',,,`$6
')`'dnl
ifelse(`$16',,dnl If no C++ output parameter is specified:
`  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,`$3',`$2`'(ifelse(`$9',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$7',,,`, ')$7)');
'dnl
,dnl A C++ output parameter is specified:
`  _INITIALIZE($17,$4,`$16',`$2`'(ifelse(`$9',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$7',,,`, ')$7)',$21);
'dnl
)dnl
ifelse(`$11',,,`dnl
  if(gerror)
    ::Glib::Error::throw_exception(gerror);
')dnl
ifelse(`$10',,,`dnl
  if(ifelse(`$16',,`retvalue',$16))
    ifelse(`$16',,`retvalue',$16)->reference(); //The function does not do a ref for us.
')dnl
dnl Insert the initializations for the C output parameters
ifelse(`$8',,,`$8
')`'dnl
ifelse(`$3',void,,`  return retvalue;
')dnl
')dnl End errthrow/refreturn
',`  return const_cast<__CPPNAME__*>(this)->$1($14);
')dnl
}
ifelse(`$12',,,`G_GNUC_END_IGNORE_DEPRECATIONS
_DEPRECATE_IFDEF_END')`'dnl The expansion of _DEPRECATE_IFDEF_END ends with a newline
ifelse(`$15',,,`#endif // $15
')
_POP()')

dnl
dnl static method
dnl                  $1       $2     $3         $4      $5        $6         $7
dnl  _STATIC_METHOD(cppname,cname,cpprettype,crettype,arglist,cdeclarations,cargs,
dnl                        $8            $9      $10         $11    $12     $13
dnl                 cinitializations,refreturn,errthrow,deprecated,ifdef,out_param,
dnl                       $14          $15      $16          $17       $18
dnl                 out_param_type,slot_type,slot_name,no_slot_copy,wrap_line)
define(`_STATIC_METHOD',`dnl
_PUSH(SECTION_CC)
ifelse(`$12',,,`#ifdef $12'
)dnl
ifelse(`$11',,,`_DEPRECATE_IFDEF_START`'dnl The expansion of _DEPRECATE_IFDEF_START ends with a newline
G_GNUC_BEGIN_IGNORE_DEPRECATIONS
')dnl
$3 __CPPNAME__::$1($5)
{
ifelse(`$9'`$10',,dnl
dnl If a slot type has been specified insert a slot copy declaration.
ifelse(`$15',,,dnl
dnl See if the slot should or should not be copied
`ifelse(`$17',,dnl
`  // Create a copy of the slot.
  auto slot_copy = new $15($16); ',dnl
dnl
`  // Use the original slot (not a copy).
  auto slot_copy = const_cast<$15*>(&$16);')

')`'dnl
dnl Insert declarations for C the output parameters
ifelse(`$6',,,`$6
')`'dnl
`ifelse(`$13',,
dnl If no C++ output parameter is specified.
`  ifelse(`$3',void,,dnl
dnl Returns non-void:
dnl Store the return if there are C output parameters
ifelse(`$6',,`return ',``$3' retval = '))_CONVERT($4,`$3',`$2`'($7)');'dnl
dnl A C++ output parameter is specified so initialize it from C return
,`  _INITIALIZE($14,$4,`$13',`$2`'($7)',$18);'dnl
)
dnl Insert the initializations for the C output parameters if there are any
ifelse(`$8',,,`$8
')`'dnl
dnl Return the value if it was stored and if the method returns something
ifelse(`$3',void,,`ifelse(`$6',,,`  return retval;
')')dnl
',dnl End if a C++ output parameter is specified.
`ifelse(`$10',,,`  GError* gerror = nullptr;')
dnl If a slot type has been specified insert a slot copy declaration.
ifelse(`$15',,,dnl
dnl See if the slot should or should not be copied
`ifelse(`$17',,dnl
`  // Create a copy of the slot.
  auto slot_copy = new $15($16); ',dnl
dnl
`  // Use the original slot (not a copy).
  auto slot_copy = const_cast<$15*>(&$16);')

')`'dnl
dnl Insert the declarations for the C output parameters
ifelse(`$6',,,`$6
')`'dnl
ifelse(`$13',,dnl If no C++ output parameter is specified:
  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,`$3',`$2`'($7)');dnl
dnl A C++ output parameter is specified:
,`  _INITIALIZE($14,$4,`$13',`$2`'($7)',$18);'dnl
)dnl
ifelse(`$10',,,`
  if(gerror)
    ::Glib::Error::throw_exception(gerror);
')dnl
dnl Insert the initializations for the C output parameters.
ifelse(`$8',,,`$8
')`'dnl
ifelse(`$9',,,`
  if(ifelse(`$13',,`retvalue',$13))
    ifelse(`$13',,`retvalue',$13)->reference(); //The function does not do a ref for us
')dnl
ifelse(`$3',void,,`  return retvalue;
')dnl
')dnl
}
ifelse(`$11',,,`G_GNUC_END_IGNORE_DEPRECATIONS
_DEPRECATE_IFDEF_END')`'dnl The expansion of _DEPRECATE_IFDEF_END ends with a newline
ifelse(`$12',,,`#endif // $12
')
_POP()')
