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

package Gir::Handlers::TopLevel;

use strict;
use warnings;

use parent qw(Gir::Handlers::Generated::TopLevel);

use Gir::Handlers::Repository;

##
## private:
##
sub _gen_subhandlers ($$)
{
  my (undef, $tags) = @_;
  my %subhandlers = map { $_ => 'Gir::Handlers::' . Gir::Handlers::Generated::Common::Misc::module_from_tag ($_) } @{$tags};

  return \%subhandlers;
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::TopLevel');
  my $self = $class->SUPER::new ();

  $self = bless ($self, $class);
  $self->_set_generator (\&_gen_subhandlers);
  $self->_setup_handlers ();
  $self->_setup_subhandlers ();
  $self->_set_start_ignores
  ({
    'repository' => undef
  });
  $self->_set_end_ignores
  ({
    'repository' => undef
  });
  return $self;
}

1; # indicate proper module load.
