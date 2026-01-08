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
{$(OUTDIR)\glibmm\}.cc{$(OUTDIR)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	$(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(OUTDIR)\glibmm\ /Fd$(OUTDIR)\glibmm\ /c @<<
$<
<<

{..\glib\glibmm\}.cc{$(OUTDIR)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if not exist $(OUTDIR)\glibmm\ md $(OUTDIR)\glibmm
	$(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(OUTDIR)\glibmm\ /Fd$(OUTDIR)\glibmm\ /c @<<
$<
<<

{..\untracked\glib\glibmm\}.cc{$(OUTDIR)\glibmm\}.obj::
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if not exist $(OUTDIR)\glibmm\ md $(OUTDIR)\glibmm
	$(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(OUTDIR)\glibmm\ /Fd$(OUTDIR)\glibmm\ /c @<<
$<
<<

{..\glib\src\}.cc.m4{$(OUTDIR)\glibmm\}.obj:
	@if not exist $(@D)\ md $(@D)
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(UNIX_TOOLS_BINDIR_CHECKED)" == "" echo Warning: m4 is not in %PATH% or specified M4 or UNIX_TOOLS_BINDIR is not valid. Builds may fail!
	@set PATH=$(PATH);$(UNIX_TOOLS_BINDIR_CHECKED)
	@for %%s in ($(<D)\*.cc.m4 $(<D)\*.h.m4) do @if not exist ..\glib\glibmm\%%~ns if not exist ..\untracked\glib\glibmm\%%~ns if not exist $(@D)\%%~ns $(M4_FULL_PATH) -I$(<D:\=/) %%s $(<D:\=/)/template.macros.m4 > $(@D)\%%~ns
	@if exist $(@D)\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B)
	@if exist ..\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B)
	@if exist ..\untracked\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c ..\untracked\glib\glibmm\$(<B)

{..\glib\src\}.ccg{$(OUTDIR)\glibmm\}.obj:
	@if not exist $(@D)\private\ md $(@D)\private
	@if not exist ..\tools\gmmproc $(MAKE) /f Makefile.vc CFG=$(CFG) ..\tools\gmmproc
	@if not exist glibmm\glibmm.rc $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(UNIX_TOOLS_BINDIR_CHECKED)" == "" echo Warning: m4 is not in %PATH% or specified M4 or UNIX_TOOLS_BINDIR is not valid. Builds may fail!
	@for %%s in ($(<D)\*.cc.m4 $(<D)\*.h.m4) do @if not exist ..\glib\glibmm\%%~ns if not exist ..\untracked\glib\glibmm\%%~ns if not exist $(@D)\%%~ns $(M4_FULL_PATH) -I$(<D:\=/) %%s $(<D:\=/)/template.macros.m4 > $(@D)\%%~ns
	@set PATH=$(PATH);$(UNIX_TOOLS_BINDIR_CHECKED)
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\glib\glibmm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\glib\glibmm\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(GLIBMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B).cc

{$(OUTDIR)\giomm\}.cc{$(OUTDIR)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(GIOMM_INCLUDES) /Fo$(OUTDIR)\giomm\ /Fd$(OUTDIR)\giomm\ /c @<<
$<
<<

{..\gio\giomm\}.cc{$(OUTDIR)\giomm\}.obj::
	if not exist $(OUTDIR)\giomm\ md $(OUTDIR)\giomm
	$(CXX) $(LIBGIOMM_CFLAGS) $(GIOMM_INCLUDES) /Fo$(OUTDIR)\giomm\ /Fd$(OUTDIR)\giomm\ /c @<<
$<
<<

{..\untracked\gio\giomm\}.cc{$(OUTDIR)\giomm\}.obj::
	if not exist $(OUTDIR)\giomm\ md $(OUTDIR)\giomm
	$(CXX) $(LIBGIOMM_CFLAGS) $(GIOMM_INCLUDES) /Fo$(OUTDIR)\giomm\ /Fd$(OUTDIR)\giomm\ /c @<<
$<
<<

{..\gio\src\}.ccg{$(OUTDIR)\giomm\}.obj:
	@if not exist $(@D)\private\ md $(@D)\private
	@if not exist ..\tools\gmmproc $(MAKE) /f Makefile.vc CFG=$(CFG) ..\tools\gmmproc
	@if "$(UNIX_TOOLS_BINDIR_CHECKED)" == "" echo Warning: m4 is not in %PATH% or specified M4 or UNIX_TOOLS_BINDIR is not valid. Builds may fail!
	@set PATH=$(PATH);$(UNIX_TOOLS_BINDIR_CHECKED)
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\gio\giomm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(GIOMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\gio\giomm\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(GIOMM_INCLUDES) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc

{..\tools\extra_defs_gen\}.cc{$(OUTDIR)\glib-extra-defs-gen\}.obj::
	@if not exist $(OUTDIR)\glib-extra-defs-gen\ md $(OUTDIR)\glib-extra-defs-gen
	$(CXX) $(CFLAGS) /DGLIBMM_GEN_EXTRA_DEFS_BUILD $(GLIBMM_INCLUDES) /Fo$(OUTDIR)\glib-extra-defs-gen\ /Fd$(OUTDIR)\glib-extra-defs-gen\ /c @<<
$<
<<

{.\glibmm\}.rc{$(OUTDIR)\glibmm\}.res:
	@if not exist $(OUTDIR)\glibmm\ md $(OUTDIR)\glibmm
	rc /fo$@ $<

{.\giomm\}.rc{$(OUTDIR)\giomm\}.res:
	@if not exist $(OUTDIR)\giomm\ md $(OUTDIR)\giomm
	rc /fo$@ $<

$(OUTDIR)\glib-extra-defs-gen\generate_extra_defs.obj:  ..\tools\extra_defs_gen\generate_extra_defs.cc  ..\tools\extra_defs_gen\generate_extra_defs.h
# Rules for building .lib files
$(GLIBMM_LIB): $(GLIBMM_DLL)
$(GIOMM_LIB): $(GIOMM_DLL)

$(GLIBMM_EXTRA_DEFS_GEN_LIB): $(GLIBMM_EXTRA_DEFS_GEN_DLL)
$(GLIBMM_EXTRA_DEFS_GEN_DLL): $(OUTDIR)\glib-extra-defs-gen\generate_extra_defs.obj
	link /DLL $(LDFLAGS) $(GOBJECT_LDFLAGS) /implib:$(GLIBMM_EXTRA_DEFS_GEN_LIB) -out:$@ @<<
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
	link /DLL $(LDFLAGS) $(GOBJECT_LDFLAGS) $(SIGC_LDFLAGS) /implib:$(GLIBMM_LIB) -out:$@ @<<
$(glibmm_OBJS)
<<
	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2

$(GIOMM_DLL): $(GLIBMM_LIB) $(giomm_OBJS)
	link /DLL $(LDFLAGS) $(GLIBMM_LIB) $(GIO_LDFLAGS) $(SIGC_LDFLAGS) /implib:$(GIOMM_LIB) -out:$@ @<<
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
	@-del /f /q $(OUTDIR)\*.exe
	@-del /f /q $(OUTDIR)\*.dll
	@-del /f /q $(OUTDIR)\*.pdb
	@-del /f /q $(OUTDIR)\*.ilk
	@-del /f /q $(OUTDIR)\*.exp
	@-del /f /q $(OUTDIR)\*.lib
	@-del ..\tools\generate_wrap_init.pl
	@-del ..\tools\gmmproc
	@-if exist $(OUTDIR)\glibmm-tests del /f /q $(OUTDIR)\glibmm-tests\*.obj
	@-if exist $(OUTDIR)\glibmm-tests del /f /q $(OUTDIR)\glibmm-tests\*.pdb
	@-del /f /q $(OUTDIR)\gschemas.compiled
	@-del /f /q $(OUTDIR)\glibmm-examples\*.obj
	@-del /f /q $(OUTDIR)\glibmm-examples\*.pdb
	@-del $(OUTDIR)\glib-extra-defs-gen\*.pdb
	@-del $(OUTDIR)\glib-extra-defs-gen\*.obj
	@-del /f /q $(OUTDIR)\giomm\*.res
	@-del /f /q $(OUTDIR)\giomm\*.obj
	@-del /f /q $(OUTDIR)\giomm\*.pdb
	@-del /f /q $(OUTDIR)\giomm\*.cc
	@-del /f /q $(OUTDIR)\giomm\private\*.h
	@-del /f /q $(OUTDIR)\giomm\*.h
	@-del /f /q $(OUTDIR)\glibmm\*.res
	@-del /f /q $(OUTDIR)\glibmm\*.obj
	@-del /f /q $(OUTDIR)\glibmm\*.pdb
	@-del /f /q $(OUTDIR)\glibmm\*.cc
	@-del /f /q $(OUTDIR)\glibmm\private\*.h
	@-del /f /q $(OUTDIR)\glibmm\*.h
	@-if exist $(OUTDIR)\glibmm-tests rd $(OUTDIR)\glibmm-tests
	@-rd $(OUTDIR)\glibmm-examples
	@-rd $(OUTDIR)\glib-extra-defs-gen
	@-rd $(OUTDIR)\giomm\private
	@-rd $(OUTDIR)\giomm
	@-rd $(OUTDIR)\glibmm\private
	@-rd $(OUTDIR)\glibmm

.SUFFIXES: .cc .h .ccg .hg .obj .cc.m4 .h.m4
