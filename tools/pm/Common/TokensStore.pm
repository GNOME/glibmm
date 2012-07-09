# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TokensStore module
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

package Common::TokensStore;

use strict;
use warnings;

sub new ($)
{
  my ($type) = @_;
  my $class = (ref $type or $type or 'Common::TokensStore');
  my $self =
  {
    'tuples' => [],
    'section_manager' => undef,
    'tokens_hg' => undef,
    'tokens_ccg' => undef,
    'wrap_init_entries' => undef,
    'modules' => undef
  };

  return bless $self, $class;
}

sub set_tuples ($$)
{
  my ($self, $tuples) = @_;

  $self->{'tuples'} = $tuples;
}

sub get_tuples ($)
{
  my ($self) = @_;

  return $self->{'tuples'};
}

sub set_section_manager ($$)
{
  my ($self, $section_manager) = @_;

  $self->{'section_manager'} = $section_manager;
}

sub get_section_manager ($)
{
  my ($self) = @_;

  return $self->{'section_manager'};
}

sub set_hg_tokens ($$)
{
  my ($self, $tokens_hg) = @_;

  $self->{'tokens_hg'} = $tokens_hg;
}

sub get_hg_tokens ($)
{
  my ($self) = @_;

  return $self->{'tokens_hg'};
}

sub set_ccg_tokens ($$)
{
  my ($self, $tokens_ccg) = @_;

  $self->{'tokens_ccg'} = $tokens_ccg;
}

sub get_ccg_tokens ($)
{
  my ($self) = @_;

  return $self->{'tokens_ccg'};
}

sub set_wrap_init_entries
{
  my ($self, $wrap_init_entries) = @_;

  $self->{'wrap_init_entries'} = $wrap_init_entries;
}

sub get_wrap_init_entries
{
  my ($self) = @_;

  return $self->{'wrap_init_entries'};
}

sub set_modules
{
  my ($self, $modules) = @_;

  $self->{'modules'} = $modules;
}

sub get_modules
{
  my ($self) = @_;

  return $self->{'modules'};
}

1; # indicate proper module load.
