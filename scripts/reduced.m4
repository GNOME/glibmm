## GLIBMM_ARG_ENABLE_API_PROPERTIES()
##
## Provide the --enable-api-properties configure argument, enabled
## by default.
##
AC_DEFUN([GLIBMM_ARG_ENABLE_API_PROPERTIES],
[
  AC_ARG_ENABLE([api-properties],
      [  --enable-api-properties  Build properties API.
                              [[default=yes]]],
      [glibmm_enable_api_properties="$enableval"],
      [glibmm_enable_api_properties='yes'])

  if test "x$glibmm_enable_api_properties" = "xyes"; then
  {
    AC_DEFINE([GLIBMM_PROPERTIES_ENABLED],[1], [Defined when the --enable-api-properties configure argument was given])
  }
  fi
])

## GLIBMM_ARG_ENABLE_API_VFUNCS()
##
## Provide the --enable-api-vfuncs configure argument, enabled
## by default.
##
AC_DEFUN([GLIBMM_ARG_ENABLE_API_VFUNCS],
[
  AC_ARG_ENABLE([api-vfuncs],
      [  --enable-api-vfuncs  Build vfuncs API.
                              [[default=yes]]],
      [glibmm_enable_api_vfuncs="$enableval"],
      [glibmm_enable_api_vfuncs='yes'])

  if test "x$glibmm_enable_api_vfuncs" = "xyes"; then
  {
    AC_DEFINE([GLIBMM_VFUNCS_ENABLED],[1], [Defined when the --enable-api-vfuncs configure argument was given])
  }
  fi
])
