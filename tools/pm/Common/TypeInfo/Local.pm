# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Local module
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

package Common::TypeInfo::Local;

use strict;
use warnings;

sub _get_conversions ($)
{
  my ($self) = @_;

  return $self->{'conversions'};
}

sub _get_global ($)
{
  my ($self) = @_;

  return $self->{'global'};
}

sub new ($$)
{
  my ($type, $global) = @_;
  my $class = (ref $type or $type or 'Common::TypeInfo::Local');
  my $self =
  {
    'conversions' => {},
    'global' => $global
  };

  return bless $self, $class;
}

sub add_conversion ($$$$$$)
{
  my ($self, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;
  my $conversions = $self->_get_conversions;

  Common::TypeInfo::Common::add_specific_conversion $conversions, $from, $to, $transfer_none, $transfer_container, $transfer_full;
}

sub get_conversion ($$$$$)
{
  my ($self, $from, $to, $transfer, $subst) = @_;
  my $conversions = $self->_get_conversions;
  my $conversion = Common::TypeInfo::Common::get_specific_conversion $conversions, $from, $to, $transfer, $subst;

  unless (defined $conversion)
  {
    my $global = $self->_get_global;

    # this will throw an exception when nothing is found.
    $conversion = $global->get_conversion ($from, $to, $transfer, $subst);
  }

  return $conversion;
}

sub c_to_cxx ($$)
{
  my ($self, $c_stuff) = @_;
  my $global = $self->_get_global;

  $global->c_to_cxx ($c_stuff);
}

sub cxx_to_c ($$)
{
  my ($self, $cxx_stuff) = @_;
  my $global = $self->_get_global;

  $global->cxx_to_c ($cxx_stuff);
}

1; # indicate proper module load.
