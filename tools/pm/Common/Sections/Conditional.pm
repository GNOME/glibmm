# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Sections::Conditional module
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

package Common::Sections::Conditional;

use strict;
use warnings;
use feature ':5.10';

use constant
{
  'FALSE' => 0,
  'TRUE' => 1
};

sub new ($$$)
{
  my ($type, $name, $bool_variable_name) = @_;
  my $class = (ref ($type) or $type or 'Common::Sections::Conditional');
  my $self =
  {
    'name' => $name,
    'false_entries' => Common::Sections::Entries->new,
    'true_entries' => Common::Sections::Entries->new,
    'bool_variable_name' => $bool_variable_name
  };

  return bless $self, $class;
}

sub get_name ($)
{
  my ($self) = @_;

  return $self->{'name'};
}

sub set_variable_name ($$)
{
  my ($self, $bool_variable_name) = @_;

  $self->{'bool_variable_name'} = $bool_variable_name;
}

sub get_variable_name ($)
{
  my ($self) = @_;

  return $self->{'bool_variable_name'};
}

sub get_entries ($$)
{
  my ($self, $which) = @_;

  given ($which)
  {
    when (FALSE)
    {
      return $self->{'false_entries'};
    }
    when (TRUE)
    {
      return $self->{'true_entries'};
    }
    default
    {
      # TODO: throw an error.
      print STDERR 'Unknown value for conditional, use Common::Sections::Conditional::{TRUE,FALSE}' . "\n";
      exit 1;
    }
  }
}

sub clear ($)
{
  my ($self) = @_;

  $self->{'false_entries'} = Common::Sections::Entries->new;
  $self->{'true_entries'} = Common::Sections::Entries->new;
}

1; #indicate proper module load.
