# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Convertors::Ustring module
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

package Common::TypeInfo::Convertors::Ustring;

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
      my $cxx_base = $to_details->get_value_details ()->get_base ();
      my $c_base = $from_details->get_value_details ()->get_base ();

      if (($cxx_base eq 'ustring' or $cxx_base eq 'Glib::ustring' or $cxx_base eq '::Glib::ustring') and ($c_base eq 'gchar' or $c_base eq 'char'))
      {
        if ($from_details->match_sigil (['*']) and $to_details->match_sigil (['', '&']))
        {
          if ($transfer == Common::TypeInfo::Common::TRANSFER_NONE)
          {
            return join ('', '::Glib::convert_const_gchar_ptr_to_ustring(', $subst, ')');
          }
          else
          {
            return join ('', '::Glib::convert_return_gchar_ptr_to_ustring(', $subst, ')');
          }
        }
      }
    }
    when (Common::TypeInfo::Global::CXX_C ())
    {
      my $c_base = $to_details->get_value_details ()->get_base ();
      my $cxx_base = $from_details->get_value_details ()->get_base ();

      if (($cxx_base eq 'ustring' or $cxx_base eq 'Glib::ustring' or $cxx_base eq '::Glib::ustring') and ($c_base eq 'gchar' or $c_base eq 'char'))
      {
        if ($to_details->match_sigil (['*']) and $from_details->match_sigil (['', '&']))
        {
          if ($transfer == Common::TypeInfo::Common::TRANSFER_NONE)
          {
            return join ('', '((', $subst, ').c_str())');
          }
          else
          {
            return join ('', 'g_strdup((', $subst, ').c_str())');
          }
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

      break unless ($container_helper_template_base eq 'ustring' or
                    $container_helper_template_base eq 'Glib::ustring' or
                    $container_helper_template_base eq '::Glib::ustring');

      my $container_helper_templates = $container_helper_template_details->get_string ();
      my $wanted_cxx_sigils = [qw(<> <>&)];

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
                if ($to_details->match_sigil ($wanted_cxx_sigils))
                {
                  return join ('', '::Glib::ListHandler< ', $container_helper_templates, ' >::list_to_vector(', $subst, ', ', $ownership, ')');
                }
              }
              when ([qw(::Glib::ListHandle Glib::ListHandle ListHandle)])
              {
                if ($to_details->match_sigil ($wanted_cxx_sigils))
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
                if ($to_details->match_sigil ($wanted_cxx_sigils))
                {
                  return join ('', '::Glib::SListHandler< ', $container_helper_templates, ' >::slist_to_vector(', $subst, ', ', $ownership, ')');
                }
              }
              when ([qw(::Glib::SListHandle Glib::SListHandle SListHandle)])
              {
                if ($to_details->match_sigil ($wanted_cxx_sigils))
                {
                  return join ('', '::Glib::SListHandle< ', $container_helper_templates, ' >(', $subst, ', ', $ownership, ')');
                }
              }
            }
          }
        }
        when ([qw(gchar char)])
        {
          if ($from_details->match_sigil (['**']))
          {
            given ($cxx_base)
            {
              when ([qw(::std::vector std::vector vector)])
              {
                if ($to_details->match_sigil ($wanted_cxx_sigils))
                {
                  return join ('', '::Glib::ArrayHandler< ', $container_helper_templates, ' >::array_to_vector(', $subst, ', ', $ownership, ')');
                }
              }
              when ([qw(::Glib::ArrayHandle Glib::ArrayHandle ArrayHandle)])
              {
                if ($to_details->match_sigil ($wanted_cxx_sigils))
                {
                  return join ('', '::Glib::ArrayHandle< ', $container_helper_templates, ' >(', $subst, ', ', $ownership, ')');
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

      break unless ($container_helper_template_base eq 'ustring' or
                    $container_helper_template_base eq 'Glib::ustring' or
                    $container_helper_template_base eq '::Glib::ustring');

      my $container_helper_templates = $container_helper_template_details->get_string ();
      my $wanted_cxx_sigils = [qw(<> <>&)];

      given ($cxx_base)
      {
        when ([qw(::std::vector std::vector vector)])
        {
          if ($from_details->match_sigil ($wanted_cxx_sigils))
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
              when (['gchar', 'char'])
              {
                if ($to_details->match_sigil ('**'))
                {
                  return join ('', '::Glib::ArrayHandler< ', $container_helper_templates, ' >::vector_to_array(', $subst, ').data()');
                }
              }
            }
          }
        }
        when ([qw(::Glib::ListHandle Glib::ListHandle ListHandle)])
        {
          if ($from_details->match_sigil ($wanted_cxx_sigils))
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
          if ($from_details->match_sigil ($wanted_cxx_sigils))
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
          if ($from_details->match_sigil ($wanted_cxx_sigils))
          {
            if ($c_base eq 'gchar' or $c_base eq 'char')
            {
              if ($to_details->match_sigil ('**'))
              {
                return join ('', $subst, '.data()');
              }
            }
          }
        }
      }
    }
  }

  return undef;
}

1; # indicate proper module load.
