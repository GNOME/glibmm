# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapInit::GError module
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

package Common::WrapInit::GError;

use strict;
use warnings;

use parent qw(Common::WrapInit::Base);

sub _get_line
{
  my ($self) = @_;
  my $cxx_type = $self->{'cxx_type'};
  my $error_domain = $self->{'error_domain'};

  return join ('', '  Glib::Error::register_domain(g_quark_from_static_string("', $error_domain, '"), &::', $cxx_type, '::throw_func);');
}

sub new
{
  my ($type, $extra_includes, $c_includes, $cxx_includes, $deprecated, $cpp_condition, $mm_module, $cxx_type, $error_domain) = @_;
  my $class = (ref $type or $type or 'Common::WrapInit::GError');
  my $self = $class->SUPER::new ($extra_includes, $c_includes, $cxx_includes, $deprecated, $cpp_condition, $mm_module);

  $self->{'cxx_type'} = $cxx_type;
  $self->{'error_domain'} = $error_domain;
  return bless ($self, $class);
}

1; # indicate proper module load.
