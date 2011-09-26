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

package Gir::Handlers::Function;

use strict;
use warnings;

use parent qw(Gir::Handlers::Generated::Function);

use Gir::Handlers::Ignore;
use Gir::Parser;

##
## private:
##
sub _doc_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _parameters_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _return_value_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _setup_subhandlers ($)
{
  my $self = shift;

  $self->_set_subhandlers
  ({
    '*' => 'Gir::Handlers::Ignore'
  });
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Function');
  my $self = $class->SUPER::new ();

  $self->_set_end_ignores
  ({
    '*' => undef
  });
  return bless ($self, $class);
}

1; # indicate proper module load.
