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
 ['', []],
 ['int a', ['int a']],
 ['const Glib::ustring& str', ['const Glib::ustring& str']],
 ['const gchar* str = " ajwaj "', ['const gchar* str = " ajwaj "']],
 ['const gchar c = \'o\'', ['const gchar c = \'o\'']],
 ['gchar c = \',\'', ['gchar c = \',\'']],
 ['const Glib::ustring& str{?}', ['const Glib::ustring& str{?}']],
 ['int a{OUT}', ['int a{OUT}']],
 ['int a, int b', ['int a', 'int b']],
 ['double& b{RET}, const std::vector<Foo::Bar::Baz>& v, A<B<C> >& stuff{?}, int i = 42', ['double& b{RET}', 'const std::vector<Foo::Bar::Baz>& v', 'A<B<C> >& stuff{?}', 'int i = 42']],
 ['int &a', ['int &a']],
 ['gchar * *foo', ['gchar * *foo']],
 [':: a :: b < c::d<e>, f, g<h,i>, j>& v1{?}, k *v2 = "a, \'b, c", l v3 = \'"\', m<n> v4= "}\\"{"', [':: a :: b < c::d<e>, f, g<h,i>, j>& v1{?}', 'k *v2 = "a, \'b, c"', 'l v3 = \'"\'', 'm<n> v4= "}\\"{"']]
);

plan (tests => @params * 1);

foreach my $entry (@params)
{
  my $line = $entry->[0];
  my $expected = $entry->[1];
  my $result = Common::Shared::string_split_func_params ($line);

  is_deeply ($result, $expected, '\'' . $line . '\'');
}
