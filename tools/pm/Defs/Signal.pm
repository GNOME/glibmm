# gmmproc - Defs::Signal module
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

package Defs::Signal;

use strict;
use warnings;
use parent qw (Defs::Function);
use Defs::Common;

#  class Defs::Signal : Defs::Function
#    {
#       string name; e.g. gtk_accelerator_valid
#       string class e.g. GtkButton ( == of-object.)
#
#       string rettype;
#
#       string when. e.g. first, last, or both.
#       string entity_type. e.g. method or signal
#    }

my $g_w = 'when';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or 'Defs::Signal');
  my $self = $class->SUPER->new ();

  $self->{$g_w} = '';

  bless ($self, $class);
  return $self;
}

sub parse ($$)
{
  my $self = shift;
  my $def = shift;
  my $whole = $def;
  my $entity = '';
  my $name = '';
  my $ret_type = 'void';
  my $param_types = [];
  my $param_names = [];
  my $when = '';
  my $class = '';

  #Remove first and last braces:
  $def =~ s/^\(//;
  $def =~ s/\)$//;
  $def =~ s/^\s*define-(\S+)\s+(\S+)\s*//;
  $entity = $1;
  $name = $2;
  $name =~ s/-/_/g; #change - to _

  # snarf down lisp fields
  if ($def =~ s/\(of-object "(\S+)"\)//)
  {
    $class = $1;
  }
  else
  {
    return 0;
    #GtkDefs::error("define-signal/define-vfunc without of-object (entity type: $$self{entity_type}): $whole");
  }

  if ($def =~ s/\(return-type "(\S+)"\)//)
  {
    $ret_type = $1;
    $ret_type =~ s/-/ /g; #e.g. replace const-gchar* with const gchar*. Otherwise it will be used in code.
    if ($ret_type eq 'none' or $ret_type eq 'None')
    {
      $ret_type = 'void';
    }
  }

  if ($def =~ s/\(when "(\S+)"\)//)
  {
    $when = $1;
  }

  # signals always have a parameter
  push (@{$param_types}, $class . '*');
  push (@{$param_names}, 'self');

  # parameters are compound lisp statement
  if ($def =~ s/\(parameters(( '\("\S+" "\S+"\))+) \)//)
  {
    my $params_h_r = Defs::Common::parse_params ($1);

    unless (keys (%{$params_h_r}))
    {
      return 0;
    }
    push (@{$param_types}, @{$params_h_r->{$Defs::Common::gc_p_t}});
    push (@{$param_names}, @{$params_h_r->{$Defs::Common::gc_p_n}});
  }

  if ($def !~ /^\s*$/)
  {
    return 0;
    #GtkDefs::error("Unhandled signal/vfunc def ($def) in $$self{class}::$$self{name}");
  }

  $self->set_entity ($entity);
  $self->set_name ($name);
  $self->set_class ($class);
  $self->set_ret_type ($ret_type);
  $self->set_param_types ($param_types);
  $self->set_param_names ($param_names);
  $self->set_when ($when);

  return 1;
}

sub get_when ($)
{
  my $self = shift;

  return $self->{$g_w};
}

sub set_when ($$)
{
  my $self = shift;
  my $when = shift;

  $self->${g_w} = $when;
}

# TODO: this is unused.
# bool has_same_types($objFunction)
# Compares return types and argument types
#sub has_same_types($$)
#{
#  my ($self, $objFuncOther) = @_;

#  #Compare return types:
#  if($self->types_are_equal($$self{rettype}, $$objFuncOther{rettype}) ne 1)
#  {
#    # printf("debug: different return types: %s, %s\n", $$self{rettype}, $$objFuncOther{rettype});
#    return 0; #Different types found.
#  }

#  #Compare arguement types:
#  my $i = 0;
#  my $param_types = $$self{param_types};
#  my $param_types_other = $$objFuncOther{param_types};
#  for ($i = 1; $i < $#$param_types + 1; $i++)
#  {
#    my $type_a = $$param_types[$i];
#    my $type_b = $$param_types_other[$i-1];

#    if($self->types_are_equal($type_a, $type_b) ne 1)
#    {
#      # printf("debug: different arg types: %s, %s\n", $type_a, $type_b);
#      return 0; #Different types found.
#    }
#  }

#  return 1; #They must all be the same for it to get this far.
#}

# TODO: this is used in unused function.
# bool types_are_equal($a, $b)
# Compares types, ignoring gint/int differences, etc.
#sub types_are_equal($$$)
#{
#  #TODO: Proper method of getting a normalized type name.

#  my ($self, $type_a, $type_b) = @_;

#  if($type_a ne $type_b)
#  {
#    #Try adding g to one of them:
#    if( ("g" . $type_a) ne $type_b )
#    {
#      #Try adding g to the other one:
#      if( $type_a ne ("g" . $type_b) )
#      {
#        #After all these checks it's still not equal:
#        return 0; #not equal.
#      }
#    }
#  }

#  # printf("DEBUG: types are equal: %s, %s\n", $$type_a, $$type_b);
#  return 1; #They must be the same for it to get this far.
#}

1; # indicate proper module load.
