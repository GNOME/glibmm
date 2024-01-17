Building glibmm on Win32
=

Currently, both the mingw (native win32) gcc compiler and MS Visual
Studio 2017 and later are supported. glibmm can be built with
mingw32-gcc using the gnu autotools (automake, autoconf, libtool).
As explicitly stated in the gtk+ for win32 distribution
(http://www.gimp.org/win32/), the gcc compiler provided by the cygwin
distribution should not be used to build glib/glibmm libraries and/or
applications (see the README.win32 that comes with the gtk+ DLLs).
This MIGHT cause conflicts between the cygwin and msvcrt runtime
environments.

If building against libsigc++-3.6.0 or later with Visual Studio, it is recommended
to use Visual Studio 2019 or later for best support-building with maximum warning
level and treating warnings as errors with Visual Studio 2017 with libsigc++-3.6.x
or later is not supported.

### Mingw

The mingw distribution which has been tested with this release is the
following :

* MinGW-4.1 as the base distribution.

The bare mingw distribution does not provide the necessary tools (`sh`, `perl`, `m4`
, `autoconf`, `automake`, ...) to run the provided configure script "as is". One
(currently non supported) solution is to use mingw in conjunction with msys,
which is readily available on the mingw website (http://www.mingw.org/).

The preferred method is to combine the cygwin distribution (for the unix tools
that were mentioned above) with mingw by making sure that the mingw
tools (`gcc`, `ld`, `dlltool`, ...) are called first.

First, make sure that you have working distribution of the native port
of both libsigc++-3.x and glib-2.0 on win32 (see
http://www.gimp.org/win32). If you can't compile a simple glib example
using gcc and `pkg-config --cflags --libs`, you should not even think
about trying to compile glibmm, let alone using precompiled libglibmm
DLLs to port your glibmm application !

The configure script can then be called using (as an example) the
following options

```
./configure --prefix=/target --build=i386-pc-mingw32 --disable-static

make
make check
make install
```

### MS Visual Studio 2017 or later

In a Visual Studio command prompt, navigate to the MSVC_NMake directory.
Run `nmake /f Makefile.vc CFG=[release|debug]` to build the glibmm and
giomm DLLs, along with their example programs.  If a prefix other than
`$(srcroot)\..\vs15\$(Platform)` is desired, pass in `PREFIX=$(your_prefix)`
in the NMake command line.  In order to build the giomm settings example
program, the `glib-compile-schemas` tool needs to reside in `$(PREFIX)\bin`, or
it must be specified via passing in `GLIB_COMPILE_SCHEMAS=...` in the NMake
command line.  If using C++ dependencies that are built with Meson, specify
`USE_MESON_LIBS=1` in your NMake command line.

The following list lists the `$(VSVER)` and the `vc14x` in the NMake-built DLLs and .lib's that
corresponds to the Visual Studio version used (Visual Studio versions before 2017 are not
supported):
  * 2017: `15`, `<libname>-vc141-2_68.[dll|pdb|lib]`
  * 2019: `16`, `<libname>-vc142-2_68.[dll|pdb|lib]`
  * 2022: `17`: `<libname>-vc143-2_68.[dll|pdb|lib]`

For Meson, the DLL/PDB filenames and .lib filenames will be like:
  * 2017: `<libname>-vc141-2.68-1.[dll|pdb]`, `<libname>-vc141-2.68.lib`
  * 2019: `<libname>-vc142-2.68-1.[dll|pdb]`, `<libname>-vc142-2.68.lib`
  * 2022: `<libname>-vc143-2.68-1.[dll|pdb]`, `<libname>-vc143-2.68.lib`

Notice that this is no longer the `vc$(VSVER)0` that was used before, to be consistent with
other common C++ libraries such as Boost.  Earlier gtkmm versions may still use the former
`vc$(VSVER)0` naming scehme, so for situations like where rebuilding code using glibmm became
inconvenient, a `USE_COMPAT_LIBS=1` NMake option is provided to use the older naming scheme.
(or use `-Dmsvc14x-parallel-installable=false` in the Meson configure command line
to avoid having the toolset version in the final DLL and .lib filenames);
again, this is only recommended if it is inconvenient to re-build the
dependent code.

For the NMake builds, the following targets are supported:

  * `all` (or no target specified): Build the glibmm and giomm DLLs and .lib,
along with the example programs
  * `tests`: Build the test programs for glibmm and giomm.
  * `install`: Copy the built glibmm and giomm DLLs, .lib's and headers to appropriate locations
under `$(PREFIX)`.
  * `clean`: Remove all the built files.  This includes the generated sources if building from a
GIT checkout, as noted below.

The NMake Makefiles support passing in the following items, with the defaults (everyone of the
following are optional if the paths of needed headers, libraries and tools are in `%INCLUDE%`,
`%LIB%` and `%PATH%` unless otherwise noted):
  * `BASE_TOOLS_PATH` (default: `$(PREFIX)\bin`: Location where tools can be located
  * `BASE_INCLUDES` (default: `$(PREFIX)\include`: Base directory where dependencies' headers can
  be located
  * `BASE_LIBPATH` (default: `$(PREFIX)\lib`: Base directory where dependencies' libraries and
  architecture-dependent or compiler-dependent headers can be located
  * `<DEP>_INCLUDEDIR` (default: `$(BASE_INCLUDES)`): Base directory where <DEP>'s headers can be
  found in their respective subdirectories as applicable, so for instance GLib's headers can be
  found in `$(GLIB_INCLUDEDIR)\glib-2.0` and `$(GLIB_INCLUDEDIR)\gio-win32-2.0`.  <DEP> here
  currently covers GLIB and LIBSIGC
  * `<DEP>_LIBDIR` (default: `$(BASE_LIBPATH)`): Base directory where <DEP>'s architecture-
  and compiler-dependent headers and .lib's can be found in their respective subdirectories as
  applicable, so for instance GLib's `glibconfig.h` can be found in
  `$(GLIB_LIBDIR)\glib-2.0\include`. <DEP> here currently covers GLIB and LIBSIGC.
  * `<DEP>_BINDIR` (default: `$(BASE_TOOLS_PATH`)`): Base directory where <DEP>'s utility programs
  can be found. <DEP> here currently covers GLIB.
  * GLIB_COMPILE_SCHEMAS (default: `$(GLIB_BINDIR)\glib-compile-schemas`): Relative or full path
  where GLib's `glib-compile-schemas` tool can be located, i.e., if `glib-compile-schemas` is in
  `%PATH%`, you may opt to just pass in `GLIB_COMPILE_SCHEMAS=glib-compile-schemas`.

The NMake Makefiles now support building the glibmm libraries directly from a GIT checkout
with a few manual steps required, namely:

  * Ensure that you have a copy of Cygwin or MSYS/MSYS64 installed, including
`m4.exe` and `sh.exe`.  You should also have a PERL for Windows installation
as well, and your `%PATH%` should contain the paths to your PERL interpreter
and the bin\ directory of your Cygwin or MSYS/MSYS64 installation, it is recommended
that these paths are towards the end of your `%PATH%`. You need to install the
`XML::Parser` PERL module as well for your PERL installation, which requires libexpat.

  * Make a new copy of the entire source tree to some location, where the build
is to be done; then in `$(srcroot)\MSVC_NMake` run `nmake /f Makefile.vc CFG=[release|debug]`,
which will first copy and generate the following files with the proper info (mote that this step
will also be run if the following files are not present in the unpacked source tarball, meaning
that in this case a PERL installation needs to be found in PATH or specified in the NMake
commandline with PERL=<path_to_perl.exe>):
```
$(srcroot)\MSVC_NMake\glibmm\glibmmconfig.h
$(srcroot)\MSVC_NMake\giomm\giommconfig.h
$(srcroot)\MSVC_NMake\glibmm\glibmm.rc
$(srcroot)\MSVC_NMake\giomm\giomm.rc
$(srcroot)\tools\gmmproc
$(srcroot)\tools\generate_wrap_init.pl
```

For `giommconfig.h`, it is recommended to keep `GIOMM_STATIC_LIB` and `GIOMM_DISABLE_DEPRECATED`
undefined unless you know what you are doing (remember, the NMake Makefiles only support DLL
builds out-of-the-box, and we don't generally support static builds).  For builds from the release
tarballs, running `nmake /f Makefile.vc CFG=[release|debug] gen-perl-scripts-real` will
also generate `$(srcroot)\tools\gmmproc` and `$(srcroot)\tools\generate_wrap_init.pl` for you.

Note that to generate any of the above 6 files, a PERL installation is also required.

For building with Meson, please see `README.md` for further instructions. Please note that
using `-Ddefault_library=[static|both]` for Visual Studio builds is not supported and
is thus not allowed._

When building with Meson, if building from a GIT checkout or if building with `maintainer-mode`
enabled, you will also need a PERL interpreter and the `m4.exe` and `sh.exe` from Cygwin or
MSYS/MSYS64, and you will need to also install Doxygen, LLVM (likely needed by Doxygen) and
GraphViz unless you pass in `-Dbuild-documentation=false` in your Meson configure command
line.  You will still need to have `mm-common` installed with its `bin` directory in your
`%PATH%`

### Glibmm methods and signals not available on win32

All glibmm methods and signals are available on win32.

