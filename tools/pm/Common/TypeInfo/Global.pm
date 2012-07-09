# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeInfo::Global module
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

package Common::TypeInfo::Global;

use strict;
use warnings;
use v5.10;

use constant
{
# type info sources
  FROM_FILES => 1,
  GENERATED => 2,
  FROM_MODULE_FILES => 3,
# conversion types
  C_CXX => 10,
  CXX_C => 11,
  C_CXX_CONTAINER => 12,
  CXX_C_CONTAINER => 13,
  UNKNOWN => 14
# internal conversion types, do not use
#  SINGLE => 20,
#  C_CXX_CONTAINER_CHECK => 21,
#  CXX_C_CONTAINER_CHECK => 22,
};

use IO::File;

use Common::Util;

use Common::TypeDetails;
use Common::TypeInfo::Common;
use Common::TypeInfo::Convertors;

sub _desired_order ()
{
  return (FROM_MODULE_FILES, GENERATED, FROM_FILES);
}

sub _type_to_string ($)
{
  my ($type) = @_;
  my $name = undef;

  given ($type)
  {
    when (C_CXX)
    {
      $name = 'C to C++';
    }
    when (CXX_C)
    {
      $name = "C++ to C";
    }
    when (C_CXX_CONTAINER)
    {
      $name = "C to C++ (container)";
    }
    when (CXX_C_CONTAINER)
    {
      $name = "C++ to C (container)";
    }
    default
    {
      $name = "invalid";
    }
  }

  return $name;
}

sub _which_to_string ($)
{
  my ($which) = @_;
  my $name = undef;

  given ($which)
  {
    when (FROM_FILES)
    {
      $name = 'from_files';
    }
    when (GENERATED)
    {
      $name = 'generated';
    }
    when (FROM_MODULE_FILES)
    {
      $name = 'from_module_files';
    }
    default
    {
# TODO: throw internal error.
      die;
    }
  }

  return $name;
}

sub _get_c_container_types ($)
{
  my ($self) = @_;

  return $self->{'c_container_types'};
}

sub _get_cxx_container_types ($)
{
  my ($self) = @_;

  return $self->{'cxx_container_types'};
}

sub _get_cxx_pointer_types ($)
{
  my ($self) = @_;

  return $self->{'cxx_pointer_types'};
}

sub _get_generated_type_infos_basename ($)
{
  my ($self) = @_;
  my $mm_module = $self->_get_mm_module;
  my $basename = join '_', 'type', 'infos', $mm_module, 'generated';

  return $basename;
}

sub _get_generated_type_infos_filename ($)
{
  my ($self) = @_;
  my $include_paths = $self->_get_include_paths;

  unless (@{$include_paths})
  {
# TODO: internal error.
    die;
  }

  my $filename = File::Spec->catfile ($include_paths->[0], $self->_get_generated_type_infos_basename ());

  return $filename;
}

sub _get_specific_conversion ($$$$$$)
{
  my ($self, $which, $from, $to, $transfer, $subst) = @_;
  my $conversions = $self->_get_specific_conversions ($which);
  my $conversion = Common::TypeInfo::Common::get_specific_conversion $conversions,
                                                                     $from,
                                                                     $to,
                                                                     $transfer,
                                                                     $subst;

  return $conversion;
}

sub _get_convertors ($)
{
  my ($self) = @_;

  return $self->{'convertors'};
}

sub _get_meaningful_base ($$$)
{
  my ($self, $value, $option) = @_;
  my $c_container_types = $self->_get_c_container_types ();
  my $cxx_container_types = $self->_get_cxx_container_types ();
  my $cxx_pointer_types = $self->_get_cxx_pointer_types ();
  my $base = $value->get_base ();
  my $done = 0;

  until ($done)
  {
    if (exists ($cxx_container_types->{$base}) or
        exists ($cxx_pointer_types->{$base}))
    {
      my $templates = $value->get_templates ();

      if (@{$templates} > 0)
      {
        $value = $templates->[0]->get_value_details ();
        $base = $value->get_base ();
      }
      else
      {
        $base = undef;
        $done = 1;
      }
    }
    else
    {
      if (exists ($c_container_types->{$base}))
      {
        my $imbue_type = $value->get_imbue_type ();

        if (@{$imbue_type} > 0)
        {
          $base = $imbue_type->[0];
        }
        else
        {
          $base = undef;
        }
      }
      $done = 1;
    }
  }

  return $base;
}

sub _conversion_type ($$$$)
{
  my ($self, $from_details, $to_details, $general_direction) = @_;
  my $conversion_type = UNKNOWN;
  my $cxx_details = undef;
  my $c_details = undef;
  my $container_conversion = UNKNOWN;

  if ($general_direction == C_CXX)
  {
    $c_details = $from_details;
    $cxx_details = $to_details;
    $container_conversion = C_CXX_CONTAINER;
  }
  elsif ($general_direction == CXX_C)
  {
    $c_details = $to_details;
    $cxx_details = $from_details;
    $container_conversion = CXX_C_CONTAINER;
  }

  if ($container_conversion != UNKNOWN)
  {
    my $c_value = $c_details->get_value_details ();
    my $cxx_value = $cxx_details->get_value_details ();
    my $c_base = $c_value->get_base ();
    my $cxx_base = $cxx_value->get_base ();
    my $c_container_types = $self->_get_c_container_types ();
    my $cxx_container_types = $self->_get_cxx_container_types ();
    my $is_a_c_container = exists ($c_container_types->{$c_base});
    my $is_a_cxx_container = exists ($cxx_container_types->{$cxx_base});

    if ($is_a_cxx_container)
    {
      if ($is_a_c_container or $c_details->match_sigil (['*', '**']))
      {
        $conversion_type = $container_conversion;
      }
      else
      {
        $conversion_type = UNKNOWN;
      }
    }
    elsif ($is_a_c_container)
    {
# TODO: should we treat Gtk::Widget** as C++ container type? I
# TODO continued: guess not, just use vector.
      $conversion_type = UNKNOWN;
    }
    else
    {
      $conversion_type = $general_direction;
    }
  }

  return $conversion_type;
}

sub _get_general_conversion ($$$$$$)
{
  my ($self, $which, $from, $to, $transfer, $subst) = @_;
  my $conversions = $self->_get_general_conversions ($which);
  my $from_c_conversions = $conversions->{'c'};
  my $cxx_infos = $conversions->{'cxx'};
  my $from_cxx_conversions = $cxx_infos->{'conversions'};
  my $conversion = undef;
  my $from_details = Common::TypeDetails::disassemble_type ($from);
  my $to_details = Common::TypeDetails::disassemble_type ($to);
  my $conversion_type = undef;
  my $conversion_direction = UNKNOWN;

  foreach my $tuple ([$from_details, $to_details, C_CXX, CXX_C], [$to_details, $from_details, CXX_C, C_CXX])
  {
    my $first_details = $tuple->[0];
    my $second_details = $tuple->[1];
    my $first_value = $first_details->get_value_details ();
    my $second_value = $second_details->get_value_details ();
    my $first_base = $self->_get_meaningful_base ($first_value);
    my $to_conversions = undef;

    next unless (defined ($first_base));

    if (exists ($from_c_conversions->{$first_base}))
    {
      $conversion_direction = $tuple->[2];
      $to_conversions = $from_c_conversions->{$first_base}{'conversions'};
    }
    elsif (exists ($from_cxx_conversions->{$first_base}))
    {
      $conversion_direction = $tuple->[3];
      $to_conversions = $from_cxx_conversions->{$first_base};
    }
    else
    {
      next;
    }

    $conversion_direction = $self->_conversion_type ($from_details, $to_details, $conversion_direction);

    next if ($conversion_direction == UNKNOWN);

    my $second_base = $self->_get_meaningful_base ($second_value);

    if (defined $second_base and exists ($to_conversions->{$second_base}))
    {
      my $temp_conversion_type = $to_conversions->{$second_base};

      if (ref ($temp_conversion_type) eq '')
      {
        $conversion_type = $temp_conversion_type;
        last;
      }
    }
  }

  if (defined $conversion_type)
  {
    my $convertors = $self->_get_convertors;

    if (exists $convertors->{$conversion_type})
    {
      $conversion = $convertors->{$conversion_type}($from_details, $to_details, $transfer, $subst, $conversion_direction);
    }
    else
    {
# TODO: internal error
      die join '', 'Unknown convertor type: `', $conversion_type, '\'.';
    }
  }

  return $conversion;
}

##
## general_conversions = { 'c'   => {
##                                    $c_stuff   => {
##                                                    'mapping'     => $cxx_stuff,
# TODO: that is completely wrong!
##                                                    'conversions' => { $cxx_stuff => $type }
##                                                  }
##                                  },
##                         'cxx' => {
##                                    'mappings'    => { $full_cxx_stuff => $c_stuff },
# TODO: and this too!
##                                    'conversions' => { $cxx_stuff => { $c_stuff => $type }}
##                                  }
##                       }
##
# TODO: This is quite long function. I wonder if it is justified.
sub _add_info_to_general_conversions ($$$$$$$)
{
  my ($self, $c_stuff, $cxx_stuff, $type, $which, $apply_conversion, $apply_mapping) = @_;

  if (not $apply_conversion and not $apply_mapping)
  {
# rather should not happen.
    return;
  }

  my $conversions = $self->_get_general_conversions ($which);
  my $cxx_sub_types = Common::Shared::split_cxx_type_to_sub_types $cxx_stuff;
  my $from_c_conversions = $conversions->{'c'};

  if (exists $from_c_conversions->{$c_stuff})
  {
    my $c_info = $from_c_conversions->{$c_stuff};

    if ($apply_mapping)
    {
      if (not exists ($c_info->{'mapping'}) or not defined ($c_info->{'mapping'}))
      {
        $c_info->{'mapping'} = $cxx_stuff;
      }
    }

    if ($apply_conversion)
    {
      if (exists ($c_info->{'conversions'}))
      {
        my $c_conversions = $c_info->{'conversions'};

        foreach my $cxx_sub_stuff (@{$cxx_sub_types})
        {
          if (exists ($c_conversions->{$cxx_sub_stuff}))
          {
            my $type_or_types = $c_conversions->{$cxx_sub_stuff};
            my $type_or_types_ref = ref ($type_or_types);

            if ($type_or_types_ref eq '')
            {
              if ($type_or_types_ref ne $type)
              {
                $c_conversions->{$cxx_sub_stuff} = [$type_or_types, $type];
              }
            }
            elsif ($type_or_types_ref eq 'ARRAY')
            {
              my $found = 0;

              foreach my $previous_type (@{$type_or_types})
              {
                if ($previous_type eq $type)
                {
                  $found = 1;
                  last;
                }
              }
              unless ($found)
              {
                push @{$type_or_types}, $type;
              }
            }
            else
            {
# TODO: internal error.
              die;
            }
          }
          else
          {
            $c_conversions->{$cxx_sub_stuff} = $type;
          }
        }
      }
      else
      {
        my %temp_conversions = map { $_ => $type } @{$cxx_sub_types};

        $c_info->{'conversions'} = \%temp_conversions;
      }
    }
  }
  else
  {
    my $c_info = {};

    if ($apply_mapping)
    {
      $c_info->{'mapping'} = $cxx_stuff;
    }
    if ($apply_conversion)
    {
      my %temp_conversions = map { $_ => $type } @{$cxx_sub_types};

      $c_info->{'conversions'} = \%temp_conversions;
    }
    $from_c_conversions->{$c_stuff} = $c_info;
  }

  my $cxx_infos = $conversions->{'cxx'};

  if ($apply_mapping)
  {
    my $cxx_mappings = $cxx_infos->{'mappings'};

    if (not exists ($cxx_mappings->{$cxx_stuff}) or not defined ($cxx_mappings->{$cxx_stuff}))
    {
      $cxx_mappings->{$cxx_stuff} = $c_stuff;
    }
  }
  if ($apply_conversion)
  {
    my $from_cxx_conversions = $cxx_infos->{'conversions'};

    foreach my $cxx_sub_stuff (@{$cxx_sub_types})
    {
      if (exists $from_cxx_conversions->{$cxx_sub_stuff})
      {
        my $cxx_conversions = $conversions->{$cxx_sub_stuff};

        if (exists ($cxx_conversions->{$c_stuff}))
        {
          my $type_or_types = $cxx_conversions->{$c_stuff};
          my $type_or_types_ref = ref ($type_or_types);

          if ($type_or_types_ref eq '')
          {
            if ($type_or_types ne $type)
            {
              $cxx_conversions->{$c_stuff} = [$type_or_types, $type];
            }
          }
          elsif ($type_or_types_ref eq 'ARRAY')
          {
            my $found = 0;

            foreach my $previous_type (@{$type_or_types})
            {
              if ($previous_type eq $type)
              {
                $found = 1;
                last;
              }
            }
            unless ($found)
            {
              push (@{$type_or_types}, $type);
            }
          }
          else
          {
# TODO: internal error.
            die;
          }
        }
        else
        {
          $cxx_conversions->{$c_stuff} = $type;
        }
      }
      else
      {
        $from_cxx_conversions->{$cxx_sub_stuff} = { $c_stuff => $type };
      }
    }
  }
}

sub _get_unambiguous_tuples ($)
{
  my ($self) = @_;
  my $conversions = $self->_get_general_conversions (GENERATED)->{'c'};
  my @tuples = ();

  foreach my $c_stuff (sort keys %{$conversions})
  {
    my $c_info = $conversions->{$c_stuff};

    if (exists ($c_info->{'mapping'}) and exists ($c_info->{'conversions'}))
    {
      my $cxx_stuff = $c_info->{'mapping'};

      if (defined ($cxx_stuff) and ref ($cxx_stuff) eq '' and exists ($c_info->{'conversions'}{$cxx_stuff}))
      {
        my $type = $c_info->{'conversions'}{$cxx_stuff};

        if (defined $type and ref ($type) eq '')
        {
          push (@tuples, [$c_stuff, $cxx_stuff, $type]);
        }
      }
    }
  }

  return \@tuples;
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

sub _get_conversions ($$)
{
  my ($self, $which) = @_;

  return $self->{_which_to_string ($which)};
}

sub _get_specific_conversions ($$)
{
  my ($self, $which) = @_;
  my $conversions = $self->_get_conversions ($which);

  return $conversions->{'specific'};
}

sub _get_general_conversions ($$)
{
  my ($self, $which) = @_;
  my $conversions = $self->_get_conversions ($which);

  return $conversions->{'general'};
}
##
## general_conversions = { 'c'   => {
##                                    $c_stuff   => {
##                                                    'mapping'     => $cxx_stuff,
##                                                    'conversions' => { $cxx_stuff => $type }
##                                                  }
##                                  },
##                         'cxx' => {
##                                    'mappings'    => { $full_cxx_stuff => $c_stuff },
##                                    'conversions' => { $cxx_stuff => { $c_stuff => $type }}
##                                  }
##                       }
##
# TODO: move into separate class.
sub _create_hierarchy ()
{
  return
  {
    'general' =>
    {
      'c' => {},
      'cxx' =>
      {
        'mappings' => {},
        'conversions' => {}
      }
    },
    'specific' => {}
  };
}

sub new ($$$)
{
  my ($type, $mm_module, $include_paths) = @_;
  my $class = (ref $type or $type or 'Common::TypeInfo::Global');
  my $c_container_types =
  {
    'GList' => undef,
    'GSList' => undef,
    'GArray' => undef,
    'GByteArray' => undef,
    'GHashTable' => undef
  };
  my $cxx_container_types =
  {
    'std::vector' => undef,
    'vector' => undef,
    'Glib::ArrayHandle' => undef,
    'ArrayHandle' => undef,
    'Glib::ListHandle' => undef,
    'ListHandle' => undef,
    'Glib::SListHandle' => undef,
    'SListHandle' => undef
  };
  my $cxx_pointer_types =
  {
    'Glib::RefPtr' => undef,
    'RefPtr' => undef
  };
  my $self =
  {
    'mm_module' => $mm_module,
    'include_paths' => $include_paths,
    'read_files' => {},
    'c_container_types' => $c_container_types,
    'cxx_container_types' => $cxx_container_types,
    'cxx_pointer_types' => $cxx_pointer_types
  };

  map { $self->{ _which_to_string ($_)} = _create_hierarchy (); } (_desired_order ());
  $self = bless ($self, $class);

  my $convertors =
  {
    'ENUM' => sub { Common::TypeInfo::Convertors::Enum::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'EQUAL' => sub { Common::TypeInfo::Convertors::Equal::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'FUNC' => sub { Common::TypeInfo::Convertors::Func::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'MANUAL' => sub { Common::TypeInfo::Convertors::Manual::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'NORMAL' => sub { Common::TypeInfo::Convertors::Normal::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'REFFED' => sub { Common::TypeInfo::Convertors::Reffed::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'STDSTRING' => sub { Common::TypeInfo::Convertors::StdString::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); },
    'USTRING' => sub { Common::TypeInfo::Convertors::Ustring::convert ($self, $_[0], $_[1], $_[2], $_[3], $_[4]); }
  };

  $self->{'convertors'} = $convertors;

  return $self;
}

sub register_convertor ($$$)
{
  my ($self, $conversion_type, $convertor) = @_;
  my $convertors = $self->_get_convertors;

  if (exists $convertors->{$conversion_type})
  {
    die;
  }
  $convertors->{$conversion_type} = $convertor;
}

sub add_generated_info ($$$$)
{
  my ($self, $c_stuff, $cxx_stuff, $type) = @_;
  my $apply_conversion = 1;
  my $apply_mapping = 1;

  $self->_add_info_to_general_conversions ($c_stuff, $cxx_stuff, $type, GENERATED, $apply_conversion, $apply_mapping);
}

sub c_to_cxx ($$)
{
  my ($self, $c_stuff) = @_;

  foreach my $which (_desired_order ())
  {
    my $from_c_conversions = $self->_get_general_conversions ($which)->{'c'};

    if (exists ($from_c_conversions->{$c_stuff}))
    {
      my $c_info = $from_c_conversions->{$c_stuff};

      if (exists $c_info->{'mapping'})
      {
        my $mapping = $c_info->{'mapping'};

        if (defined ($mapping))
        {
          return $mapping;
        }
      }
    }
  }

  return undef;
}

sub cxx_to_c ($$)
{
  my ($self, $cxx_stuff) = @_;

  foreach my $which (_desired_order ())
  {
    my $cxx_mappings = $self->_get_general_conversions ($which)->{'cxx'}{'mappings'};

    if (exists ($cxx_mappings->{$cxx_stuff}))
    {
      my $mapping = $cxx_mappings->{$cxx_stuff};

      if (defined ($mapping))
      {
        return $mapping;
      }
    }
  }

  return undef;
}

sub get_conversion ($$$$$)
{
  my ($self, $from, $to, $transfer, $subst) = @_;

  foreach my $type (_desired_order ())
  {
    foreach my $method (\&_get_specific_conversion, \&_get_general_conversion)
    {
      my $conversion = $self->$method ($type,
                                       $from,
                                       $to,
                                       $transfer,
                                       $subst);

      if (defined $conversion)
      {
        return $conversion;
      }
    }
  }

  return undef;
}

sub add_infos_from_file ($$)
{
  my ($self, $basename) = @_;
  my $generated_type_infos_filename = $self->_get_generated_type_infos_basename;

  # Do not even try to look for file that is going to be generated
  # at the end. Yeah, we make such basename reserved.
  if ($basename ne $generated_type_infos_filename)
  {
    my $include_paths = $self->_get_include_paths;
    my $read_files = $self->_get_read_files;
    my $found = 0;
    my $target = FROM_MODULE_FILES;

    foreach my $path (@{$include_paths})
    {
      my $inc_filename = File::Spec->catfile ($path, $basename);

      if (-f $inc_filename and -r $inc_filename)
      {
        $found = 1;

        unless (exists $read_files->{$inc_filename})
        {
          my $fd = IO::File->new ($inc_filename, 'r');

          $read_files->{$inc_filename} = undef;
          unless (defined $fd)
          {
# TODO: throw an error
            die 'Could not open file `' . $inc_filename . '\' for reading.' . "\n";
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
            $line =~ s/^\s*#.*//;
            $line = Common::Util::string_trim $line;

            next if (not defined $line or $line eq '');

            if ($expect_brace)
            {
              if ($line ne '{')
              {
# TODO: parsing error - expected opening brace only in line.
                die;
              }
              $expect_brace = 0;
            }
            elsif (defined $from and defined $to)
            {
              if ($line =~ /^\s*(\w+)\s*:\s*(.*)$/)
              {
                my $transfer_str = $1;
                my $transfer = $2;
                my $index = Common::TypeInfo::Common::transfer_from_string $transfer_str;

# TODO: parsing error - wrong transfer name.
                die if ($index == Common::TypeInfo::Common::TRANSFER_INVALID);
                if (defined $transfers->[$index])
                {
# TODO: parsing error - that transfer is already defined.
                  die;
                }

                $transfers->[$index] = $transfer;
              }
              elsif ($line eq '}')
              {
                my $added = 0;

                foreach my $transfer_type (Common::TypeInfo::Common::transfer_good_range)
                {
                  if (defined $transfers->[$transfer_type])
                  {
                    my $conversions = $self->_get_specific_conversions ($target);

                    $added = 1;
                    Common::TypeInfo::Common::add_specific_conversion ($conversions,
                                                                       $from,
                                                                       $to,
                                                                       $transfers->[Common::TypeInfo::Common::TRANSFER_NONE],
                                                                       $transfers->[Common::TypeInfo::Common::TRANSFER_CONTAINER],
                                                                       $transfers->[Common::TypeInfo::Common::TRANSFER_FULL]);
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
              $from = Common::Shared::_type_fixup ($1);
              $to = Common::Shared::_type_fixup ($2);
              $expect_brace = 1;
            }
            elsif ($line =~ /^(.+?)\s*<=>\s*(.+?)\s*##\s*(.+?)$/)
            {
              my $c_stuff = $1;
              my $cxx_stuff = $2;
              my $type = $3;
              my $apply_conversion = 1;
              my $apply_mapping = 1;

              $self->_add_info_to_general_conversions ($c_stuff,
                                                       $cxx_stuff,
                                                       $type,
                                                       $target,
                                                       $apply_conversion,
                                                       $apply_mapping);
            }
            elsif ($line =~ /^(.+?)\s*<!>\s*(.+?)\s*##\s*(.+?)$/)
            {
              my $c_stuff = $1;
              my $cxx_stuff = $2;
              my $type = $3;
              my $apply_conversion = 1;
              my $do_not_apply_mapping = 0;

              $self->_add_info_to_general_conversions ($c_stuff,
                                                       $cxx_stuff,
                                                       $type,
                                                       $target,
                                                       $apply_conversion,
                                                       $do_not_apply_mapping);
            }
            elsif ($line =~ /^(.+?)\s*<=>\s*(.+?)$/)
            {
              my $c_stuff = $1;
              my $cxx_stuff = $2;
              my $do_not_apply_conversion = 0;
              my $apply_mapping = 1;

              $self->_add_info_to_general_conversions ($c_stuff,
                                                       $cxx_stuff,
                                                       undef,
                                                       $target,
                                                       $do_not_apply_conversion,
                                                       $apply_mapping);
            }
            elsif ($line =~ /^include\s+(\S+)$/)
            {
              my $inc_basename = $1;

              $self->add_infos_from_file ($inc_basename);
            }
            else
            {
# TODO: do proper logging.
            }
          }
        }
        last;
      }
      $target = FROM_FILES;
    }
    unless ($found)
    {
# TODO: throw an error.
      my $message = 'Could not find `' . $basename . "' in following paths:\n";
      foreach my $inc (@{$include_paths})
      {
        $message .= "$inc\n";
      }
      die $message;
    }
  }
}

sub write_generated_infos_to_file ($)
{
  my ($self) = @_;
  my $filename = $self->_get_generated_type_infos_filename;
  my $fd = IO::File->new ($filename, 'w');

  unless (defined $fd)
  {
# TODO: do proper logging.
    print STDERR 'Could not open file `' . $filename . '\' for writing.' . "\n";
    exit 1;
  }

  $fd->print (join "\n",
              '# $(C stuff) <=> $(C++ stuff) ## $(conversion type)',
              '# LIKE: GtkWidget <=> Gtk::Widget ## NORMAL',
              '# OR',
              '# $(C stuff) <=> $(C++ stuff)',
              '# LIKE: GFileAttributeInfo <=> Gio::FileAttributeInfo',
              '# OR',
              '# $(from) => $(to):',
              '# {',
              '#   none: $(none conversion)',
              '#   container: $(container conversion)',
              '#   full: $(full conversion)',
              '# }',
              '# LIKE: const Glib::RefPtr< Gio::Emblem > => GEmblem*:',
              '#       {',
              '#         none: Glib::unwrap(##ARG##)',
              '#         full: Glib::unwrap_copy(##ARG##)',
              '#       }',
              '# all of none, container and full are optional, but at least one of them must be',
              '# specified',
              '#',
              '');

  my $c_cxx_tuples = $self->_get_unambiguous_tuples;

  foreach my $tuple (@{$c_cxx_tuples})
  {
    my $c_stuff = $tuple->[0];
    my $cxx_stuff = $tuple->[1];
    my $type = $tuple->[2];

    $fd->print (join '', $c_stuff, ' <=> ', $cxx_stuff, ' ## ', $type, "\n");
  }

  my $conversions = $self->_get_specific_conversions (GENERATED);

  foreach my $from (sort keys %{$conversions})
  {
    my $to_convs = $conversions->{$from};

    foreach my $to (sort keys %{$to_convs})
    {
      my $transfers = $to_convs->{$to};

      $fd->print (join '', $from, ' => ', $to, ':', "\n", '{', "\n");

      foreach my $transfer_type (Common::TypeInfo::Common::transfer_good_range)
      {
        my $transfer = $transfers->[$transfer_type];

        if (defined $transfer)
        {
          $fd->print (join '', '  ', (Common::TypeInfo::Common::transfer_to_string $transfer_type), ': ', $transfer, "\n");
        }
      }

      $fd->print (join '', '}', "\n\n");
    }
  }

  $fd->close;
}

1; # indicate proper module load.
