# NMake Makefile portion for code generation and
# intermediate build directory creation
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.

# Create the build directories
vs$(PDBVER)\$(CFG)\$(PLAT)\gendef	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-ex	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-ex	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm-tests	\
vs$(PDBVER)\$(CFG)\$(PLAT)\giomm-tests	\
vs$(PDBVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen:
	@-mkdir $@

# Generate .def files
vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\glibmm.def: $(GENDEF) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm $(glibmm_OBJS)
	vs$(PDBVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GLIBMM_LIBNAME) vs$(PDBVER)\$(CFG)\$(PLAT)\glibmm\*.obj

vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\giomm.def: $(GENDEF) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm $(giomm_OBJS)
	vs$(PDBVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GIOMM_LIBNAME) vs$(PDBVER)\$(CFG)\$(PLAT)\giomm\*.obj

# Compile schema for giomm settings example
vs$(PDBVER)\$(CFG)\$(PLAT)\gschema.compiled: ..\examples\settings\org.gtkmm.demo.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) --targetdir=vs$(PDBVER)\$(CFG)\$(PLAT) ..\examples\settings