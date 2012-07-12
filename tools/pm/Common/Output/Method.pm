# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Method module
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

package Common::Output::Method;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h ($$$$$$$$)
{
  my ($wrap_parser, $static, $cxx_ret_type, $cxx_func_name, $cxx_param_types, $cxx_param_names, $cxx_param_values, $const) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $code_string = '';

  die if (scalar (@{$cxx_param_types}) != scalar(@{$cxx_param_names}));
  die if ($static and $const);

  if ($static)
  {
    $code_string .= 'static ';
  }
  $code_string .= $cxx_ret_type . ' ' . $cxx_func_name;

  my $cxx_params_str = Common::Output::Shared::paramzipstr $cxx_param_types, $cxx_param_names, $cxx_param_values;

  $code_string .= '(' . $cxx_params_str . ')';
  if ($const)
  {
    $code_string .= ' const';
  }
  $code_string .= ';';
  $section_manager->append_string_to_section (nl ($code_string), $main_section);
}

sub _output_cc ($$$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $static, $cxx_ret_type, $cxx_func_name, $cxx_param_types, $cxx_param_names, $cxx_param_out_index, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = '';
  my $ret_void = ($cxx_ret_type eq 'void');

# TODO: replace with exception throwing
  # if dies then it is internal error. should not happen here.
  if ($static and ($const or $constversion))
  {
    $wrap_parser->fixed_error ('static and const does not mix.');
  }
  if (scalar (@{$cxx_param_types}) != scalar(@{$cxx_param_names}))
  {
    $wrap_parser->fixed_error ('param types count should be equal to param names count');
  }
  if ($cxx_param_out_index < 0)
  {
    if (scalar (@{$c_param_types}) != scalar(@{$cxx_param_types}))
    {
      $wrap_parser->fixed_error ('C param types count should be equal to C++ param count');
    }
  }
  else
  {
    if (scalar (@{$c_param_types}) + 1 != scalar(@{$cxx_param_types}))
    {
      $wrap_parser->fixed_error ('C param types count should be greater by one from C++ param_types (there is an output parameter.');
    }
  }

  if ($deprecated)
  {
    $code_string .= Common::Output::Shared::deprecate_start $wrap_parser;
  }
  if ($ifdef)
  {
    $code_string .= nl ('#ifdef ' . $ifdef);
  }
  if ($static)
  {
    $code_string .= nl ('// static');
  }

  my $cxx_params_str = Common::Output::Shared::paramzipstr $cxx_param_types, $cxx_param_names;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $c_type = Common::Output::Shared::get_c_type $wrap_parser;

  $code_string .= nl ($cxx_ret_type . ' ' . $full_cxx_type . '::' . $cxx_func_name . '(' . $cxx_params_str . ')' . ($const ? ' const' : '')) .
                  nl ('{');

  my $names_only = join ', ', @{$cxx_param_names};

  if ($constversion)
  {
    my $ret = '';

    unless ($ret_void)
    {
      $ret = 'return ';
    }
    $code_string .= nl ('  ' . $ret . 'const_cast< ' . $full_cxx_type . '* >(this)->' . $cxx_func_name . '(' . $names_only . ');');
  }
  else
  {
    my $this_param = '';
    my @params = ();

    unless ($static)
    {
      if ($const)
      {
        $this_param = 'const_cast< ' . $c_type . '* >(gobj())';
      }
      else
      {
        $this_param = 'gobj()';
      }

      push @params, $this_param;
    }

    my $prepped_cxx_param_types = undef;
    my $prepped_cxx_param_names = undef;

    if ($cxx_param_out_index < 0)
    {
      $prepped_cxx_param_types = $cxx_param_types;
      $prepped_cxx_param_names = $cxx_param_names;
    }
    else
    {
      # copy arrays
      $prepped_cxx_param_types = [@{$cxx_param_types}];
      $prepped_cxx_param_names = [@{$cxx_param_names}];

      splice (@{$prepped_cxx_param_types}, $cxx_param_out_index, 1);
      splice (@{$prepped_cxx_param_names}, $cxx_param_out_index, 1);
    }
    my $convs_str = Common::Output::Shared::convzipstr $wrap_parser, $prepped_cxx_param_types, $c_param_types, $c_param_transfers, $prepped_cxx_param_names;

    $prepped_cxx_param_types = undef;
    $prepped_cxx_param_names = undef;
    if (defined ($convs_str) and $convs_str ne '')
    {
      push @params, $convs_str;
    }
    if ($errthrow)
    {
      push @params, '&gerror';
    }

    my $c_param_list_str = join ', ', @params;
    my $c_func_invocation = $c_func_name . '(' . $c_param_list_str . ')';
    my $ret_convert = '';

    unless ($ret_void)
    {
      $ret_convert = Common::Output::Shared::convert_or_die ($wrap_parser, $c_ret_type, $cxx_ret_type, $ret_transfer, $c_func_invocation);
    }
    elsif ($cxx_param_out_index > -1)
    {
      $ret_convert = Common::Output::Shared::convert_or_die ($wrap_parser, $c_ret_type, $cxx_param_types->[$cxx_param_out_index], $ret_transfer, $c_func_invocation);
    }

    if ($errthrow)
    {
      $code_string .= nl ('  GError* gerror(0);');

      unless ($ret_void)
      {
        $code_string .= nl ('  ' . $cxx_ret_type . ' retvalue(' . $ret_convert . ');');
      }
      elsif ($cxx_param_out_index > -1)
      {
        $code_string .= nl ('  ' . $cxx_param_names->[$cxx_param_out_index] . ' = (' . $ret_convert . ');');
      }
      else
      {
        $code_string .= nl () .
                        nl ('  ' . $c_func_invocation . ';');
      }
      if ($errthrow)
      {
        $code_string .= nl () .
                        nl ('  if (gerror)') .
                        nl ('  {') .
                        nl ('    ::Glib::Error::throw_exception(gerror);') .
                        nl ('  }');
      }
      unless ($ret_void)
      {
        $code_string .= nl () .
                        nl ('return retvalue;');
      }
    }
    else
    {
      unless ($ret_void)
      {
        $code_string .= nl ('  return ' . $ret_convert . ';');
      }
      elsif ($cxx_param_out_index > -1)
      {
        $code_string .= nl ('  ' . $cxx_param_names->[$cxx_param_out_index] . ' = (' . $ret_convert . ');');
      }
      else
      {
        $code_string .= nl ('  ' . $c_func_invocation . ';');
      }
    }
  }
  $code_string .= nl ('}');
  if ($ifdef)
  {
    $code_string .= nl ('#endif // ' . $ifdef);
  }
  if ($deprecated)
  {
    $code_string .= Common::Output::Shared::deprecate_end $wrap_parser;
  }

  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;

  $section_manager->append_string_to_section ($code_string, $section);
}

sub output ($$$$$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $static, $cxx_ret_type, $cxx_func_name, $cxx_param_types, $cxx_param_names, $cxx_param_values, $cxx_param_nullables, $cxx_param_out_index, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow) = @_;
  my $permutations = Common::Output::Shared::get_types_permutations ($cxx_param_types, $cxx_param_nullables);

  foreach my $permutation (@{$permutations})
  {
    _output_h $wrap_parser, $static, $cxx_ret_type, $cxx_func_name, $permutation, $cxx_param_names, $cxx_param_values, $const;
    _output_cc $wrap_parser, $static, $cxx_ret_type, $cxx_func_name, $permutation, $cxx_param_names, $cxx_param_out_index, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow;
  }
}

1; # indicate proper module load.
