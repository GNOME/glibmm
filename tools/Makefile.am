AUTOMAKE_OPTIONS = subdir-objects

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_SCANNER_ARGS = \
  --warn-all
INTROSPECTION_COMPILER_ARGS = \
  --includedir=$(srcdir)

c_lib = \
  pm/tests/libgm/gm/libgm.la

c_files = \
  pm/tests/libgm/gm/gm-obj.c \
  pm/tests/libgm/gm/gm-obj.h \
  pm/tests/libgm/gm/gm-other.c \
  pm/tests/libgm/gm/gm-other.h

cxx_lib = \
  pm/tests/libgmmm/gm/gmmm/libgmmm.la

cxx_files = \
  pm/tests/libgmmm/gm/gmmm/obj.cc \
  pm/tests/libgmmm/gm/gmmm/obj.h \
  pm/tests/libgmmm/gm/gmmm/other.cc \
  pm/tests/libgmmm/gm/gmmm/other.h

cxx_templates = \
  pm/tests/libgmmm/gm/src/obj.ccg \
  pm/tests/libgmmm/gm/src/obj.hg \
  pm/tests/libgmmm/gm/src/other.ccg \
  pm/tests/libgmmm/gm/src/other.hg

cxx_gm_templates = \
  obj \
  other

gir_file = pm/tests/libgm/gm/Gm-1.0.gir
proc_stamp_file = pm/tests/libgmmm/proc/.proc-stamp

noinst_LTLIBRARIES = $(c_lib) $(cxx_lib)

pm_tests_libgm_gm_libgm_la_SOURCES = \
  $(c_files)
pm_tests_libgm_gm_libgm_la_LIBADD = \
  $(GM_LIBS)
pm_tests_libgm_gm_libgm_la_CPPFLAGS = \
  $(GM_CFLAGS)
pm_tests_libgm_gm_libgm_la_CFLAGS = \
  $(GLIBMM_WXXFLAGS)

$(gir_file): $(INTROSPECTION_SCANNER) $(c_lib)
pm_tests_libgm_gm_Gm_1_0_gir_SCANNERFLAGS =
pm_tests_libgm_gm_Gm_1_0_gir_INCLUDES = \
  GObject-2.0
pm_tests_libgm_gm_Gm_1_0_gir_CFLAGS = \
  -I$(srcdir)
pm_tests_libgm_gm_Gm_1_0_gir_LIBS = \
  $(c_lib)
pm_tests_libgm_gm_Gm_1_0_gir_FILES = \
  $(c_files)
pm_tests_libgm_gm_Gm_1_0_gir_EXPORT_PACKAGES = \
  gm-1.0
INTROSPECTION_GIRS = $(gir_file)

pm_tests_libgmmm_gm_gmmm_libgmmm_la_SOURCES = \
  $(cxx_files)
pm_tests_libgmmm_gm_gmmm_libgmmm_la_CPPFLAGS = \
  -I$(srcdir)/pm/tests/libgm \
  -I$(builddir)/pm/tests/libgmmm/gm \
  `pkg-config --cflags glibmm-2.4`
pm_tests_libgmmm_gm_gmmm_libgmmm_la_CXXFLAGS = \
  $(GLIBMM_WXXFLAGS)

$(cxx_files): $(proc_stamp_file)

inc1 = @abs_top_srcdir@/tools/pm/tests
inc2 = @abs_top_srcdir@/tools/pm
source = @abs_top_srcdir@/tools/pm/tests/libgmmm/gm/src
dest = @abs_top_builddir@/tools/pm/tests/libgmmm/gm/gmmm
gmminc = @abs_top_srcdir@/tools/pm/tests/libgmmm/proc

$(proc_stamp_file): $(gir_file) $(cxx_templates) gmmproc
	perl -I$(inc1) -I$(inc2) ./gmmproc --source $(source) --destination $(dest) --gir Gm-1.0.gir --mm-module gmmm --include $(gmminc) $(cxx_gm_templates)
	touch $(proc_stamp_file)

CLEANFILES = $(cxx_files) $(gir_file) $(proc_stamp_file)
