# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapInit::GObject module
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

package Common::WrapInit::GObject;

use strict;
use warnings;

use parent qw(Common::WrapInit::Base);

sub _get_line
{
  my ($self) = @_;
  my $get_type_func = $self->{'get_type_func'};
  my $cxx_class_type = $self->{'cxx_class_type'};
  my $cxx_type = $self->{'cxx_type'};
  my @lines =
  (
    join ('', '  Glib::wrap_register(', $get_type_func, '(), &::', $cxx_class_type, '::wrap_new);'),
    join ('', '  g_type_ensure(', $cxx_type, '::get_type());')
  );

  return join ("\n", @lines);
}

sub new
{
  my ($type, $extra_includes, $c_includes, $cxx_includes, $deprecated, $cpp_condition, $mm_module, $get_type_func, $cxx_class_type, $cxx_type) = @_;
  my $class = (ref $type or $type or 'Common::WrapInit::GObject');
  my $self = $class->SUPER::new ($extra_includes, $c_includes, $cxx_includes, $deprecated, $cpp_condition, $mm_module);

  $self->{'get_type_func'} = $get_type_func;
  $self->{'cxx_class_type'} = $cxx_class_type;
  $self->{'cxx_type'} = $cxx_type;

  return bless $self, $class;
}

1; # indicate proper module load.
