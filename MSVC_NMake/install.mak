# NMake Makefile snippet for copying the built libraries, utilities and headers to
# a path under $(PREFIX).

install: all
	@if not exist $(PREFIX)\bin\ mkdir $(PREFIX)\bin
	@if not exist $(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\ mkdir $(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include
	@if not exist $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\ @mkdir $(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private
	@if not exist $(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\ mkdir $(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include
	@if not exist $(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\ @mkdir $(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private
	@copy /b $(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).dll $(PREFIX)\bin
	@copy /b $(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).pdb $(PREFIX)\bin
	@copy /b $(CFG)\$(PLAT)\$(GLIBMM_LIBNAME).lib $(PREFIX)\lib
	@copy /b $(CFG)\$(PLAT)\$(GIOMM_LIBNAME).dll $(PREFIX)\bin
	@copy /b $(CFG)\$(PLAT)\$(GIOMM_LIBNAME).pdb $(PREFIX)\bin
	@copy /b $(CFG)\$(PLAT)\$(GIOMM_LIBNAME).lib $(PREFIX)\lib
	@copy ..\glib\glibmm.h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\"
	@copy ..\gio\giomm.h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\"
	@for %h in ($(glibmm_files_all_h)) do @copy ..\glib\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(glibmm_generated_private_headers)) do @copy ..\glib\glibmm\private\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\private\%h"
	@for %h in ($(glibmm_files_extra_ph_int)) do @copy ..\glib\glibmm\%h "$(PREFIX)\include\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\glibmm\%h"
	@for %h in ($(giomm_generated_headers) $(giomm_files_extra_h)) do @copy ..\gio\giomm\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\%h"
	@for %h in ($(giomm_generated_private_headers)) do @copy ..\gio\giomm\private\%h "$(PREFIX)\include\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\giomm\private\%h"
	@copy ".\glibmm\glibmmconfig.h" "$(PREFIX)\lib\glibmm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\"
	@copy ".\giomm\giommconfig.h" "$(PREFIX)\lib\giomm-$(GLIBMM_MAJOR_VERSION).$(GLIBMM_MINOR_VERSION)\include\"
