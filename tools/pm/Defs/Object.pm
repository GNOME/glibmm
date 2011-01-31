# gmmproc - Defs::Object module
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

package Defs::Object;

use strict;
use warnings;
use parent qw (Base::Object Defs::Named);

# class Defs::Object : public Base::Object
# {
#   string name;
#   string module;
# }

my $g_n = 'name';
my $g_m = 'module';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Defs::Object');
  my $self = $class->SUPER->new ();

  $self->{$g_n} = '';
  $self->{$g_m} = '';

  bless ($self, $class);
  return $self;
}

sub parse ($$)
{
  my $self = shift;
  my $def = shift;
  my $name = '';
  my $module = '';
  my $parent = '';
  my $c_name = '';
  my $gtype_id = '';

  $def =~ s/^\(//;
  $def =~ s/\)$//;

  # snarf down the fields
  $name = $1 if ($def =~ s/^define-object (\S+)//);
  $module = $1 if ($def =~ s/\(in-module "(\S+)"\)//);
  $parent = $1 if($def =~ s/\(parent "(\S+)"\)//);
  $c_name = $1 if($def =~ s/\(c-name "(\S+)"\)//);
  $gtype_id = $1 if($def =~ s/\(gtype-id "(\S+)"\)//);
  #TODO: get a list of implemenented interfaces.

  if ($def !~ /^\s*$/)
  {
    return 0;
    #GtkDefs::error("Unhandled object def ($def) in $$self{module}\::$$self{name}\n")
  }

  $self->set_name ($name);
  $self->set_module ($module);
  $self->set_parent ($parent);
  $self->set_c_name ($c_name);
  $self->set_gtype_id ($gtype_id);

  return 1;
}

sub get_module ($)
{
  my $self = shift;

  return $self->{$g_m};
}

sub set_module ($$)
{
  my $self = shift;
  my $module = shift;

  $self->{$g_m} = $module;
}

#TODO: should be moved elsewhere.
sub dump($)
{
  my ($self) = @_;

  print "<object>\n";

  foreach(keys %$self)
    { print "  <$_ value=\"$$self{$_}\"/>\n"; }

  print "</object>\n\n";
}


1; # indicate proper module load.
