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
gmmproc       = $(PERL) -- $(top_builddir)/tools/gmmproc
gen_wrap_init = $(PERL) -- $(top_builddir)/tools/generate_wrap_init.pl

binding_name    = glibmm
wrap_init_flags = --namespace=Glib --parent_dir=glibmm
codegen_srcdir  = $(top_srcdir)/tools

include $(srcdir)/filelist.am
include $(top_srcdir)/tools/m4/filelist.am
include $(top_srcdir)/build/generate-binding.am

files_src_m4 = $(files_cc_m4) $(files_h_m4)

other_built_sources += $(files_src_m4:%.m4=$(binding_outputdir)/%)
dist_noinst_DATA    += $(files_src_m4) template.macros.m4

$(binding_outputdir)/%: %.m4 template.macros.m4
	$(M4) -I$(srcdir) $< >$@
