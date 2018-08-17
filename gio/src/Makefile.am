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
gmmproc = $(PERL) -I$(top_srcdir)/tools/pm -- $(top_builddir)/tools/gmmproc
gen_wrap_init = $(PERL) -- $(top_builddir)/tools/generate_wrap_init.pl

binding_name    = giomm
wrap_init_flags = --namespace=Gio --parent_dir=giomm
codegen_srcdir  = $(top_srcdir)/tools

include $(srcdir)/filelist.gmake.am
include $(top_srcdir)/tools/m4/filelist.am

files_defs = $(giomm_files_defs)
files_ccg  = $(giomm_files_ccg)
files_hg   = $(giomm_files_hg)

include $(top_srcdir)/build/generate-binding.am
