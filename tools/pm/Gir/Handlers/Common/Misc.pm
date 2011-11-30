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

package Gir::Handlers::Common::Misc;

use strict;
use warnings;

use Gir::Api::Common::Base;

##
## public:
##

##
## Takes an array of mandatory-key->mandatory-value pairs, an array
## of optional-key->default-value pairs and an array with names and values
## returned by Expat parser and returns a hash with final key->value pairs. Note
## that nonexistence of a key in atts_vals array that is specified in mandatory
## keys array is fatal. Also is existence of a key that is specified in neither
## mandatory keys array nor optional keys array. Also, if mandatory key has
## a mandatory value specified then it is fatal when actual value differs from
## it. If any optional key does not exist in atts_vals array then the one from
## array of optional-key->default_value pairs is taken.
##
sub extract_values($$$)
{
  my ($keys, $optional_keys, $atts_vals) = @_;
  my $params = {};
  my %check = ();
  my %leftovers = ();
  my $leftover = undef;
  my $att = undef;
  my $check_value = 0;

  foreach my $pair (@{$keys})
  {
    my $key = $pair->[0];

    $params->{$key} = $pair->[1];
    $check{$key} = undef;
  }
  foreach my $pair (@{$optional_keys})
  {
    $params->{$pair->[0]} = $pair->[1];
  }

  foreach my $entry (@{$atts_vals})
  {
    if (defined ($leftover))
    {
      $leftovers{$leftover} = $entry;
      $leftover = undef;
    }
    elsif (not defined ($att))
    {
      if (exists ($params->{$entry}))
      {
        $att = $entry;
        if (exists $check{$att})
        {
          delete ($check{$att});
          $check_value = 1;
        }
      }
      else
      {
        $leftover = $entry;
      }
    }
    else
    {
      if ($check_value)
      {
        $check_value = 0;
        unless (defined $params->{$att})
        {
          $params->{$att} = $entry;
        }
        elsif ($params->{$att} ne $entry)
        {
          print STDERR 'Expected value `' . $params->{$att} . '\' for `' . $att . '\', got `' . $entry  . '\'.' . "\n";
          exit 1;
        }
      }
      else
      {
        $params->{$att} = $entry;
      }
      $att = undef;
    }
  }

  my @check_keys = sort keys (%check);
  my $message = '';

  if (@check_keys > 0)
  {
    $message .= 'Missing attributes:' . "\n";

    foreach my $key (@check_keys)
    {
      $message .= '  ' . $key . "\n";
    }
  }

  my @leftover_keys = sort keys %leftovers;

  if (@leftover_keys > 0)
  {
    $message .= 'Leftover attributes:' . "\n";

    foreach $leftover (@leftover_keys)
    {
      $message .= "  " . $leftover . " => " . $leftovers{$leftover} . "\n";
    }
  }

  if ($message)
  {
    # TODO: throw an error.
    print STDERR $message;
    exit 1;
  }

  return $params;
}

##
## Takes an object and its index in array. Tries to find out object's name.
## If it fails, then it just generates a name using given index. This function
## tries to use (if possible) an original type name - it prefers `GtkWidget'
## over `Widget' or `gtk_widget_new' over `new'.
##
sub get_object_name ($$)
{
  my ($object, $index) = @_;
  my @name_atts =
  (
    'attribute_c_type',
    'attribute_c_identifier',
    'attribute_glib_type-name',
    'attribute_name',
    'attribute_glib_name'
  );

  foreach my $name (@name_atts)
  {
    if ($object->_has_attribute ($name))
    {
      my $object_name = $object->_get_attribute ($name);

      return $object_name if (defined $object_name and $object_name ne '');
    }
  }

  return ref ($object) . '#' . $index;
}

1; # indicate proper module load.
