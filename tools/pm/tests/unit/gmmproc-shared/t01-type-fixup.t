#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

# TODO: use '$(srcdir)/../../../'
push (@INC, '../../../');

require Common::Shared;

use Test::More;

my @types =
(
 ['', ''],
 ['int', 'int'],
 ['  int  ', 'int'],
 ['const Glib::ustring&', 'const Glib::ustring&'],
 ['const gchar*', 'const gchar*'],
 ['const Glib::ustring &', 'const Glib::ustring&'],
 ['const std::vector<Foo::Bar::Baz> &', 'const std::vector< Foo::Bar::Baz >&'],
 ['A<B<C> *>&', 'A< B< C >* >&'],
 ['gchar * *', 'gchar**'],
 ['int *   &', 'int*&'],
 ['Glib :: ustring', 'Glib::ustring'],
 [':: Glib :: ustring', '::Glib::ustring'],
 [' std :: vector <  :: Glib :: ustring  > &', 'std::vector< ::Glib::ustring >&'],
 ['a<b,c,d<e,f,g> >', 'a< b, c, d< e, f, g > >']
);

plan (tests => @types * 1);

foreach my $entry (@types)
{
  my $type = $entry->[0];
  my $expected = $entry->[1];
  my $result = Common::Shared::_type_fixup ($type);

  is ($result, $expected, join ('', '\'', $type, '\' => \'', $expected, '\''));
}
