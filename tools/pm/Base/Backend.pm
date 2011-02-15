# gmmproc - Base::Backend module
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

package Base::Backend;

use strict;
use warnings;
use Base::Exceptions;

# class Base::Backend
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

# public
sub new ($$)
{
  my $type = shift;
  my $class = (ref ($type) or $type or "Base::Backend");
  my $self = {};

  bless ($self, $class);
  return $self;
}

sub read_file ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'read_file ($$) is not implemented.'));
}

sub get_enums ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_enums ($$) is not implemented.'));
}

sub get_methods ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_methods ($$) is not implemented.'));
}

sub get_signals ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_signals ($$) is not implemented.'));
}

sub get_properties ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_properties ($$) is not implemented.'));
}

sub get_objects ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_objects ($$) is not implemented.'));
}

sub get_functions ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_functions ($$) is not implemented.'));
}

sub get_unwrapped_methods ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_methods ($$) is not implemented.'));
}

sub get_unwrapped_signals ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_signals ($$) is not implemented.'));
}

sub get_unwrapped_properties ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_properties ($$) is not implemented.'));
}

sub get_unwrapped_objects ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_objects ($$) is not implemented.'));
}

sub get_unwrapped_enums ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_enums ($$) is not implemented.'));
}

sub get_unwrapped_functions ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_functions ($$) is not implemented.'));
}

sub get_unwrapped_vfuncs ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'get_unwrapped_vfuncs ($$) is not implemented.'));
}

sub lookup_enum ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_enum ($$) is not implemented.'));
}

sub lookup_object ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_object ($$) is not implemented.'));
}

sub lookup_property ($$$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_property ($$) is not implemented.'));
}

sub lookup_method ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_method ($$) is not implemented.'));
}

sub lookup_function ($$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_function ($$) is not implemented.'));
}

sub lookup_signal ($$$)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'lookup_signal ($$) is not implemented.'));
}

sub create_outputter_backend ($)
{
  my $self = shift;
  my $class = ref ($self);

  $Base::Exceptions::not_implemented->throw (error => join ('::', $class, 'create_outputter_backend ($$) is not implemented.'));
}

1; #indicate proper module load.
