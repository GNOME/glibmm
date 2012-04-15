# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Conversions module
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

package Common::ConversionsStore;

use strict;
use warnings;
use feature ':5.10';
use constant
{
  'TRANSFER_INVALID' => -1, # do not use
  'TRANSFER_NONE' => 0,
  'TRANSFER_CONTAINER' => 1,
  'TRANSFER_FULL' => 2,
  'TRANSFER_LAST' => 3 # do not use
};

sub transfer_from_string ($)
{
  my ($string) = @_;

  if ($string eq 'none')
  {
    return TRANSFER_NONE;
  }
  if ($string eq 'container')
  {
    return TRANSFER_CONTAINER;
  }
  if ($string eq 'full')
  {
    return TRANSFER_FULL;
  }
  return TRANSFER_INVALID;
}

sub transfer_to_string ($)
{
  my ($transfer) = @_;

  given ($transfer)
  {
    when (TRANSFER_NONE)
    {
      return 'none';
    }
    when (TRANSFER_CONTAINER)
    {
      return 'container';
    }
    when (TRANSFER_FULL)
    {
      return 'full';
    }
    default
    {
      return 'invalid';
    }
  }
}

sub _new_generic ($$$)
{
  my ($type, $global_store, $generated) = @_;
  my $class = (ref $type or $type or 'Common::ConversionsStore');
  my $self =
  {
    'our' => {},
    'generated' => $generated,
    'other' => $global_store
  };

  return bless $self, $class;
}

sub _get_our ($)
{
  my ($self) = @_;

  return $self->{'our'};
}

sub _get_other ($)
{
  my ($self) = @_;

  return $self->{'other'};
}

sub _get_generated ($)
{
  my ($self) = @_;

  return $self->{'generated'};
}

sub _add_generic ($$$$$$$)
{
  my ($self, $from, $to, $transfer_none, $transfer_container, $transfer_full, $conversions) = @_;
  unless (exists $conversions->{$from})
  {
    $conversions->{$from} = {};
  }

  my $from_conversions = $conversions->{$from};

  unless (exists $from_conversions->{$to})
  {
    $from_conversions->{$to} = [$transfer_none, $transfer_container, $transfer_full];
  }
# TODO: what should be done with duplicates?
}

sub _get_mm_module ($)
{
  my ($self) = @_;

  return $self->{'mm_module'};
}

sub _get_include_paths ($)
{
  my ($self) = @_;

  return $self->{'include_paths'};
}

sub _get_read_files ($)
{
  my ($self) = @_;

  return $self->{'read_files'};
}

sub new_local ($$)
{
  my ($type, $global_store) = @_;

  return _new_generic ($type, $global_store, undef);
}

sub new_global ($$$)
{
  my ($type, $mm_module, $include_paths) = @_;
  my $self =  _new_generic ($type, undef, {});

  $self->{'mm_module'} = $mm_module;
  $self->{'include_paths'} = $include_paths;
  $self->{'read_files'} = {};

  return $self;
}

sub add_new ($$$$$$)
{
  my ($self, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;
  my $conversions = $self->_get_our;

  $self->_add_generic ($from, $to, $transfer_none, $transfer_container, $transfer_full, $conversions);
}

sub add_new_generated ($$$$$$)
{
  my ($self, $from, $to, $transfer_none, $transfer_container, $transfer_full) = @_;
  my $conversions = $self->_get_generated;

# TODO: exception - not usable from local instance.
  die unless defined $conversions;

  $self->_add_generic ($from, $to, $transfer_none, $transfer_container, $transfer_full, $conversions);
}

sub get_conversion ($$$$$)
{
  my ($self, $from, $to, $transfer, $name) = @_;
  my $conversion = undef;

  if ($transfer > TRANSFER_INVALID and $transfer < TRANSFER_LAST)
  {
    my @conversions_table = ($self->_get_our, $self->_get_generated);

    foreach my $conversions (@conversions_table)
    {
      if (defined $conversions and exists $conversions->{$from})
      {
        my $from_conversions = $conversions->{$from};

        if (exists $from_conversions->{$to})
        {
          my $template = undef;

          do
          {
            $template = $from_conversions->{$to}[$transfer];
            --$transfer;
          }
          while (not defined $template and $transfer != TRANSFER_INVALID);

          if (defined $template)
          {
            $template =~ s/##ARG##/$name/g;

            $conversion = $template;
            last;
          }
        }
      }
    }
  }

  unless (defined $conversion)
  {
    my $other = $self->_get_other;

    if (defined $other)
    {
      $conversion = $other->get_conversion ($from, $to, $transfer, $name);
    }
  }
  unless (defined $conversion)
  {
# TODO: Throw an error or something? Or should the lack of
# TODO continued: conversion handled by caller? Rather the
# TODO continued: former.
    die 'Could not find conversion from `' . $from . '\' to `' . $to . '\' with transfer `' . (transfer_to_string $transfer) . '\'.' . "\n";
  }

  return $conversion;
}

sub add_from_file ($$)
{
  my ($self, $basename) = @_;
  my $mm_module = $self->_get_mm_module;

  # Do not even try to look for file that is going to be generated
  # at the end. Yeah, we make such basename reserved.
  if ($basename ne join '_', 'conversions', $mm_module, 'generated')
  {
    my $include_paths = $self->_get_include_paths;
    my $read_files = $self->_get_read_files;

    foreach my $path (@{$include_paths})
    {
      my $inc_filename = File::Spec->catfile ($path, $basename);

      if (-f $inc_filename and -r $inc_filename)
      {
        unless (exists $read_files->{$inc_filename})
        {
          my $fd = IO::File->new ($inc_filename, 'r');

          $read_files->{$inc_filename} = undef;
          unless (defined $fd)
          {
# TODO: throw an error
            print STDERR 'Could not open file `' . $inc_filename . '\' for reading.' . "\n";
            exit 1;
          }

          my @lines = $fd->getlines;
          my $line_num = 0;
          my $from = undef;
          my $to = undef;
          my $transfers = [undef, undef, undef];
          my $expect_brace = 0;

          $fd->close;
          foreach my $line (@lines)
          {
            ++$line_num;
            $line =~ s/\s*#.*//;
            $line = Common::Util::string_trim ($line);
            next unless $line;
            if ($expect_brace)
            {
              unless ($line =~ '^\s*\{\s*$')
              {
# TODO: parsing error - expected opening brace only in line.
                die;
              }
              $expect_brace = 0;
            }
            elsif (defined $from and defined $to)
            {
              if ($line =~ /\s*(\w+)\s*:\s*(.*)$/)
              {
                my $transfer_str = $1;
                my $transfer = $2;
                my $index = transfer_from_string $transfer_str;

# TODO: parsing error - wrong transfer name.
                die if ($index == TRANSFER_INVALID);
                if (defined $transfers->[$index])
                {
# TODO: parsing error - that transfer is already defined.
                  die;
                }

                $transfers->[$index] = $transfer;
              }
              elsif ($line =~ /^\s*\}\s*$/)
              {
                my $added = 0;

                foreach my $transfer_type (TRANSFER_NONE .. TRANSFER_FULL)
                {
                  if (defined $transfers->[$transfer_type])
                  {
                    $added = 1;
                    $self->add_new ($from,
                                    $to,
                                    @{$transfers});
                    last;
                  }
                }
# TODO: parsing error - no transfer specified.
                die unless $added;

                $from = undef;
                $to = undef;
                $transfers = [undef, undef, undef];
              }
            }
            elsif ($line =~ /^(.+?)\s*=>\s*(.+):$/)
            {
              $from = $1;
              $to = $2;
              $expect_brace = 1;
            }
            elsif ($line =~ /^include\s+(\S+)^/)
            {
              my $inc_basename = $1;

              $self->add_from_file ($inc_basename);
            }
            else
            {
              print STDERR $inc_filename . ':' . $line_num . ' - could not parse the line.' . "\n";
            }
          }
        }
        last;
      }
    }
  }
}

sub write_to_file ($)
{
  my ($self) = @_;
  my $conversions = $self->_get_generated;

# TODO: error - not usable from local instance.
  die unless defined $conversions;

  my $include_paths = $self->_get_include_paths;
  my $mm_module = $self->_get_mm_module;

  unless (@{$include_paths})
  {
# TODO: internal error.
    die;
  }

  my $filename = File::Spec->catfile ($include_paths->[0], join '_', 'conversions', $mm_module, 'generated');
  my $fd = IO::File->new ($filename, 'w');

  unless (defined $fd)
  {
# TODO: error.
    die;
  }

  foreach my $from (sort keys %{$conversions})
  {
    my $to_convs = $conversions->{$from};

    foreach my $to (sort keys %{$to_convs})
    {
      my $transfers = $to_convs->{$to};

      $fd->print (join '', $from, ' => ', $to, ':', "\n", '{', "\n");

      foreach my $transfer_type (TRANSFER_NONE .. TRANSFER_FULL)
      {
        my $transfer = $transfers->[$transfer_type];

        if (defined $transfer)
        {
          $fd->print (join '', '  ', (transfer_to_string $transfer_type), ': ', $transfer, "\n");
        }
      }

      $fd->print (join '', '}', "\n\n");
    }
  }
  $fd->close;
}

1; # indicate proper module load.
