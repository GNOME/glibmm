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
{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\untracked\glib\glibmm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\glib\glibmm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.obj::
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\ /Fdvs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\glib\src\}.cc.m4{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.obj:
	@if not exist $(@D)\ $(MAKE) /f Makefile.vc CFG=$(CFG) $(@D)
	@for %%s in ($(<D)\*.cc.m4 $(<D)\*.h.m4) do @if not exist ..\glib\glibmm\%%~ns if not exist ..\untracked\glib\glibmm\%%~ns if not exist $(@D)\%%~ns $(M4) -I$(<D:\=/) %%s $(<D:\=/)/template.macros.m4 > $(@D)\%%~ns
	@if exist $(@D)\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B)
	@if exist ..\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B)
	@if exist ..\untracked\glib\glibmm\$(<B) $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\untracked\glib\glibmm\$(<B)

{..\glib\src\}.ccg{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.obj:
	@if not exist $(@D)\private\ $(MAKE) /f Makefile.vc CFG=$(CFG) $(@D)\private
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\glib\glibmm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\glib\glibmm\$(<B).cc $(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c ..\glib\glibmm\$(<B).cc

{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(PDBVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(PDBVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\untracked\gio\giomm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(VSVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\gio\giomm\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fovs$(PDBVER)\$(CFG)\$(PLAT)\giomm\ /Fdvs$(PDBVER)\$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{..\gio\src\}.ccg{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.obj:
	@if not exist $(@D)\private\ $(MAKE) /f Makefile.vc CFG=$(CFG) $(@D)\private
	@for %%s in ($(<D)\*.ccg) do @if not exist ..\gio\giomm\%%~ns.cc if not exist $(@D)\%%~ns.cc $(PERL) -I ../tools/pm -- ../tools/gmmproc -I ../tools/m4 --defs $(<D:\=/) %%~ns $(<D:\=/) $(@D)
	@if exist $(@D)\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc
	@if exist ..\gio\giomm\$(<B).cc $(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(@D)\ /Fd$(@D)\ /c $(@D)\$(<B).cc

{..\tools\extra_defs_gen\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\}.obj::
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ $(MAKE) /f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen
	$(CXX) $(GLIBMM_BASE_CFLAGS) /DGLIBMM_GEN_EXTRA_DEFS_BUILD $(GLIBMM_EXTRA_INCLUDES) $(CFLAGS_NOGL) /Fovs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ /Fdvs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\ /c @<<
$<
<<

{.\glibmm\}.rc{vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\}.res:
	rc /fo$@ $<

{.\giomm\}.rc{vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\}.res:
	rc /fo$@ $<

vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\generate_extra_defs.obj:  ..\tools\extra_defs_gen\generate_extra_defs.cc  ..\tools\extra_defs_gen\generate_extra_defs.h
# Rules for building .lib files
$(GLIBMM_LIB): $(GLIBMM_DLL)
$(GIOMM_LIB): $(GIOMM_DLL)

$(GLIBMM_EXTRA_DEFS_GEN_LIB): $(GLIBMM_EXTRA_DEFS_GEN_DLL)
$(GLIBMM_EXTRA_DEFS_GEN_DLL): vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\generate_extra_defs.obj
	link /DLL $(LDFLAGS_NOLTCG) $(GOBJECT_LIBS) /implib:$(GLIBMM_EXTRA_DEFS_GEN_LIB) -out:$@ @<<
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
$(GLIBMM_DLL): vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm $(glibmm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) $(GOBJECT_LIBS) $(LIBSIGC_LIB) /implib:$(GLIBMM_LIB) -out:$@ @<<
$(glibmm_OBJS)
<<

	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2
$(GIOMM_DLL): $(GLIBMM_LIB) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\giomm.def $(giomm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) $(GLIBMM_LIB) $(GIO_LIBS) $(LIBSIGC_LIB) /implib:$(GIOMM_LIB) /def:vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\giomm.def -out:$@ @<<
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

# For the gendef tool
{.\gendef\}.cc{vs$(PDBVER)\$(CFG)\$(PLAT)\}.exe:
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\gendef\ $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\gendef
	$(CXX) $(GLIBMM_BASE_CFLAGS) $(CFLAGS) /Fo$(@D)\gendef\ /Fd$(@D)\gendef\ $< /link $(LDFLAGS) /out:$@

# For the buildable glibmm examples
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-compose.exe: ..\examples\compose\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-dispatcher2.exe: ..\examples\thread\dispatcher2.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-keyfile.exe: ..\examples\keyfile\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-markup.exe: ..\examples\markup\parser.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-options.exe: ..\examples\options\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-properties.exe: ..\examples\properties\properties_example.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-regex.exe: ..\examples\regex\main.cc $(GLIBMM_LIB)

vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-compose.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-dispatcher2.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-keyfile.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-markup.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-options.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-properties.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex-regex.exe:
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex
	$(CXX) $(GLIBMM_EX_CFLAGS) $(CFLAGS) /Fo$(@D)\glibmm-ex\ /Fd$(@D)\glibmm-ex\ $** /link $(LDFLAGS) $(GLIBMM_EX_LIBS) /out:$@

# For the buildable giomm examples

vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-client_bus_listnames.exe: ..\examples\dbus\client_bus_listnames.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-session_bus_service.exe: ..\examples\dbus\session_bus_service.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-server_without_bus.exe: ..\examples\dbus\server_without_bus.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-resolver.exe: ..\examples\network\resolver.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-socket-client.exe: ..\examples\network\socket-client.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-socket-server.exe: ..\examples\network\socket-server.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-settings.exe: ..\examples\settings\settings.cc $(GIOMM_LIB)

vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-client_bus_listnames.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-session_bus_service.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-dbus-server_without_bus.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-resolver.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-socket-client.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-network-socket-server.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-settings.exe:
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex
	@if "$@" == "vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex-settings.exe" $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\gschema.compiled
	$(CXX) $(GIOMM_EX_CFLAGS) $(CFLAGS) /Fo$(@D)\giomm-ex\ /Fd$(@D)\giomm-ex\ $** /link $(LDFLAGS) $(GIOMM_EX_LIBS) /out:$@

# For building the glibmm tests
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_base64.exe: ..\tests\glibmm_base64\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_binding.exe: ..\tests\glibmm_binding\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bool_arrayhandle.exe: ..\tests\glibmm_bool_arrayhandle\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bool_vector.exe: ..\tests\glibmm_bool_vector\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_btree.exe: ..\tests\glibmm_btree\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_buildfilename.exe: ..\tests\glibmm_buildfilename\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bytearray.exe: ..\tests\glibmm_bytearray\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_date.exe: ..\tests\glibmm_date\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_mainloop.exe: ..\tests\glibmm_mainloop\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_nodetree.exe: ..\tests\glibmm_nodetree\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_object.exe: ..\tests\glibmm_object\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_objectbase.exe: ..\tests\glibmm_objectbase\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_objectbase_move.exe: ..\tests\glibmm_objectbase_move\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_object_move.exe: ..\tests\glibmm_object_move\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_refptr.exe: ..\tests\glibmm_refptr\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_refptr_sigc_bind.exe: ..\tests\glibmm_refptr_sigc_bind\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_compose.exe: ..\tests\glibmm_ustring_compose\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_format.exe: ..\tests\glibmm_ustring_format\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_make_valid.exe: ..\tests\glibmm_ustring_make_valid\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_sprintf.exe: ..\tests\glibmm_ustring_sprintf\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_value.exe: ..\tests\glibmm_value\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_valuearray.exe: ..\tests\glibmm_valuearray\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_variant.exe: ..\tests\glibmm_variant\main.cc $(GLIBMM_LIB)

vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_base64.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_binding.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bool_arrayhandle.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bool_vector.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_btree.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_buildfilename.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_bytearray.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_date.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_interface_move.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_mainloop.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_nodetree.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_object.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_objectbase.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_objectbase_move.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_object_move.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_refptr.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_refptr_sigc_bind.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_compose.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_format.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_make_valid.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_ustring_sprintf.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_value.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_valuearray.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_variant.exe:
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests
	$(CXX) $(GLIBMM_EX_CFLAGS) $(CFLAGS) /Fo$(@D)\glibmm-tests\ /Fd$(@D)\glibmm-tests\ $** /link $(LDFLAGS) $(GLIBMM_EX_LIBS) /out:$@

# For giomm tests
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_asyncresult_sourceobject.exe: ..\tests\giomm_asyncresult_sourceobject\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_ioerror.exe: ..\tests\giomm_ioerror\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_ioerror_and_iodbuserror.exe: ..\tests\giomm_ioerror_and_iodbuserror\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_listmodel.exe: ..\tests\giomm_listmodel\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_memoryinputstream.exe: ..\tests\giomm_memoryinputstream\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_simple.exe: ..\tests\giomm_simple\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_stream_vfuncs.exe: ..\tests\giomm_stream_vfuncs\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_tls_client.exe: ..\tests\giomm_tls_client\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_interface_implementation.exe: ..\tests\glibmm_interface_implementation\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_null_containerhandle.exe: ..\tests\glibmm_null_containerhandle\main.cc $(GLIBMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_null_vectorutils.exe: ..\tests\glibmm_null_vectorutils\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_vector.exe: ..\tests\glibmm_vector\main.cc $(GIOMM_LIB)
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_weakref.exe: ..\tests\glibmm_weakref\main.cc $(GLIBMM_LIB)

vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_asyncresult_sourceobject.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_ioerror.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_ioerror_and_iodbuserror.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_listmodel.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_memoryinputstream.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_simple.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_stream_vfuncs.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-giomm_tls_client.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_interface_implementation.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_null_containerhandle.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_null_vectorutils.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_vector.exe	\
vs$(PDBVER)\$(CFG)\$(PLAT)\test-glibmm_weakref.exe:
	@if not exist vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests $(MAKE) -f Makefile.vc CFG=$(CFG) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests
	$(CXX) $(GIOMM_EX_CFLAGS) $(CFLAGS) /Fo$(@D)\giomm-tests\ /Fd$(@D)\giomm-tests\ $** /link $(LDFLAGS) $(GIOMM_EX_LIBS) /out:$@

clean:
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.exe
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.dll
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.ilk
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.exp
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\*.lib
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.exe
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.dll
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.pdb
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.ilk
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.exp
	@-del /f /q vs$(VSVER)\$(CFG)\$(PLAT)\*.lib
	@-del ..\tools\generate_wrap_init.pl
	@-del ..\tools\gmmproc
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\gschemas.compiled
	@-del vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\*.pdb
	@-del vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen\*.obj
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests\*.obj
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex\*.obj
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.def
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.res
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.obj
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.cc
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\private\*.h
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.h
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests\*.obj
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex\*.obj
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.def
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.res
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.obj
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.pdb
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.cc
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\private\*.h
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.h
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\gendef\*.obj
	@-del /f /q vs$(PDBVER)\$(CFG)\$(PLAT)\gendef\*.pdb
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests rd vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\private
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\giomm
	@-if exist vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests rd vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\private
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm
	@-rd vs$(PDBVER)\$(CFG)\$(PLAT)\gendef

.SUFFIXES: .cc .h .ccg .hg .obj .cc.m4 .h.m4
