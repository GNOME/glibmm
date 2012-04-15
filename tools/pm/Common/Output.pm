# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output module
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

package Common::Output;

use strict;
use warnings;

use Common::Output::BoxedTypeStatic;
use Common::Output::BoxedType;
use Common::Output::Ctor;
use Common::Output::Enum;
use Common::Output::Generic;
use Common::Output::GError;
use Common::Output::GObject;
use Common::Output::GtkObject;
use Common::Output::Interface;
use Common::Output::Method;
use Common::Output::OpaqueCopyable;
use Common::Output::OpaqueRefcounted;
use Common::Output::Property;
use Common::Output::VFunc;

1; # indicate proper module load.
