# Convert the source listing to object (.obj) listing in
# another NMake Makefile module, include it, and clean it up.
# This is a "fact-of-life" regarding NMake Makefiles...
# This file does not need to be changed unless one is maintaining the NMake Makefiles

# For those wanting to add things here:
# To add a list, do the following:
# # $(description_of_list)
# if [call create-lists.bat header $(makefile_snippet_file) $(variable_name)]
# endif
#
# if [call create-lists.bat file $(makefile_snippet_file) $(file_name)]
# endif
#
# if [call create-lists.bat footer $(makefile_snippet_file)]
# endif
# ... (repeat the if [call ...] lines in the above order if needed)
# !include $(makefile_snippet_file)
#
# (add the following after checking the entries in $(makefile_snippet_file) is correct)
# (the batch script appends to $(makefile_snippet_file), you will need to clear the file unless the following line is added)
#!if [del /f /q $(makefile_snippet_file)]
#!endif

# In order to obtain the .obj filename that is needed for NMake Makefiles to build DLLs/static LIBs or EXEs, do the following
# instead when doing 'if [call create-lists.bat file $(makefile_snippet_file) $(file_name)]'
# (repeat if there are multiple $(srcext)'s in $(source_list), ignore any headers):
# !if [for %c in ($(source_list)) do @if "%~xc" == ".$(srcext)" @call create-lists.bat file $(makefile_snippet_file) $(intdir)\%~nc.obj]
#
# $(intdir)\%~nc.obj needs to correspond to the rules added in build-rules-msvc.mak
# %~xc gives the file extension of a given file, %c in this case, so if %c is a.cc, %~xc means .cc
# %~nc gives the file name of a given file without extension, %c in this case, so if %c is a.cc, %~nc means a

NULL=

# Ensure we build the right generated sources for giomm
giomm_generated_sources = $(giomm_files_any_hg:.hg=.cc)
giomm_generated_sources = $(giomm_generated_sources) wrap_init.cc
giomm_generated_headers = $(giomm_files_any_hg:.hg=.h)
giomm_generated_private_headers = $(giomm_files_any_hg:.hg=_p.h)
glibmm_generated_private_headers = $(glibmm_files_used_hg:.hg=_p.h)
glibmm_files_extra_ph_int = $(glibmm_files_extra_ph:/=\)

# For glibmm

!if [call create-lists.bat header glibmm.mak glibmm_OBJS]
!endif

!if [for %c in ($(glibmm_files_built_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm\%~nc.obj]
!endif

!if [for %c in ($(glibmm_files_extra_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm\%~nc.obj]
!endif

!if [@call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm\glibmm.res]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak glibmm_real_hg]
!endif

!if [for %c in ($(glibmm_files_used_hg)) do @call create-lists.bat file glibmm.mak ..\glib\src\%c]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

# For giomm

!if [call create-lists.bat header glibmm.mak giomm_OBJS]
!endif

!if [for %c in ($(giomm_generated_sources)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\giomm\%~nc.obj]
!endif

!if [for %c in ($(giomm_files_extra_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\giomm\%~nc.obj]
!endif

!if [@call create-lists.bat file glibmm.mak vs^$(VSVER)\^$(CFG)\^$(PLAT)\giomm\giomm.res]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak giomm_real_hg]
!endif

!if [for %c in ($(giomm_files_any_hg)) do @call create-lists.bat file glibmm.mak ..\gio\src\%c]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [for %d in ($(PREFIX)) do @echo PREFIX_REAL=%~dpnd>>glibmm.mak]
!endif

!if [echo.>>glibmm.mak]
!endif

# We skip building the following examples/tests:
# child_watch, iochannel_stream: Builds on *NIX only
!if [for %d in (examples tests) do @call create-lists.bat header glibmm.mak glibmm_%d & @(for /f %t in ('dir /ad /b ..\%d') do @if not "%t" == "child_watch" if not "%t" == "dbus" if not "%t" == "iochannel_stream" if not "%t" == "network" if not "%t" == "thread" call create-lists.bat file glibmm.mak vs$(VSVER)\$(CFG)\$(PLAT)\%t.exe) & @call create-lists.bat footer glibmm.mak]
!endif

!if [for %t in (dbus network thread) do @for %s in (..\examples\%t\*.cc) do @echo glibmm_examples = ^$(glibmm_examples) vs^$(VSVER)\^$(CFG)\^$(PLAT)\%~ns.exe>>glibmm.mak]
!endif

!if [echo.>>glibmm.mak]
!endif

!if [for %d in (examples tests) do @for /f %t in ('dir /ad /b ..\%d') do @if not "%t" == "child_watch" if not "%t" == "dbus" if not "%t" == "iochannel_stream" if not "%t" == "network" if not "%t" == "thread" for %s in (..\%d\%t\*.cc) do @echo vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm-%d\%t-%~ns.obj: %s>>glibmm.mak & @echo. if not exist ^$(@D)\ md ^$(@D)>>glibmm.mak & @echo.	^$(CXX) ^$(GIOMM_EX_CFLAGS) ^$(CFLAGS) /Fo^$(@D)\%t-%~ns.obj /Fd^$(@D)\ ^$** /c>>glibmm.mak & @echo.>>glibmm.mak]
!endif

!if [for %t in (dbus network thread) do @for %s in (..\examples\%t\*.cc) do @echo vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm-examples\%t-%~ns.obj: %s>>glibmm.mak & @echo. if not exist ^$(@D)\ md ^$(@D)>>glibmm.mak & @echo.	^$(CXX) ^$(GIOMM_EX_CFLAGS) ^$(CFLAGS) /Fo^$(@D)\%t-%~ns.obj /Fd^$(@D)\ ^$** /c>>glibmm.mak & @echo.>>glibmm.mak]
!endif

!if [for %d in (examples tests) do @for /f %t in ('dir /ad /b ..\%d') do @if not "%t" == "child_watch" if not "%t" == "dbus" if not "%t" == "iochannel_stream" if not "%t" == "network" if not "%t" == "thread" call create-lists.bat header glibmm.mak %t_OBJS & @(for %s in (..\%d\%t\*.cc) do @call create-lists.bat file glibmm.mak vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-%d\%t-%~ns.obj) & @call create-lists.bat footer glibmm.mak]
!endif

!if [for %d in (examples tests) do @for /f %t in ('dir /ad /b ..\%d') do @if not "%t" == "child_watch" if not "%t" == "dbus" if not "%t" == "iochannel_stream" if not "%t" == "network" if not "%t" == "thread" echo vs^$(VSVER)\^$(CFG)\^$(PLAT)\%t.exe: ^$(GIOMM_LIB) ^$(GLIBMM_LIB) ^$(%t_OBJS)>>glibmm.mak & @echo.	link ^$(LDFLAGS) ^$** /libpath:^$^(GLIB_LIBDIR^) ^$(GIO_LIBS) /libpath:^$^(LIBSIGC_LIBDIR^) ^$(LIBSIGC_LIB) /out:^$@>>glibmm.mak & @echo.>>glibmm.mak]
!endif

!if [for %t in (dbus network thread) do @for %s in (..\examples\%t\*.cc) do @echo vs^$(VSVER)\^$(CFG)\^$(PLAT)\%~ns.exe: ^$(GIOMM_LIB) ^$(GLIBMM_LIB) vs^$(VSVER)\^$(CFG)\^$(PLAT)\glibmm-examples\%t-%~ns.obj>>glibmm.mak & @echo.	link ^$(LDFLAGS) ^$** /libpath:^$^(GLIB_LIBDIR^) ^$(GIO_LIBS) /libpath:^$^(LIBSIGC_LIBDIR^) ^$(LIBSIGC_LIB) /out:^$@>>glibmm.mak & @echo.>>glibmm.mak]
!endif

!include glibmm.mak

!if [del /f /q glibmm.mak]
!endif
