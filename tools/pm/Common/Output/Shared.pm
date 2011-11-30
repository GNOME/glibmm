# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Shared module
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

package Common::Output::Shared;

use strict;
use warnings;

use constant
{
  'PROTECTED_GCLASS_VAR' => 'PROTECTED_GCLASS_BOOL_VARIABLE',
  'DYNAMIC_GTYPE_REGISTRATION_VAR' => 'DYNAMIC_GTYPE_REGISTRATION_BOOL_VARIABLE',
  'STRUCT_NOT_HIDDEN_VAR' => 'STRUCT_NOT_HIDDEN_BOOL_VARIABLE',
  'NO_WRAP_FUNCTION_VAR' => 'NO_WRAP_FUNCTION_BOOL_VARIABLE',
  'DO_NOT_DERIVE_GTYPE_VAR' => 'DO_NOT_DERIVE_GTYPE_BOOL_VARIABLE',
  'CUSTOM_WRAP_NEW_VAR' => 'CUSTOM_WRAP_NEW_BOOL_VARIABLE',
  'CUSTOM_CTOR_CAST_VAR' => 'CUSTOM_CTOR_CAST_BOOL_VARIABLE',
  'DERIVES_INITIALLY_UNOWNED_VAR' => 'DERIVES_INITIALLY_UNOWNED_BOOL_VARIABLE',
  'CUSTOM_DTOR_VAR' => 'CUSTOM_DTOR_BOOL_VARIABLE'
};

sub nl
{
  return (shift or '') . "\n";
}

sub doxy_skip_begin ()
{
  return '#ifndef DOXYGEN_SHOULD_SKIP_THIS';
}

sub doxy_skip_end ()
{
  return '#endif // DOXYGEN_SHOULD_SKIP_THIS';
}

sub open_namespaces ($)
{
  my ($namespaces) = @_;
  my $code_string = '';

  foreach my $opened_name (reverse @{$namespaces})
  {
    $code_string .= nl ('namespace ' . $opened_name) .
                    nl ('{') .
                    nl ();
  }
  return $code_string;
}

sub close_namespaces ($)
{
  my ($namespaces) = @_;
  my $code_string = '';

  foreach my $closed_name (@{$namespaces})
  {
    $code_string .= nl ('} // namespace ' . $closed_name) .
                    nl ();
  }
  return $code_string;
}

sub join_namespaces ($)
{
  my ($namespaces) = @_;

  return join ('::', reverse @{$namespaces});
}

sub create_class_local_prefix ($$)
{
  my ($namespaces, $class) = @_;
  my $single_string = join_namespaces ($namespaces) . '_' . $class;

  $single_string =~ s/\W+/_/g;
  $single_string =~ s/_+/_/g;
  return uc ($single_string) . '_';
}


1; # indicate proper module load.
