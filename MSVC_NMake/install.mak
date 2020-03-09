# NMake Makefile snippet for copying the built libraries, utilities and headers to
# a path under $(PREFIX).

install: all
	@if not exist $(PREFIX)\bin\ md $(PREFIX)\bin
	@if not exist $(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\ md $(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include
	@if not exist $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\ @md $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private
	@if not exist $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm_generate_extra_defs\ @md $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm_generate_extra_defs
	@if not exist $(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\ md $(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include
	@if not exist $(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\ @md $(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private
	@-for %d in (m4 pm) do @md $(PREFIX)\share\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\proc\%d
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).dll $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).pdb $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).lib $(PREFIX)\lib
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GIOMM_LIBNAME).dll $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GIOMM_LIBNAME).pdb $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GIOMM_LIBNAME).lib $(PREFIX)\lib
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_EXTRA_DEFS_GEN_LIBNAME).dll $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_EXTRA_DEFS_GEN_LIBNAME).pdb $(PREFIX)\bin
	@copy /b vs$(VSVER)\$(CFG)\$(PLAT)\$(GLIBMM_EXTRA_DEFS_GEN_LIBNAME).lib $(PREFIX)\lib
	@copy /b $(GLIBMM_EXTRA_DEFS_GEN_LIB) $(PREFIX)\lib
	@copy ..\glib\glibmm.h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\"
	@copy ..\gio\giomm.h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\"
	@for %h in ($(glibmm_files_all_h)) do @if exist ..\glib\glibmm\%h copy ..\glib\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(glibmm_files_all_h)) do @if exist ..\untracked\glib\glibmm\%h copy ..\untracked\glib\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(glibmm_files_all_h)) do @if exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\%h copy vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(glibmm_generated_private_headers)) do @if exist ..\glib\glibmm\private\%h copy ..\glib\glibmm\private\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\%h"
	@for %h in ($(glibmm_generated_private_headers)) do @if exist ..\untracked\glib\glibmm\private\%h copy ..\untracked\glib\glibmm\private\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\%h"
	@for %h in ($(glibmm_generated_private_headers)) do @if exist vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\private\%h copy vs$(VSVER)\$(CFG)\$(PLAT)\glibmm\private\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\%h"
	@for %h in ($(glibmm_files_extra_ph_int)) do @copy ..\glib\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(giomm_generated_headers) $(giomm_files_extra_h)) do @if exist ..\gio\giomm\%h copy ..\gio\giomm\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\%h"
	@for %h in ($(giomm_generated_headers) $(giomm_files_extra_h)) do @if exist ..\untracked\gio\giomm\%h copy ..\untracked\gio\giomm\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\%h"
	@for %h in ($(giomm_generated_headers) $(giomm_files_extra_h)) do @if exist vs$(VSVER)\$(CFG)\$(PLAT)\giomm\%h copy vs$(VSVER)\$(CFG)\$(PLAT)\giomm\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\%h"
	@for %h in ($(giomm_generated_private_headers)) do @if exist ..\gio\giomm\private\%h copy ..\gio\giomm\private\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\%h"
	@for %h in ($(giomm_generated_private_headers)) do @if exist ..\untracked\gio\giomm\private\%h copy ..\untracked\gio\giomm\private\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\%h"
	@for %h in ($(giomm_generated_private_headers)) do @if exist vs$(VSVER)\$(CFG)\$(PLAT)\giomm\private\%h copy vs$(VSVER)\$(CFG)\$(PLAT)\giomm\private\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\%h"
	@copy ".\glibmm\glibmmconfig.h" "$(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\"
	@copy ".\giomm\giommconfig.h" "$(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\"
	@copy "..\tools\extra_defs_gen\generate_extra_defs.h" "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm_generate_extra_defs\"
	@for %d in (m4 pm) do copy ..\tools\%d\* $(PREFIX)\share\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\proc\%d
	@for %f in (gmmproc generate_wrap_init.pl) do @if exist ..\tools\%f copy ..\tools\%f $(PREFIX)\share\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\proc
	@for %f in (gmmproc generate_wrap_init.pl) do @if not exist ..\tools\%f copy ..\tools\%f.in $(PREFIX)\share\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\proc\%f
	@echo Please ensure gmmproc and generate_wrap_init.pl in $(PREFIX)\share\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\proc contain the correct paths
