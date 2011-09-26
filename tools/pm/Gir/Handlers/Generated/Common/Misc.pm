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

package Gir::Handlers::Generated::Common::Misc;

use strict;
use warnings;

##
## public:
##
sub extract_values($$$)
{
  my ($keys, $optional_keys, $atts_vals) = @_;
  my $params = {};
  my %check = ();
  my %leftovers = ();
  my $leftover = undef;
  my $att = undef;

  foreach my $key (@{$keys})
  {
    $params->{$key} = undef;
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
        delete ($check{$att});
      }
      else
      {
        $leftover = $entry;
      }
    }
    else
    {
      $params->{$att} = $entry;
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

sub module_from_tag ($)
{
  # unreadable, huh?
  # - splits 'foo-BAR:bAz' to 'foo', 'BAR' and 'bAz'
  # - changes 'foo' to 'Foo', 'BAR' to 'Bar' and 'bAz' to 'Baz'
  # - joins 'Foo', 'Bar' and 'Baz' into one string 'FooBarBaz'
  # - returns the joined string
  return join ('', map { ucfirst lc } split (/\W+/, shift));
}

1; # indicate proper module load.
