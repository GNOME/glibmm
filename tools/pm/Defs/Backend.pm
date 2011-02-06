# gmmproc - Defs::Backend module
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

package Defs::Backend;

use strict;
use warnings;

# class Defs::Backend
# {
#   function array get_methods ();
#   property array get_properties ();
#   function array get_signals ();
#
#   enum lookup_enum(c_type)
#   object lookup_object(c_name)
#   function lookup_method(c_name)
#   function lookup_function(c_name)
#   property lookup_property(object, c_name)
#   function lookup_signal(object, c_name)
# }

# token description members
my $gi_l_n = 'internal_line_number';
my $gi_t = 'internal_token';

sub split_tokens ($)
{
  my $token_string = shift;
  my $tokens_a_r = [];
  # whether we are inside double quotes.
  my $inside_dquotes = 0;
  # whether we are inside double and then single quotes (for situations like
  # "'"'").
  my $inside_squotes = 0;
  # number of yet unpaired opening parens.
  my $parens = 0;
  # length of token string
  my $len = length ($token_string);
  # whether previous char was a backslash - important only when being between
  # double quotes.
  my $backslash = 0;
  # index of first opening paren - beginning of a new token.
  my $begin_token = 0;
  # current line number
  my $line_number = 1;
  # current token line number
  my $token_line_number = 1;

  for (my $index = 0; $index < $len; ++$index)
  {
    my $char = substr ($token_string, $index, 1);
    # if we are inside double quotes.
    if ($char eq "\n")
    {
      ++$line_number;
    }
    elsif ($inside_dquotes)
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
      # ones - means, we are going outside string.
      elsif ($char eq '"' and not $inside_squotes)
      {
        $inside_dquotes = 0;
      }
      # if current char is unescaped single quote, then we have two cases:
      # 1. it just plain apostrophe.
      # 2. it is a piece of a C code:
      #  a) opening quotes,
      #  b) closing quotes.
      # if there is near (2 or 3 indexes away) second quote, then it is 2a,
      # if 2a occured earlier, then it is 2b.
      # otherwise is 1.
      elsif ($char eq '\'')
      {
        # if we are already inside single quotes, it is 2b.
        if ($inside_squotes)
        {
          $inside_squotes = 0;
        }
        else
        {
          # if there is closing quotes near, it is 2a.
          if (substr ($token_string, $index, 4) =~ /^'\\?.'/)
          {
            $inside_squotes = 1;
          }
          # else it is just 1.
        }
      }
    }
    # double quotes - beginning of a string.
    elsif ($char eq '"')
    {
      $inside_dquotes = 1;
    }
    # opening paren - if paren count is 0 then this is a beginning of a token.
    elsif ($char eq '(')
    {
      unless ($parens)
      {
        $begin_token = $index;
        $token_line_number = $line_number;
      }
      $parens++;
    }
    # closing paren - if paren count is 1 then this is an end of a token, so we
    # extract it from token string and push into token list.
    elsif ($char eq ')')
    {
      $parens--;
      unless ($parens)
      {
        my $token_len = $index + 1 - $begin_token;
        my $token = substr ($token_string, $begin_token, $token_len);

        $token =~ s/\s+/ /g;
        push (@{$tokens_a_r}, { $gi_l_n => $token_line_number, $gi_t => $token });
      }
    }
    # do nothing on other chars.
  }
  return $tokens_a_r;
}

sub get_contents ($)
{
  my $file = shift;
  my $fd = IO::File->new ($file, 'r');
  my @buf = ();

  while (my $line = <$fd>)
  {
     $line =~ s/^;.*$//; # remove comments
     push (@buf, $line);
  }
  $fd->close ();

  my $contents = join('', @buf);

  # simplify multiple tabs and spaces into one space, but preserve newlines
  # for line number purposes.
  $contents =~ s/[\ \t\r\f]+/ /g;
  return $contents;
}

# member names
my $g_i_p = 'include_paths';
my $g_e = 'enums';
my $g_o = 'objects';
my $g_m = 'methods';
my $g_s = 'signals';
my $g_p = 'properties';
my $g_a_r_f = 'already_read_files';

sub new ($$)
{
  my $type = shift;
  my $include_paths_a_r = shift;
  my $class = (ref ($type) or $type or "Defs::Backend");
  my $self =
  {
    $g_i_p => $include_paths_a_r,
    $g_e => {},
    $g_o => {},
    $g_m => {},
    $g_s => {},
    $g_p => {},
    $g_a_r_f => {}
  };

  bless ($self, $class);
  return $self;
}

sub read_file ($$)
{
  my $self = shift;
  my $file = shift;
  my $real_path = '';

  for my $path (@{$self->{$g_i_p}})
  {
    my $temp_path = join ('/', $path, $file);

    if (-r $temp_path)
    {
      $real_path = $temp_path;
      last;
    }
  }
  unless ($real_path)
  {
    print STDERR join (' ', 'Could not find file', $file, 'in paths:', join (':', @{$self->{$g_i_p}}), "\n");
    return 0;
  }

  if (exists ($self->{$g_a_r_f}{$real_path}))
  {
    return 1;
  }
  ${self}->{$g_a_r_f}{$real_path} = 1;

  my $tokens_a_r = split_tokens (get_contents ($real_path));

  # scan through top level tokens
  for my $token_description (@{$tokens_a_r})
  {
    my $token = $token_description->{$gi_t};

    next if ($token =~ /^\s*$/);

    if ($token =~ /\(include (\S+)\)/)
    {
      unless ($self->read_file ($1))
      {
        return 0;
      }
      next;
    }
    elsif ($token =~ /^\(define-flags-extended.*\)$/)
    { $self->on_enum ($token); }
    elsif ($token =~ /^\(define-enum-extended.*\)$/)
    { $self->on_enum ($token); }
    elsif ($token =~ /^\(define-flags.*\)$/)
    { }
    elsif ($token =~ /^\(define-enum.*\)$/)
    { }
    elsif ($token =~ /^\(define-object.*\)$/)
    { $self->on_object ($token); }
    elsif ($token =~ /^\(define-function.*\)$/)
    { $self->on_function ($token); }
    elsif ($token =~ /^\(define-method.*\)$/)
    { $self->on_method ($token); }
    elsif ($token =~ /^\(define-property.*\)$/)
    { $self->on_property ($token); }
    elsif ($token =~ /^\(define-signal.*\)$/)
    { $self->on_signal ($token);  }
    elsif ($token =~ /^\(define-vfunc.*\)$/)
    { $self->on_vfunc ($token); }
    else
    {
      my $line_number = $token_description->{$gi_l_n};

      if ($token =~ /^\(define-(\S+) (\S+)/)
      {
        print STDERR join (' ', 'Unknown lisp definition for', $1, $2, 'at line:', $line_number, "\n");
        return 0;
      }
      else
      {
        print STDERR join ('', 'Unknown token at line: ', $line_number, "\n", $token, "\n");
        return 0;
      }
    }
  }

  return 1;
}

sub get_enums ($)
{
  my $self = shift;

  return [];
}

sub get_methods ($)
{
  my $self = shift;

  return [];
}

sub get_signals ($)
{
  my $self = shift;

  return [];
}

sub get_properties ($)
{
  my $self = shift;

  return [];
}

sub get_objects ($)
{
  my $self = shift;

  return [];
}

sub get_functions ($)
{
  my $self = shift;

  return [];
}

sub get_marked ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_methods ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_signals ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_properties ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_objects ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_enums ($)
{
  my $self = shift;

  return [];
}

sub get_unwrapped_functions ($)
{
  my $self = shift;

  return [];
}

sub lookup_enum ($$)
{
  my $self = shift;
  my $c_name = shift;

  return undef;
}

sub lookup_object ($$)
{
  my $self = shift;
  my $c_name = shift;

  return undef;
}

sub lookup_property ($$$)
{
  my $self = shift;
  my $object = shift;
  my $name = shift;

  return undef;
}

sub lookup_method ($$)
{
  my $self = shift;
  my $c_name = shift;

  return undef;
}

sub lookup_function ($$)
{
  my $self = shift;
  my $c_name = shift;

  return undef;
}

sub lookup_signal ($$$)
{
  my $self = shift;
  my $object = shift;
  my $name = shift;

  return undef;
}

sub get_outputter_backend ($)
{
  my $self = shift;

  return undef;
}




sub on_enum ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Enum->new ($token);

  $self->{$g_e}{$thing->get_c_name ()} = $thing;
}

sub on_object ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Object->new ($token);

  $self->{$g_o}{$thing->get_c_name ()} = $thing;
}

sub on_function ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Function->new ($token);

  $self->{$g_m}{$thing->get_c_name ()} = $thing;
}

sub on_method ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Function->new ($token);

  $self->{$g_m}{$thing->get_c_name ()} = $thing if ($thing);
}

sub on_property ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Property->new ($token);

  $self->{$g_p}{join ('::', $thing->get_class (), $thing->get_name ())} = $thing;
}

sub on_signal ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Signal->new ($token);

  $self->{$g_s}{join ('::', $thing->get_class (), $thing->get_name ())} = $thing;
}

sub on_vfunc ($$)
{
  my $self = shift;
  my $token = shift;
  my $thing = Defs::Signal->new ($token);

  $self->{$g_s}{join ('::', $thing->get_class (), $thing->get_name ())} = $thing;
}

1; #indicate proper module load.
