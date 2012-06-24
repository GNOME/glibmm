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

  return join ('', @new_array);
}

require Common::Shared;

my @params =
(
 [[], undef],
 [['(', ')'], ['', 0]],
 [['ab', '(', 'x', ')'], undef],
 [['(', 'x', ')', 'ab'], ['x', 0]],
 [['(', 'x', '(', 'ab', ')', ', cd', ')'], ['x(ab), cd', 0]],
 [['('], undef],
 [[')'], undef],
 [['(', '(', ')'], undef],
 [['(', 'void', ' ', 'func', '(', 'char', ' ', 'a', ' ', '=', ' ', '\'', '(', '\'', ')', ',', ' ', 'c_func', ')'], ['void func(char a = \'(\'), c_func', 0]],
 [['(', "\n", ')'], ["\n", 1]],
 [['(', 'a', "\n", ')'], ["a\n", 1]],
 [['(', 'ab', "\n", 'cd', ')'], ["ab\ncd", 1]]
);

plan (tests => scalar (@params));

foreach my $entry (@params)
{
  my $tokens = $entry->[0];
  my $expected = $entry->[1];
  my $label = atos ($tokens);
  my $result = Common::Shared::extract_bracketed_text ($tokens);

  is_deeply ($result, $expected, '\'' . $label . '\'');
}
