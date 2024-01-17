# NMake Makefile portion for compilation rules
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.  The format
# of NMake Makefiles here are different from the GNU
# Makefiles.  Please see the comments about these formats.

# Inference rules for compiling the .obj files.
# Used for libs and programs with more than a single source file.
# Format is as follows
# (all dirs must have a trailing '\'):
#
# {$(srcdir)}.$(srcext){$(destdir)}.obj::
# 	$(CC)|$(CXX) $(cflags) /Fo$(destdir) /c @<<
# $<
# <<
{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\glib\glibmm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if not exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ md vs$(VSVER)\$(CFG)\$(PLAT)\glibmm
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\untracked\glib\glibmm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if not exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ md vs$(VSVER)\$(CFG)\$(PLAT)\glibmm
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\glib\src\}.cc.m4{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.obj:
	@if not exist $(@D)\ md $(@D)
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@for %%s in ($(<D)\*.cc.m4 $(<D)\*.h.m4) do @if not exist ..\glib\glibmm\%%~ns if not exist ..\untracked\glib\glibmm\%%~ns if not exist $(@D)\%%~ns $(M4) -I$(<D:\=/) %%s $(<D:\=/)/template.macros.m4 > $(@D)\%%~ns
	@if exist $(@D)\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B)
	@if exist ..\untracked\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\untracked\glib\glibmm\$(<B)
	@if exist ..\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B)

{..\glib\src\}.ccg{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.obj:
	@if not exist $(@D)\private\ md $(@D)\private
	@if not exist ..\tools\gmmproc $(MAKE) /f Makefile.vc CFG=$(CFG) ..\tools\gmmproc
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\glib\glibmm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\glib\glibmm\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B).cc

{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\gio\giomm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	if not exist vs$(VSVER)\$(CFG)\$(PLAT)\giomm\ md vs$(VSVER)\$(CFG)\$(PLAT)\giomm
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\untracked\gio\giomm\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	if not exist vs$(VSVER)\$(CFG)\$(PLAT)\giomm\ md vs$(VSVER)\$(CFG)\$(PLAT)\giomm
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\gio\src\}.ccg{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.obj:
	@if not exist $(@D)\private\ md $(@D)\private
	@if not exist ..\tools\gmmproc $(MAKE) /f Makefile.vc CFG=$(CFG) ..\tools\gmmproc
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\gio\giomm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\gio\giomm\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc

{..\tools\extra_defs_gen\}.cc{vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\}.obj::
	@if not exist vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ md vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen
	$(CXX) $(GLIBMM_BASE_CFLAGS) /DGLIBMM_GEN_EXTRA_DEFS_BUILD $(GLIBMM_EXTRA_INCLUDES) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ /c @<<
$<
<<

{.\glibmm\}.rc{vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\}.res:
	@if not exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ md vs$(VSVER)\$(CFG)\$(PLAT)\glibmm
	rc /fo$@ $<

{.\giomm\}.rc{vs$(VSVER)\$(CFG)\$(PLAT)\giomm\}.res:
	@if not exist vs$(VSVER)\$(CFG)\$(PLAT)\giomm\ md vs$(VSVER)\$(CFG)\$(PLAT)\giomm
	rc /fo$@ $<

vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\generate_extra_defs.obj:  ..\tools\extra_defs_gen\generate_extra_defs.cc  ..\tools\extra_defs_gen\generate_extra_defs.h
# Rules for building .lib files
$(GLIBMM_LIB): $(GLIBMM_DLL)
$(GIOMM_LIB): $(GIOMM_DLL)

$(GLIBMM_EXTRA_DEFS_GEN_LIB): $(GLIBMM_EXTRA_DEFS_GEN_DLL)
$(GLIBMM_EXTRA_DEFS_GEN_DLL): vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\generate_extra_defs.obj
	link /DLL $(LDFLAGS_NOLTCG) /libpath:$(GLIB_LIBDIR) $(GOBJECT_LIBS) /implib:$(GLIBMM_EXTRA_DEFS_GEN_LIB) -out:$@ @<<
$**
<<
	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2


# Rules for linking DLLs
# Format is as follows (the mt command is needed for MSVC 2005/2008 builds):
# $(dll_name_with_path): $(dependent_libs_files_objects_and_items)
#	link /DLL [$(linker_flags)] [$(dependent_libs)] [/def:$(def_file_if_used)] [/implib:$(lib_name_if_needed)] -out:$@ @<<
# $(dependent_objects)
# <<
# 	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2
$(GLIBMM_DLL): $(glibmm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) /libpath:$(GLIB_LIBDIR) $(GOBJECT_LIBS) /libpath:$(LIBSIGC_LIBDIR) $(LIBSIGC_LIB) /implib:$(GLIBMM_LIB) -out:$@ @<<
$(glibmm_OBJS)
<<

	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2
$(GIOMM_DLL): $(GLIBMM_LIB) $(giomm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) /libpath:$(GLIB_LIBDIR) $(GLIBMM_LIB) $(GIO_LIBS) /libpath:$(LIBSIGC_LIBDIR) $(LIBSIGC_LIB) /implib:$(GIOMM_LIB) -out:$@ @<<
$(giomm_OBJS)
<<
	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2

# Rules for linking Executables
# Format is as follows (the mt command is needed for MSVC 2005/2008 builds):
# $(dll_name_with_path): $(dependent_libs_files_objects_and_items)
#	link [$(linker_flags)] [$(dependent_libs)] -out:$@ @<<
# $(dependent_objects)
# <<
# 	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;1

clean:
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.exe
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.dll
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.pdb
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.ilk
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.exp
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.lib
	@-del ..\tools\generate_wrap_init.pl
	@-del ..\tools\gmmproc
	@-if exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests\*.obj
	@-if exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests\*.pdb
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\gschemas.compiled
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-examples\*.obj
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-examples\*.pdb
	@-del vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\*.pdb
	@-del vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\*.obj
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.res
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.obj
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.pdb
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.cc
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\private\*.h
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.h
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.res
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.obj
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.pdb
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.cc
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\private\*.h
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.h
	@-if exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests rd vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-examples
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\giomm\private
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\giomm
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\private
	@-rd vs$(VSVER)\$(CFG)\$(PLAT)\glibmm

.SUFFIXES: .cc .h .ccg .hg .obj .cc.m4 .h.m4
