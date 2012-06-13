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

use Common::Util;

sub extract_token ($)
{
  my ($tokens) = @_;
  my $line_change = 0;

  while (@{$tokens})
  {
    my $token = shift @{$tokens};

    if ($token =~ /\n/)
    {
      ++$line_change;
    }

    return [$token, $line_change];
  }

  return [undef, $line_change];
}

sub cleanup_tokens
{
  return grep { defined and $_ ne '' } @_;
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
    return undef if (not $line_change and $token != /^\s+$/);
  }

  my $escape = 0;
  my $sq = 0;
  my $dq = 0;

  # Concatenate until the corresponding ")":
  while (@{$tokens})
  {
    my $result = extract_token $tokens;
    my $token = $result->[0];
    my $add_to_line = $result->[1];

    $line_change += $add_to_line;
    if ($escape)
    {
      # do nothing
      $escape = 0;
    }
    elsif ($sq)
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
    else
    {
      ++$level if ($token eq '(');
      --$level if ($token eq ')');
    }

    return [$str, $line_change] unless $level;
    $str .= $token;
  }

  return undef;
}

sub string_split_commas ($)
{
  my ($in) = @_;
  my @out = ();
  my @tokens = cleanup_tokens (split (/([,()"'\\])/, $in));

  if (@tokens)
  {
    my $level = 0;
    my $str = '';
    my $sq = 0;
    my $dq = 0;
    my $escape = 0;

    while (@tokens)
    {
      my $token = shift @tokens;

      if ($escape)
      {
        # do nothing
        $escape = 0;
      }
      elsif ($sq)
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

    push (@out, Common::Util::string_trim $str);
  }
  return @out;
}

sub string_split_func_params ($)
{
  my ($in) = @_;
  my @out = ();
  my @tokens = cleanup_tokens (split(/([,()"'\\<>{}])/, $in));

  if (@tokens)
  {
    my $level = 0;
    my $str = '';
    my $sq = 0;
    my $dq = 0;
    my $escape = 0;
    my @close_stack = ();
    my %pairs = ('(' => ')', '<' => '>', '{' => '}');
    my @opens = keys (%pairs);
    my @closes = values (%pairs);

    while (@tokens)
    {
      my $token = shift @tokens;

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
      elsif ($token ~~ @opens)
      {
        ++$level;
        push @close_stack, $pairs{$token};
      }
      elsif ($token ~~ @closes)
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
        push @out, Common::Util::string_trim ($str);
        $str = '';
        next;
      }

      $str .= $token;
    }

    push @out, Common::Util::string_trim ($str);
  }
  return \@out;
}

sub _type_fixup ($)
{
  my ($type) = @_;

  # 'int * &' -> 'int*&'
  while ($type =~ /\s+[&*]+/)
  {
    $type =~ s/\s+([&*]+)/$1 /g;
  }
  # vector<int> -> vector< int >
  while ($type =~ /<\S/)
  {
    $type =~ s/<(\S)/< $1/g;
  }
  while ($type =~ /\S>/)
  {
    $type =~ s/(\S)>/$1 >/g;
  }
  # std::vector < int >& -> std::vector< int >&
  while ($type =~ /\w\s+</)
  {
    $type =~ s/(\w)\s+</$1</g;
  }
  # std :: vector -> std::vector
  while ($type =~ /\w\s+::/)
  {
    $type =~ s/(\w)\s+::/$1::/g;
  }
  while ($type =~ /::\s+/)
  {
    $type =~ s/::\s+/::/g;
  }
  # a< b,c,d > -> a< b, c, d >
  while ($type =~ /,\S/)
  {
    $type =~ s/,(\S)/, $1/g;
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
    my $rest = Common::Util::string_trim (shift (@subparts));

    if (@subparts)
    {
      $value = Common::Util::string_trim (join ('', @subparts));
    }
    if ($rest =~ /^(.+?)(\w+)(?:{([^}]+)})?$/)
    {
      my $type = $1;
      my $name = $2;
      my $param = $3;
      my $nullable = 0;
      my $out = 0;

      given ($param)
      {
        when ('?')
        {
          $nullable = 1;
        }
        when (['OUT', 'RET'])
        {
          $out = 1;
        }
        when (undef)
        {
          # That's fine - no {foo} was used at all.
        }
        default
        {
          die '|' . $param . '|';
        }
      }
      $type = _type_fixup $type;

      push (@params,
            {
              'type' => $type,
              'name' => $name,
              'value' => $value,
              'nullable' => $nullable,
              'out' => $out
            });
    }
    else
    {
      return [];
    }
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

  my @tokens = cleanup_tokens (split (/([\s(),"'\\]|\w+)/, $line));

  # get before
  while (@tokens)
  {
    my $token = Common::Util::string_trim (shift (@tokens));

    next if ($token eq '');

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

    if ($token eq ')')
    {
      unshift (@tokens, $token);
      last;
    }
    push @after_parts, $token;
  }

  my $after = '';

  if (@after_parts)
  {
    $after = Common::Util::string_trim (join '', reverse @after_parts);
  }
  @after_parts = undef;

  while (@tokens)
  {
    my $token = Common::Util::string_trim (shift (@tokens));

    if ($token ne '')
    {
      unshift (@tokens, $token);
      last;
    }
  }

  #get params
  my @params_parts = ();
  my $level = 0;
  my $maybe_dq_change = 0;
  my $dq = 0;
  my $maybe_sq_change = 0;
  my $sq = 0;
  my $no_push = 0;

  while (@tokens)
  {
    my $token = shift @tokens;

    if ($no_push)
    {
      $no_push = 0;
    }
    else
    {
      push @params_parts, $token;
    }
    if ($maybe_dq_change)
    {
      $maybe_dq_change = 0;
      if ($token ne '\\')
      {
        $dq = 0;
        $no_push = 1;
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
        $no_push = 1;
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

  my $params = Common::Util::string_trim (join ('', reverse @params_parts));

  @params_parts = undef;
  # get rid of whitespaces
  while (@tokens)
  {
    my $token = Common::Util::string_trim (shift (@tokens));

    next if ($token eq '');

    unshift @tokens, $token;
    last;
  }

  my @name_parts = ();
  my $try_operator = join ('', reverse (@tokens)) =~ /\boperator\b/;

  if ($try_operator)
  {
    while (@tokens)
    {
      my $token = shift (@tokens);

      push (@name_parts, $token);

      last if ($token =~ '\boperator\b');
    }
  }
  else
  {
    if (@tokens)
    {
      push (@name_parts, shift (@tokens));
    }
  }

  my $name = Common::Util::string_simplify (join ('', reverse (@name_parts)));
  my $ret_type = Common::Util::string_simplify (join '', reverse @tokens);

  $ret_type = _type_fixup $ret_type;
  @name_parts = undef;
  return [$before, $ret_type, $name, $params, $after];
}

sub split_cxx_type_to_sub_types ($)
{
  my ($cxx_type) = @_;
  my @cxx_parts = split '::', $cxx_type;
  my @cxx_sub_types = ();

  for (my $iter = 0; $iter < @cxx_parts; ++$iter)
  {
    my $cxx_sub_type = join '::', @cxx_parts[$iter .. $#cxx_parts];

    push @cxx_sub_types, $cxx_sub_type;
  }

  return \@cxx_sub_types;
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
    my ($param, $possible_value) = split /\s+/, $arg, 2;

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
