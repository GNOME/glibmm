#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;
use IO::File;
use v5.12;

my %macros = ();

sub grep_for_possible_macros
{
  my $m4_block = 0;

  foreach my $line (@_)
  {
    my $m4 = 0;

    if ($m4_block or $line =~ /^\s*#m4\b/)
    {
      $m4 = 1;
    }
    elsif ($line =~ /^\s*#m4end\b/)
    {
      $m4 = 1;
      $m4_block = 0;
    }

    while (($m4 and $line =~ /\b([A-Z_]+)\b/) or (not $m4 and $line =~ /\b(_[A-Z_]+)\b/))
    {
      my $macro = $1;

      $macros{$macro} = undef;
      $line =~ s/$macro//g;
    }
  }
}

foreach my $file (@ARGV)
{
  my $fd = IO::File->new ($file, 'r');

  unless (defined ($fd))
  {
    say ('Could not open `' . $file . '.');
  }

  my @lines = $fd->getlines ();

  $fd->close ();
  grep_for_possible_macros (@lines);
}

foreach my $macro (sort (keys (%macros)))
{
  say $macro;
}
