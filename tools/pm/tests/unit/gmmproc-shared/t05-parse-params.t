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
 ['()', []],
 ['', []],
 ['int a', [h('int', 'a', undef, 0, 0)]],
 ['(int a)', [h('int', 'a', undef, 0, 0)]],
 ['const Glib::ustring& str', [h('const Glib::ustring&', 'str', undef, 0, 0)]],
 ['const gchar* str = " ajwaj "', [h('const gchar*', 'str', '" ajwaj "', 0, 0)]],
 ['const gchar c = \'o\'', [h('const gchar', 'c', '\'o\'', 0, 0)]],
 ['gchar c = \',\'', [h('gchar', 'c', '\',\'', 0, 0)]],
 ['const Glib::ustring& str{?}', [h('const Glib::ustring&', 'str', undef, 1, 0)]],
 ['int a{OUT}', [h('int', 'a', undef, 0, 1)]],
 ['int a{RET}', [h('int', 'a', undef, 0, 1)]],
 ['int a, int b', [h('int', 'a', undef, 0, 0), h('int', 'b', undef, 0, 0)]],
 ['double& b{RET}, const std::vector<Foo::Bar::Baz>& v, A<B<C> >& stuff{?}, int i = 42', [h('double&', 'b', undef, 0, 1), h('const std::vector< Foo::Bar::Baz >&', 'v', undef, 0, 0), h('A< B< C > >&', 'stuff', undef, 1, 0), h('int', 'i', '42', 0, 0)]],
 ['int &a', [h('int&', 'a', undef, 0, 0)]],
 ['gchar * *foo', [h('gchar**', 'foo', undef, 0, 0)]],
 [':: a :: b < c::d<e>, f, g<h,i>, j>& v1{?}, k *v2 = "a, \'b, c", l v3 = \'"\', m<n> v4= "}\"{"', [h('::a::b< c::d< e >, f, g< h, i >, j >&', 'v1', undef, 1, 0), h('k*', 'v2', '"a, \'b, c"', 0, 0), h('l', 'v3', '\'"\'', 0, 0), h('m< n >',  'v4' ,'"}\"{"', 0, 0)]]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $line = $entry->[0];
  my $expected = $entry->[1];
  my $result = Common::Shared::parse_params ($line);

  is_deeply ($result, $expected, '\'' . $line . '\'');
}
