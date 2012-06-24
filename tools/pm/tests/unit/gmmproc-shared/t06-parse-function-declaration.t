#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

use Test::More;

# TODO: use '$(srcdir)/../../../'
push (@INC, '../../../');

require Common::Shared;

sub h
{
  croak (join ('', 'Expected 5 parameters, got ', scalar (@_))) if (@_ != 5);

  return
  {
    'type' => shift,
    'name' => shift,
    'value' => shift,
    'nullable' => shift,
    'out' => shift
  };
}

my @params =
(
 ['', ['', '', '', '', '']],
 ['void f()', ['', 'void', 'f', '()', '']],
 ['static void f()', ['static', 'void', 'f', '()', '']],
 ['void f() const', ['', 'void', 'f', '()', 'const']],
 ['static void f() const', ['static', 'void', 'f', '()', 'const']],
 ['int f(int a)', ['', 'int', 'f', '(int a)', '']],
 ['int f(:: a :: b < c::d<e>, f, g<h,i>, j>& v1{?}, k *v2 = "a, \'b, c", l v3 = \'"\', m<n> v4= "}\\"{", o v5 = \'\\\'\')', ['', 'int', 'f', '(:: a :: b < c::d<e>, f, g<h,i>, j>& v1{?}, k *v2 = "a, \'b, c", l v3 = \'"\', m<n> v4= "}\\"{", o v5 = \'\\\'\')', '']],
 ['int operator==(int a, int b)', ['', 'int', 'operator==', '(int a, int b)', '']],
 ['int &operator ()(int a)', ['', 'int&', 'operator ()', '(int a)', '']],
 [':: a :: b < c::d<e>, f, g<h,i>, j> &f()', ['', '::a::b< c::d< e >, f, g< h, i >, j >&', 'f', '()', '']]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $line = $entry->[0];
  my $expected = $entry->[1];
  my $result = Common::Shared::parse_function_declaration ($line);

  is_deeply ($result, $expected, '\'' . $line . '\'');
}
