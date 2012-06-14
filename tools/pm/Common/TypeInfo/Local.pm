# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Local module
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

package Common::TypeInfo::Local;

use strict;
use warnings;

sub _get_conversions ($)
{
  my ($self) = @_;

  return $self->{'conversions'};
}

sub _get_named_conversions ($)
{
  my ($self) = @_;

  return $self->{'named_conversions'};
}

sub _get_global ($)
{
  my ($self) = @_;

  return $self->{'global'};
}

#named_conversions =>
#{
#  'names' => {$name => $from}, # this is for lookup whether name exists and for deletion.
#  'conversions' =>
#  {
#    $from =>
#    {
#      'names' => {$name => $to}, # if this hash has only one element we are free to delete whole from part
#      'to' =>
#      {
#        $to =>
#        {
#          'names_indices' => {$name => $index_in_names_stack}, # to quickly find $name's index in 'names_stack' so we can quickly remove it (without traversing whole stack).
#          'names_stack' => [$name1, $name2], # order matters! index -1 (last) is top of the stack. if this array has only one element then we are free to delete whole to part. Otherwise we just remove a name from the 'names_stack', 'transfers' and 'names_indices'.
#          'transfers' =>
#          {
#            $name1 => [$transfer_none, $transfer_container, $transfer_full],
#            $name2 => [$transfer_none, $transfer_container, $transfer_full]
#          }
#        }
#      }
#    }
#  }
#}

sub _get_named_conversion ($$$$$)
{
  my ($self, $from, $to, $transfer, $subst) = @_;
  my $named_conversions = $self->_get_named_conversions ();
  my $from_conversions = $named_conversions->{'conversions'};

  if (exists ($from_conversions->{$from}))
  {
    my $to_conversions = $from_conversions->{$from}{'to'};

    if (exists ($to_conversions->{$to}))
    {
      my $to_section = $to_conversions->{$to};
      my $name = $to_section->{'names_stack'}[-1];

      return $to_section->{'transfers'}{$name}[$transfer];
    }
  }
  return undef;
}

sub new ($$)
{
  my ($type, $global) = @_;
  my $class = (ref $type or $type or 'Common::TypeInfo::Local');
  my $self =
  {
    'conversions' => {},
    'named_conversions' =>
    {
      'names' => {},
      'conversions' => {}
    },
    'global' => $global
  };

  return bless $self, $class;
}

sub add_conversion ($$$$$$)
{
  my ($self, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;
  my $conversions = $self->_get_conversions;

  Common::TypeInfo::Common::add_specific_conversion $conversions, $from, $to, $transfer_none, $transfer_container, $transfer_full;
}

sub named_conversion_exists ($$)
{
  my ($self, $name) = @_;
  my $named_conversions = $self->_get_named_conversions ();
  my $names = $named_conversions->{'names'};

  return exists ($names->{$name});
}

sub push_named_conversion ($$$$$$$)
{
  my ($self, $name, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;

  die if $self->named_conversion_exists ($name);

  my $named_conversions = $self->_get_named_conversions ();
  my $toplevel_conversions = $named_conversions->{'conversions'};

  $named_conversions->{'names'}{$name} = $from;

  if (exists ($toplevel_conversions->{$from}))
  {
    my $from_section = $toplevel_conversions->{$from};
    my $to_conversions = $toplevel_conversions->{'to'};

    $from_section->{'names'}{$name} = $to;

    if (exists ($to_conversions->{$to}))
    {
      my $to_section = $to_conversions->{$to};
      my $names_stack = $to_section->{'names_stack'};

      $to_section->{'names_indices'}{$name} = scalar (@{$names_stack});
      push (@{$names_stack}, $name);
      $to_section->{'transfers'}{$name} = [$transfer_none, $transfer_container, $transfer_full];
    }
    else
    {
      $to_conversions->{$to} =
      {
        'names_indices' => {$name => 0},
        'names_stack' => [$name],
        'transfers' =>
        {
          $name => [$transfer_none, $transfer_container, $transfer_full]
        }
      };
    }
  }
  else
  {
    $toplevel_conversions->{$from} =
    {
      'names' => {$name => $to},
      'to' =>
      {
        $to =>
        {
          'names_indices' => {$name => 0},
          'names_stack' => [$name],
          'transfers' =>
          {
            $name => [$transfer_none, $transfer_container, $transfer_full]
          }
        }
      }
    };
  }
}

sub pop_named_conversion ($$)
{
  my ($self, $name) = @_;

  die unless ($self->named_conversion_exists ($name));

  my $named_conversions = $self->_get_named_conversions ();
  my $toplevel_names = $named_conversions->{'names'};

  if (scalar (keys (%{$toplevel_names})) > 1)
  {
    my $from = delete ($toplevel_names->{$name});
    my $from_conversions = $named_conversions->{'conversions'};
    my $from_section = $from_conversions->{$from};
    my $from_names = $from_section->{'names'};

    if (scalar (keys (%{$from_names})) > 1)
    {
      my $to = delete ($from_names->{$name});
      my $to_conversions = $from_section->{'to'};
      my $to_section = $to_conversions->{$to};
      my $to_names_stack = $to_section->{'names_stack'};

      if (scalar (@{$to_names_stack}) > 1)
      {
        my $index = delete ($to_section->{'names_indices'}{$name});

        splice (@{$to_names_stack}, $index, 1);
        delete ($to_section->{'transfers'}{$name});
      }
      else
      {
        delete $to_conversions->{$to};
      }
    }
    else
    {
      delete $from_conversions->{$from};
    }
  }
  else
  {
    $named_conversions =
    {
      'names' => {},
      'conversions' => {}
    };
  }
}

sub get_conversion ($$$$$)
{
  my ($self, $from, $to, $transfer, $subst) = @_;
  my $conversion = $self->_get_named_conversion ($from, $to, $transfer, $subst);

  unless (defined ($conversion))
  {
    my $conversions = $self->_get_conversions;

    $conversion = Common::TypeInfo::Common::get_specific_conversion $conversions, $from, $to, $transfer, $subst;

    unless (defined $conversion)
    {
      my $global = $self->_get_global;

      # this will throw an exception when nothing is found.
      $conversion = $global->get_conversion ($from, $to, $transfer, $subst);
    }
  }

  return $conversion;
}

sub c_to_cxx ($$)
{
  my ($self, $c_stuff) = @_;
  my $global = $self->_get_global;

  $global->c_to_cxx ($c_stuff);
}

sub cxx_to_c ($$)
{
  my ($self, $cxx_stuff) = @_;
  my $global = $self->_get_global;

  $global->cxx_to_c ($cxx_stuff);
}

1; # indicate proper module load.
