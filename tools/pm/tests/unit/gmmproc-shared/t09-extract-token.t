#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

use Test::More;

# TODO: use '$(srcdir)/../../../'
push (@INC, '../../../');

sub atos
{
  my ($array) = @_;
  # TODO: do it with map
  my @new_array = ();

  foreach my $entry (@{$array})
  {
    my $new = '';

    if ($entry eq "\n")
    {
      $new = '\n';
    }
    else
    {
      $new = $entry;
    }
    push (@new_array, $new);
  }

  return '[' . join (', ', @new_array) . ']';
}

require Common::Shared;

my @params =
(
 [[], [undef, 0], 0, undef],
 [['foo'], ['foo', 0], 0, undef],
 [['foo', 'bar'], ['foo', 0], 1, 'bar'],
 [['foo', "\n", 'bar'], ['foo', 0], 2, "\n"],
 [["\n", 'foo'], ["\n", 1], 1, 'foo'],
 [["\n", "\n"], ["\n", 1], 1, "\n"],
 [["\n"], ["\n", 1], 0, undef]
);
my $test_plan = @params * 2;

foreach my $entry (@params)
{
  my $next_val = $entry->[3];

  if (defined ($next_val))
  {
    ++$test_plan;
  }
}

plan (tests => $test_plan);

foreach my $entry (@params)
{
  my $tokens = $entry->[0];
  my $expected = $entry->[1];
  my $remaining_count = $entry->[2];
  my $next_val = $entry->[3];
  my $label = atos ($tokens);
  my $result = Common::Shared::extract_token ($tokens);

  is_deeply ($result, $expected, $label);
  is (scalar (@{$tokens}), $remaining_count, 'remaining count: ' . $remaining_count);
  if ($remaining_count)
  {
    is ($tokens->[0], $next_val, 'next val: \'' . ($next_val eq "\n" ? '\n' : $next_val) . '\'');
  }
}
