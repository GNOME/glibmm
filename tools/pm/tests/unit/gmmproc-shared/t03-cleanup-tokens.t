#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

use Test::More;

# TODO: use '$(srcdir)/../../../'
push (@INC, '../../../');

require Common::Shared;

sub atos
{
  my ($array) = @_;
  my @new_array = ();

  return 'undef' unless (defined ($array));

  foreach my $str (@{$array})
  {
    my $new = '';

    if (defined ($str))
    {
      if ($str eq "\n")
      {
        $new = '\'\n\'';
      }
      else
      {
        $new = '\'' . $str . '\'';
      }
    }
    else
    {
      $new = 'undef';
    }

    push (@new_array, $new);
  }

  return '[' . join (', ', @new_array) . ']';
}

my @sets =
(
 [[], []],
 [[''], []],
 [[undef], []],
 [['', undef], []],
 [['a'], ['a']],
 [['a', '', undef], ['a']],
 [['a', 'b'], ['a', 'b']],
 [['a', "\n", 'b'], ['a', "\n", 'b']]
);

plan (tests => scalar (@sets) * 1);

foreach my $entry (@sets)
{
  my $tokens = $entry->[0];
  my $expected = $entry->[1];
  my $label = atos ($tokens) . ' -> ' . atos ($expected);
  my @result = Common::Shared::cleanup_tokens (@{$tokens});

  is_deeply (\@result, $expected, $label);
}
