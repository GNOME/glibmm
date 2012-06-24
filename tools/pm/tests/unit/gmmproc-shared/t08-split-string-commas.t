#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

use Test::More;

# TODO: use '$(srcdir)/../../../'
push (@INC, '../../../');

require Common::Shared;

my @params =
(
 ['', []],
 ['foo', ['foo']],
 ['foo, bar', ['foo', 'bar']],
 ['foo(bar), baz', ['foo(bar)', 'baz']],
 ['foo(bar, baz), biff', ['foo(bar, baz)', 'biff']],
 ['foo, opt=\',\\\'\'', ['foo', 'opt=\',\\\'\'']],
 ['foo, opt=",\""', ['foo', 'opt=",\""']]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $line = $entry->[0];
  my $expected = $entry->[1];
  my @result = Common::Shared::string_split_commas ($line);

  is_deeply (\@result, $expected, '\'' . $line . '\'');
}
