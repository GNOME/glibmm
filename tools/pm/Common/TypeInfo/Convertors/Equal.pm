# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Convertors::Equal module
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

package Common::TypeInfo::Convertors::Equal;

use strict;
use warnings;
use v5.10;

sub convert ($$$$$$)
{
  my ($tiglobal, $from_details, $to_details, $transfer, $subst, $conversion_type) = @_;

  given ($conversion_type)
  {
    when (Common::TypeInfo::Global::CXX_C)
    {
      if ($from_details->equal ($to_details, Common::TypeDetails::Base::RECURSIVE | Common::TypeDetails::Base::ACCESS_MODIFIERS))
      {
        return $subst;
      }
      if ($from_details->equal ($to_details, Common::TypeDetails::Base::ACCESS_MODIFIERS))
      {
        foreach my $sigil_pair ([['&'], ['*']], [['*&'], ['**']], [['**&'], ['***']])
        {
          my $from_sigil = $sigil_pair->[0];
          my $to_sigil = $sigil_pair->[1];

          if ($from_details->match_sigil ($from_sigil) and $to_details->match_sigil ($to_sigil))
          {
            return '&' . $subst;
          }
        }
      }
    }
    when (Common::TypeInfo::Global::C_CXX)
    {
      if ($from_details->equal ($to_details, Common::TypeDetails::Base::RECURSIVE | Common::TypeDetails::Base::ACCESS_MODIFIERS))
      {
        return $subst;
      }
# TODO: Correspondence C_CXX and from 'ptr' and to 'ref'
# TODO continued: has no sense - pointer can be NULL and
# TODO continued: reference cannot. But maybe add it if there
# TODO continued: are some cases when we are sure that pointer
# TODO continued: will never be NULL.
#      if ($from_details->equal ($to_details, Common::TypeDetails::Base::ACCESS_MODIFIERS) and $from_details->isa (Common::TypeDetails::Ptr) and $to_details->isa (Common::TypeDetails::Ref))
#      {
#        return join '', '*(', $subst, ')';
#      }
    }
# TODO: Container conversions?
  }

  return undef;
}

1; # indicate proper module load.
