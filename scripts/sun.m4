AC_DEFUN(GLIBMM_PROG_CXX_SUN,
  [AC_CACHE_CHECK(whether we are using SUN CC compiler, ac_cv_prog_sun_cxx,
    [if AC_TRY_COMMAND(${CXX-g++} -V 2>&1) | egrep "Sun WorkShop" >/dev/null 2>&1; then
      ac_cv_prog_sun_cxx=yes
    else
      ac_cv_prog_sun_cxx=no
    fi]
   )]

   if test "x${gtkmm_cv_cxx_has_namespace_std}" = "xyes"; then
   {
     AC_DEFINE([GLIBMM_COMPILER_SUN_FORTE],[1], [Defined when the SUN Forte C++ compiler is being used.])
   }
   fi
)
