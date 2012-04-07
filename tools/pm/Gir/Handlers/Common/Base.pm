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

package Gir::Handlers::Common::Base;

use strict;
use warnings;

use Gir::Handlers::Common::Store;

##
## protected:
##
sub _call_hooks_general ($$$)
{
  my ($self, $tag_name, $hooks) = @_;

  if (exists $hooks->{$tag_name})
  {
    my $tag_hooks = $hooks->{$tag_name};

    foreach my $pair (@{$tag_hooks})
    {
      my $object = $pair->[0];
      my $hook = $pair->[1];

      if (defined $object)
      {
#        print STDERR 'Calling method hook for `' . $tag_name . '\'.' . "\n";
        $object->$hook;
      }
      else
      {
#        print STDERR 'Calling function hook for `' . $tag_name . '\'.' . "\n";
        &{$hook};
      }
    }
  }
}

sub _call_start_hooks ($$)
{
  my ($self, $tag_name) = @_;
  my $start_hooks = $self->{'start_hooks'};

  $self->_call_hooks_general ($tag_name, $start_hooks);
}

sub _call_end_hooks ($$)
{
  my ($self, $tag_name) = @_;
  my $end_hooks = $self->{'end_hooks'};

  $self->_call_hooks_general ($tag_name, $end_hooks);
}

##
## public:
##
sub new ($$$)
{
  my ($type, $start_store, $end_store, $subhandlers) = @_;
  my $class = (ref $type or $type or 'Gir::Handlers::Common::Base');
  my $self =
  {
    'start_handlers' => $start_store,
    'end_handlers' => $end_store,
    'start_hooks' => {},
    'end_hooks' => {},
    'subhandlers' => $subhandlers
  };

  return bless $self, $class;
}

sub install_start_hook ($$$$)
{
  my ($self, $tag_name, $object, $hook) = @_;
  my $start_hooks = $self->{'start_hooks'};

  unless (exists $start_hooks->{$tag_name})
  {
    $start_hooks->{$tag_name} = [];
  }

  my $tag_start_hooks = $start_hooks->{$tag_name};

  push @{$tag_start_hooks}, [$object, $hook];
}

sub install_end_hook ($$$$)
{
  my ($self, $tag_name, $object, $hook) = @_;
  my $end_hooks = $self->{'end_hooks'};

  unless (exists $end_hooks->{$tag_name})
  {
    $end_hooks->{$tag_name} = [];
  }

  my $tag_end_hooks = $end_hooks->{$tag_name};

  push @{$tag_end_hooks}, [$object, $hook];
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

  if (exists $subhandlers->{$elem})
  {
    my $package = $subhandlers->{$elem};
    my $instance = $package->new;

    return $instance;
  }
  return undef;
}

1; # indicate proper module load.
