# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfoStore module
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

package Common::TypeInfoStore;

use strict;
use warnings;

use IO::File;

use Common::Util;

sub _add_new_to ($$$$$)
{
  my ($self, $c_stuff, $cpp_stuff, $c_to_cpp, $cpp_to_c) = @_;

  if (exists $c_to_cpp->{$c_stuff})
  {
    my $old_stuff = $c_to_cpp->{$c_stuff};
    my $ref_type = ref $old_stuff;

    if ($ref_type eq 'ARRAY')
    {
      my $found = 0;

      foreach my $stuff (@{$old_stuff})
      {
        if ($stuff eq $cpp_stuff)
        {
          $found = 1;
          last;
        }
      }
      unless ($found)
      {
        push @{$old_stuff}, $cpp_stuff;
      }
    }
    elsif ($ref_type eq '')
    {
      if ($old_stuff ne $cpp_stuff)
      {
        $c_to_cpp->{$c_stuff} = [$old_stuff, $cpp_stuff];
      }
    }
    else
    {
# TODO: throw internal error;
      print STDERR 'Internal error - C->C++ type info should be array or string' . "\n";
      exit 1;
    }
  }
  else
  {
    $c_to_cpp->{$c_stuff} = $cpp_stuff;
  }

  my $cpp_sub_types = Common::Shared::split_cpp_types_to_sub_types $cpp_stuff;

  foreach my $cpp_sub_stuff (@{$cpp_sub_types})
  {
    if (exists $cpp_to_c->{$cpp_sub_stuff})
    {
      my $old_stuff = $cpp_to_c->{$cpp_sub_stuff};
      my $ref_type = ref $old_stuff;

      if ($ref_type eq 'ARRAY')
      {
        my $found = 0;

        foreach my $stuff (@{$old_stuff})
        {
          if ($stuff eq $c_stuff)
          {
            $found = 1;
            last;
          }
        }
        unless ($found)
        {
          push @{$old_stuff}, $c_stuff;
        }
      }
      elsif ($ref_type eq '')
      {
        if ($old_stuff ne $c_stuff)
        {
          $cpp_to_c->{$cpp_sub_stuff} = [$old_stuff, $c_stuff];
        }
      }
      else
      {
# TODO: throw internal error;
        print STDERR 'Internal error - C++->C type info should be array or string' . "\n";
        exit 1;
      }
    }
    else
    {
      $cpp_to_c->{$cpp_sub_stuff} = $c_stuff;
    }
  }
}

sub _get_unambiguous_pairs ($)
{
  my ($self) = @_;
  my $c_to_cpp = $self->{'c_to_cpp'};
  my @pairs = ();

  foreach my $c_stuff (sort keys %{$c_to_cpp})
  {
    my $cpp_stuff = $c_to_cpp->{$c_stuff};
    my $ref_type = ref $cpp_stuff;

    if ($ref_type eq '')
    {
      push @pairs, [$c_stuff, $cpp_stuff];
    }
  }

  return \@pairs;
}

sub _get_stuff_from ($$$)
{
  my ($self, $stuff, $mapping_name) = @_;
  my $mapping = $self->{$mapping_name};

  if (exists $mapping->{$stuff})
  {
    return $mapping->{$stuff};
  }
  else
  {
    my $from_files = $self->{'from_files'};

    $mapping = $from_files->{$mapping_name};
    if (exists $mapping->{$stuff})
    {
      return $mapping->{$stuff};
    }
  }

  return undef;
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

  return $self->get_read_files;
}

sub _get_c_to_cpp ($$)
{
  my ($self, $from_files) = @_;

  if ($from_files)
  {
    return $self->{'from_files'}{'c_to_cpp'};
  }
  return $self->{'c_to_cpp'};
}

sub _get_cpp_to_c ($$)
{
  my ($self, $from_files) = @_;

  if ($from_files)
  {
    return $self->{'from_files'}{'cpp_to_c'};
  }
  return $self->{'cpp_to_c'};
}

sub new ($$$)
{
  my ($type, $mm_module, $include_paths) = @_;
  my $class = (ref $type or $type or 'Common::TypeInfoStore');
  my $self =
  {
    'c_to_cpp' => {},
    'cpp_to_c' => {},
    'from_files' =>
    {
      'c_to_cpp' => {},
      'cpp_to_c' => {}
    },
    'mm_module' => $mm_module,
    'include_paths' => $include_paths,
    'read_files' => {}
  };

  return bless $self, $class;
}

sub add_new ($$$)
{
  my ($self, $c_stuff, $cpp_stuff) = @_;
  my $c_to_cpp = $self->_get_c_to_cpp (0);
  my $cpp_to_c = $self->_get_cpp_to_c (0);

  $self->_add_new_to ($c_stuff, $cpp_stuff, $c_to_cpp, $cpp_to_c);
}

sub c_to_cpp ($$)
{
  my ($self, $c_stuff) = @_;

  return $self->_get_stuff_from ($c_stuff, 'c_to_cpp');
}

sub cpp_to_c ($$)
{
  my ($self, $cpp_stuff) = @_;

  return $self->_get_stuff_from ($cpp_stuff, 'cpp_to_c');
}

sub add_from_file ($$)
{
  my ($self, $basename) = @_;
  my $mm_module = $self->_get_mm_module;

  # Do not even try to look for file that is going to be generated
  # at the end. Yeah, we make such basename reserved.
  if ($basename ne join '_', 'mappings', $mm_module, 'generated')
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
          my $c_to_cpp = $self->_get_c_to_cpp (1);
          my $cpp_to_c = $self->_get_cpp_to_c (1);
          my $line_num = 0;

          $fd->close;
          foreach my $line (@lines)
          {
            ++$line_num;
            $line =~ s/\s*#.*//;
            $line = Common::Util::string_trim ($line);
            if ($line eq '')
            {
              next;
            }
            if ($line =~ /^(\S+)\s*<=>\s*(\S+)$/ or $line =~ /^(\S+)\s*,\s*(\S+)$/)
            {
              my $c_stuff = $1;
              my $cpp_stuff = $2;

              $self->_add_new_to ($c_stuff, $cpp_stuff, $c_to_cpp, $cpp_to_c);
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
  my $include_paths = $self->_get_include_paths;
  my $mm_module = $self->_get_mm_module;

  unless (@{$include_paths})
  {
# TODO: internal error.
    die;
  }

  my $filename = File::Spec->catfile ($include_paths->[0], join '_', 'mappings', $mm_module, 'generated');
  my $fd = IO::File->new ($filename, 'w');

  unless (defined $fd)
  {
    print STDERR 'Could not open file `' . $filename . '\' for writing.' . "\n";
    exit 1;
  }

  my $c_cpp_pairs = $self->_get_unambiguous_pairs;

  foreach my $pair (@{$c_cpp_pairs})
  {
    my $c_stuff = $pair->[0];
    my $cpp_stuff = $pair->[1];

    $fd->print (join '', $c_stuff, ' <=> ', $cpp_stuff, "\n");
  }

  $fd->close;
}

1; # indicate proper module load.
