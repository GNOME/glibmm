# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapParser module
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

package Common::SectionManager;

use strict;
use warnings;
use feature ':5.10';

use Common::Sections::Entries;
use Common::Sections::Section;
use Common::Sections::Conditional;
use constant
{
  'SECTION_H' => 'SECTION_MAIN_H',
  'SECTION_CC' => 'SECTION_MAIN_CC',
  'SECTION_P_H' => 'SECTION_MAIN_P_H',
  'SECTION_DEV_NULL' => 'SECTION_MAIN_DEV_NULL',
  'VARIABLE_UNKNOWN' => 'NO_SUCH_VARIABLE_FOR_NOW'
};

sub _get_section ($$)
{
  my ($self, $section_name) = @_;
  my $all_sections = $self->{'all_sections'};

  unless (exists $all_sections->{$section_name})
  {
    $all_sections->{$section_name} = Common::Sections::Section->new ($section_name);
  }

  return $all_sections->{$section_name}
}

sub _get_conditional ($$)
{
  my ($self, $conditional_name) = @_;
  my $conditionals = $self->{'conditionals'};

  unless (exists $conditionals->{$conditional_name})
  {
    $conditionals->{$conditional_name} = Common::Sections::Conditional->new ($conditional_name, VARIABLE_UNKNOWN);
  }

  return $conditionals->{$conditional_name};
}

sub _append_stuff_to_entries ($$$$)
{
  my ($self, $type, $stuff, $entries) = @_;

  given ($type)
  {
    when (Common::Sections::Entries::STRING ())
    {
      $entries->append_string ($stuff);
    }
    when (Common::Sections::Entries::SECTION ())
    {
      my $section = $self->_get_section ($stuff);

      $entries->append_section ($section);
    }
    when (Common::Sections::Entries::CONDITIONAL ())
    {
      my $conditional = $self->_get_conditional ($stuff);

      $entries->append_conditional ($conditional);
    }
    default
    {
      print STDERR 'Wrong type of entry.' . "\n";
      exit 1;
    }
  }
}

sub _append_stuff_to_section ($$$$)
{
  my ($self, $type, $stuff, $section_name) = @_;
  my $section = $self->_get_section ($section_name);
  my $entries = $section->get_entries;

  $self->append_stuff_to_entries ($type, $stuff, $entries);
}

sub _append_stuff_to_conditional ($$$$$)
{
  my ($self, $type, $stuff, $conditional_name, $bool) = @_;

  if ($bool)
  {
    $bool = Common::Sections::Entries::TRUE ();
  }
  else
  {
    $bool = Common::Sections::Entries::FALSE ();
  }

  my $conditional = $self->_get_conditional ($conditional_name);
  my $entries = $conditional->get_entries ($bool);

  $self->append_stuff_to_entries ($type, $stuff, $entries);
}

sub new ($)
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'Common::SectionManager');
  my $main_h_section = Common::Sections::Section->new (SECTION_H);
  my $main_cc_section = Common::Sections::Section->new (SECTION_CC);
  my $main_p_h_section = Common::Sections::Section->new (SECTION_P_H);
  my $main_dev_null_section = Common::Sections::Section->new (SECTION_DEV_NULL);
  my $self =
  {
    'toplevel_sections' =>
    {
      $main_h_section->get_name => $main_h_section,
      $main_cc_section->get_name => $main_cc_section,
      $main_p_h_section->get_name => $main_p_h_section,
      $main_dev_null_section->get_name => $main_dev_null_section
    },
    'all_sections' =>
    {
      $main_h_section->get_name => $main_h_section,
      $main_cc_section->get_name => $main_cc_section,
      $main_p_h_section->get_name => $main_p_h_section,
      $main_dev_null_section->get_name => $main_dev_null_section
    },
    'conditionals' => {},
    'variables' => {}
  };

  return bless $self, $class;
}

sub get_variable ($$)
{
  my ($self, $name) = @_;
  my $variables = $self->{'variables'};

  unless (exists $variables->{$name})
  {
    $variables->{$name} = Common::Sections::Conditional::FALSE ();
  }

  return $variables->{$name};
}

sub set_variable ($$$)
{
  my ($self, $name, $value) = @_;
  my $variables = $self->{'variables'};

  if ($value)
  {
    $variables->{$name} = Common::Sections::Conditional::TRUE ();
  }
  else
  {
    $variables->{$name} = Common::Sections::Conditional::FALSE ();
  }
}

##
## string, section name
##
sub append_string_to_section ($$$)
{
  shift->_append_stuff_to_section (Common::Sections::Entries::STRING (), shift, shift);
}

##
## section name, section name
##
sub append_section_to_section ($$$)
{
  shift->_append_stuff_to_section (Common::Sections::Entries::SECTION (), shift, shift);
}

##
## conditional name, section name
##
sub append_conditional_to_section ($$$)
{
  shift->_append_stuff_to_section (Common::Sections::Entries::CONDITIONAL (), shift, shift);
}

##
## string, conditional name, bool value
##
sub append_string_to_conditional ($$$$)
{
  shift->_append_stuff_to_conditional (Common::Sections::Entries::STRING (), shift, shift, shift);
}

##
## section name, conditional name, bool value
##
sub append_section_to_conditional ($$$$)
{
  shift->_append_stuff_to_conditional (Common::Sections::Entries::SECTION (), shift, shift, shift);
}

##
## conditional name, conditional name, bool value
##
sub append_conditional_to_conditional ($$$$)
{
  shift->_append_stuff_to_conditional (Common::Sections::Entries::CONDITIONAL (), shift, shift, shift);
}

sub set_variable_for_conditional ($$$)
{
  my ($self, $variable_name, $conditional_name) = @_;
  my $conditional = $self->_get_conditional ($conditional_name);

  $conditional->set_variable_name ($variable_name);
}

sub write_main_section_to_file ($$$)
{
  my ($self, $section_name, $file_name) = @_;
  my $toplevel_sections = $self->{'toplevel_sections'};

  unless (exists $toplevel_sections->{$section_name})
  {
    print STDERR 'No such toplevel section: `' . $section_name . '\'.';
    exit 1;
  }

  my $fd = IO::File->new ($file_name, 'w');

  unless (defined $fd)
  {
    print STDERR 'Could not open file `' . $file_name . '\' for writing.' . "\n";
    exit 1;
  }

  my $section = $toplevel_sections->{$section_name};
  my $entries = $section->get_entries;

  for (my $iter = 0; $iter < @{$entries}; ++$iter)
  {
    my $pair = $entries->[$iter];
    my $type = $pair->[0];
    my $entry = $pair->[1];

    given ($type)
    {
      when (Common::Sections::Entries::STRING ())
      {
        $fd->print ($entry);
      }
      when (Common::Sections::Entries::SECTION ())
      {
        my $new_entries = $entry->get_entries;

        if (@{$new_entries})
        {
          splice @{$entries}, $iter, 1, @{$new_entries};
          $entry->clear;
          redo;
        }
      }
      when (Common::Sections::Entries::CONDITIONAL ())
      {
        my $new_entries = $entry->get_entries ($self->get_variable ($entry->get_variable_name));

        if (@{$new_entries})
        {
          splice @{$entries}, $iter, 1, @{$new_entries};
          $entry->clear;
          redo;
        }
      }
      default
      {
        print STDERR 'Unknown type of entry in section.' . "\n";
        exit 1;
      }
    }
  }
  $section->clear;
  $fd->close;
}

1; # indicate proper module load.
