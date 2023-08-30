## Copyright (c) 2009, 2010, 2011  Openismus GmbH  <http://www.openismus.com/>
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

AUTOMAKE_OPTIONS = subdir-objects

check_PROGRAMS =				\
	giomm_ioerror/test			\
	giomm_ioerror_and_iodbuserror/test	\
	giomm_memoryinputstream/test			\
	giomm_simple/test			\
  giomm_stream_vfuncs/test \
	giomm_asyncresult_sourceobject/test	\
	giomm_tls_client/test			\
	giomm_listmodel/test \
	glibmm_base64/test			\
	glibmm_binding/test     \
	glibmm_date/test			\
	glibmm_environ/test			\
	glibmm_buildfilename/test		\
	glibmm_interface_implementation/test	\
	glibmm_interface_move/test			\
	glibmm_mainloop/test			\
	glibmm_nodetree/test			\
	glibmm_object/test			\
	glibmm_object_move/test			\
	glibmm_objectbase/test			\
	glibmm_objectbase_move/test			\
	glibmm_regex/test			\
	glibmm_ustring_compare/test		\
	glibmm_ustring_compose/test		\
	glibmm_ustring_format/test		\
	glibmm_ustring_hash/test		\
	glibmm_ustring_sprintf/test		\
	glibmm_value/test			\
	glibmm_variant/test			\
	glibmm_vector/test			\
	glibmm_bool_vector/test			\
	glibmm_null_vectorutils/test		\
	glibmm_refptr/test		\
	glibmm_refptr_sigc_bind/test		\
	glibmm_bytearray/test			\
	glibmm_ustring_make_valid/test

TESTS =	$(check_PROGRAMS)

glibmm_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
giomm_includes  = -I$(top_builddir)/gio $(if $(srcdir:.=),-I$(top_srcdir)/gio)
local_cppflags  = -I$(top_builddir) $(glibmm_includes) $(giomm_includes)

AM_CPPFLAGS = $(local_cppflags) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS) -DGLIBMM_DISABLE_DEPRECATED -DGIOMM_DISABLE_DEPRECATED


local_libglibmm = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la
local_libgiomm  = $(top_builddir)/gio/giomm/libgiomm-$(GIOMM_API_VERSION).la

LDADD = $(local_libglibmm) $(GLIBMM_LIBS)
giomm_ldadd = $(local_libglibmm) $(local_libgiomm) $(GIOMM_LIBS)

giomm_ioerror_test_SOURCES = giomm_ioerror/main.cc
giomm_ioerror_test_LDADD   = $(giomm_ldadd)

giomm_ioerror_and_iodbuserror_test_SOURCES = giomm_ioerror_and_iodbuserror/main.cc
giomm_ioerror_and_iodbuserror_test_LDADD   = $(giomm_ldadd)

giomm_memoryinputstream_test_SOURCES = giomm_memoryinputstream/main.cc
giomm_memoryinputstream_test_LDADD   = $(giomm_ldadd)

giomm_simple_test_SOURCES  = giomm_simple/main.cc
giomm_simple_test_LDADD    = $(giomm_ldadd)

giomm_stream_vfuncs_test_SOURCES = giomm_stream_vfuncs/main.cc
giomm_stream_vfuncs_test_LDADD   = $(giomm_ldadd)

giomm_asyncresult_sourceobject_test_SOURCES  = giomm_asyncresult_sourceobject/main.cc
giomm_asyncresult_sourceobject_test_LDADD    = $(giomm_ldadd)

giomm_tls_client_test_SOURCES                = giomm_tls_client/main.cc
giomm_tls_client_test_LDADD                  = $(giomm_ldadd)

giomm_listmodel_test_SOURCES                = giomm_listmodel/main.cc
giomm_listmodel_test_LDADD                  = $(giomm_ldadd)

glibmm_base64_test_SOURCES               = glibmm_base64/main.cc
glibmm_binding_test_SOURCES              = glibmm_binding/main.cc
glibmm_buildfilename_test_SOURCES        = glibmm_buildfilename/main.cc
glibmm_date_test_SOURCES                 = glibmm_date/main.cc
glibmm_environ_test_SOURCES              = glibmm_environ/main.cc

glibmm_interface_implementation_test_SOURCES = glibmm_interface_implementation/main.cc
glibmm_interface_implementation_test_LDADD = $(giomm_ldadd)

glibmm_interface_move_test_SOURCES       = glibmm_interface_move/main.cc
glibmm_mainloop_test_SOURCES             = glibmm_mainloop/main.cc
glibmm_nodetree_test_SOURCES             = glibmm_nodetree/main.cc
glibmm_object_test_SOURCES               = glibmm_object/main.cc \
					   glibmm_object/test_derived_object.h
glibmm_object_move_test_SOURCES          = glibmm_object_move/main.cc \
					   glibmm_object/test_derived_object.h
glibmm_objectbase_test_SOURCES           = glibmm_objectbase/main.cc \
					   glibmm_objectbase/test_derived_objectbase.h \
					   glibmm_object/test_derived_object.h
glibmm_objectbase_move_test_SOURCES      = glibmm_objectbase_move/main.cc \
					   glibmm_objectbase/test_derived_objectbase.h \
					   glibmm_object/test_derived_object.h
glibmm_ustring_compare_test_SOURCES      = glibmm_ustring_compare/main.cc
glibmm_ustring_compose_test_SOURCES      = glibmm_ustring_compose/main.cc
glibmm_ustring_format_test_SOURCES       = glibmm_ustring_format/main.cc
glibmm_ustring_hash_test_SOURCES         = glibmm_ustring_hash/main.cc
glibmm_ustring_sprintf_test_SOURCES      = glibmm_ustring_sprintf/main.cc
glibmm_regex_test_SOURCES                = glibmm_regex/main.cc
glibmm_value_test_SOURCES                = glibmm_value/main.cc
glibmm_variant_test_SOURCES              = glibmm_variant/main.cc
glibmm_vector_test_SOURCES               = glibmm_vector/main.cc
glibmm_vector_test_LDADD                 = $(giomm_ldadd)
glibmm_bool_vector_test_SOURCES          = glibmm_bool_vector/main.cc
glibmm_null_vectorutils_test_SOURCES     = glibmm_null_vectorutils/main.cc
glibmm_null_vectorutils_test_LDADD       = $(giomm_ldadd)
glibmm_refptr_test_SOURCES               = glibmm_refptr/main.cc
glibmm_refptr_sigc_bind_test_SOURCES     = glibmm_refptr_sigc_bind/main.cc
glibmm_bytearray_test_SOURCES            = glibmm_bytearray/main.cc
glibmm_ustring_make_valid_test_SOURCES   = glibmm_ustring_make_valid/main.cc
