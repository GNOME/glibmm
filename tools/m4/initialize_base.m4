dnl
dnl Macros for keeping track of how to initialize a C++ from a C type.

#
#  Define a hashing for names
#
define(`__HASH',`__`'m4_translit(`$*',`ABCDEFGHIJKLMNOPQRSTUVWXYZ<>[]&*, ',`abcdefghijklmnopqrstuvwxyzVBNMRSC_')`'')
define(`__EQUIV',`m4_ifdef(EV`'__HASH(`$1'),EV`'__HASH(`$1'),`$1')')

dnl __HASH2(firsttype, secondtype)
dnl
dnl Provides a textual combination of the two given types which can be used as
dnl a hash to store and retrieve conversions and initializations.  It first
dnl sees if the two types have equivalent types that should be used in their
dnl places (using the __EQUIV macro above).  Since the types returned by
dnl __EQUIV may contain commas (because of types such as std::map<>), quote the
dnl call to the macro to avoid the types to be interpreted as more than one
dnl argument to the pushdef() calls.  Also quote the expansion of the __E1 and
dnl __E2 macros in the m4_ifelse for the same reason.
define(`__HASH2',`dnl
pushdef(`__E1',`__EQUIV(`$1')')pushdef(`__E2',`__EQUIV(`$2')')dnl
m4_ifelse(_QUOTE(__E1),_QUOTE(__E2),`__EQ',__HASH(__E1)`'__HASH(__E2))`'dnl
popdef(`__E1')popdef(`__E2')`'')

define(`IN__EQ',`$3')

#  _INITIALIZE(target_type, fromtype, output_param_name, c_return, wrap_line)
#
#    Print an initialize statement from ctype to cpptype
define(`_INITIALIZE',`dnl
m4_ifelse(`$1',void,`$4',`dnl
pushdef(`__INI',`IN`'__HASH2(`$1',`$2')')dnl
m4_ifdef(__INI,`m4_indir(__INI,m4_substr(`$1',`0',m4_decr(m4_len(`$1'))),`$2',`$3', $4)',`
m4_errprint(`No initialization for type $1 from type $2 defined (line: $5, output param: $3, c return: $4)
')
m4_m4exit(1)
')`'dnl
')`'dnl
')

# _INITIALIZATION(fromtype, totype, initialization)
#
#  Functions for populating initialization tables.
#
define(`_INITIALIZATION',`
m4_ifelse(`$3',,,`define(IN`'__HASH2(`$1',`$2'),m4_patsubst(`$3',`; +',`;
  '))')
')


include(initialize_glib.m4)
