#!/usr/bin/perl
#
# Copyright (C) 2010 The gtkmm Development Team
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
# This script just fixes automatically generated defs files. It does not
# override single line defs. To override a def a first two lines of the def
# and its override must match. See gtk_signals.defs and gtk_defs.overrides
# in gtkmm's gtk/src/gtk directory.
#
# Usage: defs_fixer.pl defs overrides
#
use strict;
use warnings;
use IO::File;

sub main ();
sub read_file ($);
sub override ($$);
sub get_header($);
sub get_quoted_text ($);
sub write_file ($$);
sub get_end_token_index ($$);

main ();

sub main ()
{
  if (@ARGV != 2)
  {
    print STDERR "usage: defs_fixer.pl defs_file override_file\n";
    exit 1;
  }

  my $defs_a_r = read_file ($ARGV[0]);
  my $overrides_a_r = read_file ($ARGV[1]);

  unless (@{$defs_a_r})
  {
    print STDERR join ('', $ARGV[0], 'holds no tokens.', "\n");
    exit 1;
  }

  unless (@{$overrides_a_r})
  {
    print STDERR join ('', $ARGV[1], 'holds no tokens.', "\n");
    exit 1;
  }

  if (override ($defs_a_r, $overrides_a_r))
  {
    write_file ($ARGV[0], $defs_a_r);
  }
  else
  {
    print STDOUT "Nothing to fix.\n";
  }
  exit 0;
}

sub read_file($)
{
  my $buf_a_r = [];
  my $path = shift;
  my $file = IO::File->new ($path, 'r');

  unless (defined ($file))
  {
    print STDERR join ('', 'Failed to open file: ', $path, "\n");
    exit 1;
  }

  @{$buf_a_r} = <$file>;
  $file->close ();
  return $buf_a_r;
}

sub override($$)
{
  my $defs_a_r = shift;
  my $overrides_a_r = shift;
  my $defs_index = 0;
  my $anything_changed = 0;

  for (my $defs_index = 0; $defs_index < @{$defs_a_r}; ++$defs_index)
  {
    my $def = $defs_a_r->[$defs_index];
    my $def_header = get_header ($def);

    if ($def_header ne '<!>')
    {
      my $overrides_index = 0;

      for (my $overrides_index = 0; $overrides_index < @{$overrides_a_r}; ++$overrides_index)
      {
        my $override = $overrides_a_r->[$overrides_index];
        my $override_header = get_header ($override);

        if ($override_header ne '<!>')
        {
          if ($def_header eq $override_header
              and $defs_index + 1 < @{$defs_a_r}
              and $overrides_index + 1 < @{$overrides_a_r}
              and $defs_a_r->[$defs_index + 1] eq $overrides_a_r->[$overrides_index + 1]
             )
          {
            my $defs_end_index = get_end_token_index ($defs_a_r, $defs_index);
            my $overrides_end_index = get_end_token_index ($overrides_a_r, $overrides_index);
            # replace a def with override
            splice (@{$defs_a_r}, $defs_index, $defs_end_index - $defs_index, @{$overrides_a_r}[$overrides_index .. $overrides_end_index - 1]);
            # remove an override from overrides
            splice (@{$overrides_a_r}, $overrides_index, $overrides_end_index - $overrides_index);
            print join ('', 'Fixed \'', $def_header, '\' (', get_quoted_text ($defs_a_r->[$defs_index + 1]), ").\n");
            $anything_changed = 1;
            last;
          }
        }
      }
    }
  }
  return $anything_changed;
}

sub get_header ($)
{
  my $token = shift;
  # we do not care about single line defs - they do not happen in generated
  # defs, so we mark them as <!>.
  if ($token =~ /^\((\S+\s+\S+[^)])\n$/)
  {
    my $header = $1;
    $header =~ s/\s+/ /g;
    return $header;
  }
  return '<!>';
}

sub get_quoted_text ($)
{
  my $line = shift;

  if ($line =~ /"([^"]*)"/)
  {
    return $1;
  }
  return "null";
}

sub write_file ($$)
{
  my $path = shift;
  my $defs_a_r = shift;
  my $file = IO::File->new ($path, 'w');

  unless (defined ($file))
  {
    print STDERR join ('', 'Failed to open file for writing: ', $path, "\n");
    exit 1;
  }

  for my $def (@{$defs_a_r})
  {
    print $file $def;
  }
}

# returns an index that is one past the def.
sub get_end_token_index ($$)
{
  my $lines_a_r = shift;
  my $start_index = shift;

  for (my $iter = $start_index; $iter < @{$lines_a_r}; ++$iter)
  {
    if ($lines_a_r->[$iter] eq ")\n")
    {
      return $iter + 1;
    }
  }
  return 0 + @{$lines_a_r};
}
