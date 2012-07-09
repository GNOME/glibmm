## Copyright (c) 2009  Openismus GmbH  <http://www.openismus.com/>
##
## This file is part of glibmm.
##
## glibmm is free software: you can redistribute it and/or modify it
## under the terms of the GNU Lesser General Public License as published
## by the Free Software Foundation, either version 2.1 of the License,
## or (at your option) any later version.
##
## glibmm is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.

# Override code generator commands to use the uninstalled tools.
include $(top_srcdir)/tools/pm/filelist.am
include $(srcdir)/filelist.am
include $(top_srcdir)/tools/proc/filelist.am

codegen_proc_srcdir  = $(top_srcdir)/tools/proc
gmmproc_script = $(top_builddir)/tools/gmmproc
gmmproc_perl_includes = -I$(top_srcdir)/tools/pm
gmmproc_extra_dependencies = $(gmmproc_pm_modules) $(gmmproc_script)

binding_name = glibmm
wrap_init_namespace = Glib
gir_basename = GLib-2.0.gir

files_ccg  = $(glibmm_files_ccg)
files_hg   = $(glibmm_files_hg)

include $(top_srcdir)/build/generate-binding.am

files_src_m4 = $(glibmm_files_cc_m4) $(glibmm_files_h_m4)

other_built_sources += $(patsubst %.m4,$(binding_outputdir)/%,$(files_src_m4))
dist_noinst_DATA    += $(files_src_m4) template.macros.m4

$(binding_outputdir)/%: %.m4 template.macros.m4
	$(AM_V_GEN)$(M4) -I$(srcdir) $< >$@
