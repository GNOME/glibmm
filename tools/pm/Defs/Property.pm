# gmmproc - Defs::Property module
#
# Copyright 2011 glibmm development team
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#

package Defs::Property;

use strict;
use warnings;
use parent qw (Base::Property Defs::Named);

# class Defs::Property : public Base::Property
# {
#   string name;
#   string docs;
# }

my $g_n = 'name';
my $g_d = 'docs';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Defs::Property');
  my $self = $class->SUPER->new ();

  $self->{$g_n} = '';
  $self->{$g_d} = '';

  bless ($self, $class);
  return $self;
}

sub parse ($$)
{
  my $self = shift;
  my $def = shift;
  my $name = '';
  my $class = '';
  my $type = '';
  my $readable = 0;
  my $writable = 0;
  my $construct_only = 0;
  my $docs = '';

  $def =~ s/^\(//;
  $def =~ s/\)$//;
  # snarf down the fields
  $name = $1 if ($def =~ s/^define-property (\S+)//);
  $name =~ s/-/_/g;
  $class = $1 if ($def =~ s/\(of-object "(\S+)"\)//);
  $type = $1 if ($def =~ s/\(prop-type "(\S+)"\)//);
  $readable = ($1 eq "#t") if ($def =~ s/\(readable (\S+)\)//);
  $writable = ($1 eq "#t") if ($def =~ s/\(writable (\S+)\)//);
  $construct_only = ($1 eq "#t") if ($def =~ s/\(construct-only (\S+)\)//);
  $docs = $1 if ($def =~ s/\(docs "([^"]*)"\)//);
  # Add a full-stop if there is not one already:
  if (defined ($docs) and $docs =~ /\.$/)
  {
    $docs = $docs . ".";
  }

  if ($def !~ /^\s*$/)
  {
    return 0;
    #GtkDefs::error("Unhandled property def ($def) in $$self{class}\::$$self{name}\n");
  }

  $self->set_name ($name);
  $self->set_c_name ($name);
  $self->set_class ($class);
  $self->set_type ($type);
  $self->set_readable ($readable);
  $self->set_writable ($writable);
  $self->set_construct_only ($construct_only);
  $self->set_docs ($docs);
  $self->set_entity ('property');

  return 1;
}

sub get_docs ($)
{
  my $self = shift;

  return $self->{$g_d};
}

sub set_docs ($$)
{
  my $self = shift;
  my $docs = shift;

  $self->{$g_d} = $docs;
}

#TODO: should be moved elsewhere.
sub dump($)
{
  my ($self) = @_;

  print "<property>\n";

  foreach (keys %$self)
  { print "  <$_ value=\"$$self{$_}\"/>\n"; }

  print "</property>\n\n";
}

1; # indicate proper module load.
