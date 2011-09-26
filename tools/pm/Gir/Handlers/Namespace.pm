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

package Gir::Handlers::Namespace;

use strict;
use warnings;

use parent qw(Gir::Handlers::Generated::Namespace);

use Gir::Handlers::Alias;
use Gir::Handlers::Bitfield;
use Gir::Handlers::Callback;
use Gir::Handlers::Class;
use Gir::Handlers::Constant;
use Gir::Handlers::Enumeration;
use Gir::Handlers::Function;
use Gir::Handlers::Interface;
use Gir::Handlers::Record;
use Gir::Handlers::Union;
use Gir::Parser;

##
## private:
##
sub _alias_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _bitfield_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _callback_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _class_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _constant_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _enumeration_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _function_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _interface_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _record_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

sub _union_start_impl ($$$)
{
  my ($self, $parser, $params) = @_;
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Namespace');
  my $self = $class->SUPER::new ();

  $self->_set_end_ignores
  ({
    '*' => undef
  });
  return bless ($self, $class);
}

1; # indicate proper module load.
