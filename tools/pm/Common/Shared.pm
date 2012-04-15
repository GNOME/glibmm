# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Shared module
#
# Copyright 2012 glibmm development team
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

package Common::Shared;

use strict;
use warnings;
use feature ':5.10';

use constant
{
  'GEN_NONE' => 0,
  'GEN_NORMAL' => (1 >> 0),
  'GEN_REF' => (1 >> 1),
  'GEN_PTR' => (1 >> 2),
  'GEN_CONST' => (1 >> 3)
};

use Common::Util;

sub extract_token ($)
{
  my ($tokens) = @_;
  my $line_change = 0;

  while (@{$tokens})
  {
    my $token = shift @{$tokens};

    # skip empty tokens
    next if (not defined $token or $token eq '');

    if ($token =~ /\n/)
    {
      ++$line_change;
    }

    return [$token, $line_change];
  }

  return ['', $line_change];
}

sub extract_bracketed_text ($)
{
  my ($tokens) = @_;
  my $level = 1;
  my $str = '';
  my $line_change = 0;

  # Move to the first "(":
  while (@{$tokens})
  {
    my $result = extract_token $tokens;
    my $token = $result->[0];
    my $add_to_line = $result->[1];

    $line_change += $add_to_line;
    last if ($token eq '(');
  }

  # Concatenate until the corresponding ")":
  while (@{$tokens})
  {
    my $result = extract_token $tokens;
    my $token = $result->[0];
    my $add_to_line = $result->[1];

    $line_change += $add_to_line;
    ++$level if ($token eq '(');
    --$level if ($token eq ')');

    return [$str, $line_change] unless $level;
    $str .= $token;
  }

  return undef;
}

sub string_split_commas ($)
{
  my ($in) = @_;
  my @out = ();
  my $level = 0;
  my $str = '';
  my @tokens = split(/([,()"'\\])/, $in);
  my $sq = 0;
  my $dq = 0;
  my $escape = 0;

  while (@tokens)
  {
    my $token = shift @tokens;

    next if ($token eq '');

    if ($escape)
    {
      # do nothing
    }
    if ($sq)
    {
      if ($token eq '\'')
      {
        $sq = 0;
      }
    }
    elsif ($dq)
    {
      if ($token eq '"')
      {
        $dq = 0;
      }
    }
    elsif ($token eq '\\')
    {
      $escape = 1;
    }
    elsif ($token eq '\'')
    {
      $sq = 1;
    }
    elsif ($token eq '"')
    {
      $dq = 1;
    }
    elsif ($token eq '(')
    {
      ++$level;
    }
    elsif ($token eq ')')
    {
      --$level;
    }
    elsif ($token eq ',' and not $level)
    {
      push @out, Common::Util::string_trim $str;
      $str = '';
      next;
    }

    $str .= $token;
  }

  push @out, Common::Util::string_trim $str;
  return @out;
}

sub string_split_func_params ($)
{
  my ($in) = @_;
  my @out = ();
  my $level = 0;
  my $str = '';
  my @tokens = split(/([,()"'\\<>])/, $in);
  my $sq = 0;
  my $dq = 0;
  my $escape = 0;
  my @close_stack = ();
  my %closes = ('(' => ')', '<' => '>');

  while (@tokens)
  {
    my $token = shift @tokens;

    next if ($token eq '');

    if ($sq)
    {
      if ($escape)
      {
        $escape = 0;
      }
      elsif ($token eq '\'')
      {
        $sq = 0;
      }
      elsif ($token eq '\\')
      {
        $escape = 1;
      }
    }
    elsif ($dq)
    {
      if ($escape)
      {
        $escape = 0;
      }
      elsif ($token eq '"')
      {
        $dq = 0;
      }
      elsif ($token eq '\\')
      {
        $escape = 1;
      }
    }
    elsif ($token eq '\'')
    {
      $sq = 1;
    }
    elsif ($token eq '"')
    {
      $dq = 1;
    }
    elsif ($token eq '(' or $token eq '<')
    {
      ++$level;
      push @close_stack, $closes{$token};
    }
    elsif ($token eq ')' or $token eq '>')
    {
      my $expected = pop @close_stack;

      if ($expected eq $token)
      {
        --$level;
      }
      else
      {
        return [];
      }
    }
    elsif ($token eq ',' and not $level)
    {
      push @out, $str;
      $str = '';
      next;
    }

    $str .= $token;
  }

  push @out, $str;
  return \@out;
}

sub _type_fixup ($)
{
  my ($type) = @_;

  while ($type =~ /\s+[&*]+/)
  {
    $type =~ s/\s+([*&]+)/$1 /g;
  }
  while ($type =~ /<\S/)
  {
    $type =~ s/<(\S)/< $1/g;
  }
  while ($type =~ /\S>/)
  {
    $type =~ s/(\S)>/$1 >/g;
  }
  $type = Common::Util::string_simplify $type;
}

# - split params with something similar to string_split_commas
# - split every part with `='
# - second part, if defined, is default value
# - from first part take last word - it is parameter name
# - the rest should be a parameter type.
sub parse_params ($)
{
  my ($line) = @_;

  $line =~ s/^\s*\(\s*//;
  $line =~ s/\s*\)\s*$//;

  return [] unless $line;

  my $parts = string_split_func_params ($line);
  my @params = ();

  foreach my $part (@{$parts})
  {
    my @subparts = split ('=', $part);
    my $value = undef;
    my $rest = Common::Util::string_trim $subparts[0];
    my $name = undef;
    my $type = undef;

    if (@subparts > 1)
    {
      $value = join '', $subparts[1 .. @subparts - 1];
    }
    if ($rest =~ /^(.+\W)(\w+)$/)
    {
      $type = $1;
      $name = $2;

      $type = _type_fixup $type;
    }
    else
    {
      return [];
    }

    push @params, {'type' => $type, 'name' => $name, 'value' => $value};
  }
  return \@params;
}

# TODO: Do some basic checks after parsing. For example check
# TODO continued: if there are any parens (to catch a case
# TODO continued: when we want to wrap a method with no
# TODO continued: parameters, but we actually forgot to append
# TODO continued: `()' to method name.
# - start scanning string from its end.
# - string from end of string to last closing paren should be saved as $after
# - string from last closing paren to its opening counterpart should be stored as $params
# - string from opening parent to whitespace should be saved as $name (beware of operator foo!)
# - string at the beginning could be `static', if so then store it in $before, otherwise $before is empty
# - rest of it should be a return type.
sub parse_function_declaration ($)
{
  my ($line) = @_;
  my $before = '';

  $line = Common::Util::string_simplify ($line);

  my @tokens = split /([\s(),"'\\])/, $line;

  # get before
  while (@tokens)
  {
    my $token = shift @tokens;

    next unless ($token);

    $token = Common::Util::string_trim ($token);

    next unless ($token);

    if ($token eq 'static')
    {
      $before = $token;
    }
    else
    {
      unshift @tokens, $token;
    }
    last;
  }

  @tokens = reverse @tokens;

  #get after
  my @after_parts = ();

  while (@tokens)
  {
    my $token = shift @tokens;

    next unless ($token);
    last if ($token eq ')');
    push @after_parts, $token;
  }

  my $after = '';

  if (@after_parts)
  {
    $after = Common::Util::string_trim (join '', reverse @after_parts);
  }
  @after_parts = undef;

  #get params
  my @params_parts = (')');
  my $level = 1;
  my $maybe_dq_change = 0;
  my $dq = 0;
  my $maybe_sq_change = 0;
  my $sq = 0;

  while (@tokens)
  {
    my $token = shift @tokens;

    next unless ($token);
    push @params_parts, $token;
    if ($maybe_dq_change)
    {
      $maybe_dq_change = 0;
      if ($token ne '\\')
      {
        $dq = 0;
        unshift @tokens, $token;
      }
    }
    elsif ($dq)
    {
      if ($token eq '"')
      {
        $maybe_dq_change = 1;
      }
    }
    elsif ($maybe_sq_change)
    {
      $maybe_sq_change = 0;
      if ($token ne '\\')
      {
        $sq = 0;
        unshift @tokens, $token;
      }
    }
    elsif ($sq)
    {
      if ($token eq '\'')
      {
        $maybe_sq_change = 1;
      }
    }
    elsif ($token eq '"')
    {
      $dq = 1;
    }
    elsif ($token eq '\'')
    {
      $sq = 1;
    }
    elsif ($token eq ')')
    {
      ++$level;
    }
    elsif ($token eq '(')
    {
      --$level;
      unless ($level)
      {
        last;
      }
    }
  }

  # TODO: this is probably not what we want for string default values.
  # TODO continued: not sure if we should care about that.
  # TODO continued: if string parameter's default value holds several consecutive whitespaces
  # TODO continued: then those ones are going to be changed into single space.
  my $params = Common::Util::string_trim (join '', reverse @params_parts);

  @params_parts = undef;
  # get rid of whitespaces
  while (@tokens)
  {
    my $token = shift @tokens;

    next unless ($token);

    $token = Common::Util::string_trim ($token);

    next unless ($token);

    unshift @tokens, $token;
    last;
  }

  my @name_parts = ();
  my $try_operator = 0;

# TODO: this part needs testing
  while (@tokens)
  {
    my $token = shift @tokens;

    next unless ($token);

    my $trimmed_token = Common::Util::string_trim ($token);

    if ($try_operator)
    {
      if ($trimmed_token)
      {
        if ($trimmed_token eq 'operator')
        {
          push @name_parts, $trimmed_token . ' ';
        }
        else
        {
          unshift @tokens, $token . ' ';
        }
        last;
      }
    }
    elsif ($trimmed_token)
    {
      push @name_parts, $trimmed_token;
    }
    else
    {
      $try_operator = 1;
    }
  }

  my $name = Common::Util::string_simplify (join '', reverse @name_parts);
  my $ret_type = Common::Util::string_simplify (join '', reverse @tokens);

  $ret_type = _type_fixup $ret_type;
  @name_parts = undef;
  return [$before, $ret_type, $name, $params, $after];
}

sub split_cpp_type_to_sub_types ($)
{
  my ($cpp_type) = @_;
  my @cpp_parts = split '::', $cpp_type;
  my @cpp_sub_types = ();

  for (my $iter = 0; $iter < @cpp_parts; ++$iter)
  {
    my $cpp_sub_type = join '::', @cpp_parts[$iter .. $#cpp_parts];

    push @cpp_sub_types, $cpp_sub_type;
  }

  return \@cpp_sub_types;
}

# prototype needed, because it is recursively called.
sub gen_cpp_types ($$);

sub gen_cpp_types ($$)
{
  my ($all_cpp_types, $flags) = @_;

  if (@{$all_cpp_types} > 0 and $flags != GEN_NONE)
  {
    my $outermost_type = $all_cpp_types->[0];
    my $sub_types = split_cpp_type_to_sub_types ($outermost_type);
    my @gen_types = ();

    if (@{$all_cpp_types} > 1)
    {
      my @further_types = @{$all_cpp_types}[1 .. $#{$all_cpp_types}];
      my $child_sub_types = gen_cpp_types (\@further_types, $flags);

      @further_types = ();
      foreach my $sub_type (@{$sub_types})
      {
        push @gen_types, map { $sub_type . '< ' . $_ . ' >'} @{$child_sub_types};
      }
    }
    else
    {
      push @gen_types, @{$sub_types};
    }

    my @ret_types = ();

    if ($flags & GEN_NORMAL == GEN_NORMAL)
    {
      push @ret_types, @gen_types;
    }
    if ($flags & GEN_REF == GEN_REF)
    {
      push @ret_types, map { $_ . '&' } @gen_types;
    }
    if ($flags & GEN_PTR == GEN_PTR)
    {
      push @ret_types, map { $_ . '*' } @gen_types;
    }
    if ($flags & GEN_CONST == GEN_CONST)
    {
      push @ret_types, map { 'const ' . $_ } @ret_types;
    }
    return \@ret_types;
  }
  return [];
}

sub get_args ($$)
{
  my ($args, $descs) = @_;
  my %better_descs = ();

  while (my ($desc, $ref) = each %{$descs})
  {
    my $ref_type = undef;

    if ($desc =~ /^(o?)([abs])\(([\w-]+)\)$/)
    {
      my $obsolete = ($1 eq 'o');
      my $type = $2;
      my $param = $3;

      $better_descs{$param} = {'type' => $type, 'ref' => $ref, 'obsolete' => $obsolete};
      $ref_type = (($type eq 'a') ? 'ARRAY' : 'SCALAR');
    }
    else
    {
# TODO: programming error - throw an exception.
      die;
    }
    if (defined $ref and (ref $ref) ne $ref_type)
    {
# TODO: programming error - throw an exception
      die;
    }

  }

  my $errors = [];
  my $warnings = [];

  foreach my $arg (@{$args})
  {
    my ($param, $possible_value) = split /[\s]+/, $arg, 2;

    unless ($param =~ /^[\w-]+$/)
    {
      push @{$errors}, [$param, 'Should contain only alphanumeric characters, underlines and dashes.'];
      next;
    }
    unless (exists $better_descs{$param})
    {
      push @{$errors}, [$param, 'Unknown parameter.'];
      next;
    }

    my $desc = $better_descs{$param};
    my $type = $desc->{'type'};

    if ($desc->{'obsolete'})
    {
      push @{$warnings}, [$param, 'Obsolete parameter.'];
    }

    if (defined $desc->{'value'} and $type ne 'a')
    {
      push @{$errors}, [$param, 'Given twice.'];
      next;
    }

    my $ref = $desc->{'ref'};

    given ($type)
    {
      when ('a')
      {
        unless (defined $possible_value)
        {
          push @{$errors}, [$param, 'Expected value, got nothing.'];
          next;
        }
        push @{$ref}, $possible_value;
      }
      when ('b')
      {
        if (defined $possible_value)
        {
          push @{$errors}, [$param, join '', 'No value expected, got `', $possible_value, '\'.'];
          next;
        }
        ${$ref} = 1;
      }
      when ('s')
      {
        unless (defined $possible_value)
        {
          push @{$errors}, [$param, 'Expected value, got nothing.'];
          next;
        }
        ${$ref} = $possible_value;
      }
    }
  }

  my $results = undef;

  unless (@{$errors})
  {
    $errors = undef;
  }
  unless (@{$warnings})
  {
    $warnings = undef;
  }
  if (defined $errors or defined $warnings)
  {
    $results = [$errors, $warnings];
  }
  return $results;
}

1; # indicate proper module load.
