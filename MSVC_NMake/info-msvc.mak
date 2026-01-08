# NMake Makefile portion for displaying config info

all-build-info:
	@echo.
	@echo ----------
	@echo Build info
	@echo ----------
	@echo Build Type: $(CFG)

help:
	@echo.
	@echo ===========================
	@echo Building glibmm Using NMake
	@echo ===========================
	@echo nmake /f Makefile.vc CFG=[release^|debug] ^<option1=xxx option2=xxx^>
	@echo.
	@echo Where:
	@echo ------
	@echo CFG: Required, use CFG=release for an optimized build and CFG=debug
	@echo for a debug build.  PDB files are generated for all builds.
	@echo.
	@echo -----
	@echo A few options are supported here, namely:
	@echo.
	@echo PREFIX: Optional, the path where dependent libraries and tools may be
	@echo found, default is $$(srcrootdir)\..\vs$$(short_vs_ver)\$$(platform),
	@echo where $$(short_vs_ver) is 15 for VS 2017 and so on; and
	@echo $$(platform) is Win32 for 32-bit builds and x64 for x64 builds.
	@echo.
	@echo BASE_INCLUDEDIR: Base directory where headers of various dependencies can
	@echo be found, default is $$(PREFIX)\include. This can be overridden by
	@echo [DEP]_INCLUDEDIR, as described below.
	@echo.
	@echo BASE_LIBDIR: Base directory where .lib's and architecture-dependent headers
	@echo of various dependencies can be found, default is $$(PREFIX)\lib. This can
	@echo be overridden by [DEP]_LIBDIR, as described below.
	@echo.
	@echo [DEP]_INCLUDEDIR: Optional, base directories where headers of various
	@echo dependencies can be found, default is $$(BASE_INCLUDEDIR). DEP includes
	@echo GLIB and SIGC. Their subdirs, such as 'glib-2.0' for GLib, will be searched
	@echo for, meaning $$(GLIB_INCLUDEDIR)\glib-2.0 will be looked for the GLib headers,
	@echo and so on.
	@echo.
	@echo [DEP]_LIBDIR: Optional, base directories where .libs of various
	@echo dependencies can be found, along with architecture-dependent headers, default is
	@echo $$(BASE_LIBDIR). DEP includes GLIB and SIGC. The subdirs, for the archtecture-
	@echo dependent headers, such as 'glib-2.0\include' for GLib, will be searched for,
	@echo meaning $$(GLIB_LIBDIR)\glib-2.0\include will be looked for the GLib architecture-
	@echo dependent headers, and so on.
	@echo.
	@echo GLIB_BIN_DIR: Directory where GLib executable tools can be found; can be overridden
	@echo with GLIB_COMPILE_SCHEMAS as well, as needed.
	@echo.
	@echo PERL, M4: Path to the PERL intepreter and the m4 utility program, if not in ^%PATH^%.
	@echo PERL is needed for all builds and m4 is needed if building from a GIT checkout. As
	@echo an alternative to using M4, one can use UNIX_TOOLS_BINDIR instead to point to the
	@echo directory where m4.exe is located, such as Cygwin's or MSYS2/MSYS64's 'bin' directory,
	@echo as other UNIXy tools may be used during code generation for a build from a GIT checkout.
	@echo.
	@echo GLIB_COMPILE_SCHEMAS: Location of the glib-compile-schemas tool,
	@echo if it cannot be found in $$(GLIB_BIN_DIR).  This tool is needed for the
	@echo giomm settings example program.
	@echo.
	@echo USE_MESON_LIBS: Use DLLs and LIBs of C++ dependencies that are built with Meson,
	@echo as applicable.
	@echo ======
	@echo A 'clean' target is supported to remove all generated files, intermediate
	@echo object files and binaries for the specified configuration.
	@echo.
	@echo An 'install' target is supported to copy the build (DLLs, utility programs,
	@echo LIBs, along with the header files) to appropriate locations under $$(PREFIX).
	@echo.
	@echo A 'tests' target is supported to build the test programs.
	@echo ======
	@echo.
