# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Generic module
#
# Copyright 2011 glibmm development team
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

package Common::Output::Generic;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub output ($$$)
{
  my ($wrap_parser, $c_type, $cpp_type) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cc_end_section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_END;
  my $cc_namespace_section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;
  my $code_string = nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl () .
                    nl ('private:') .
                    nl ();

  $section_manager->append_string_to_section ($code_string, $main_section);
  $section_manager->push_section ($cc_end_section);
  $section_manager->append_string (Common::Output::Shared::open_namespaces $wrap_parser);
  $section_manager->append_section ($cc_namespace_section);
  $section_manager->append_string (Common::Output::Shared::close_namespaces $wrap_parser);
  $section_manager->pop_entry;
}

1; # indicate proper module load.
