# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::CFunctionInfo module
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

package Common::CFunctionInfo;

use strict;
use warnings;

use parent qw (Common::CallableInfo);

sub _get_name_from_gir ($$)
{
  my (undef, $gir_function) = @_;

  return $gir_function->get_a_c_identifier;
}

sub new_from_gir ($$)
{
  my ($type, $gir_function) = @_;
  my $class = (ref $type or $type or 'Common::CFunctionInfo');
  my $self = $class->SUPER::new ($gir_function);
  my $throws = $gir_function->get_a_throws;

  $self->{'throws'} = $throws;

  return bless $self, $class;
}

sub get_throws ($)
{
  my ($self) = @_;

  return $self->{'throws'};
}

1; # indicate proper module load.
