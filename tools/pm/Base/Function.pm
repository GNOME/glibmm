# gmmproc - Base::Function module
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

package Base::Function;

use strict;
use warnings;
use parent qw (Base::Entity);
use Util;

##################################################
### Function
# Contains data and methods used by both Function (C++ declarations) and GtkDefs::Function (C defs descriptions)
# Note that GtkDefs::Signal inherits from GtkDefs::Function so it get these methods too.
#
# class Base::Function : public Base::Entity
# {
#   string array param_types;
#   string array param_names;
#   string       ret_type;
#   string       c_name;
# }

my $g_p_t = 'param_types';
my $g_p_n = 'param_names';
my $g_r_t = 'ret_type';
my $g_c_n = 'c_name';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Base::Function");
  my $self = $class->SUPER->new ();

  $self->{$g_p_t} = [];
  $self->{$g_p_n} = [];
  $self->{$g_r_t} = '';
  $self->{$g_c_n} = '';

  bless ($self, $class);
  return $self;
}

sub get_param_types ($)
{
  my $self = shift;

  return $self->{$g_p_t};
}

sub set_param_types ($$)
{
  my $self = shift;
  my $param_types = shift;

  $self->{$g_p_t} = shift;
}

sub get_param_names ($)
{
  my $self = shift;

  return $self->{$g_p_n};
}

sub set_param_names ($$)
{
  my $self = shift;
  my $param_names = shift;

  $self->{$g_p_n} = shift;
}

sub get_param_count ($)
{
  my $self = shift;

  return scalar (@{$self->{$g_p_t}});
}

sub get_ret_type ($)
{
  my $self = shift;

  return $self->{$g_r_t};
}

sub set_ret_type ($$)
{
  my $self = shift;
  my $ret_type = shift;

  $self->{$g_r_t} = $ret_type;
}

sub get_c_name ($)
{
  my $self = shift;

  return $self->{$g_c_n};
}

sub set_c_name ($$)
{
  my $self = shift;
  my $c_name = shift;

  $self->{$g_c_n} = $c_name;
}

# TODO: should be moved elsewhere.
# $string args_types_only($)
# comma-delimited argument types.
sub args_types_only($)
{
  my $self = shift;

  return join(", ", @{$self->{$g_p_t}});
}

# TODO: should be moved elsewhere.
# $string args_names_only($)
sub args_names_only($)
{
  my $self = shift;

  return join(", ", @{$self->{$g_p_n}});
}

# TODO: should be moved elsewhere.
# $string args_types_and_names($)
sub args_types_and_names($)
{
  my $self = shift;
  my $param_types = $self->{$g_p_t};
  my $param_names = $self->{$g_p_n};
  my @out;

  for (my $i = 0; $i < @{$param_types}; ++$i)
  {
    my $str = sprintf("%s %s", $$param_types[$i], $$param_names[$i]);
    push(@out, $str);
  }

  my $result =  join(", ", @out);
  return $result;
}

# TODO: this is used nowhere.
# $string args_names_only_without_object($)
#sub args_names_only_without_object2($)
#{
#  my $self = shift;

#  my $param_names = $$self{param_names};

#  my $result = "";
#  my $bInclude = 0; #Ignore the first (object) arg.
#  foreach (@{$param_names})
#  {
#    # Add comma if there was an arg before this one:
#    if( $result ne "")
#    {
#      $result .= ", ";
#    }

#    # Append this arg if it's not the first one:
#    if($bInclude)
#    {
#      $result .= $_;
#    }

#    $bInclude = 1;
#  }

#  return $result;
#}

#TODO: should be moved elsewhere.
# $string args_types_and_names_without_object($)
sub args_types_and_names_without_object($)
{
  my $self = shift;

  my $param_names = $$self{param_names};
  my $param_types = $$self{param_types};
  my $i = 0;
  my @out;

  for ($i = 1; $i < $#$param_types + 1; $i++) #Ignore the first arg.
  {
    my $str = sprintf("%s %s", $$param_types[$i], $$param_names[$i]);
    push(@out, $str);
  }

  return join(", ", @out);
}
# TODO: this is used nowhere.
# $string args_names_only_without_object($)
#sub args_names_only_without_object($)
#{
#  my $self = shift;

#  my $param_names = $$self{param_names};

#  my $result = "";
#  my $bInclude = 0; #Ignore the first (object) arg.
#  foreach (@{$param_names})
#  {
#    # Add comma if there was an arg before this one:
#    if( $result ne "")
#    {
#      $result .= ", ";
#    }

#    # Append this arg if it's not the first one:
#    if($bInclude)
#    {
#      $result .= $_;
#    }

#    $bInclude = 1;
#  }

#  return $result;
#}

# TODO: should be moved elsewhere.
sub dump($)
{
  my $self = shift;

  my $param_types = $$self{param_types};
  my $param_names = $$self{param_names};

  print "<function>\n";
  foreach (keys %$self)
  {
    print "  <$_ value=\"$$self{$_}\"/>\n" if (!ref $$self{$_} && $$self{$_} ne "");
  }

  if (scalar(@$param_types)>0)
  {
    print "  <parameters>\n";

    for (my $i = 0; $i < scalar(@$param_types); $i++)
    {
      print "    \"$$param_types[$i]\" \"$$param_names[$i]\" \n";
    }

    print "  </parameters>\n";
  }

  print "</function>\n\n";
}

# TODO: should be moved elsewhere.
sub args_types_and_names_with_default_values($)
{
  my $self = shift;

  my $i;

  my $param_names = $$self{param_names};
  my $param_types = $$self{param_types};
  my $param_default_values = $$self{param_default_values};
  my @out;
  
  for ($i = 0; $i < $#$param_types + 1; $i++)
  {
    my $str = sprintf("%s %s", $$param_types[$i], $$param_names[$i]);

    if(defined($$param_default_values[$i]))
    {
      if($$param_default_values[$i] ne "")
      {
        $str .= " = " . $$param_default_values[$i];
      }
    }

    push(@out, $str);
  }

  return join(", ", @out);
}

1; # indicate proper module load.
