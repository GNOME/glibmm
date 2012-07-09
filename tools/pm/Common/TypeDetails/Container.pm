# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeDetails::Container module
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

package Common::TypeDetails::Container;

use strict;
use warnings;

use parent qw(Common::TypeDetails::Base);

sub _get_contained_type ($)
{
  my ($self) = @_;

  return $self->{'contained_type'};
}

sub _get_sigil ($)
{
  my ($self) = @_;

  return $self->{'sigil'};
}

sub _get_split_values ($)
{
  my ($self) = @_;
  my $sigil = $self->_get_sigil ();

  return join ('', $self->SUPER::_get_split_values (), $sigil);
}

sub new ($$$)
{
  my ($type, $const, $volatile, $contained_type, $sigil) = @_;
  my $class = (ref $type or $type or 'Common::TypeDetails::Container');
  my $self = $class->SUPER::new ($const, $volatile, $sigil);

  $self->{'contained_type'} = $contained_type;

  return bless $self, $class;
}

sub get_value_details ($)
{
  my ($self) = @_;
  my $contained_type = $self->_get_contained_type;

  return $contained_type->get_value_details;
}

sub match_sigil ($$$)
{
  my ($self, $matches, $flags) = @_;
  my $sigil = $self->_get_sigil ();

  unless (ref ($matches))
  {
    $matches = [$matches];
  }
  unless (defined ($flags))
  {
    $flags = Common::TypeDetails::Base::NONE;
  }

  foreach my $match (@{$matches})
  {
    $match = $self->match_basic_sigil ($match, $flags);

    next unless (defined $match);

    my $tokens = $self->_tokenize ($match);

    if (@{$tokens} and $tokens->[0] eq $sigil)
    {
      my $contained_type = $self->_get_contained_type ();
      my $sub_match = substr ($match, 0, -1);
      my $matched = $contained_type->match_sigil ($sub_match, $flags);

      if ($matched)
      {
        return $matched;
      }
    }
  }
  return 0;
}

sub get_string ($)
{
  my ($self) = @_;
  my $contained_type = $self->_get_contained_type ();
  my $sigil = self->_get_sigil ();
  my $basic_string = $self->get_basic_string ();

  return ($contained_type->get_string () . $sigil . ($basic_string ? ' ' . $basic_string : ''));
}

sub equal ($$$)
{
  my ($self, $other, $flags) = @_;

  unless ($self->SUPER::equal ($other, $flags))
  {
    return 0;
  }

  if (($flags & Common::TypeDetails::Base::RECURSIVE) == Common::TypeDetails::Base::RECURSIVE)
  {
    my $self_contained_type = $self->_get_contained_type;
    my $other_contained_type = $self->_get_contained_type;

    return $self_contained_type->equal ($other_contained_type, $flags);
  }

  return 1;
}

1; # indicate proper module load.
