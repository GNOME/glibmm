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
  'VARIABLE_UNKNOWN' => 'NO_SUCH_VARIABLE_FOR_NOW',
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

sub _append_stuff_to_entries ($$$$$)
{
  my ($self, $type, $stuff, $entries, $is_linked) = @_;

  given ($type)
  {
    when (Common::Sections::Entries::STRING ())
    {
      $entries->append_string ($stuff);
    }
    when (Common::Sections::Entries::SECTION ())
    {
      my $section = $self->_get_section ($stuff);

      if (defined $is_linked)
      {
        $section->set_linked ($is_linked);
      }
      $entries->append_section ($section);
    }
    when (Common::Sections::Entries::CONDITIONAL ())
    {
      my $conditional = $self->_get_conditional ($stuff);

      if (defined $is_linked)
      {
        $conditional->set_linked ($is_linked);
      }
      $entries->append_conditional ($conditional);
    }
    default
    {
      print STDERR 'Wrong type of entry.' . "\n";
      exit 1;
    }
  }
}

sub _get_entries_and_linking_from_section ($$)
{
  my ($self, $section_name) = @_;
  my $section = $self->_get_section ($section_name);

  return ($section->get_entries, $section->is_linked);
}

sub _get_entries_and_linking_from_conditional ($$$)
{
  my ($self, $conditional_name, $bool) = @_;
  my $conditional = $self->_get_conditional ($conditional_name);

  if ($bool)
  {
    $bool = Common::Sections::Conditional::TRUE ();
  }
  else
  {
    $bool = Common::Sections::Conditional::FALSE ();
  }

  return ($conditional->get_entries ($bool), $conditional->is_linked);
}

sub _append_stuff_to_section ($$$$)
{
  my ($self, $type, $stuff, $section_name) = @_;
  my ($entries, $is_linked) = $self->_get_entries_and_linking_from_section ($section_name);

  $self->_append_stuff_to_entries ($type, $stuff, $entries, $is_linked);
}

sub _append_stuff_to_conditional ($$$$$)
{
  my ($self, $type, $stuff, $conditional_name, $bool) = @_;
  my ($entries, $is_linked) = $self->_get_entries_and_linking_from_conditional ($conditional_name, $bool);

  $self->_append_stuff_to_entries ($type, $stuff, $entries, $is_linked);
}

sub _get_entries_stack ($)
{
  my ($self) = @_;

  return $self->{'entries_stack'};
}

sub _push_entry ($$$)
{
  my ($self, $entry, $is_linked) = @_;
  my $entries_stack = $self->_get_entries_stack;

  push @{$entries_stack}, [$entry, $is_linked];
}

sub _append_generic ($$$)
{
  my ($self, $type, $stuff) = @_;
  my $entries_stack = $self->_get_entries_stack;
  my $entry = $entries_stack->[-1];
  my $entries = $entry->[0];
  my $is_linked = $entry->[1];

  $self->_append_stuff_to_entries ($type, $stuff, $entries, $is_linked);
}

sub _get_variables ($)
{
  my ($self) = @_;

  return $self->{'variables'};
}

sub _get_main_sections ($)
{
  my ($self) = @_;

  return $self->{'main_sections'};
}

sub new ($)
{
  my ($type) = @_;
  my $class = (ref $type or $type or 'Common::SectionManager');
  my $main_h_section = Common::Sections::Section->new_main (Common::Sections::H->[0]);
  my $main_cc_section = Common::Sections::Section->new_main (Common::Sections::CC->[0]);
  my $main_p_h_section = Common::Sections::Section->new_main (Common::Sections::P_H->[0]);
  my $main_dev_null_section = Common::Sections::Section->new_main (Common::Sections::DEV_NULL->[0]);

  my $self =
  {
    'main_sections' =>
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
    'variables' => {},
    'entries_stack' => []
  };

  $self = bless $self, $class;

  $self->push_section ($main_dev_null_section->get_name);

  return $self;
}

sub get_variable ($$)
{
  my ($self, $name) = @_;
  my $variables = $self->_get_variables;

  unless (exists $variables->{$name})
  {
    $variables->{$name} = Common::Sections::Conditional::FALSE ();
  }

  return $variables->{$name};
}

sub set_variable ($$$)
{
  my ($self, $name, $value) = @_;
  my $variables = $self->_get_variables;

  if ($value)
  {
    $variables->{$name} = Common::Sections::Conditional::TRUE ();
  }
  else
  {
    $variables->{$name} = Common::Sections::Conditional::FALSE ();
  }
}

sub append_string_to_section ($$$)
{
  my ($self, $string, $target_section_name) = @_;

  $self->_append_stuff_to_section (Common::Sections::Entries::STRING (), $string, $target_section_name);
}

sub append_section_to_section ($$$)
{
  my ($self, $section_name, $target_section_name) = @_;

  $self->_append_stuff_to_section (Common::Sections::Entries::SECTION (), $section_name, $target_section_name);
}

sub append_conditional_to_section ($$$)
{
  my ($self, $conditional_name, $target_section_name) = @_;

  $self->_append_stuff_to_section (Common::Sections::Entries::CONDITIONAL (), $conditional_name, $target_section_name);
}

sub append_string_to_conditional ($$$$)
{
  my ($self, $string, $target_conditional_name, $bool) = @_;

  $self->_append_stuff_to_conditional (Common::Sections::Entries::STRING (), $string, $target_conditional_name, $bool);
}

sub append_section_to_conditional ($$$$)
{
  my ($self, $section_name, $target_conditional_name, $bool) = @_;

  $self->_append_stuff_to_conditional (Common::Sections::Entries::SECTION (), $section_name, $target_conditional_name, $bool);
}

sub append_conditional_to_conditional ($$$$)
{
  my ($self, $conditional_name, $target_conditional_name, $bool) = @_;

  $self->_append_stuff_to_conditional (Common::Sections::Entries::CONDITIONAL (), $conditional_name, $target_conditional_name, $bool);
}

sub set_variable_for_conditional ($$$)
{
  my ($self, $variable_name, $conditional_name) = @_;
  my $conditional = $self->_get_conditional ($conditional_name);

  $conditional->set_variable_name ($variable_name);
}

sub write_main_section_to_file ($$$)
{
  my ($self, $section_constant, $file_name) = @_;
  my $section_name = $section_constant->[0];
  my $main_sections = $self->_get_main_sections;

  unless (exists $main_sections->{$section_name})
  {
    print STDERR 'No such main section: `' . $section_name . '\'.' . "\n";
    exit 1;
  }

  my $fd = IO::File->new ($file_name, 'w');

  unless (defined $fd)
  {
    print STDERR 'Could not open file `' . $file_name . '\' for writing.' . "\n";
    exit 1;
  }

  my $section = $main_sections->{$section_name};
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

sub is_section_linked_to_main_section ($$)
{
  my ($self, $section_name) = @_;
  my $section = $self->_get_section ($section_name);

  return $section->is_linked;
}

sub is_conditional_linked_to_main_section ($$)
{
  my ($self, $conditional_name) = @_;
  my $conditional = $self->_get_conditional ($conditional_name);

  return $conditional->is_linked;
}

sub push_section ($$)
{
  my ($self, $section_name) = @_;
  my ($entries, $is_linked) = $self->_get_entries_and_linking_from_section ($section_name);

  $self->_push_entry ($entries, $is_linked);
}

sub push_conditional ($$$)
{
  my ($self, $conditional_name, $bool) = @_;
  my ($entries, $is_linked) = $self->_get_entries_and_linking_from_conditional ($conditional_name, $bool);

  $self->_push_entry ($entries, $is_linked);
}

sub pop_entry ($)
{
  my ($self) = @_;
  my $entries_stack = $self->_get_entries_stack;

  if (@{$entries_stack} > 1)
  {
    pop @{$entries_stack};
  }
}

sub append_string ($$)
{
  my ($self, $string) = @_;

  $self->_append_generic (Common::Sections::Entries::STRING (), $string);
}

sub append_section ($$)
{
  my ($self, $section) = @_;

  $self->_append_generic (Common::Sections::Entries::SECTION (), $section);
}

sub append_conditional ($$)
{
  my ($self, $conditional) = @_;

  $self->_append_generic (Common::Sections::Entries::CONDITIONAL (), $conditional);
}

1; # indicate proper module load.
