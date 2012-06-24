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
 ['a', ['a']],
 ['a::b', ['a::b', 'b']],
 ['a::b::c', ['a::b::c', 'b::c', 'c']],
 ['::a', ['::a', 'a']],
 ['::a::b', ['::a::b', 'a::b', 'b']],
 ['::a::b::c', ['::a::b::c', 'a::b::c', 'b::c', 'c']]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $cxx_type = $entry->[0];
  my $expected = $entry->[1];
  my $result = Common::Shared::split_cxx_type_to_sub_types ($cxx_type);

  is_deeply ($result, $expected, '\'' . $cxx_type . '\'');
}
