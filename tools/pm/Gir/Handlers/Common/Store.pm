# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
## Copyright 2011 Krzesimir Nowak
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
##

package Gir::Handlers::Common::Store;

use strict;
use warnings;

##
## public:
##
sub new ($$)
{
  my ($type, $methods) = @_;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Common::Store');
  my $self =
  {
    'methods' => $methods
  };

  return bless ($self, $class);
}

sub has_method_for ($$)
{
  my ($self, $elem) = @_;
  my $methods = $self->{'methods'};

  return exists ($methods->{$elem});
}

sub get_method_for ($$)
{
  my ($self, $elem) = @_;

  if ($self->has_method_for ($elem))
  {
    my $methods = $self->{'methods'};

    return $methods->{$elem};
  }
  # TODO: error.
}

1;
