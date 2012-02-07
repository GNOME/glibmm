dnl $Id$

dnl
dnl
dnl  Code generation sections for making a method.
dnl
dnl


dnl
dnl method 
dnl           $1      $2     $3         $4       $5     $6    $7     $8        $9        $10         $11       $12         $13                $14        $15             $16
dnl  _METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,const,refreturn,errthrow,deprecated,constversion,ifdef,arglist_without_types,out_param,out_param_cpptype,wrap_line)
define(`_METHOD',`dnl
_PUSH(SECTION_CC)
ifelse(`$10',,,`_DEPRECATE_IFDEF_START
')dnl
ifelse(`$13',,,`#ifdef $13'
)dnl
$3 __CPPNAME__::$1`'($5)ifelse(`$7',1,` const')
{
ifelse(`$11',,dnl
`ifelse(`$8'`$9',,dnl If it is not errthrow or refreturn
`ifelse(`$14',,dnl If no output parameter is specified
`ifelse(`$3',void,dnl If it returns voids:
`  $2(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6);' dnl It it returns non-void:
,`  return _CONVERT($4,`$3',`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)');'dnl
)'dnl End if it returns voids.
dnl An output parameter is specified:
,`  _INITIALIZE($15,$4,`$14',`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)',$16);'dnl
)',dnl End if an output parameter is specified.
dnl If is errthrow or refreturn
`ifelse(`$9',,,`  GError* gerror = 0;')
ifelse(`$14',,dnl If no output parameter is specified:
`  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,`$3',`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)');'dnl
dnl An output parameter is specified:
,`  _INITIALIZE($15,$4,`$14',`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)',$16);'dnl
)dnl
ifelse(`$9',,,`
  if(gerror)
    ::Glib::Error::throw_exception(gerror);
')
ifelse(`$8',,,`dnl
  if(ifelse(`$14',,`retvalue',$14))
    ifelse(`$14',,`retvalue',$14)->reference(); //The function does not do a ref for us.
')dnl
ifelse(`$3',void,,`  return retvalue;')
')dnl End errthrow/refreturn
',`  return const_cast<__CPPNAME__*>(this)->$1($12);')
}

ifelse(`$13',,,`
#endif // $13
')dnl
ifelse(`$10',,,`_DEPRECATE_IFDEF_END
')dnl
_POP()')

dnl
dnl static method
dnl                  $1       $2     $3         $4      $5     $6      $7      $8         $9       $10     $11        $12           $13
dnl  _STATIC_METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,refreturn,errthrow,deprecated,ifdef,out_param,out_param_type,wrap_line)
define(`_STATIC_METHOD',`dnl
_PUSH(SECTION_CC)
ifelse(`$9',,,`_DEPRECATE_IFDEF_START
')dnl
ifelse(`$10',,,`#ifdef $10'
)dnl
$3 __CPPNAME__::$1($5)
{
ifelse(`$7'`$8',,dnl
`ifelse(`$11',,dnl If no output parameter is specified
`ifelse(`$3',void,,`  return ')_CONVERT($4,`$3',`$2`'($6)');
'dnl
dnl An output parameter is specified:
,`  _INITIALIZE($12,$4,`$11',`$2`'($6)',$13);'
)',dnl End if an output parameter is specified.
`ifelse(`$8',,,`  GError* gerror = 0;')
ifelse(`$11',,dnl If no output parameter is specified:
  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,`$3',`$2`'($6)');
dnl An output parameter is specified:
,`  _INITIALIZE($12,$4,`$11',`$2`'($6)',$13);'dnl
)dnl
ifelse(`$8',,,`
  if(gerror)
    ::Glib::Error::throw_exception(gerror);
')
ifelse(`$7',,,`dnl
  if(ifelse(`$11',,`retvalue',$11))
    ifelse(`$11',,`retvalue',$11)->reference(); //The function does not do a ref for us
')dnl
ifelse(`$3',void,,`  return retvalue;')
')dnl
}

ifelse(`$10',,,`
#endif // $10
')dnl
ifelse(`$9',,,`_DEPRECATE_IFDEF_END
')
_POP()')


