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

!if [for %c in ($(glibmm_files_built_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\glibmm\%~nc.obj]
!endif

!if [for %c in ($(glibmm_files_extra_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\glibmm\%~nc.obj]
!endif

!if [@call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\glibmm\glibmm.res]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

# For giomm

!if [call create-lists.bat header glibmm.mak giomm_OBJS]
!endif

!if [for %c in ($(giomm_generated_sources)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm\%~nc.obj]
!endif

!if [for %c in ($(giomm_files_extra_cc)) do @if "%~xc" == ".cc" @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm\%~nc.obj]
!endif

!if [@call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm\giomm.res]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak glibmm_ex]
!endif

# We skip building the following examples:
# child_watch, iochannel_stream: Builds on *NIX only
# thread\dispatcher.cc: Not C++-17 compliant
!if [for %e in (compose dispatcher2 keyfile markup options properties regex) do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\glibmm-ex-%e.exe]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak giomm_ex]
!endif

!if [for %e in (resolver socket-client socket-server) do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm-ex-network-%e.exe]
!endif

!if [for %e in (settings) do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm-ex-%e.exe]
!endif

!if [for %e in (client_bus_listnames session_bus_service server_without_bus) do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\giomm-ex-dbus-%e.exe]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak glibmm_tests]
!endif

# Skip the following:
# glibmm_interface_implementation, glibmm_null_vectorutils, glibmm_vector: Are actually using giomm
# glibmm_interface_move: Relies on g_autoptr_*()
!if [for /f %d in ('dir /ad /b ..\tests\glibmm_*') do @if not "%d" == "glibmm_interface_implementation" if not "%d" == "glibmm_interface_move" if not "%d" == "glibmm_null_vectorutils" if not "%d" == "glibmm_vector" @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\test-%d.exe]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!if [call create-lists.bat header glibmm.mak giomm_tests]
!endif

!if [for /f %d in ('dir /ad /b ..\tests\giomm_*') do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\test-%d.exe]
!endif

!if [for %d in (interface_implementation null_vectorutils vector) do @call create-lists.bat file glibmm.mak ^$(CFG)\^$(PLAT)\test-glibmm_%d.exe]
!endif

!if [call create-lists.bat footer glibmm.mak]
!endif

!include glibmm.mak

!if [del /f /q glibmm.mak]
!endif
