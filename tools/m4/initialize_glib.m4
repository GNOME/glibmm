dnl
dnl Initialization rules for glibmm C++ types from Glib C types.
dnl

dnl Basic Types
_INITIALIZATION(`bool&',`gboolean',`$3 = static_cast<bool>($4)')


dnl VariantBase
_INITIALIZATION(`Glib::VariantBase&',`GVariant*',`$3 = Glib::wrap($4)')

dnl VariantType
_INITIALIZATION(`Glib::VariantType&',`const GVariantType*',`$3 = Glib::wrap(const_cast<GVariantType*>($4))')

dnl ustring
_INITIALIZATION(`Glib::ustring&',`gchar*',`$3 = Glib::convert_return_gchar_ptr_to_ustring($4)')
