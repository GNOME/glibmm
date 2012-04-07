# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Enum module
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

package Common::Output::Enum;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_enum ($$$)
{
  my ($wrap_parser, $cpp_type, $members) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $string_members = Common::Output::Shared::convert_members_to_strings $members;
  my $code_string = nl ('enum ' . $cpp_type) .
                    nl ('{') .
                    nl (join ((nl ','), @{$string_members})) .
                    nl ('};') .
                    nl ();

  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub _output_flag_ops ($$$)
{
  my ($wrap_parser, $cpp_type, $flags) = @_;

  if ($flags)
  {
    my $section_manager = $wrap_parser->get_section_manager;
    my $container_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
    my $full_cpp_type = join '::', $container_cpp_type, $cpp_type;
    my $code_string .= nl ('inline ' . $full_cpp_type . ' operator|(' . $full_cpp_type . ' lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('  { return static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs)); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . ' operator&(' . $full_cpp_type . ' lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('  { return static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs)); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . ' operator^(' . $full_cpp_type . ' lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('{ return static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs)); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . ' operator~(' . $full_cpp_type . ' flags)') .
                       nl ('  { return static_cast<' . $full_cpp_type . '>(~static_cast<unsigned>(flags)); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . '& operator|=(' . $full_cpp_type . '& lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('  { return (lhs = static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs))); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . '& operator&=(' . $full_cpp_type . '& lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('  { return (lhs = static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs))); }') .
                       nl () .
                       nl ('inline ' . $full_cpp_type . '& operator^=(' . $full_cpp_type . '& lhs, ' . $full_cpp_type . ' rhs)') .
                       nl ('  { return (lhs = static_cast<' . $full_cpp_type . '>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs))); }') .
                       nl ();

    if ($container_cpp_type)
    {
      my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_AFTER_FIRST_CLASS;

      $section_manager->append_string_to_section ($code_string, $section);
    }
    else
    {
      $section_manager->append_string_to_section ($code_string, $wrap_parser->get_main_section);
    }
  }
}

sub _output_gtype_func_h ($$$$)
{
  my ($wrap_parser, $cpp_type, $flags, $get_type_func) = @_;
  my $type = undef;

  if ($flags)
  {
    $type = Common::Output::Shared::FLAGS_TYPE;
  }
  else
  {
    $type = Common::Output::Shared::ENUM_TYPE;
  }

  Common::Output::Shared::output_enum_gtype_func_h $wrap_parser, $cpp_type, $type, $get_type_func;
}

sub _output_gtype_func_cc ($$$)
{
  my ($wrap_parser, $cpp_type, $get_type_func) = @_;

  Common::Output::Shared::output_enum_gtype_func_cc $wrap_parser, $cpp_type, $get_type_func;
}

sub output ($$$$$)
{
  my ($wrap_parser, $cpp_type, $members, $flags, $get_type_func) = @_;

  _output_enum $wrap_parser, $cpp_type, $members;
  _output_flag_ops $wrap_parser, $cpp_type, $flags;
  _output_gtype_func_h $wrap_parser, $cpp_type, $flags, $get_type_func;
  _output_gtype_func_cc $wrap_parser, $cpp_type, $get_type_func;
}

1; # indicate proper module load.
