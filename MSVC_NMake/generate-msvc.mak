# NMake Makefile portion for code generation and
# intermediate build directory creation
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.

# Create the build directories
$(CFG)\$(PLAT)\gendef	\
$(CFG)\$(PLAT)\glibmm	\
$(CFG)\$(PLAT)\giomm	\
$(CFG)\$(PLAT)\glibmm-ex	\
$(CFG)\$(PLAT)\giomm-ex	\
$(CFG)\$(PLAT)\glibmm-tests	\
$(CFG)\$(PLAT)\giomm-tests:
	@-mkdir $@

# Generate .def files
$(CFG)\$(PLAT)\glibmm\glibmm.def: $(GENDEF) $(CFG)\$(PLAT)\glibmm $(glibmm_OBJS)
	$(CFG)\$(PLAT)\gendef.exe $@ $(GLIBMM_LIBNAME) $(CFG)\$(PLAT)\glibmm\*.obj

$(CFG)\$(PLAT)\giomm\giomm.def: $(GENDEF) $(CFG)\$(PLAT)\giomm $(giomm_OBJS)
	$(CFG)\$(PLAT)\gendef.exe $@ $(GIOMM_LIBNAME) $(CFG)\$(PLAT)\giomm\*.obj

# Compile schema for giomm settings example
$(CFG)\$(PLAT)\gschema.compiled: ..\examples\settings\org.gtkmm.demo.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) --targetdir=$(CFG)\$(PLAT) ..\examples\settings