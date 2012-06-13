# gmmproc - Base::Exceptions module
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

package Base::Exceptions;

use strict;
use warnings;

our $base = 'BaseException';
our $not_implemented = 'NotImplementedException';
our $i_o = 'IOException';
our $parse = 'ParseException';

my $g_i = 'isa';
my $g_d = 'description';

my $g_s = 'These exceptions are related to ';

use Exception::Class
(
  $base,
  $not_implemented =>
  {
    $g_i => $base,
    $g_d => join ('', $g_s, 'NIH.')
  },
  $i_o =>
  {
    $g_i => $base,
    $g_d => join ('', $g_s, 'IO.')
  }
  $parse =>
  {
    $g_i => $base,
    $g_d => join ('', $g_s, 'parsing.')
  }
);

1; #indicate proper module load.
