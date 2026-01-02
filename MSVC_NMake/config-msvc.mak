# NMake Makefile portion for enabling features for Windows builds

# These are the base minimum libraries required for building glibmm.
!ifndef BASE_INCLUDEDIR
BASE_INCLUDEDIR = $(PREFIX)\include
!endif
!ifndef BASE_LIBDIR
BASE_LIBDIR = $(PREFIX)\lib
!endif
!ifndef BASE_TOOLS_PATH
BASE_TOOLS_PATH = $(PREFIX)\bin
!endif

# Please do not change anything beneath this line unless maintaining the NMake Makefiles
GLIBMM_MAJOR_VERSION = 2
GLIBMM_MINOR_VERSION = 68

SIGC_MAJOR_VERSION = 3
SIGC_MINOR_VERSION = 0

SIGC_SERIES = $(SIGC_MAJOR_VERSION).$(SIGC_MINOR_VERSION)
GLIBMM_API_VERSION = $(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)
GLIB_API_VERSION = 2.0
DEPS_MKFILE = deps-vs$(VSVER)-$(PLAT)-$(CFG).mak
M4_PATH_MKFILE = find-m4-bindir-vs$(VSVER)-$(PLAT)-$(CFG).mak
BUILD_MKFILE_SNIPPET = glibmm-vs$(VSVER)-$(PLAT)-$(CFG).mak
UNIX_TOOLS_PATH_MKFILE = check-unix-tools-bindir-vs$(VSVER)-$(PLAT)-$(CFG).mak

# Gather up dependencies for their include directories and lib/bin dirs.
!if [for %t in (SIGC GLIB) do @(echo !ifndef %t_INCLUDEDIR>>$(DEPS_MKFILE) & echo %t_INCLUDEDIR=^$^(BASE_INCLUDEDIR^)>>$(DEPS_MKFILE) & echo !endif>>$(DEPS_MKFILE))]
!endif
!if [for %t in (SIGC GLIB) do @(echo !ifndef %t_LIBDIR>>$(DEPS_MKFILE) & echo %t_LIBDIR=^$^(BASE_LIBDIR^)>>$(DEPS_MKFILE) & echo !endif>>$(DEPS_MKFILE))]
!endif
!if [for %t in (GLIB) do @(echo !ifndef %t_BINDIR>>$(DEPS_MKFILE) & echo %t_BINDIR=^$^(BASE_TOOLS_PATH^)>>$(DEPS_MKFILE) & echo !endif>>$(DEPS_MKFILE))]
!endif

!include $(DEPS_MKFILE)

!if [del /f/q $(DEPS_MKFILE)]
!endif

!if "$(CFG)" == "debug" || "$(CFG)" == "Debug"
DEBUG_SUFFIX = -d
!else
DEBUG_SUFFIX =
!endif

!ifndef M4
!ifdef UNIX_TOOLS_BINDIR
M4 = $(UNIX_TOOLS_BINDIR)\m4.exe
!else
M4 = m4
!endif
!endif

# Try to deduce full path to m4.exe, as needed
!if [if not exist $(M4)\ if exist $(M4) echo M4_FULL_PATH = $(M4)>$(M4_PATH_MKFILE)]
!endif
!if [if exist $(M4).exe echo M4_FULL_PATH = $(M4).exe>$(M4_PATH_MKFILE)]
!endif
!if [if not exist $(M4_PATH_MKFILE) ((echo M4_FULL_PATH = \>$(M4_PATH_MKFILE)) & where $(M4)>>$(M4_PATH_MKFILE) 2>NUL)]
!endif

!include $(M4_PATH_MKFILE)

!if [del /f/q $(M4_PATH_MKFILE)]
!endif

!if [if not "$(UNIX_TOOLS_BINDIR)" == "" if not "$(M4_FULL_PATH)" == "" echo UNIX_TOOLS_BINDIR_CHECKED = $(UNIX_TOOLS_BINDIR)>$(UNIX_TOOLS_PATH_MKFILE)]
!endif

!if [if "$(UNIX_TOOLS_BINDIR)" == "" if not "$(M4_FULL_PATH)" == "" (for %f in ($(M4_FULL_PATH)) do @echo UNIX_TOOLS_BINDIR_CHECKED = %~dpf>$(UNIX_TOOLS_PATH_MKFILE))]
!endif

!if [if not exist $(UNIX_TOOLS_PATH_MKFILE) (echo UNIX_TOOLS_BINDIR_CHECKED = >$(UNIX_TOOLS_PATH_MKFILE))]
!endif

!include $(UNIX_TOOLS_PATH_MKFILE)

!if [del /f/q $(UNIX_TOOLS_PATH_MKFILE)]
!endif

GLIBMM_DEPS_INCLUDES =	\
	/FImsvc_recommended_pragmas.h	\
	/I$(GLIB_INCLUDEDIR)\gio-win32-$(GLIB_API_VERSION)	\
	/I$(GLIB_INCLUDEDIR)\glib-$(GLIB_API_VERSION)	\
	/I$(GLIB_LIBDIR)\glib-$(GLIB_API_VERSION)\include	\
	/I$(SIGC_INCLUDEDIR)\sigc++-$(SIGC_SERIES)	\
	/I$(SIGC_LIBDIR)\sigc++-$(SIGC_SERIES)\include	\
	/I$(BASE_INCLUDEDIR)

GLIBMM_BASE_INCLUDES =	\
	/I..\untracked\glib /I..\untracked\glib\glibmm		\
	/I..\glib /I..\glib\glibmm /I.\glibmm

GLIBMM_INCLUDES =	\
	/Ivs$(VSVER)\$(CFG)\$(PLAT)	\
	$(GLIBMM_BASE_INCLUDES)	\
	$(GLIBMM_DEPS_INCLUDES)

GIOMM_INCLUDES =	\
	/Ivs$(VSVER)\$(CFG)\$(PLAT)	\
	$(GLIBMM_BASE_INCLUDES:glib=gio)	\
	$(GLIBMM_BASE_INCLUDES)	\
	$(GLIBMM_DEPS_INCLUDES)

LIBGLIBMM_CFLAGS = $(CFLAGS) /DGLIBMM_BUILD /DSIZEOF_WCHAR_T=2
LIBGIOMM_CFLAGS = $(LIBGLIBMM_CFLAGS:/DGLIBMM_=/DGIOMM_)

# We build glibmm-vc$(VSVER_LIB)-$(GLIBMM_MAJOR_VERSION)_$(GLIBMM_MINOR_VERSION).dll or
#          glibmm-vc$(VSVER_LIB)-d-$(GLIBMM_MAJOR_VERSION)_$(GLIBMM_MINOR_VERSION).dll at least
#          giomm-vc$(VSVER_LIB)-$(GLIBMM_MAJOR_VERSION)_$(GLIBMM_MINOR_VERSION).dll or
#          giomm-vc$(VSVER_LIB)-d-$(GLIBMM_MAJOR_VERSION)_$(GLIBMM_MINOR_VERSION).dll at least

!if "$(USE_COMPAT_LIBS)" != ""
VSVER_LIB = $(PDBVER)0
MESON_VSVER_LIB =
!else
VSVER_LIB = $(PDBVER)$(VSVER_SUFFIX)
MESON_VSVER_LIB = -vc$(VSVER_LIB)
!endif

!ifdef USE_MESON_LIBS
SIGC_LIBNAME = sigc-$(SIGC_SERIES)
GLIBMM_LIBNAME = glibmm$(MESON_VSVER_LIB)-$(GLIBMM_API_VERSION)
GIOMM_LIBNAME = giomm$(MESON_VSVER_LIB)-$(GLIBMM_API_VERSION)
GLIBMM_EXTRA_DEFS_GEN_LIBNAME = glibmm_generate_extra_defs-$(GLIBMM_API_VERSION)

GLIBMM_DLLNAME = $(GLIBMM_LIBNAME)-1
GIOMM_DLLNAME = $(GIOMM_LIBNAME)-1
GLIBMM_EXTRA_DEFS_GEN_DLLNAME = $(GLIBMM_EXTRA_DEFS_GEN_LIBNAME)-1
!else
SIGC_LIBNAME = sigc-vc$(VSVER_LIB)$(DEBUG_SUFFIX)-$(SIGC_SERIES:.=_)
GLIBMM_LIBNAME = glibmm-vc$(VSVER_LIB)$(DEBUG_SUFFIX)-$(GLIBMM_API_VERSION:.=_)
GIOMM_LIBNAME = giomm-vc$(VSVER_LIB)$(DEBUG_SUFFIX)-$(GLIBMM_API_VERSION:.=_)
GLIBMM_EXTRA_DEFS_GEN_LIBNAME = glibmm_generate_extra_defs-$(GLIBMM_API_VERSION)

GLIBMM_DLLNAME = $(GLIBMM_LIBNAME)
GIOMM_DLLNAME = $(GIOMM_LIBNAME)
GLIBMM_EXTRA_DEFS_GEN_DLLNAME = $(GLIBMM_EXTRA_DEFS_GEN_LIBNAME)
!endif

SIGC_LIB = $(SIGC_LIBNAME).lib

GLIBMM_DLL = vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_DLLNAME).dll
GLIBMM_LIB = vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).lib
GIOMM_DLL = vs$(VSVER)\$(CFG)\$(PLAT)\$(GIOMM_DLLNAME).dll
GIOMM_LIB = vs$(VSVER)\$(CFG)\$(PLAT)\$(GIOMM_LIBNAME).lib
GLIBMM_EXTRA_DEFS_GEN_DLL = vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_EXTRA_DEFS_GEN_DLLNAME).dll
GLIBMM_EXTRA_DEFS_GEN_LIB = vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_EXTRA_DEFS_GEN_LIBNAME).lib

# Set up library paths for libsigc++ and GLib
BASE_LDFLAGS = /libpath:$(BASE_LIBDIR)
!if "$(SIGC_LIBDIR)" != "$(BASE_LIBDIR)"
SIGC_LDFLAGS = /libpath:$(SIGC_LIBDIR)
!endif

# GLib
!if "$(GLIB_LIBDIR)" != "$(BASE_LIBDIR)"
GLIB_LDFLAGS = /libpath:$(GLIB_LIBDIR)
!endif

GOBJECT_LIBS = gobject-2.0.lib gmodule-2.0.lib glib-2.0.lib
GIO_LIBS = gio-2.0.lib $(GOBJECT_LIBS)
GOBJECT_LDFLAGS = $(GLIB_LDFLAGS) $(GOBJECT_LIBS) $(BASE_LDFLAGS)
GIO_LDFLAGS =  $(GLIB_LDFLAGS) $(GIO_LIBS) $(BASE_LDFLAGS)
SIGC_LDFLAGS = $(SIGC_LDFLAGS) $(SIGC_LIB)

GLIBMM_EX_LIBS = $(GLIBMM_LIB) $(SIGC_LDFLAGS) $(GOBJECT_LDFLAGS)
GIOMM_EX_LIBS = $(GIOMM_LIB) $(GLIBMM_LIB) $(SIGC_LDFLAGS) $(GIO_LDFLAGS)

# Set a default location for glib-compile-schemas, if not specified
!ifndef GLIB_COMPILE_SCHEMAS
GLIB_COMPILE_SCHEMAS = $(GLIB_BINDIR)\glib-compile-schemas
!endif
