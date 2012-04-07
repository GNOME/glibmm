# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Property module
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

package Common::Output::Property;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h ($$$$)
{
  my ($wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $proxy_type = 'Glib::PropertyProxy' . $proxy_suffix . '< ' . $prop_cpp_type . ' >';
  my $method_suffix = ($proxy_suffix eq '_ReadOnly' ? ' const' : '');
  my $code_string = (nl '  /** You rarely need to use properties because there are get_and _set_ methods for almost all of them.') .
                    (nl '   * @return A PropertyProxy that allows you to get or set the property of the value, or receive notification when') .
                    (nl '   * the value of the property changes.') .
                    (nl '   */') .
                    (nl '  ' . $proxy_type . ' property_' . $prop_cpp_name . '()' . $method_suffixP);

  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub _output_cc ($$$$$)
{
  my ($wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name, $prop_c_name) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_PROPERTY_PROXIES;
  my $proxy_type = 'Glib::PropertyProxy' . $proxy_suffix . '< ' . $prop_cpp_type . ' >';
  my $method_suffix = ($proxy_suffix eq '_ReadOnly' ? ' const' : '');
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $code_string = (nl $proxy_type . ' ' . $full_cpp_type . '::property_' . $prop_cpp_name . '()' . $method_suffix) .
                    (nl '{') .
                    (nl '  ' . $proxy_type . '(this, "' . $prop_c_name'");') .
                    (nl '}') .
                    (nl);

  $section_manager->append_string_to_section ($code_string, $section);
}

sub output ($$$$$$$)
{
  my ($wrap_parser, $construct_only, $readable, $writable, $prop_cpp_type, $prop_cpp_name, $prop_c_name) = @_;
  my $read_only = 0;
  my $write_only = 0;

  if ($construct_only)
  {
    $read_only = 1;
  }
  elsif (not $readable)
  {
    $write_only = 1;
  }
  elsif (not $writable)
  {
    $read_only = 1;
  }

  my $proxy_suffix = ($read_only ? '_ReadOnly' : ($write_only ? '_WriteOnly' : ''));

  _output_h $wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name;
  _output_cc $wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name, $prop_c_name;

  if (not $read_only and $readable)
  {
    $proxy_suffix = '_ReadOnly';

    _output_h $wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name;
    _output_cc $wrap_parser, $proxy_suffix, $prop_cpp_type, $prop_cpp_name, $prop_c_name;
  }
}

1; # indicate proper module load.
