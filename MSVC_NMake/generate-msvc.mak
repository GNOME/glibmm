# NMake Makefile portion for code generation and
# intermediate build directory creation
# Items in here should not need to be edited unless
# one is maintaining the NMake build files.

# Compile schema for giomm settings example
vs$(VSVER)\$(CFG)\$(PLAT)\gschema.compiled: ..\examples\settings\org.gtkmm.demo.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) --targetdir=$(@D) $(**D)

# Generate wrap_init.cc files
vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\wrap_init.cc: $(glibmm_real_hg) ..\tools\generate_wrap_init.pl
	@if not exist ..\glib\glibmm\wrap_init.cc $(PERL) -- "../tools/generate_wrap_init.pl" --namespace=Glib --parent_dir=glibmm $(glibmm_real_hg:\=/)>$@

vs$(VSVER)\$(CFG)\$(PLAT)\giomm\wrap_init.cc: $(giomm_real_hg) ..\tools\generate_wrap_init.pl
	@if not exist ..\gio\giomm\wrap_init.cc $(PERL) -- "../tools/generate_wrap_init.pl" --namespace=Gio --parent_dir=giomm $(giomm_real_hg:\=/)>$@

# Generate pre-generated resources and configuration headers (builds from GIT)
prep-git-build: pkg-ver.mak
	$(MAKE) /f Makefile.vc CFG=$(CFG) GENERATE_VERSIONED_FILES=1 glibmm\glibmm.rc giomm\giomm.rc giomm\giommconfig.h

gen-perl-scripts-real: pkg-ver.mak
	$(MAKE) /f Makefile.vc CFG=$(CFG) GENERATE_VERSIONED_FILES=1 ..\tools\gmmproc ..\tools\generate_wrap_init.pl

glibmm\glibmm.rc: ..\configure.ac glibmm\glibmm.rc.in glibmm\glibmmconfig.h
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(DO_REAL_GEN)" == "1" echo Generating $@...
	@if "$(DO_REAL_GEN)" == "1" copy $@.in $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GLIBMM_MAJOR_VERSION\@/$(PKG_MAJOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GLIBMM_MINOR_VERSION\@/$(PKG_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GLIBMM_MICRO_VERSION\@/$(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@PACKAGE_VERSION\@/$(PKG_MAJOR_VERSION).$(PKG_MINOR_VERSION).$(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GLIBMM_MODULE_NAME\@/glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" del $@.bak

glibmm\glibmmconfig.h: ..\configure.ac ..\glib\glibmmconfig.h.in
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(DO_REAL_GEN)" == "1" echo Copying $@ from ..\glib\glibmmconfig.h.in...
	@if "$(DO_REAL_GEN)" == "1" copy ..\glib\glibmmconfig.h.in $@

giomm\giomm.rc: ..\configure.ac
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(DO_REAL_GEN)" == "1" echo Generating $@...
	@if "$(DO_REAL_GEN)" == "1" copy $@.in $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GIOMM_MAJOR_VERSION\@/$(PKG_MAJOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GIOMM_MINOR_VERSION\@/$(PKG_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GIOMM_MICRO_VERSION\@/$(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@PACKAGE_VERSION\@/$(PKG_MAJOR_VERSION).$(PKG_MINOR_VERSION).$(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GIOMM_MODULE_NAME\@/giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" del $@.bak

# You may change GIOMM_DISABLE_DEPRECATED and GIOMM_STATIC_LIB if you know what you are doing
giomm\giommconfig.h: ..\configure.ac ..\gio\giommconfig.h.in
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) prep-git-build
	@if "$(DO_REAL_GEN)" == "1" echo Generating $@...
	@if "$(DO_REAL_GEN)" == "1" copy ..\gio\$(@F).in $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\#undef GIOMM_DISABLE_DEPRECATED/\/\* \#undef GIOMM_DISABLE_DEPRECATED \*\//g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\#undef GIOMM_STATIC_LIB/\/\* \#undef GIOMM_STATIC_LIB \*\//g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\#undef GIOMM_MAJOR_VERSION/\#define GIOMM_MAJOR_VERSION $(PKG_MAJOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\#undef GIOMM_MINOR_VERSION/\#define GIOMM_MINOR_VERSION $(PKG_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\#undef GIOMM_MICRO_VERSION/\#define GIOMM_MICRO_VERSION $(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" del $@.bak

..\tools\gmmproc: ..\configure.ac ..\tools\gmmproc.in
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) gen-perl-scripts-real
	@if "$(DO_REAL_GEN)" == "1" echo Generating $@...
	@if "$(DO_REAL_GEN)" == "1" copy ..\tools\gmmproc.in $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@PERL\@/$(PERL:\=\/)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@prefix\@/$(PREFIX_REAL:\=\/)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@exec_prefix\@/$(PREFIX_REAL:\=\/)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@libdir\@/$(PREFIX_REAL:\=\/)\/share/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@M4\@/$(M4:\=\/)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@GLIBMM_MODULE_NAME\@/glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@PACKAGE_VERSION\@/$(PKG_MAJOR_VERSION).$(PKG_MINOR_VERSION).$(PKG_MICRO_VERSION)/g" $@
	@if "$(DO_REAL_GEN)" == "1" del $@.bak

..\tools\generate_wrap_init.pl: ..\configure.ac ..\tools\generate_wrap_init.pl.in
	@if not "$(DO_REAL_GEN)" == "1" if exist pkg-ver.mak del pkg-ver.mak
	@if not exist pkg-ver.mak $(MAKE) /f Makefile.vc CFG=$(CFG) gen-perl-scripts-real
	@if "$(DO_REAL_GEN)" == "1" echo Generating $@...
	@if "$(DO_REAL_GEN)" == "1" copy ..\tools\generate_wrap_init.pl.in $@
	@if "$(DO_REAL_GEN)" == "1" $(PERL) -pi.bak -e "s/\@PERL\@/$(PERL:\=\/)/g" $@
	@if "$(DO_REAL_GEN)" == "1" del $@.bak

pkg-ver.mak: ..\configure.ac
	@echo Generating version info Makefile Snippet...
	@$(PERL) -00 -ne "print if /AC_INIT\(/" $** |	\
	$(PERL) -pe "tr/, /\n/s" |	\
	$(PERL) -ne "print if 2 .. 2" |	\
	$(PERL) -ne "print /\[(.*)\]/" > ver.txt
	@echo @echo off>pkg-ver.bat
	@echo.>>pkg-ver.bat
	@echo set /p glibmm_ver=^<ver.txt>>pkg-ver.bat
	@echo for /f "tokens=1,2,3 delims=." %%%%a IN ("%glibmm_ver%") do (echo PKG_MAJOR_VERSION=%%%%a^& echo PKG_MINOR_VERSION=%%%%b^& echo PKG_MICRO_VERSION=%%%%c)^>$@>>pkg-ver.bat
	@pkg-ver.bat
	@del ver.txt pkg-ver.bat
