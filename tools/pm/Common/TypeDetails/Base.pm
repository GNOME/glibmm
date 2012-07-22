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

package Common::TypeDetails::Base;

use strict;
use warnings;

use constant
{
  NONE => 0,
  BASE => 1 << 0,
  ACCESS_MODIFIERS => 1 << 1,
  STRUCTURE => 1 << 2,
  RECURSIVE => 1 << 2 | 1 << 3, # recursive check forces structure equality
  COMPLETE => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
};

sub _get_split_values ($)
{
  return '?cv';
}

sub _get_sigil ($)
{
  my ($self) = @_;

  return $self->{'sigil'};
}

sub _tokenize ($$)
{
  my ($self, $match) = @_;
  my $split_values = $self->_get_split_values ();
  my @final_tokens = reverse (Common::Shared::cleanup_tokens (split (/([$split_values])/, $match)));

  return \@final_tokens;
}

sub new ($$$$)
{
  my ($type, $const, $volatile, $sigil) = @_;
  my $class = (ref $type or $type or 'Common::TypeDetails::Base');
  my $self =
  {
    'const' => $const,
    'volatile' => $volatile,
    'sigil' => $sigil
  };

  return bless $self, $class;
}

sub get_value_details ($)
{
# TODO: not implemented error.
  die;
}

sub match_sigil ($$$)
{
# TODO: not implemented error.
  die;
}

sub match_basic_sigil ($$$)
{
  my ($self, $match, $flags) = @_;
  my $const_checked = 0;
  my $volatile_checked = 0;
  my $do_not_care = 0;
  my $drop = 0;

  unless (defined ($flags))
  {
    $flags = NONE;
  }

  my $check = (($flags & ACCESS_MODIFIERS) == ACCESS_MODIFIERS);

  foreach my $index (-1, -2, -3)
  {
    my $char = '';

    if (length ($match) >= -$index)
    {
      $char = substr ($match, $index, 1);
    }

    if ($char eq 'c')
    {
      if ($do_not_care or $const_checked or ($check and not $self->get_const ()))
      {
        return undef;
      }
      $const_checked = 1;
      ++$drop;
    }
    elsif ($char eq 'v')
    {
      if ($do_not_care or $volatile_checked or ($check and not $self->get_volatile ()))
      {
        return undef;
      }
      $volatile_checked = 0;
      ++$drop;
    }
    elsif ($char eq '?')
    {
      if ($const_checked or $volatile_checked or $do_not_care)
      {
        return undef;
      }
      $do_not_care = 1;
      ++$drop;
    }
    else
    {
      last;
    }
  }

  if ($check and ((not $const_checked and $self->get_const ()) or (not $volatile_checked and $self->get_volatile ())))
  {
    return undef;
  }

  if ($drop)
  {
    return substr ($match, 0, -$drop);
  }
  return $match;
}

sub equal ($$$)
{
  my ($self, $other, $flags) = @_;

  if ($flags & ACCESS_MODIFIERS == ACCESS_MODIFIERS)
  {
    if ($self->get_const () != $other->get_const () or
        $self->get_volatile () != $other->get_volatile ())
    {
      return 0;
    }
  }

  if ((($flags & STRUCTURE) == STRUCTURE) and $self->_get_sigil () ne $other->_get_sigil ())
  {
    return 0;
  }

  return 1;
}

sub get_string ($)
{
# TODO: not implemented error
  die;
}

sub get_basic_string ($)
{
  my ($self) = @_;
  my @str = ();

  if ($self->get_const ())
  {
    push (@str, 'const');
  }
  if ($self->get_volatile ())
  {
    push (@str, 'volatile');
  }

  return join (' ', @str);
}

sub get_const ($)
{
  my ($self) = @_;

  return $self->{'const'};
}

sub get_volatile ($)
{
  my ($self) = @_;

  return $self->{'volatile'};
}

1; # indicate proper module load.
