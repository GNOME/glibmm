# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Member module
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

package Common::Output::Member;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub output_get
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $conversion = $type_info_local->get_conversion ($c_type, $cxx_type, Common::TypeInfo::Common::TRANSFER_NONE, 'gobj()->' . $c_name);

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', $cxx_type, ' get_', $cxx_name, '() const;'));
  $cc_code_string .= nl (join ('', $cxx_type, ' ', $full_cxx_type, '::get_', $cxx_name, '() const')) .
                     nl ('{') .
                     nl (join ('', '  return ', $conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

sub output_get_ptr
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $conversion = $type_info_local->get_conversion ($c_type, $cxx_type, Common::TypeInfo::Common::TRANSFER_NONE, 'gobj()->' . $c_name);
  my $const_conversion = $type_info_local->get_conversion ($c_type, 'const ' . $cxx_type, Common::TypeInfo::Common::TRANSFER_NONE, 'gobj()->' . $c_name);

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', $cxx_type, ' get_', $cxx_name, '();')) .
                       nl (join ('', 'const ', $cxx_type, ' get_', $cxx_name, '() const;')) .
  $cc_code_string .= nl (join ('', $cxx_type, ' ', $full_cxx_type, '::get_', $cxx_name, '()')) .
                     nl ('{') .
                     nl (join ('', '  return ', $conversion, ';')) .
                     nl ('}') .
                     nl () .
                     nl (join ('', 'const ', $cxx_type, ' ', $full_cxx_type, '::get_', $cxx_name, '() const')) .
                     nl ('{') .
                     nl (join ('', '  return ', $const_conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

sub output_get_ref_ptr
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $reffed_cxx_type = 'Glib::RefPtr< ' . $cxx_type . '>';
  my $reffed_const_cxx_type = 'Glib::RefPtr< const ' . $cxx_type . '>';
  my $conversion = $type_info_local->get_conversion ($c_type, $reffed_cxx_type, Common::TypeInfo::Common::TRANSFER_NONE, 'gobj()->' . $c_name);
  my $const_conversion = $type_info_local->get_conversion ($c_type, $reffed_const_cxx_type, Common::TypeInfo::Common::TRANSFER_NONE, 'gobj()->' . $c_name);

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', $reffed_cxx_type, ' get_', $cxx_name, '();')) .
                       nl (join ('', $reffed_const_cxx_type, ' get_', $cxx_name, '() const;')) .
  $cc_code_string .= nl (join ('', $cxx_type, ' ', $full_cxx_type, '::get_', $cxx_name, '()')) .
                     nl ('{') .
                     nl (join ('', '  return ', $conversion, ';')) .
                     nl ('}') .
                     nl () .
                     nl (join ('', $reffed_const_cxx_type, ' ', $full_cxx_type, '::get_', $cxx_name, '() const')) .
                     nl ('{') .
                     nl (join ('', '  return ', $const_conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

sub output_set
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $conversion = $type_info_local->get_conversion ($cxx_type, $c_type, Common::TypeInfo::Common::TRANSFER_NONE, 'value');

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', 'void set_', $cxx_name, '(const ', $cxx_type, '& value);'));
  $cc_code_string .= nl (join ('', 'void ', $full_cxx_type, '::set_', $cxx_name, '(const ', $cxx_type, '& value)')) .
                     nl ('{') .
                     nl (join ('', '  gobj->', $c_name, ' = ', $conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

sub output_set_ptr
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $conversion = $type_info_local->get_conversion ($cxx_type, $c_type, Common::TypeInfo::Common::TRANSFER_NONE, 'value');

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', 'void set_', $cxx_name, '(const ', $cxx_type, ' value);'));
  $cc_code_string .= nl (join ('', 'void ', $full_cxx_type, '::set_', $cxx_name, '(const ', $cxx_type, ' value)')) .
                     nl ('{') .
                     nl (join ('', '  gobj->', $c_name, ' = ', $conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

sub output_set_ref_ptr
{
  my ($wrap_parser, $cxx_name, $c_name, $cxx_type, $c_type, $deprecated) = @_;
  my $section_manager = $wrap_parser->get_section_manager ();
  my $main_section = $wrap_parser->get_main_section ();
  my $cc_section = Common::Output::Shared::get_section ($wrap_parser, Common::Sections::CC_NAMESPACE);
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $main_code_string = '';
  my $cc_code_string = '';
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type ($wrap_parser);
  my $ref_cxx_type = join ('', 'Glib::RefPtr< ', $cxx_type, ' >');
  my $conversion = $type_info_local->get_conversion ($ref_cxx_type, $c_type, Common::TypeInfo::Common::TRANSFER_NONE, 'value');
  my $old_conversion = $type_info_local->get_conversion ($c_type, $ref_cxx_type, Common::TypeInfo::TRANSFER_FULL, 'gobj->' . $c_name);

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_start ($wrap_parser);
  }

  $main_code_string .= nl (join ('', 'void set_', $cxx_name, '(const ', $ref_cxx_type, '& value);'));
  $cc_code_string .= nl (join ('', 'void ', $full_cxx_type, '::set_', $cxx_name, '(const ', $ref_cxx_type, '& value)')) .
                     nl ('{') .
                     nl ('  // Take possession of the old value, unrefing it in the destructor.') .
                     nl (join ('', '  ', $ref_cxx_type, ' old_value(', $old_conversion, ');')) .
                     nl () .
                     nl (join ('', '  gobj->', $c_name, ' = ', $conversion, ';')) .
                     nl ('}') .
                     nl ();

  if ($deprecated)
  {
    $main_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
    $cc_code_string .= Common::Output::Shared::deprecate_end ($wrap_parser);
  }

  $section_manager->append_string_to_section ($main_code_string, $main_section);
  $section_manager->append_string_to_section ($cc_code_string, $cc_section);
}

1; # indicate proper module load.
