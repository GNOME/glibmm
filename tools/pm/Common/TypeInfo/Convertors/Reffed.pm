# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Convertors::Reffed module
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

package Common::TypeInfo::Convertors::Reffed;

use strict;
use warnings;
use v5.10;

sub convert ($$$$$$)
{
  my ($tiglobal, $from_details, $to_details, $transfer, $subst, $conversion_type) = @_;

  given ($conversion_type)
  {
    when (Common::TypeInfo::Global::C_CXX ())
    {
      my $cxx_value_details = $to_details->get_value_details ();
      my $cxx_base = $cxx_value_details->get_base ();
      my $cxx_templates = $cxx_value_details->get_templates ();

      if (($cxx_base eq 'RefPtr' or $cxx_base eq 'Glib::RefPtr') and @{$cxx_templates} == 1)
      {
        if ($from_details->match_sigil (['*'], Common::TypeDetails::Base::ACCESS_MODIFIERS) and $to_details->match_sigil (['<>&', '<>', '<c>&', '<c>'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
        {
          return join ('', 'Glib::wrap(', $subst, ', ', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? 'false' : 'true'), ')');
        }
      }
    }
    when (Common::TypeInfo::Global::CXX_C ())
    {
      my $cxx_value_details = $from_details->get_value_details ();
      my $cxx_base = $cxx_value_details->get_base ();
      my $cxx_templates = $cxx_value_details->get_templates ();

      if ($cxx_base eq 'RefPtr' or $cxx_base eq 'Glib::RefPtr' and @{$cxx_templates} == 1)
      {
        if ($from_details->match_sigil (['<c>&', '<c>', '<c>c&', '<c>c'], Common::TypeDetails::Base::ACCESS_MODIFIERS) and $to_details->match_sigil (['*c'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
        {
          if ($to_details->match_sigil (['*c']))
          {
            return join ('', 'Glib::unwrap', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? '_copy' : ''), '(', $subst, ')');
          }
          elsif ($to_details->match_sigil (['*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
          {
            my $c_value_details = $to_details->get_value_details ();
            my $c_base = $c_value_details->get_base ();

            return join ('', 'const_cast< ', $c_base, ' >(Glib::unwrap', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? '_copy' : ''), '(', $subst, '))');
          }
        }

        if ($from_details->match_sigil (['<>&', '<>', '<>c&', '<>c'], Common::TypeDetails::Base::ACCESS_MODIFIERS) and $to_details->match_sigil (['*', 'c*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
        {
          return join ('', 'Glib::unwrap', (($transfer > Common::TypeInfo::Common::TRANSFER_NONE) ? '_copy' : ''), '(', $subst, ')');
        }
      }
    }
    when (Common::TypeInfo::Global::C_CXX_CONTAINER ())
    {
      my $c_value_details = $from_details->get_value_details ();
      my $c_base = $c_value_details->get_base ();
      my $cxx_value_details = $to_details->get_value_details ();
      my $cxx_base = $cxx_value_details->get_base ();
      my $ownership = undef;

      given ($transfer)
      {
        when (Common::TypeInfo::Common::TRANSFER_NONE)
        {
          $ownership = 'Glib::OWNERSHIP_NONE';
        }
        when (Common::TypeInfo::Common::TRANSFER_CONTAINER)
        {
          $ownership = 'Glib::OWNERSHIP_SHALLOW';
        }
        when (Common::TypeInfo::Common::TRANSFER_FULL)
        {
          $ownership = 'Glib::OWNERSHIP_DEEP';
        }
        default
        {
          die;
        }
      }

      my $cxx_value_templates = $cxx_value_details->get_templates ();

      break if (@{$cxx_value_templates} != 1);

      my $container_helper_template_details = $cxx_value_templates->[0];
      my $container_helper_template_base = $container_helper_template_details->get_value_details ()->get_base ();

      break if ($container_helper_template_base ne 'RefPtr' and $container_helper_template_base ne 'Glib::RefPtr');

      my $container_helper_templates = $container_helper_template_details->get_string ();

      given ($c_base)
      {
        when ('GList')
        {
          if ($from_details->match_sigil (['*', 'c*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
          {
            given ($cxx_base)
            {
              when ([qw(::std::vector std::vector vector)])
              {
                if ($to_details->match_sigil (['<<>>', '<<>>&']))
                {
                  return join ('', '::Glib::ListHandler< ', $container_helper_templates, ' >::list_to_vector(', $subst, ', ', $ownership, ')');
                }
              }
              when ([qw(::Glib::ListHandle Glib::ListHandle ListHandle)])
              {
                if ($to_details->match_sigil (['<<>>', '<<>>&']))
                {
                  return join ('', '::Glib::ListHandle< ', $container_helper_templates, ' >(', $subst, ', ', $ownership, ')');
                }
              }
            }
          }
        }
        when ('GSList')
        {
          if ($from_details->match_sigil (['*', 'c*'], Common::TypeDetails::Base::ACCESS_MODIFIERS))
          {
            given ($cxx_base)
            {
              when ([qw(::std::vector std::vector vector)])
              {
                if ($to_details->match_sigil (['<<>>', '<<>>&']))
                {
                  return join ('', '::Glib::SListHandler< ', $container_helper_templates, ' >::slist_to_vector(', $subst, ', ', $ownership, ')');
                }
              }
              when ([qw(::Glib::SListHandle Glib::SListHandle SListHandle)])
              {
                if ($to_details->match_sigil (['<<>>', '<<>>&']))
                {
                  return join ('', '::Glib::SListHandle< ', $container_helper_templates, ' >(', $subst, ', ', $ownership, ')');
                }
              }
            }
          }
        }
      }
    }
    when (Common::TypeInfo::Global::CXX_C_CONTAINER ())
    {
      my $cxx_value_details = $from_details->get_value_details ();
      my $cxx_base = $cxx_value_details->get_base ();
      my $c_value_details = $to_details->get_value_details ();
      my $c_base = $c_value_details->get_base ();

      break if ($transfer != Common::TypeInfo::Common::TRANSFER_NONE);

      my $cxx_value_templates = $cxx_value_details->get_templates ();

      break if (@{$cxx_value_templates} != 1);

      my $container_helper_template_details = $cxx_value_templates->[0];
      my $container_helper_template_base = $container_helper_template_details->get_value_details ()->get_base ();

      break if ($container_helper_template_base ne 'RefPtr' and $container_helper_template_base ne 'Glib::RefPtr');

      my $container_helper_templates = $container_helper_template_details->get_string ();

      given ($cxx_base)
      {
        when ([qw(::std::vector std::vector vector)])
        {
          if ($from_details->match_sigil (['<<>>', '<<>>&']))
          {
            given ($c_base)
            {
              when ('GList')
              {
                if ($to_details->match_sigil ('*'))
                {
                  return join ('', '::Glib::ListHandler< ', $container_helper_templates, ' >::vector_to_list(', $subst, ').data()');
                }
              }
              when ('GSList')
              {
                if ($to_details->match_sigil ('*'))
                {
                  return join ('', '::Glib::SListHandler< ', $container_helper_templates, ' >::vector_to_slist(', $subst, ').data()');
                }
              }
              default
              {
# TODO: check for c_type**
              }
            }
          }
        }
        when ([qw(::Glib::ListHandle Glib::ListHandle ListHandle)])
        {
          if ($from_details->match_sigil (['<<>>', '<<>>&']))
          {
            if ($c_base eq 'GList')
            {
              if ($to_details->match_sigil ('*'))
              {
                return join ('', $subst, '.data()');
              }
            }
          }
        }
        when ([qw(::Glib::SListHandle Glib::SListHandle SListHandle)])
        {
          if ($from_details->match_sigil (['<<>>', '<<>>&']))
          {
            if ($c_base eq 'GSList')
            {
              if ($to_details->match_sigil ('*'))
              {
                return join ('', $subst, '.data()');
              }
            }
          }
        }
        when ([qw(::Glib::ArrayHandle Glib::ArrayHandle ArrayHandle)])
        {
          if ($from_details->match_sigil (['<<>>', '<<>>&']))
          {
# TODO: check for c_type**.
          }
        }
      }
    }
  }

  return undef;
}

1; # indicate proper module load.
