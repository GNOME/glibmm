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
{..\glib\glibmm\}.cc{$(CFG)\$(PLAT)\glibmm\}.obj::
	$(CXX) $(LIBGLIBMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(CFG)\$(PLAT)\glibmm\ /c @<<
$<
<<

{..\gio\giomm\}.cc{$(CFG)\$(PLAT)\giomm\}.obj::
	$(CXX) $(LIBGIOMM_CFLAGS) $(CFLAGS_NOGL) /Fo$(CFG)\$(PLAT)\giomm\ /c @<<
$<
<<

{.\glibmm\}.rc{$(CFG)\$(PLAT)\glibmm\}.res:
	rc /fo$@ $<

{.\giomm\}.rc{$(CFG)\$(PLAT)\giomm\}.res:
	rc /fo$@ $<

# Rules for building .lib files
$(GLIBMM_LIB): $(GLIBMM_DLL)
$(GIOMM_LIB): $(GIOMM_DLL)

# Rules for linking DLLs
# Format is as follows (the mt command is needed for MSVC 2005/2008 builds):
# $(dll_name_with_path): $(dependent_libs_files_objects_and_items)
#	link /DLL [$(linker_flags)] [$(dependent_libs)] [/def:$(def_file_if_used)] [/implib:$(lib_name_if_needed)] -out:$@ @<<
# $(dependent_objects)
# <<
# 	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2
$(GLIBMM_DLL): $(CFG)\$(PLAT)\glibmm\glibmm.def $(glibmm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) $(GOBJECT_LIBS) $(LIBSIGC_LIB) /implib:$(GLIBMM_LIB) /def:$(CFG)\$(PLAT)\glibmm\glibmm.def -out:$@ @<<
$(glibmm_OBJS)
<<

	@-if exist $@.manifest mt /manifest $@.manifest /outputresource:$@;2
$(GIOMM_DLL): $(GLIBMM_LIB) $(CFG)\$(PLAT)\giomm\giomm.def $(giomm_OBJS)
	link /DLL $(LDFLAGS_NOLTCG) $(GLIBMM_LIB) $(GIO_LIBS) $(LIBSIGC_LIB) /implib:$(GIOMM_LIB) /def:$(CFG)\$(PLAT)\giomm\giomm.def -out:$@ @<<
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
{.\gendef\}.cc{$(CFG)\$(PLAT)\}.exe:
	@if not exist $(CFG)\$(PLAT)\gendef\ $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\gendef
	$(CXX) $(GLIBMM_BASE_CFLAGS) $(CFLAGS) /Fo$(CFG)\$(PLAT)\gendef\ $< /link $(LDFLAGS) /out:$@

# For the buildable glibmm examples
$(CFG)\$(PLAT)\glibmm-ex-compose.exe: ..\examples\compose\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-dispatcher2.exe: ..\examples\thread\dispatcher2.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-keyfile.exe: ..\examples\keyfile\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-markup.exe: ..\examples\markup\parser.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-options.exe: ..\examples\options\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-properties.exe: ..\examples\properties\properties_example.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\glibmm-ex-regex.exe: ..\examples\regex\main.cc $(GLIBMM_LIB)

$(CFG)\$(PLAT)\glibmm-ex-compose.exe	\
$(CFG)\$(PLAT)\glibmm-ex-dispatcher2.exe	\
$(CFG)\$(PLAT)\glibmm-ex-keyfile.exe	\
$(CFG)\$(PLAT)\glibmm-ex-markup.exe	\
$(CFG)\$(PLAT)\glibmm-ex-options.exe	\
$(CFG)\$(PLAT)\glibmm-ex-properties.exe	\
$(CFG)\$(PLAT)\glibmm-ex-regex.exe:
	@if not exist $(CFG)\$(PLAT)\glibmm-ex $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\glibmm-ex
	$(CXX) $(GLIBMM_EX_CFLAGS) $(CFLAGS) /Fo$(CFG)\$(PLAT)\glibmm-ex\ $** /link $(LDFLAGS) $(GLIBMM_EX_LIBS) /out:$@

# For the buildable giomm examples

$(CFG)\$(PLAT)\giomm-ex-dbus-client_bus_listnames.exe: ..\examples\dbus\client_bus_listnames.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-dbus-session_bus_service.exe: ..\examples\dbus\session_bus_service.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-dbus-server_without_bus.exe: ..\examples\dbus\server_without_bus.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-network-resolver.exe: ..\examples\network\resolver.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-network-socket-client.exe: ..\examples\network\socket-client.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-network-socket-server.exe: ..\examples\network\socket-server.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\giomm-ex-settings.exe: ..\examples\settings\settings.cc $(GIOMM_LIB)

$(CFG)\$(PLAT)\giomm-ex-dbus-client_bus_listnames.exe	\
$(CFG)\$(PLAT)\giomm-ex-dbus-session_bus_service.exe	\
$(CFG)\$(PLAT)\giomm-ex-dbus-server_without_bus.exe	\
$(CFG)\$(PLAT)\giomm-ex-network-resolver.exe	\
$(CFG)\$(PLAT)\giomm-ex-network-socket-client.exe	\
$(CFG)\$(PLAT)\giomm-ex-network-socket-server.exe	\
$(CFG)\$(PLAT)\giomm-ex-settings.exe:
	@if not exist $(CFG)\$(PLAT)\giomm-ex $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\giomm-ex
	@if "$@" == "$(CFG)\$(PLAT)\giomm-ex-settings.exe" $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\gschema.compiled
	$(CXX) $(GIOMM_EX_CFLAGS) $(CFLAGS) /Fo$(CFG)\$(PLAT)\giomm-ex\ $** /link $(LDFLAGS) $(GIOMM_EX_LIBS) /out:$@

# For building the glibmm tests
$(CFG)\$(PLAT)\test-glibmm_base64.exe: ..\tests\glibmm_base64\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_bool_arrayhandle.exe: ..\tests\glibmm_bool_arrayhandle\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_bool_vector.exe: ..\tests\glibmm_bool_vector\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_btree.exe: ..\tests\glibmm_btree\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_buildfilename.exe: ..\tests\glibmm_buildfilename\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_bytearray.exe: ..\tests\glibmm_bytearray\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_date.exe: ..\tests\glibmm_date\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_mainloop.exe: ..\tests\glibmm_mainloop\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_nodetree.exe: ..\tests\glibmm_nodetree\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_object.exe: ..\tests\glibmm_object\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_objectbase.exe: ..\tests\glibmm_objectbase\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_objectbase_move.exe: ..\tests\glibmm_objectbase_move\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_object_move.exe: ..\tests\glibmm_object_move\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_refptr.exe: ..\tests\glibmm_refptr\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_refptr_sigc_bind.exe: ..\tests\glibmm_refptr_sigc_bind\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_ustring_compose.exe: ..\tests\glibmm_ustring_compose\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_ustring_format.exe: ..\tests\glibmm_ustring_format\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_ustring_make_valid.exe: ..\tests\glibmm_ustring_make_valid\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_value.exe: ..\tests\glibmm_value\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_valuearray.exe: ..\tests\glibmm_valuearray\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_variant.exe: ..\tests\glibmm_variant\main.cc $(GLIBMM_LIB)

$(CFG)\$(PLAT)\test-glibmm_base64.exe	\
$(CFG)\$(PLAT)\test-glibmm_bool_arrayhandle.exe	\
$(CFG)\$(PLAT)\test-glibmm_bool_vector.exe	\
$(CFG)\$(PLAT)\test-glibmm_btree.exe	\
$(CFG)\$(PLAT)\test-glibmm_buildfilename.exe	\
$(CFG)\$(PLAT)\test-glibmm_bytearray.exe	\
$(CFG)\$(PLAT)\test-glibmm_date.exe	\
$(CFG)\$(PLAT)\test-glibmm_interface_move.exe	\
$(CFG)\$(PLAT)\test-glibmm_mainloop.exe	\
$(CFG)\$(PLAT)\test-glibmm_nodetree.exe	\
$(CFG)\$(PLAT)\test-glibmm_object.exe	\
$(CFG)\$(PLAT)\test-glibmm_objectbase.exe	\
$(CFG)\$(PLAT)\test-glibmm_objectbase_move.exe	\
$(CFG)\$(PLAT)\test-glibmm_object_move.exe	\
$(CFG)\$(PLAT)\test-glibmm_refptr.exe	\
$(CFG)\$(PLAT)\test-glibmm_refptr_sigc_bind.exe	\
$(CFG)\$(PLAT)\test-glibmm_ustring_compose.exe	\
$(CFG)\$(PLAT)\test-glibmm_ustring_format.exe	\
$(CFG)\$(PLAT)\test-glibmm_ustring_make_valid.exe	\
$(CFG)\$(PLAT)\test-glibmm_value.exe	\
$(CFG)\$(PLAT)\test-glibmm_valuearray.exe	\
$(CFG)\$(PLAT)\test-glibmm_variant.exe:
	@if not exist $(CFG)\$(PLAT)\glibmm-tests $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\glibmm-tests
	$(CXX) $(GLIBMM_EX_CFLAGS) $(CFLAGS) /Fo$(CFG)\$(PLAT)\glibmm-tests\ $** /link $(LDFLAGS) $(GLIBMM_EX_LIBS) /out:$@

# For giomm tests
$(CFG)\$(PLAT)\test-giomm_asyncresult_sourceobject.exe: ..\tests\giomm_asyncresult_sourceobject\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_ioerror.exe: ..\tests\giomm_ioerror\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_ioerror_and_iodbuserror.exe: ..\tests\giomm_ioerror_and_iodbuserror\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_listmodel.exe: ..\tests\giomm_listmodel\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_memoryinputstream.exe: ..\tests\giomm_memoryinputstream\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_simple.exe: ..\tests\giomm_simple\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_stream_vfuncs.exe: ..\tests\giomm_stream_vfuncs\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-giomm_tls_client.exe: ..\tests\giomm_tls_client\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_interface_implementation.exe: ..\tests\glibmm_interface_implementation\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_null_containerhandle.exe: ..\tests\glibmm_null_containerhandle\main.cc $(GLIBMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_null_vectorutils.exe: ..\tests\glibmm_null_vectorutils\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_vector.exe: ..\tests\glibmm_vector\main.cc $(GIOMM_LIB)
$(CFG)\$(PLAT)\test-glibmm_weakref.exe: ..\tests\glibmm_weakref\main.cc $(GLIBMM_LIB)

$(CFG)\$(PLAT)\test-giomm_asyncresult_sourceobject.exe	\
$(CFG)\$(PLAT)\test-giomm_ioerror.exe	\
$(CFG)\$(PLAT)\test-giomm_ioerror_and_iodbuserror.exe	\
$(CFG)\$(PLAT)\test-giomm_listmodel.exe	\
$(CFG)\$(PLAT)\test-giomm_memoryinputstream.exe	\
$(CFG)\$(PLAT)\test-giomm_simple.exe	\
$(CFG)\$(PLAT)\test-giomm_stream_vfuncs.exe	\
$(CFG)\$(PLAT)\test-giomm_tls_client.exe	\
$(CFG)\$(PLAT)\test-glibmm_interface_implementation.exe	\
$(CFG)\$(PLAT)\test-glibmm_null_containerhandle.exe	\
$(CFG)\$(PLAT)\test-glibmm_null_vectorutils.exe	\
$(CFG)\$(PLAT)\test-glibmm_vector.exe	\
$(CFG)\$(PLAT)\test-glibmm_weakref.exe:
	@if not exist $(CFG)\$(PLAT)\giomm-tests $(MAKE) -f Makefile.vc CFG=$(CFG) $(CFG)\$(PLAT)\giomm-tests
	$(CXX) $(GIOMM_EX_CFLAGS) $(CFLAGS) /Fo$(CFG)\$(PLAT)\giomm-tests\ $** /link $(LDFLAGS) $(GIOMM_EX_LIBS) /out:$@

clean:
	@-del /f /q $(CFG)\$(PLAT)\*.exe
	@-del /f /q $(CFG)\$(PLAT)\*.dll
	@-del /f /q $(CFG)\$(PLAT)\*.pdb
	@-del /f /q $(CFG)\$(PLAT)\*.ilk
	@-del /f /q $(CFG)\$(PLAT)\*.exp
	@-del /f /q $(CFG)\$(PLAT)\*.lib
	@-del /f /q $(CFG)\$(PLAT)\gschemas.compiled
	@-if exist $(CFG)\$(PLAT)\giomm-tests del /f /q $(CFG)\$(PLAT)\giomm-tests\*.obj
	@-del /f /q $(CFG)\$(PLAT)\giomm-ex\*.obj
	@-del /f /q $(CFG)\$(PLAT)\giomm\*.def
	@-del /f /q $(CFG)\$(PLAT)\giomm\*.res
	@-del /f /q $(CFG)\$(PLAT)\giomm\*.obj
	@-if exist $(CFG)\$(PLAT)\glibmm-tests del /f /q $(CFG)\$(PLAT)\glibmm-tests\*.obj
	@-del /f /q $(CFG)\$(PLAT)\glibmm-ex\*.obj
	@-del /f /q $(CFG)\$(PLAT)\glibmm\*.def
	@-del /f /q $(CFG)\$(PLAT)\glibmm\*.res
	@-del /f /q $(CFG)\$(PLAT)\glibmm\*.obj
	@-del /f /q $(CFG)\$(PLAT)\gendef\*.obj
	@-if exist $(CFG)\$(PLAT)\giomm-tests rd $(CFG)\$(PLAT)\giomm-tests
	@-rd $(CFG)\$(PLAT)\giomm-ex
	@-rd $(CFG)\$(PLAT)\giomm
	@-if exist $(CFG)\$(PLAT)\glibmm-tests rd $(CFG)\$(PLAT)\glibmm-tests
	@-rd $(CFG)\$(PLAT)\glibmm-ex
	@-rd $(CFG)\$(PLAT)\glibmm
	@-rd $(CFG)\$(PLAT)\gendef
	@-del /f /q vc$(PDBVER)0.pdb
