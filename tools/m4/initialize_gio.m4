dnl
dnl Initializations for giomm C++ types from Gio C types.
dnl

dnl UnixFDList
_INITIALIZATION(`Glib::RefPtr<UnixFDList>&',`GUnixFDList*', `$3 = Glib::wrap($4)')
