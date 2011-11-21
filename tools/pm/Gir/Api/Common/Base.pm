# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
## Copyright 2011 Krzesimir Nowak
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
##

package Gir::Api::Common::Base;

use strict;
use warnings;

##
## protected:
##

##
## Takes group name and member name and tries to retrieve such member from
## a group. Note that asking for a member of nonexistent group is fatal.
## When such member does not exist then undef is returned.
##
sub _get_group_member_by_name ($$$)
{
  my ($self, $group_name, $member_name) = @_;
  my $groups = $self->{'groups'};

  unless (exists ($groups->{$group_name}))
  {
    # TODO: throw error.
    print STDERR 'No such group: ' . $group_name . '.' . "\n";
    exit 1;
  }

  my $group = $groups->{$group_name};
  my $unordered = $group->{'unordered'};

  if (exists ($unordered->{$member_name}))
  {
    return $group->{'ordered'}[$unordered->{$member_name}];
  }
  return undef;
}

##
## Takes group name and index of a member and tries to retrieve a member
## at given index from a group. Note that asking for a member of nonexistent
## group or noexistent index is fatal. This method always returns a valid
## member.
##
sub _get_group_member_by_index ($$$)
{
  my ($self, $group_name, $index) = @_;
  my $groups = $self->{'groups'};

  unless (exists ($groups->{$group_name}))
  {
    # TODO: throw error.
    print STDERR 'No such group: ' . $group_name .  '.' . "\n";
    exit 1;
  }

  my $group = $groups->{$group_name};
  my $ordered = $group->{'ordered'};

  unless ($index < @{$ordered})
  {
    # TODO: throw error.
    print STDERR 'No member under index ' . $index . ' in group ' . $group_name . '.' . "\n";
    exit 1;
  }
  return $ordered->[$index];
}

##
## Takes group name and returns a count of members in the group. Note that asking
## for a count of nonexistent group is fatal. This method always return a correct
## count.
##
sub _get_group_member_count ($$)
{
  my ($self, $group_name) = @_;
  my $groups = $self->{'groups'};

  unless (exists ($groups->{$group_name}))
  {
    # TODO: throw error.
    print STDERR 'No such group: ' . $group_name . '.' . "\n";
    exit 1;
  }

  return @{$groups->{$group_name}{'ordered'}};
}

##
## Takes group name, member name and member itself and puts the member into
## a group. Note that trying to put a member into nonexistent group or trying
## to put a member whose name is already in group is fatal.
##
sub _add_member_to_group ($$$$)
{
  my ($self, $group_name, $member_name, $member) = @_;
  my $groups = $self->{'groups'};

  unless (exists ($groups->{$group_name}))
  {
    # TODO: throw error.
    print STDERR 'No such group: ' . $group_name . '.' . "\n";
    exit 1;
  }

  my $group = $groups->{$group_name};
  my $unordered = $group->{'unordered'};

  if (exists ($unordered->{$member_name}))
  {
    # TODO: throw error.
    print STDERR 'Member ' . $member_name . ' already exists in group: ' . $group_name . '.' . "\n";
    exit 1;
  }

  my $ordered = $group->{'ordered'};
  my $new_index = @{$ordered};

  push (@{$ordered}, $member);
  $unordered->{$member_name} = $new_index;
}

##
## Takes attribute name and tries returns its value. Note that asking for
## a value of nonexistent attribute is fatal.
##
sub _get_attribute ($$)
{
  my ($self, $attribute_name) = @_;
  my $attributes = $self->{'attributes'};

  unless (exists ($attributes->{$attribute_name}))
  {
    # TODO: throw error.
    print STDERR 'No such attribute: ' . $attribute_name . '.' . "\n";
    exit 1;
  }

  return $attributes->{$attribute_name};
}

##
## Takes attribute name and attribute value and sets the value for the name.
## Note that asking for setting a value to nonexistent attribute is fatal.
##
sub _set_attribute ($$$)
{
  my ($self, $attribute_name, $attribute_value) = @_;
  my $attributes = $self->{'attributes'};

  unless (exists ($attributes->{$attribute_name}))
  {
    # TODO: throw error.
    print STDERR 'No such attribute: ' . $attribute_name . '.' . "\n";
    exit 1;
  }

  $attributes->{$attribute_name} = $attribute_value;
}

##
## Takes attribute name and check if this object have such attribute.
##
sub _has_attribute ($$)
{
  my ($self, $attribute_name) = @_;
  my $attributes = $self->{'attributes'};

  return exists ($attributes->{$attribute_name});
}

##
## public:
##

##
## Takes an array of group names and an array of attribute names and creates
## an instance of a class. This is the only method where actual group names
## and attribute names can be set.
##
sub new ($$$)
{
  my ($type, $groups, $attributes) = @_;
  my $class = (ref ($type) or $type or 'Gir::Api::Common::Base');
  my %member_groups = map { $_ => {'ordered' => [], 'unordered' => {}}; } @{$groups};
  my %member_attributes = map { $_ => undef } @{$attributes};
  my $self =
  {
    # group_name => {'ordered' => [{obj1}, {obj2}, ...], 'unordered' => {name_of_obj1 => idx_of_obj1, name_of_obj2 => idx_of_obj2}}
    'groups' => \%member_groups,
    # attribute => value
    'attributes' => \%member_attributes
  };

  bless ($self, $class);
  return $self;
}

1; # indicate proper module load.
