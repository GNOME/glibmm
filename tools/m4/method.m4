dnl $Id$

dnl
dnl
dnl  Code generation sections for making a method.  
dnl
dnl


dnl
dnl method 
dnl            $1      $2     $3         $4       $5    $6    $7     $8        $9
dnl  _METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,const,refreturn,errthrow)
define(`_METHOD',`dnl
_PUSH(SECTION_CC)
$3 __CPPNAME__::$1`'($5)ifelse(`$7',1,` const')
{
ifelse(`$8'`$9',,dnl
`  ifelse(`$3',void,,`return ')_CONVERT($4,$3,`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)');
', dnl
`ifelse(`$9',,,`  GError *error = 0;')
  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,$3,`$2`'(ifelse(`$7',1,const_cast<__CNAME__*>(gobj()),gobj())`'ifelse(`$6',,,`, ')$6)');
ifelse(`$9',,,`  if(error) ::Glib::Error::throw_exception(error);')
ifelse(`$8',,,`dnl
  if(!(retvalue.is_null()))
    retvalue->reference(); //The function does not do a ref for us.
')dnl
ifelse(`$3',void,,`  return retvalue;')
')dnl
}

_POP()')

dnl
dnl static method
dnl                  $1       $2     $3         $4      $5     $6      $7      $8
dnl  _STATIC_METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,refreturn,errthrow))
define(`_STATIC_METHOD',`dnl
_PUSH(SECTION_CC)
$3 __CPPNAME__::$1($5)
{
ifelse(`$7'`$8',,dnl
`  ifelse(`$3',void,,`return ')_CONVERT($4,$3,`$2`'($6)');
', dnl
`ifelse(`$8',,,`  GError *error = 0;')
  ifelse(`$3',void,,``$3' retvalue = ')_CONVERT($4,$3,`$2`'($6)');
ifelse(`$8',,,`  if(error) ::Glib::Error::throw_exception(error);')
ifelse(`$7',,,`dnl
  if(!(retvalue.is_null()))
    retvalue->reference(); //The function does not do a ref for us.
')dnl
ifelse(`$3',void,,`  return retvalue;')
')dnl
}

_POP()')


