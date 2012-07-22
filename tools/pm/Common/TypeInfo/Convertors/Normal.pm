# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Convertors::Normal module
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

package Common::TypeInfo::Convertors::Normal;

use strict;
use warnings;
use v5.12;

sub convert
{
  my ($tiglobal, $from_details, $to_details, $transfer, $subst, $conversion_type) = @_;

  given ($conversion_type)
  {
    when (Common::TypeInfo::Global::C_CXX ())
    {
      if ($from_details->match_sigil (['c*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
      {
        if ($to_details->match_sigil ([''], Common::TypeDetails::Base::ACCESS_MODIFIERS))
        {
          my $base = $from_details->get_value_details ()->get_base ();

          return 'Glib::wrap(const_cast< ' . $base . '* >(' . $subst . '), ' . (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? 'false' : 'true') . ')';
        }
      }

      if ($from_details->match_sigil (['*']) and $to_details->match_sigil (['']))
      {
          return join ('', 'Glib::wrap(', $subst, ', ', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? 'false' : 'true'), ')');
      }
    }
    when (Common::TypeInfo::Global::CXX_C ())
    {
      if ($from_details->match_sigil (['c&'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
      {
        if ($to_details->match_sigil (['*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
        {
          return 'const_cast< ' . $to_details->get_string () . ' >(Glib::unwrap' . (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? '_copy' : '') . '(' . $subst . '))';
        }
      }

      if ($from_details->match_sigil (['&']) and $to_details->match_sigil (['*']))
      {
        return join ('', 'Glib::unwrap', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? '_copy' : ''), '(', $subst, ')');
      }
    }
    when (Common::TypeInfo::Global::C_CXX_CONTAINER ())
    {

    }
    when (Common::TypeInfo::Global::CXX_C_CONTAINER ())
    {

    }
  }

  return undef;
}

1; # indicate proper module load.
