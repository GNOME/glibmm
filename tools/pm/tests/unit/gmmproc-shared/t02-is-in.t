#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

use Test::More;

sub atos
{
  my ($array) = @_;

  return 'undef' unless (defined ($array));

  foreach my $str (@{$array})
  {
    unless (defined ($str))
    {
      $str = 'undef';
    }
  }

  return '[' . join (', ', @{$array}) . ']';
}

sub u
{
  unless (defined ($_[0]))
  {
    return 'undef';
  }

  return $_[0];
}

my @params =
(
 [undef, [], 0],
 [undef, ['a'], 0],
 [undef, [undef], 1],
 [undef, ['a', 'b'], 0],
 [undef, ['a', undef, 'b'], 1],
 ['a', [], 0],
 ['a', ['a'], 1],
 ['a', [undef], 0],
 ['a', [undef, 'b'], 0],
 ['a', ['a', undef, 'b'], 1],
 ['a b', [], 0],
 ['a b', ['a b'], 1],
 ['a b', [undef], 0],
 ['a b', [undef, 'b a'], 0],
 ['a b', ['a b', undef, 'b a'], 1]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $needle = $entry->[0];
  my $haystack = $entry->[1];
  my $expected = $entry->[2];
  my $result = $needle ~~ @{$haystack};

  if ($result)
  {
    $result = 1;
  }
  else
  {
    $result = 0;
  }

  is ($result, $expected, join ('', u ($needle), ' in ', atos ($haystack)));
}
