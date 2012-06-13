# gmmproc - Defs::Common module
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

package Defs::Common;

our $gc_p_t = 'common_param_types';
our $gc_p_n = 'common_param_names';

sub parse_params ($)
{
  my $params = shift;
  my $param_types = [];
  my $param_names = [];
  my $params_hr =
  {
    $gc_p_t = $param_types,
    $gc_p_n = $param_names
  };

  # break up the parameter statements
  for my $part (split (/\s*'*[()]\s*/, $param))
  {
    next unless ($part);
    if (/^"(\S+)" "(\S+)"$/)
    {
      my ($p1, $p2) = ($1, $2);
      $p1 =~ s/-/ /;
      push (@{${param_types}}, $p1);
      push (@{${param_names}}, $p2);
    }
    else
    {
      return {};
      #GtkDefs::error("Unknown parameter statement ($_) in $$self{c_name}\n");
    }
  }
  return $params_h_r;
}

1; # indicate proper module load.
