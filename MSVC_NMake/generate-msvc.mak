# NMake Makefile portion for code generation and
# intermediate build directory creation
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.

# Create the build directories
vs$(PDBVER)\$(CFG)\$(PLAT)\gendef	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\private	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\private	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen:
	@-md $@

# Generate .def files
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\glibmm.def: $(GENDEF) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm $(glibmm_OBJS)
	vs$(PDBVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GLIBMM_LIBNAME) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.obj

vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\giomm.def: $(GENDEF) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm $(giomm_OBJS)
	vs$(PDBVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GIOMM_LIBNAME) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.obj

# Compile schema for giomm settings example
vs$(PDBVER)\$(CFG)\$(PLAT)\gschema.compiled: ..\examples\settings\org.gtkmm.demo.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) --targetdir=vs$(PDBVER)\$(CFG)\$(PLAT) ..\examples\settings

# Generate wrap_init.cc files

vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\wrap_init.cc: $(glibmm_real_hg)
	@if not exist ..\glib\glibmm\wrap_init.cc $(PERL) -- "../tools/generate_wrap_init.pl" --namespace=Glib --parent_dir=glibmm $(glibmm_real_hg:\=/)>$@

vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\wrap_init.cc: $(giomm_real_hg)
	@if not exist ..\gio\giomm\wrap_init.cc $(PERL) -- "../tools/generate_wrap_init.pl" --namespace=Gio --parent_dir=giomm $(giomm_real_hg:\=/)>$@
