# NMake Makefile portion for code generation and
# intermediate build directory creation
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.

# Create the build directories
vs$(VSVER)\$(CFG)\$(PLAT)\gendef	\
vs$(VSVER)\$(CFG)\$(PLAT)\glibmm	\
vs$(VSVER)\$(CFG)\$(PLAT)\giomm	\
vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-ex	\
vs$(VSVER)\$(CFG)\$(PLAT)\giomm-ex	\
vs$(VSVER)\$(CFG)\$(PLAT)\glibmm-tests	\
vs$(VSVER)\$(CFG)\$(PLAT)\giomm-tests	\
vs$(VSVER)\$(CFG)\$(PLAT)\glib-extra-defs-gen:
	@-mkdir $@

# Generate .def files
vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\glibmm.def: $(GENDEF) vs$(VSVER)\$(CFG)\$(PLAT)\glibmm $(glibmm_OBJS)
	vs$(VSVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GLIBMM_LIBNAME) vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\*.obj

vs$(VSVER)\$(CFG)\$(PLAT)\giomm\giomm.def: $(GENDEF) vs$(VSVER)\$(CFG)\$(PLAT)\giomm $(giomm_OBJS)
	vs$(VSVER)\$(CFG)\$(PLAT)\gendef.exe $@ $(GIOMM_LIBNAME) vs$(VSVER)\$(CFG)\$(PLAT)\giomm\*.obj

# Compile schema for giomm settings example
vs$(VSVER)\$(CFG)\$(PLAT)\gschema.compiled: ..\examples\settings\org.gtkmm.demo.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) --targetdir=vs$(VSVER)\$(CFG)\$(PLAT) ..\examples\settings