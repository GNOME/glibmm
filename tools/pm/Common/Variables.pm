# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Variables module
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

package Common::Variables;

use strict;
use warnings;

use Common::Constants;

use constant
{
  'PROTECTED_GCLASS' => ['PROTECTED_GCLASS_BOOL_VARIABLE', Common::Constants::CLASS],
  'DYNAMIC_GTYPE_REGISTRATION' => ['DYNAMIC_GTYPE_REGISTRATION_BOOL_VARIABLE', Common::Constants::CLASS],
  'STRUCT_NOT_HIDDEN' => ['STRUCT_NOT_HIDDEN_BOOL_VARIABLE', Common::Constants::CLASS],
  'NO_WRAP_FUNCTION' => ['NO_WRAP_FUNCTION_BOOL_VARIABLE', Common::Constants::CLASS],
  'DO_NOT_DERIVE_GTYPE' => ['DO_NOT_DERIVE_GTYPE_BOOL_VARIABLE', Common::Constants::CLASS],
  'CUSTOM_WRAP_NEW' => ['CUSTOM_WRAP_NEW_BOOL_VARIABLE', Common::Constants::CLASS],
  'CUSTOM_CTOR_CAST' => ['CUSTOM_CTOR_CAST_BOOL_VARIABLE', Common::Constants::CLASS],
  'DERIVES_INITIALLY_UNOWNED' => ['DERIVES_INITIALLY_UNOWNED_BOOL_VARIABLE', Common::Constants::CLASS],
  'CUSTOM_DTOR' => ['CUSTOM_DTOR_BOOL_VARIABLE', Common::Constants::CLASS],
  'CUSTOM_DEFAULT_CTOR' => ['CUSTOM_DEFAULT_CTOR_BOOL_VARIABLE', Common::Constants::CLASS],
  'CUSTOM_STRUCT_PROTOTYPE' => ['CUSTOM_STRUCT_PROTOTYPE_BOOL_VARIABLE', Common::Constants::CLASS],
  'IS_INTERFACE' => ['IS_INTERFACE_BOOL_VARIABLE', Common::Constants::CLASS]
};

1; # indicate proper module load.
