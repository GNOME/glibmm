# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapParser module
#
# Copyright 2011 glibmm development team
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

package Common::Sections::Section;

use strict;
use warnings;

use Common::Sections::Entries;

sub new ($$)
{
  my ($type, $name) = @_;
  my $class = (ref ($type) or $type or 'Common::Sections::Section');
  my $self =
  {
    'name' => $name,
    'entries' => Common::Sections::Entries->new
  };

  return bless $self, $class;
}

sub get_name ($)
{
  my ($self) = @_;

  return $self->{'name'};
}

sub get_entries ($)
{
  my ($self) = @_;

  return $self->{'entries'};
}

sub clear ($)
{
  my ($self) = @_;

  $self->{'entries'} = Common::Sections::Entries->new;
}

1; #indicate proper module load.
