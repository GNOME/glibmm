# gmmproc - Defs::Function module
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

package Defs::Function;

use strict;
use warnings;
use parent qw (Base::Function Defs::Named);
use Defs::Common;

#  class Function : FunctionBase
#
#    {
#       string name; e.g. gtk_accelerator_valid
#       string c_name;
#       string class e.g. GtkButton
#
#       string rettype;
#       string array param_types;
#       string array param_names;
#
#       string entity_type. e.g. method or signal
#
#       bool varargs;
#       bool mark;
#
#    }

my $g_c = 'class';
my $g_n = 'name';
my $g_v = 'varargs';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Defs::Function");
  my $self = $class->SUPER->new ();

  $self->{$g_c} = '';
  $self->{$g_n} = '';
  $self->{$g_v} = 0;

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
  my $c_name = '';
  my $class = '';
  my $ret_type = 'void';
  my $varargs = 0;
  my $param_types = [];
  my $param_names = [];

  $def =~ s/^\(//;
  $def =~ s/\)$//;
  $def =~ s/^\s*define-(\S+)\s+(\S+)\s*//;
  $entity = $1;
  $name = $2;
  $name =~ s/-/_/g;
  # snarf down lisp fields
  if ($def =~ s/\(c-name "(\S+)"\)//)
  {
    $c_name = $1;
  }
  if ($def=~s/\(of-object "(\S+)"\)//)
  {
    $class = $1;
  }
  if ($def =~ s/\(return-type "(\S+)"\)//)
  {
    $ret_type = $1;
    $ret_type =~ s/-/ /g;
    if ($ret_type eq 'none' or $ret_type eq 'None')
    {
      $ret_type = 'void';
    }
  }

  if ($def =~ s/\(varargs\s+#t\)//)
  {
    $varargs = 1;
  }

  # methods have a parameter not stated in the defs file
  if ($entity eq 'method')
  {
    push (@{$param_types}, $class . '*');
    push (@{$param_names}, 'self');
  }

  # parameters are compound lisp statement
  if ($def =~ s/\(parameters(( '\("\S+" "\S+"\))*) \)//)
  {
    my $params_h_r = Defs::Common::parse_params ($1);

    unless (keys (%{$params_h_r}))
    {
      return 0;
    }
    push (@{$param_types}, @{$params_h_r->{$Defs::Common::gc_p_t}});
    push (@{$param_names}, @{$params_h_r->{$Defs::Common::gc_p_n}});
  }

  # is-constructor-of:
  if ($def =~ s/\(is-constructor-of "(\S+)"\)//)
  {
    #Ignore them.
  }

  # of-object
  if ($def =~ s/\(of-object "(\S+)"\)//)
  {
    #Ignore them.
  }

  if ($def !~ /^\s*$/)
  {
    #GtkDefs::error("Unhandled function parameter ($def) in $$self{c_name}\n");
    return 0;
  }

  $self->set_entity ($entity);
  $self->set_name ($name);
  $self->set_c_name ($c_name);
  $self->set_class ($class);
  $self->set_ret_type ($ret_type);
  $self->set_varargs ($varargs);
  $self->set_param_types ($param_types);
  $self->set_param_names ($param_names);

  return 1;
}

sub get_class ($)
{
  my $self = shift;

  return $self->{$g_c};
}

sub set_class ($$)
{
  my $self = shift;
  my $class = shift;

  $self->{$g_c} = $class;
}

sub has_varargs ($)
{
  my $self = shift;

  return $self->{$g_v};
}

sub set_varargs ($$)
{
  my $self = shift;
  my $varargs = shift;

  $self->{$g_v} = $varargs;
}

# $string get_return_type_for_methods().
# Changes gchar* (not const-gchar*) to return-gchar* so that _CONVERT knows that it needs to be freed.
sub get_return_type_for_methods ($)
{
  my $self = shift;
  my $ret_type = $self->get_ret_type ();

  if($ret_type eq "gchar*" or $ret_type eq "char*")
  {
    $ret_type = "return-" . $ret_type;
  }

  return $ret_type;
}

1; # indicate proper module load.
