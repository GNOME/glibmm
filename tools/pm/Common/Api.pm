# gmmproc - Common::Api module
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

package Common::Api;

use strict;
use warnings;

# class Common::Api
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


sub deduce_backend_from_file ($)
{
  my $file = shift;

  if ($file =~ /defs$/)
  {
    return 'Defs';
  }
  elsif ($file =~ /gir$/)
  {
    return 'Gir';
  }
  return undef;
}

#my $g_o = 'outputter';
my $g_b = 'backend';

sub new ($$$)
{
  my $type = shift;
  my $file = shift;
  my $defs_a_r = shift;
#  my $outputter = shift;
  my $class = (ref ($type) or $type or "Common::Api");
  my $backend = undef;
  my $main_backend_module = deduce_backend_from_file ($file);

  unless (eval ("require $main_backend_module::Backend; \$backend = $main_backend_module::Backend->new (\$defs_a_r);"))
  {
    #TODO: implement Gir backend and remove the condition below.
    if ($main_backend_module eq 'Gir')
    {
      print STDERR join ('', 'Gir backend for file ', $file, "is not yet implemented\n");
    }
    #TODO: error!
    exit 1;
  }
#  $outputter->set_backend ($backend->get_outputter_backend ());

  unless ($backend->read_file ($file))
  {
    #TODO: error!
    exit 1;
  }

  my $self =
  {
    $g_b => $backend
#    $g_o => $outputter
  };

  bless ($self, $class);
  return $self;
}

sub read_file ($$)
{
  my $self = shift;
}

sub get_enums ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_enums ();
  }
  # TODO: error!
  return [];
}

sub get_methods ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_methods ();
  }
  # TODO: error!
  return [];
}

sub get_signals ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_signals ();
  }
  # TODO: error!
  return [];
}

sub get_properties ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_properties ();
  }
  # TODO: error!
  return [];
}

sub get_objects ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_objects ();
  }
  # TODO: error!
  return [];
}

sub get_functions ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_functions ();
  }
  # TODO: error!
  return [];
}

sub get_marked ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    return $backend->get_marked ();
  }
  # TODO: error!
  return [];
}

sub get_unwrapped ($)
{
  my $self = shift;
  my $backend = $self->{$g_b};
  my $unwrapped = [];

  if (defined ($backend))
  {
    push (@{$unwrapped}, $backend->get_unwrapped_methods ());
    push (@{$unwrapped}, $backend->get_unwrapped_signals ());
    push (@{$unwrapped}, $backend->get_unwrapped_properties ());
    push (@{$unwrapped}, $backend->get_unwrapped_objects ());
    push (@{$unwrapped}, $backend->get_unwrapped_enums ());
    push (@{$unwrapped}, $backend->get_unwrapped_functions ());
    return $unwrapped;
  }
  # TODO: error!
  return [];
}

sub lookup_enum ($$$)
{
  my $self = shift;
  my $c_name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $enum = $backend->lookup_enum ($c_name);

    if (defined ($enum) and $mark == 1)
    {
      $enum->set_marked (1);
    }
    return $enum;
  }
  # TODO: error!
  return undef;
}

sub lookup_object ($$$)
{
  my $self = shift;
  my $c_name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $obj = $backend->lookup_object ($c_name);

    if (defined ($obj) and $mark == 1)
    {
      $obj->set_marked (1);
    }
    return $obj;
  }
  # TODO: error!
  return undef;
}

sub lookup_property ($$$$)
{
  my $self = shift;
  my $object = shift;
  my $name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $property = $backend->lookup_property ($object, string_canonical ($name));

    if (defined ($property) and $mark == 1)
    {
      $property->set_marked (1);
    }
    return $property;
  }
  # TODO: error!
  return undef;
}

sub lookup_method ($$$)
{
  my $self = shift;
  my $c_name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $method = $backend->lookup_method (string_canonical ($c_name));

    if (defined ($method) and $mark == 1)
    {
      $method->set_marked (1);
    }
    return $method;
  }
  # TODO: error!
  return undef;
}

sub lookup_function ($$$)
{
  my $self = shift;
  my $c_name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $function = $backend->lookup_function (string_canonical ($c_name));

    if (defined ($function) and $mark == 1)
    {
      $function->set_marked (1);
    }
    return $function;
  }
  # TODO: error!
  return undef;
}

sub lookup_signal ($$$$)
{
  my $self = shift;
  my $object = shift;
  my $name = shift;
  my $mark = (shift == 1 ? 1 : 0);
  my $backend = $self->{$g_b};

  if (defined ($backend))
  {
    my $signal = $backend->lookup_signal ($object, string_canonical ($name));

    if (defined ($signal) and $mark == 1)
    {
      $signal->set_marked (1);
    }
    return $signal;
  }
  # TODO: error!
  return undef;
}

1; #indicate proper module load.
