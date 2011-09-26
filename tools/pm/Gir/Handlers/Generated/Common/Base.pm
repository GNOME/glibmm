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

package Gir::Handlers::Generated::Common::Base;

use strict;
use warnings;

use Gir::Handlers::Generated::Common::Misc;
use Gir::Handlers::Generated::Common::Store;

##
## private
##
sub _base_gen_subhandlers_impl ($$)
{
  my (undef, $tags) = @_;
  my %subhandlers = map { $_ => 'Gir::Handlers::Generated::' . Gir::Handlers::Generated::Common::Misc::module_from_tag ($_) } @{$tags};

  return \%subhandlers;
}

##
## private virtuals:
##
sub _setup_handlers ($)
{
  #TODO: throw an error;
  print STDERR 'Gir::Handlers::Generated::Common::Base::_setup_handlers ($) is not implemented.' . "\n";
  exit 1;
}

sub _setup_subhandlers ($)
{
  #TODO: throw an error;
  print STDERR 'Gir::Handlers::Generated::Common::Base::_setup_subhandlers ($) is not implemented.' . "\n";
  exit 1;
}

sub _generate_subhandlers ($$)
{
  my ($self, $tags) = @_;
  my $generator = $self->{'generator'};

  return $self->$generator ($tags);
}

##
## protected:
##
sub _set_handlers ($$$)
{
  my ($self, $start_handlers, $end_handlers) = @_;

  $self->{'start_handlers'} = $start_handlers;
  $self->{'end_handlers'} = $end_handlers;
}

sub _set_subhandlers ($$)
{
  my ($self, $subhandlers) = @_;

  $self->{'subhandlers'} = $subhandlers;
}

sub _set_generator ($$)
{
  my ($self, $generator) = @_;

  $self->{'generator'} = $generator;
}

sub _set_start_ignores ($$)
{
  my ($self, $ignores) = @_;

  $self->{'start_ignored'} = $ignores;
}

sub _set_end_ignores ($$)
{
  my ($self, $ignores) = @_;

  $self->{'end_ignored'} = $ignores;
}

sub _is_start_ignored ($$)
{
  my ($self, $tag) = @_;
  my $ignores = $self->{'start_ignored'};

  return (exists ($ignores->{$tag}) or exists ($ignores->{'*'}));
}

sub _is_end_ignored ($$)
{
  my ($self, $tag) = @_;
  my $ignores = $self->{'end_ignored'};

  return (exists ($ignores->{$tag}) or exists ($ignores->{'*'}));
}

##
## public:
##
sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Gir::Handlers::Generated::Common::Base');
  my $self =
  {
    'start_handlers' => {},
    'end_handlers' => {},
    'start_ignored' => {},
    'end_ignored' => {},
    'subhandlers' => {},
    'generator' => \&_base_gen_subhandlers_impl
  };

  return bless ($self, $class);
}

sub get_start_handlers ($)
{
  my $self = shift;

  return $self->{'start_handlers'};
}

sub get_end_handlers ($)
{
  my $self = shift;

  return $self->{'end_handlers'};
}

sub get_subhandlers_for ($$)
{
  my ($self, $elem) = @_;
  my $subhandlers = $self->{'subhandlers'};
  my $package = undef;

  if (exists ($subhandlers->{$elem}))
  {
    $package = $subhandlers->{$elem};
  }
  elsif (exists ($subhandlers->{'*'}))
  {
    $package = $subhandlers->{'*'};
  }

  if (defined ($package))
  {
    my $generator = $self->{'generator'};
    my $instance = $package->new ();

    $instance->_set_generator ($generator);
    $instance->_setup_handlers ();
    $instance->_setup_subhandlers ();
    return $instance;
  }
  return undef;
}

1; # indicate proper module load.
