# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeDetails::Base module
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

package Common::TypeDetails;

use strict;
use warnings;

use Common::TypeDetails::Base;
use Common::TypeDetails::Container;
use Common::TypeDetails::Value;

#
# That does not support function types ('int (*)(int,
# double)').
#
# PTR_TYPE -> [VAL_TYPE, REF_TYPE, PTR_TYPE, FUN_TYPE(x)]
# REF_TYPE -> [VAL_TYPE, REF_TYPE(?), PTR_TYPE(x)]
# VAL_TYPE -> NIL
# FUN_TYPE(x) -> NIL
#
# (x) - NIH
# (?) - incorrect in C++
#
sub disassemble_type ($);

sub disassemble_type ($)
{
  my ($cxx_type_or_array_ref) = @_;
  my $parameter_ref = ref $cxx_type_or_array_ref;
  my $parts = undef;
  unless ($parameter_ref)
  {
    # string was passed
    my @temp_parts = reverse (Common::Shared::cleanup_tokens (split (/(\w+|[()*&<>,`']|::)/, $cxx_type_or_array_ref)));

    $parts = \@temp_parts;
  }
  elsif ($parameter_ref eq 'ARRAY')
  {
    # array ref was passed
    $parts = $cxx_type_or_array_ref;
  }
  die unless defined $parts;

  my $const = 0;
  my $volatile = 0;

  while (@{$parts})
  {
    my $part = shift @{$parts};

    next if (not defined $part or $part eq '');

    if ($part eq 'const')
    {
      die if $const;
      $const = 1;
    }
    elsif ($part eq 'volatile')
    {
      die if $volatile;
      $volatile = 1;
    }
    elsif ($part eq '*' or $part eq '&')
    {
      # this is container type - either pointer or reference.
      my $contained_type = disassemble_type $parts;

      return Common::TypeDetails::Container->new ($const,
                                                  $volatile,
                                                  $contained_type,
                                                  $part);
    }
    elsif ($part !~ /^\s+$/)
    {
      # this is value type, put token back and continue
      # parsing in another loop.
      unshift @{$parts}, $part;
      last;
    }
  }

  my @template_parts = ();
  my $template_level = 0;
  my $template = undef;
  my @type_parts = ();
  my $base_type = '';
  my $imbue_type = undef;
  my $collect_imbue_type = 0;
  my @imbue_parts = ();

  foreach my $part (@{$parts})
  {
    next if $part eq '';

    if ($collect_imbue_type)
    {
      my $gather_parts = 0;

      if ($part eq '`')
      {
        $gather_parts = 1;
        $collect_imbue_type = 0;
      }
      elsif ($part eq ',')
      {
        $gather_parts = 1;
      }

      if ($gather_parts)
      {
        push @{$imbue_type}, join ('', @imbue_parts);
        @imbue_parts = ();
      }
      else
      {
        push @imbue_parts, $part;
      }
    }
    elsif ($template_level)
    {
      ++$template_level if ($part eq '>');
      --$template_level if ($part eq '<');

      if ($template_level == 0 or ($template_level == 1 and $part eq ','))
      {
        my $template_type = disassemble_type \@template_parts;

        push @{$template}, $template_type;
        @template_parts = ();
      }
      else
      {
        push @template_parts, $part;
      }
    }
    elsif ($part eq '>')
    {
      die if defined $template;
      die if defined $imbue_type;
      $template_level = 1;
      $template = [];
    }
    elsif ($part eq 'const')
    {
      # there cannot be any modifiers between template/imbue type and
      # base type.
      die if ((defined ($template) or defined ($imbue_type)) and @type_parts == 0);
      die if $const;
      $const = 1;
    }
    elsif ($part eq 'volatile')
    {
      # there cannot be any modifiers between template/imbue type and
      # base type.
      die if ((defined ($template) or defined ($imbue_type)) and @type_parts == 0);
      die if $volatile;
      $volatile = 1;
    }
    elsif ($part eq '\'')
    {
      die if defined $template;
      die if defined $imbue_type;
      $collect_imbue_type = 1;
      $imbue_type = [];
    }
    elsif ($part =~ /^[,&*]$/)
    {
      die;
    }
    elsif ($part !~ /^\s+$/)
    {
      push @type_parts, $part;
    }
  }

  $base_type = join '', reverse @type_parts;

  unless (defined ($template))
  {
    $template = [];
  }
  unless (defined ($imbue_type))
  {
    $imbue_type = [];
  }

  return Common::TypeDetails::Value->new ($const,
                                          $volatile,
                                          $base_type,
                                          $template,
                                          $imbue_type);
}

1; # indicate proper module load.
