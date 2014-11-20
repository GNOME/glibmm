dnl
dnl Glib C names have prefix 'G' but C++ namespace Glib
dnl
define(`_CONV_GLIB_ENUM',`dnl
_CONVERSION(`G$1', `$1', (($1)(__ARG3__)))
_CONVERSION(`G$1', `Glib::$1', ((Glib::$1)(__ARG3__)))
_CONVERSION(`$1', `G$1', ((G$1)(__ARG3__)))
_CONVERSION(`Glib::$1', `G$1', ((G$1)(__ARG3__)))
')dnl

_EQUAL(gchar,char)
_EQUAL(gchar*,char*)
_EQUAL(gchar**,char**)
_EQUAL(gint**,int**)
_EQUAL(gchar**,char*[])
_EQUAL(const gchar*,const char*)
_EQUAL(const-gchar*,const char*)
_EQUAL(gpointer*,void**)

_EQUAL(gboolean,int)
_EQUAL(gint,int)
_EQUAL(gint*,int*)
_EQUAL(gint&,int&)
_EQUAL(guint,unsigned int)
_EQUAL(guint*,unsigned int*)
_EQUAL(guint&,unsigned int&)
_EQUAL(gdouble,double)
_EQUAL(gdouble*,double*)
_EQUAL(gfloat, float)
_EQUAL(float*,gfloat[])

_EQUAL(const-char*,const-gchar*)
_EQUAL(return-char*,return-gchar*)
_EQUAL(gpointer,void*)
_EQUAL(gconstpointer,const void*)

_EQUAL(GdkAtom,Gdk::Atom)
_EQUAL(GTimeSpan,TimeSpan)

# Basic Types
_CONVERSION(`int',`bool',`$3')
_CONVERSION(`bool',`int',`static_cast<int>($3)')
_CONVERSION(`unsigned int',`bool',`$3')
_CONVERSION(`bool',`unsigned int',`static_cast<unsigned int>($3)')
_CONVERSION(`bool&',`gboolean*',`(($2) &($3))')
_CONVERSION(`int&',`gint*',`&($3)')
_CONVERSION(`gint*',`int&',`*($3)')
_CONVERSION(`guint&',`guint*',`&($3)')
_CONVERSION(`guint64&',`guint64*',`&($3)')
_CONVERSION(`double&',`gdouble*',`&($3)')
_CONVERSION(`float&',`gfloat*',`&($3)')
_CONVERSION(`gchar**',`char**',`$3')
_CONVERSION(`char**',`gchar**',`$3')
_CONVERSION(`gpointer&',`gpointer*',`&($3)')
_CONVERSION(`void*&',`gpointer*',`&($3)')

_CONVERSION(`GError*&',`GError**',`&($3)')

dnl
dnl # These are for fixmegtkconst
_CONVERSION(`const guchar*',`guchar*',`const_cast<guchar*>($3)',`$3')

_CONV_GLIB_ENUM(BindingFlags)
_CONV_GLIB_ENUM(IOCondition)
_CONV_GLIB_ENUM(IOFlags)
_CONV_GLIB_ENUM(IOStatus)
_CONV_GLIB_ENUM(KeyFileFlags)
_CONV_GLIB_ENUM(OptionArg)
_CONV_GLIB_ENUM(RegexCompileFlags)
_CONV_GLIB_ENUM(RegexMatchFlags)
_CONV_GLIB_ENUM(SeekType)
_CONV_GLIB_ENUM(TimeType)


_CONVERSION(`gunichar&',`gunichar*',`&($3)')
_CONVERSION(`gsize&',`gsize*',`&($3)')


# Strings:
define(`__GCHARP_TO_USTRING',`Glib::convert_const_gchar_ptr_to_ustring($`'3)')
define(`__GCHARP_TO_STDSTRING',`Glib::convert_const_gchar_ptr_to_stdstring($`'3)')

_CONVERSION(`const Glib::ustring&',`const char*',`$3.c_str()')
_CONVERSION(`const Glib::ustring&', `const guchar*', `(($2)$3.c_str())')
_CONVERSION(`const std::string&',`const char*',`$3.c_str()')
_CONVERSION(`std::string',`const char*',`$3.c_str()')
_CONVERSION(`const Glib::ustring&',`gchar*',`const_cast<gchar*>($3.c_str())')
_CONVERSION(`gchar*',`Glib::ustring',__GCHARP_TO_USTRING)
_CONVERSION(`const-gchar*',`Glib::ustring',__GCHARP_TO_USTRING)
_CONVERSION(`const-guchar*',`Glib::ustring',__GCHARP_TO_USTRING)
_CONVERSION(`const gchar*',`Glib::ustring',__GCHARP_TO_USTRING)
_CONVERSION(`const char*',`Glib::ustring',__GCHARP_TO_USTRING)
_CONVERSION(`const char*',`const Glib::ustring&',__GCHARP_TO_USTRING)
_CONVERSION(`const char*',`std::string',__GCHARP_TO_STDSTRING)
_CONVERSION(`const char*',`const-gchar*',`$3')
_CONVERSION(`const-gchar*',`const char*',`$3')
_CONVERSION(`const char*',`const std::string&',__GCHARP_TO_STDSTRING)
_CONVERSION(`char*',`std::string',__GCHARP_TO_STDSTRING)
_CONVERSION(`std::string', `char*', `g_strdup(($3).c_str())')
_CONVERSION(`const std::string&', `char*', `g_strdup(($3).c_str())')
_CONVERSION(`Glib::ustring', `char*', `g_strdup(($3).c_str())')

_CONVERSION(`return-gchar*',`Glib::ustring',`Glib::convert_return_gchar_ptr_to_ustring($3)')
_CONVERSION(`return-gchar*',`std::string',`Glib::convert_return_gchar_ptr_to_stdstring($3)')
_CONVERSION(`return-char*',`Glib::ustring',`Glib::convert_return_gchar_ptr_to_ustring($3)')

dnl DateTime
_CONVERSION(`GDateTime*',`DateTime',`Glib::wrap($3)')
_CONVERSION(`GDateTime*',`Glib::DateTime',`Glib::wrap($3)')
_CONVERSION(`const DateTime&',`GDateTime*',`const_cast<$2>($3.gobj())')

dnl KeyFile
_CONVERSION(`Glib::KeyFile&',`GKeyFile*',`($3).gobj()')

dnl Object
_CONVERSION(`const Glib::RefPtr<Glib::Object>&',`GObject*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<const Glib::Object>&',`GObject*',__CONVERT_CONST_REFPTR_TO_P_SUN(Glib::Object))
_CONVERSION(`GObject*',`Glib::RefPtr<Glib::Object>',`Glib::wrap($3)')
_CONVERSION(`GObject*',`Glib::RefPtr<const Glib::Object>',`Glib::wrap($3)')

_CONVERSION(`GObject*',`Glib::RefPtr<Glib::ObjectBase>',`Glib::wrap($3)')
_CONVERSION(`GObject*',`Glib::RefPtr<const Glib::ObjectBase>',`Glib::wrap($3)')

dnl OptionGroup
_CONVERSION(`OptionGroup&',`GOptionGroup*',`($3).gobj()')
_CONVERSION(`Glib::OptionGroup&',`GOptionGroup*',`($3).gobj()')

dnl Bytes
_CONVERSION(`GBytes*',`Glib::RefPtr<Glib::Bytes>',`Glib::wrap($3)')
_CONVERSION(`GBytes*',`Glib::RefPtr<const Glib::Bytes>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<const Glib::Bytes>&',`GBytes*',__CONVERT_CONST_REFPTR_TO_P_SUN(Glib::Bytes)))

dnl ByteArray
_CONVERSION(`GByteArray*',`Glib::RefPtr<ByteArray>',`Glib::wrap($3)')

dnl Regex
_CONVERSION(`GRegex*',`Glib::RefPtr<Regex>',`Glib::wrap($3)')
_CONVERSION(`GRegex*',`Glib::RefPtr<const Regex>',`Glib::wrap($3)')

#Source
_CONVERSION(`GSource*',`Glib::RefPtr<Glib::Source>',`Glib::wrap($3)')

dnl TimeVal
_CONVERSION(`const TimeVal&',`const GTimeVal*',`&($3)')
_CONVERSION(`TimeVal&',`GTimeVal*',`&($3)')

dnl TimeZone
_CONVERSION(`GTimeZone*',`TimeZone',`Glib::wrap($3)')
_CONVERSION(`const TimeZone&',`GTimeZone*',`const_cast<$2>($3.gobj())')

dnl ValueBase
_CONVERSION(`Glib::ValueBase&',`GValue*',`($3).gobj()')
_CONVERSION(`const Glib::ValueBase&',`const GValue*',`($3).gobj()')
_CONVERSION(`const Glib::ValueBase&',`GValue*',`const_cast<GValue*>(($3).gobj())')
_CONVERSION(`GValue*', `Glib::ValueBase&', `*reinterpret_cast<Glib::ValueBase*>($3)')
_CONVERSION(`const GValue*', `const Glib::ValueBase&', `*reinterpret_cast<const Glib::ValueBase*>($3)')

#Variant
_CONVERSION(`GVariant*',`Glib::VariantBase',`Glib::wrap($3, false)')
_CONVERSION(`GVariant*',`Glib::VariantContainerBase',`Glib::VariantContainerBase($3, false)')
_CONVERSION(`const VariantBase&',`GVariant*',`const_cast<GVariant*>(($3).gobj())')
_CONVERSION(`const Glib::VariantBase&',`GVariant*',`const_cast<GVariant*>(($3).gobj())')
_CONVERSION(`const Glib::VariantContainerBase&',`GVariant*',`const_cast<GVariant*>(($3).gobj())')

# VariantContainerBase
_CONVERSION(`const VariantContainerBase&',`GVariant*',`const_cast<GVariant*>(($3).gobj())')

#VariantDict
_CONVERSION(`GVariantDict*',`Glib::RefPtr<VariantDict>',`Glib::wrap($3)')
_CONVERSION(`GVariantDict*',`Glib::RefPtr<Glib::VariantDict>',`Glib::wrap($3)')
_CONVERSION(`GVariantDict*',`Glib::RefPtr<const Glib::VariantDict>',`Glib::wrap($3)')

#VariantType
_CONVERSION(`const GVariantType*',`Glib::VariantType',`Glib::wrap(const_cast<GVariantType*>($3), true)')
_CONVERSION(`const VariantType&',`const GVariantType*',`($3).gobj()')
_CONVERSION(`const Glib::VariantType&',`const GVariantType*',`($3).gobj()')
_CONVERSION(`GVariantType*',`VariantType',`Glib::wrap($3)')

dnl Miscellaneous
_CONVERSION(`gint64&',`gint64*',`&($3)')
