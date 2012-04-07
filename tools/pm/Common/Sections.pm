# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Sections module
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

package Common::Sections;

use strict;
use warnings;

use Common::Constants;

use Common::Sections::Section;
use Common::Sections::Conditional;
use Common::Sections::Entries;

use constant
{
  'H' => ['SECTION_H', Common::Constants::FILE ()], # main header section
  'CC' => ['SECTION_CC', Common::Constants::FILE ()], # main implementation section
  'P_H' => ['SECTION_P_H', Common::Constants::FILE ()], # main private header section
  'DEV_NULL' => ['SECTION_DEV_NULL', Common::Constants::FILE ()], # everything put into this section goes to /dev/null
  'H_CONTENTS' => ['SECTION_H_CONTENTS', Common::Constants::FILE ()],
  'CC_CONTENTS' => ['SECTION_CC_CONTENTS', Common::Constants::FILE ()],
  'P_H_CONTENTS' => ['SECTION_P_H_CONTENTS', Common::Constants::FILE ()],
  'CC_UNNAMED_NAMESPACE' => ['SECTION_UNNAMED_NAMESPACE', Common::Constants::FILE ()], # blablabla
  'H_BEGIN' => ['SECTION_HEADER_BEGIN', Common::Constants::FILE ()], # SECTION_HEADER_FIRST
  'HEADER1' => ['SECTION_HEADER1', Common::Constants::FILE ()], # TODO: check if needed, use better name, H_FOO
  'HEADER2' => ['SECTION_HEADER2', Common::Constants::FILE ()], # TODO: check if needed, use better name, H_FOO
  'HEADER3' => ['SECTION_HEADER3', Common::Constants::FILE ()], # TODO: check if needed, use better name, H_FOO
  'CC_PRE_INCLUDES' => ['SECTION_CC_PRE_INCLUDES', Common::Constants::FILE ()],
  'CC_INCLUDES' => ['SECTION_CC_INCLUDES', Common::Constants::FILE ()],
  'CC_CUSTOM' => ['SECTION_CC_CUSTOM', Common::Constants::FILE ()], # TODO: check if needed, SECTION_SRC_CUSTOM
  'CC_GENERATED' => ['SECTION_CC_GENERATED', Common::Constants::FILE ()], # TODO: check if needed, SECTION_CC_GENERATED
  'CC_END' => ['SECTION_CC_END', Common::Constants::FILE ()],
  'CC_NAMESPACE' => ['SECTION_CC_NAMESPACE', Common::Constants::NAMESPACE ()],
  'CLASS1' => ['SECTION_CLASS1', Common::Constants::CLASS ()], # TODO: check if needed, use better name, CC_FOO
  'CLASS2' => ['SECTION_CLASS2', Common::Constants::CLASS ()], # TODO: check if needed, use better name, CC_FOO
  'P_CC_IMPLEMENTS_INTERFACES' => ['SECTION_P_CC_IMPLEMENTS_INTERFACES', Common::Constants::CLASS ()],
  'H_VFUNCS' => ['SECTION_H_VFUNCS', Common::Constants::CLASS ()],
  'H_VFUNCS_CPP_WRAPPER' => ['SECTION_H_VFUNCS_CPP_WRAPPER', Common::Constants::CLASS ()], # TODO: probably not needed.
  'H_DEFAULT_SIGNAL_HANDLERS' => ['SECTION_H_DEFAULT_SIGNAL_HANDLERS', Common::Constants::CLASS ()],
  'CC_DEFAULT_SIGNAL_HANDLERS' => ['SECTION_CC_DEFAULT_SIGNAL_HANDLERS', Common::Constants::CLASS ()],
  'CC_VFUNCS' => ['SECTION_CC_VFUNCS', Common::Constants::CLASS ()],
  'CC_VFUNCS_CPP_WRAPPER' => ['SECTION_CC_VFUNCS_CPP_WRAPPER', Common::Constants::CLASS ()], # TODO: probably not needed
  'P_H_DEFAULT_SIGNAL_HANDLERS' => ['SECTION_P_H_DEFAULT_SIGNAL_HANDLERS', Common::Constants::CLASS ()],
  'P_H_VFUNCS' => ['SECTION_P_H_VFUNCS', Common::Constants::CLASS ()],
  'P_CC_DEFAULT_SIGNAL_HANDLERS' => ['SECTION_P_CC_DEFAULT_SIGNAL_HANDLERS', Common::Constants::CLASS ()],
  'P_CC_VFUNCS' => ['SECTION_P_CC_VFUNCS', Common::Constants::CLASS ()],
  'P_CC_INIT_DEFAULT_SIGNAL_HANDLERS' => ['SECTION_P_CC_INIT_DEFAULT_SIGNAL_HANDLERS', Common::Constants::CLASS ()],
  'P_CC_INIT_VFUNCS' => ['SECTION_P_CC_INIT_VFUNCS', Common::Constants::CLASS ()],
  'P_CC_NAMESPACE' => ['SECTION_P_CC_NAMESPACE', Common::Constants::CLASS ()],
  'H_BEFORE_FIRST_NAMESPACE' => ['SECTION_BEFORE_FIRST_NAMESPACE', Common::Constants::FIRST_NAMESPACE ()],
  'H_BEFORE_FIRST_CLASS' => ['SECTION_BEFORE_FIRST_CLASS', Common::Constants::FIRST_CLASS ()],
  'H_AFTER_FIRST_CLASS' => ['SECTION_AFTER_FIRST_CLASS', Common::Constants::FIRST_CLASS ()],
  'H_AFTER_FIRST_NAMESPACE' => ['SECTION_AFTER_FIRST_NAMESPACE', Common::Constants::FIRST_NAMESPACE ()],
  'H_SIGNAL_PROXIES' => ['SECTION_H_SIGNAL_PROXIES', Common::Constants::CLASS ()],
  'CC_SIGNAL_PROXIES' => ['SECTION_CC_SIGNAL_PROXIES', Common::Constants::CLASS ()],
  'H_PROPERTY_PROXIES' => ['SECTION_H_PROPERTY_PROXIES', Common::Constants::CLASS ()],
  'CC_PROPERTY_PROXIES' => ['SECTION_CC_PROPERTY_PROXIES', Common::Constants::CLASS ()],
  'CC_INITIALIZE_EXTRA' => ['SECTION_CC_INITIALIZE_EXTRA', Common::Constants::CLASS ()] # TODO: check if needed.
};

1; # indicate proper module load.
