# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::OpaqueRefcounted module
#
# Copyright 2012 glibmm development team
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#

package Common::Output::OpaqueRefcounted;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h_in_class ($$$$)
{
  my ($wrap_parser, $c_type, $cxx_type, $new_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cxx_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();

  if (defined $new_func and $new_func ne '' and $new_func ne 'NONE')
  {
    $code_string .= nl ('  static Glib::RefPtr< ' . $cxx_type . ' > create();') .
                    nl ();
  }

  my $copy_proto = 'const';
  my $reinterpret = 0;
  my $definitions = 0;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $main_section = $wrap_parser->get_main_section;

  $code_string .= nl ('  /** Increment the reference count for this object.') .
                  nl ('   * You should never need to do this manually - use the object via a RefPtr instead.') .
                  nl ('   */') .
                  nl ('  void reference() const;') .
                  nl () .
                  nl ('  /** Decrement the reference count for this object.') .
                  nl ('   * You should never need to do this manually - use the object via a RefPtr instead.') .
                  nl ('   */') .
                  nl ('  void unreference() const;') .
                  nl () .
                  nl (Common::Output::Shared::gobj_protos_str $c_type, $copy_proto, $reinterpret, $definitions) .
                  nl () .
                  nl ('protected:') .
                  nl ('  // Do not derive this. ' . $full_cxx_type . ' can neither be constructed nor deleted.') .
                  nl ('  ' . $cxx_type . '();') .
                  nl ('  void operator delete(void*, size_t);') .
                  nl () .
                  nl ('private:') .
                  nl (Common::Output::Shared::copy_protos_str $cxx_type) .
                  nl ();
  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub _output_h_after_first_namespace ($$)
{
  my ($wrap_parser, $c_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $result_type = 'refptr';
  my $take_copy_by_default = 'no';
  my $open_glib_namespace = 1;
  my $const_function = 0;
# TODO: This should not be a conditional, but a plain string.
  my $conditional = Common::Output::Shared::wrap_proto $wrap_parser, $c_type, $result_type, $take_copy_by_default, $open_glib_namespace, $const_function;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_NAMESPACE;

  $section_manager->append_conditional_to_section ($conditional, $section);
}

sub _output_cc ($$$$$)
{
  my ($wrap_parser, $c_type, $new_func, $ref_func, $unref_func) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_GENERATED;
  my $code_string = nl ('/* Why reinterpret_cast< ' . $full_cxx_type . '* >(gobject) is needed:') .
                    nl (' *') .
                    nl (' * A ' . $full_cxx_type . ' instance is in fact always a ' . $c_type . ' instance.') .
                    nl (' * Unfortunately, ' . $c_type . ' cannot be a member of ' . $full_cxx_type . ',') .
                    nl (' * because it is an opaque struct.  Also, the C interface does not provide') .
                    nl (' * any hooks to install a destroy notification handler, thus we cannot') .
                    nl (' * wrap it dynamically either.') .
                    nl (' *') .
                    nl (' * The cast works because ' . $full_cxx_type . ' does not have any member data, and') .
                    nl (' * it is impossible to derive from it.  This is ensured by not implementing') .
                    nl (' * the (protected) default constructor.  The ctor is protected rather than') .
                    nl (' * private just to avoid a compile warning.') .
                    nl (' */') .
                    nl ('/* krnowak:') .
                    nl (' * This is an awful hack and I think it is not necessary.') .
                    nl (' * We could store a pointer to C instance.') .
                    nl (' * We just would not be an owner of this pointer.') .
                    nl (' */') .
                    nl () .
                    nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('Glib::RefPtr< ' . $full_cxx_type . ' > wrap(' . $c_type . '* object, bool take_copy)') .
                    nl ('{') .
                    nl ('  if (take_copy && object)') .
                    nl ('    ' . $ref_func . '(object);') .
                    nl () .
                    nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                    nl ('  return Glib::RefPtr< ' . $full_cxx_type . ' >(reinterpret_cast< ' . $full_cxx_type . '* >(object));') .
                    nl ('}') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl () .
                    nl (Common::Output::Shared::open_namespaces $wrap_parser) .
                    nl ();
  if (defined $new_func and $new_func ne '' and $new_func ne 'NONE')
  {
    $code_string .= nl ('// static') .
                    nl ('Glib::RefPtr< ' . $full_cxx_type . ' > ' . $full_cxx_type . '::create()') .
                    nl ('{') .
                    nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                    nl ('  return Glib::RefPtr< ' . $full_cxx_type . ' >(reinterpret_cast< ' . $full_cxx_type . ' >(' . $new_func . '()));') .
                    nl ('}') .
                    nl ();
  }

  $code_string .= nl ('void ' . $full_cxx_type . '::reference() const') .
                  nl ('{') .
                  nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                  nl ('  ' . $ref_func . '(reinterpret_cast< ' . $c_type . '* >(const_cast< ' . $full_cxx_type .  '* >(this)));') .
                  nl ('}') .
                  nl () .
                  nl ('void ' . $full_cxx_type . '::unreference() const') .
                  nl ('{') .
                  nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                  nl ('  ' . $unref_func . '(reinterpret_cast< ' . $c_type . '* >(const_cast< ' . $full_cxx_type . '* >(this)));') .
                  nl ('}') .
                  nl () .
                  nl ($c_type . '* ' . $full_cxx_type . '::gobj()') .
                  nl ('{') .
                  nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                  nl ('  return reinterpret_cast< ' . $c_type . '* >(this);') .
                  nl ('}') .
                  nl () .
                  nl ('const ' . $c_type . '* ' . $full_cxx_type . '::gobj() const') .
                  nl ('{') .
                  nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                  nl ('  return reinterpret_cast< const ' . $c_type . '* >(this);') .
                  nl ('}') .
                  nl () .
                  nl ($c_type . '* ' . $full_cxx_type . '::gobj_copy() const') .
                  nl ('{') .
                  nl ('  // See the comment at the top of this file, if you want to know why the cast works.') .
                  nl ('  ' . $c_type . '* const gobject = reinterpret_cast< ' . $c_type . '* >(const_cast< ' . $full_cxx_type . '* >(this));') .
                  nl ('  ' . $ref_func . '(gobject);') .
                  nl ('  return gobject;') .
                  nl ('}') .
                  nl ();
  $section_manager->append_string_to_section ($code_string, $section);
  $code_string = nl () .
                 Common::Output::Shared::close_namespaces $wrap_parser;
  $section_manager->append_string_to_section ($code_string, $section);
}

sub output ($$$$$$)
{
  my ($wrap_parser, $c_type, $cxx_type, $new_func, $ref_func, $unref_func) = @_;

  _output_h_in_class $wrap_parser, $c_type, $cxx_type, $new_func;
  _output_h_after_first_namespace $wrap_parser, $c_type;
  _output_cc $wrap_parser, $c_type, $new_func, $ref_func, $unref_func;
}

1; # indicate proper module load.
