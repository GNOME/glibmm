dnl $Id$

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

define(`CF__EQ',`$3')

#  _CONVERT(fromtype, totype, name, wrap_line)
#
#    Print the conversion from 'fromtype' to 'totype'
define(`_CONVERT',`dnl
m4_ifelse(`$2',void,`$3',`dnl
pushdef(`__COV',`CF`'__HASH2(`$1',`$2')')dnl
m4_ifdef(__COV,`m4_indir(__COV,`$1',`$2',`$3')',`
m4_errprint(`No conversion from $1 to $2 defined (line: $4, parameter name: $3)
')
m4_m4exit(1)
')`'dnl
')`'dnl
')


# _CONVERSION(fromtype, totype, conversion)
#
#  Functions for populating the tables.
#
define(`_CONVERSION',`
m4_ifelse(`$3',,,`define(CF`'__HASH2(`$1',`$2'),`$3')')
')

define(`_EQUAL',`define(EV`'__HASH(`$1'),`$2')')

/*******************************************************************/


define(`__ARG3__',`$`'3')
define(`_CONV_ENUM',`dnl
_CONVERSION(`$1$2', `$2', (($2)(__ARG3__)))
_CONVERSION(`$1$2', `$1::$2', (($1::$2)(__ARG3__)))
_CONVERSION(`$2', `$1$2', (($1$2)(__ARG3__)))
_CONVERSION(`$1::$2', `$1$2', (($1$2)(__ARG3__)))
')dnl

# e.g. Glib::RefPtr<Gdk::Something> to GdkSomething*
define(`__CONVERT_REFPTR_TO_P',`Glib::unwrap($`'3)')

define(`__FR2P',`($`'3).gobj()')
define(`__CFR2P',`const_cast<$`'2>($`'3.gobj())')
define(`__FCR2P',`const_cast<$`'2>(($`'3).gobj())')

define(`__FL2H_SHALLOW',`$`'2($`'3, Glib::OWNERSHIP_SHALLOW)')

# e.g. Glib::RefPtr<const Gdk::Something> to GdkSomething*
#define(`__CONVERT_CONST_REFPTR_TO_P',`const_cast<$`'2>($`'3->gobj())')
define(`__CONVERT_CONST_REFPTR_TO_P',`const_cast<$`'2>(Glib::unwrap($`'3))')

# The Sun Forte compiler doesn't seem to be able to handle these, so we are using the altlernative,  __CONVERT_CONST_REFPTR_TO_P_SUN.
# The Sun compiler gives this error, for instance:
#  "widget.cc", line 4463: Error: Overloading ambiguity between "Glib::unwrap<Gdk::Window>(const Glib::RefPtr<const Gdk::Window>&)" and
# "Glib::unwrap<const Gdk::Window>(const Glib::RefPtr<const Gdk::Window>&)".
#
define(`__CONVERT_CONST_REFPTR_TO_P_SUN',`const_cast<$`'2>(Glib::unwrap<$1>($`'3))')


#include(convert_gtk.m4)
#include(convert_pango.m4)
#include(convert_gdk.m4)
#include(convert_atk.m4)
include(convert_glib.m4)

