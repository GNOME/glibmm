# gmmproc - Defs::Enum module
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

package Defs::Enum;

use strict;
use warnings;
use parent qw (Base::Enum Defs::Named);

# class Defs::Enum : public Base::Enum, public Defs::Named
# {
#       string module;
# }

#
# private functions:
#

sub split_enum_tokens($)
{
  my ($token_string) = @_;
  my @tokens = ();
  # index of first opening double quotes between parens - beginning of a new
  # token.
  my $begin_token = 0;
  # index of last closing double quotes between parens - end of a token.
  my $end_token = 0;
  # whether we are inside double quotes.
  my $inside_dquotes = 0;
  # whether we are inside double and then single quotes (for situations like
  # "'"'").
  my $inside_squotes = 0;
  my $len = length($token_string);
  # whether we found opening paren and we are expecting an opening double
  # quotes.
  my $near_begin = 0;
  # count of double quotes pairs between parens.
  my $dq_count = 0;
  # whether previous char was a backslash - important only when being between
  # double quotes.
  my $backslash = 0;
  for (my $index = 0; $index < $len; $index++)
  {
    my $char = substr($token_string, $index, 1);
    if ($inside_dquotes)
    {
      # if prevous char was backslash, then current char is not important -
      # we are still inside double or double/single quotes anyway.
      if ($backslash)
      {
        $backslash = 0;
      }
      # if current char is backslash.
      elsif ($char eq '\\')
      {
        $backslash = 1;
      }
      # if current char is unescaped double quotes and we are not inside single
      # ones - means, we are going outside string. We mark this place as an end
      # of the token in case we find a closing paren after this.
      elsif ($char eq '"' and not $inside_squotes)
      {
        $inside_dquotes = 0;
        $end_token = $index;
      }
      # if current char is single quote then switch being inside single quotes
      # state.
      elsif ($char eq '\'')
      {
        $inside_squotes = not $inside_squotes;
      }
    }
    # current char is opening paren - this means we are near the beginning of
    # a token (first double quotes after this paren).
    elsif ($char eq '(')
    {
      $near_begin = 1;
    }
    # current char is closing paren - this means we reached end of a token at
    # last closing double quotes.
    elsif ($char eq ')')
    {
      my $token_len = $end_token + 1 - $begin_token;
      my $token = substr($token_string, $begin_token, $token_len);
      # there should be three pairs of double quotes.
      if ($dq_count == 3)
      {
        push(@tokens, $token);
      }
      else
      {
        print STDERR "Wrong value statement while parsing ($token)\n";
      }
      $dq_count = 0;
    }
    # current char is opening double quotes - this can be a beginning of
    # a token.
    elsif ($char eq '"')
    {
      if ($near_begin)
      {
        $begin_token = $index;
        $near_begin = 0;
      }
      $inside_dquotes = 1;
      $dq_count++;
    }
  }
  return @tokens;
}

my $gi_e_n = 'internal_element_names';
my $gi_e_v = 'internal_element_values';

sub parse_values($)
{
  my $value = shift;
  my $element_names  = [];
  my $element_values = [];
  my $elements_h_r =
  {
    $gi_e_n => $element_names,
    $gi_e_v => $element_values
  };
  my $common_prefix = undef;
  # break up the value statements - it works with parens inside double quotes
  # and handles triples like '("dq-token", "MY_SCANNER_DQ_TOKEN", "'"'").
  for my $line (split_enum_tokens ($value))
  {
    if ($line =~ /^"\S+" "(\S+)" "(.+)"$/)
    {
      my ($name, $value) = ($1, $2);
      # detect whether there is module prefix common to all names, e.g. GTK_
      my $prefix = $1 if ($name =~ /^([^_]+_)/);

      if (not defined($common_prefix))
      {
        $common_prefix = $prefix;
      }
      elsif ($prefix ne $common_prefix)
      {
        $common_prefix = '';
      }

      push(@{$element_names}, $name);
      push(@{$element_values}, $value);
    }
    else
    {
      return {};
      #GtkDefs::error("Unknown value statement ($_) in $$self{c_type}\n");
    }
  }

  if ($common_prefix)
  {
    # cut off the module prefix, e.g. GTK_
    s/^$common_prefix// foreach (@{$element_names});
  }

  return $elements_h_r;
}

#
# end of private functions.
#

my $g_m = 'module';

sub new ($)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Defs::Enum");
  my $self = $class->SUPER->new ();

  $self->{$g_m} = '';

  return bless ($self, $class);
}

sub parse ($$)
{
  my $self = shift;
  my $def = shift;
  my $flags = 0;
  my $c_name = '';
  my $name = '';
  my $element_names = [];
  my $element_values = [];
  my $module = '';

  $def =~ s/^\(//;
  $def =~ s/\)$//;

  # snarf down the fields
  if($def =~ s/^define-(enum|flags)-extended (\S+)//)
  {
    $name = $2;
    $flags = 1 if ($1 eq 'flags');
  }

  $module = $1 if ($def =~ s/\(in-module "(\S+)"\)//);
  $c_name = $1 if ($def =~ s/\(c-name "(\S+)"\)//);

  # values are compound lisp statement
  if($def =~ s/\(values((?: '\("\S+" "\S+" "[^"]+"\))*) \)//)
  {
    my $elements_h_r = parse_values ($1);

    unless (keys (%{$elements_h_r}))
    {
      return 0;
    }
    $element_names = $elements_h_r->{$gi_e_n};
    $element_values = $elements_h_r->{$gi_e_v};
  }

  if($def !~ /^\s*$/)
  {
    return 0;
    #GtkDefs::error("Unhandled enum def ($def) in $$self{module}\::$$self{type}\n")
  }

  # this should never happen
  if (scalar (@{$element_names}) != scalar (@{$element_values}))
  {
    return 0;
  }

  $self->set_flags ($flags);
  $self->set_c_name ($c_name);
  $self->set_name ($name);
  $self->set_element_names ($element_names);
  $self->set_element_values ($element_values);
  $self->set_module ($module);

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

  $self->${g_m} = $module;
}

# TODO: should be moved elsewhere.
sub beautify_values($)
{
  my $self = shift;

  return if($$self{flags});

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  my $num_elements = scalar(@$elem_values);
  return if($num_elements == 0);

  my $first = $$elem_values[0];
  return if($first !~ /^-?[0-9]+$/);

  my $prev = $first;

  # Continuous?  (Aliases to prior enum values are allowed.)
  foreach my $value (@$elem_values)
  {
    return if ($value =~ /[G-WY-Zg-wy-z_]/);
    return if(($value < $first) || ($value > $prev + 1));
    $prev = $value;
  }

  # This point is reached only if the values are a continuous range.
  # 1) Let's kill all the superfluous values, for better readability.
  # 2) Substitute aliases to prior enum values.

  my %aliases = ();

  for(my $i = 0; $i < $num_elements; ++$i)
  {
    my $value = \$$elem_values[$i];
    my $alias = \$aliases{$$value};

    if(defined($$alias))
    {
      $$value = $$alias;
    }
    else
    {
      $$alias = $$elem_names[$i];
      $$value = "" unless($first != 0 && $$value == $first);
    }
  }
}

# TODO: should be moved elsewhere.
sub build_element_list($$$$)
{
  my ($self, $ref_flags, $ref_no_gtype, $indent) = @_;

  my @subst_in  = [];
  my @subst_out = [];

  # Build a list of custom substitutions, and recognize some flags too.

  foreach(@$ref_flags)
  {
    if(/^\s*(NO_GTYPE)\s*$/)
    {
      $$ref_no_gtype = $1;
    }
    elsif(/^\s*(get_type_func=)(\s*)\s*$/)
    {
      my $part1 = $1;
      my $part2 = $2;
    }
    elsif(/^\s*s#([^#]+)#([^#]*)#\s*$/)
    {
      push(@subst_in,  $1);
      push(@subst_out, $2);
    }
    elsif($_ !~ /^\s*$/)
    {
      return undef;
    }
  }

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  my $num_elements = scalar(@$elem_names);
  my $elements = "";

  for(my $i = 0; $i < $num_elements; ++$i)
  {
    my $name  = $$elem_names[$i];
    my $value = $$elem_values[$i];

    for(my $ii = 0; $ii < scalar(@subst_in); ++$ii)
    {
      $name  =~ s/${subst_in[$ii]}/${subst_out[$ii]}/;
      $value =~ s/${subst_in[$ii]}/${subst_out[$ii]}/;
    }

    $elements .= "${indent}${name}";
    $elements .= " = ${value}" if($value ne "");
    $elements .= ",\n" if($i < $num_elements - 1);
  }

  return $elements;
}

#TODO: should be moved elsewhere.
sub dump($)
{
  my ($self) = @_;

  print "<enum module=\"$$self{module}\" type=\"$$self{type}\" flags=$$self{flags}>\n";

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  for(my $i = 0; $i < scalar(@$elem_names); ++$i)
  {
    print "  <element name=\"$$elem_names[$i]\"  value=\"$$elem_values[$i]\"/>\n";
  }

  print "</enum>\n\n";
}

1; # indicate proper module load.
