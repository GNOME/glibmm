# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Convertors::Enum module
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

package Common::TypeInfo::Convertors::Enum;

use strict;
use warnings;
use v5.10;

sub convert ($$$$$$)
{
  my ($tiglobal, $from_details, $to_details, $transfer, $subst, $conversion_type) = @_;

  given ($conversion_type)
  {
    when (Common::TypeInfo::Global::C_CXX)
    {
      continue;
    }
    when (Common::TypeInfo::Global::CXX_C)
    {
      if ($from_details->match_sigil (['']) and $to_details->match_sigil (['']))
      {
        my $to_value_details = $to_details->get_value_details ();

        return join '', 'static_cast< ', $to_value_details->get_base (), ' >(', $subst, ')';
      }
# TODO: C pointer from/to C++ ref?
    }
# TODO: Container conversions?
  }

  return undef;
}

1; # indicate proper module load.
