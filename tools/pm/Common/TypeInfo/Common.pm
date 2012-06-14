# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Common module
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

package Common::TypeInfo::Common;

use strict;
use warnings;
use feature ':5.10';
use constant
{
  'TRANSFER_INVALID' => -1, # do not use
  'TRANSFER_NONE' => 0,
  'TRANSFER_CONTAINER' => 1,
  'TRANSFER_FULL' => 2,
  'TRANSFER_LAST' => 3 # do not use
};

sub transfer_good_range ()
{
  return (TRANSFER_NONE .. TRANSFER_FULL);
}

sub transfer_from_string ($)
{
  my ($string) = @_;

  given ($string)
  {
    when ('none')
    {
      return TRANSFER_NONE;
    }
    when ('container')
    {
      return TRANSFER_CONTAINER;
    }
    when ('full')
    {
      return TRANSFER_FULL;
    }
    default
    {
      return TRANSFER_INVALID;
    }
  }
}

sub transfer_to_string ($)
{
  my ($transfer) = @_;

  given ($transfer)
  {
    when (TRANSFER_NONE)
    {
      return 'none';
    }
    when (TRANSFER_CONTAINER)
    {
      return 'container';
    }
    when (TRANSFER_FULL)
    {
      return 'full';
    }
    default
    {
      return 'invalid';
    }
  }
}

sub add_specific_conversion ($$$$$$)
{
  my ($conversions, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;
  unless (exists $conversions->{$from})
  {
    $conversions->{$from} = {};
  }

  my $from_conversions = $conversions->{$from};

# TODO: should we warn about overwriting previous conversion if it existed?
  $from_conversions->{$to} = [$transfer_none, $transfer_container, $transfer_full];
}

sub get_specific_conversion ($$$$$)
{
  my ($conversions, $from, $to, $transfer, $name) = @_;
  my $conversion = undef;

  if ($transfer > TRANSFER_INVALID and $transfer < TRANSFER_LAST)
  {
    if (defined $conversions and exists $conversions->{$from})
    {
      my $from_conversions = $conversions->{$from};

      if (exists $from_conversions->{$to})
      {
        my $template = undef;

        do
        {
          $template = $from_conversions->{$to}[$transfer];
          --$transfer;
        }
        while (not defined $template and $transfer != TRANSFER_INVALID);

        if (defined $template)
        {
          $template =~ s/##ARG##/$name/g;

          $conversion = $template;
        }
      }
    }
  }

  return $conversion;
}

1; # indicate proper module load.
