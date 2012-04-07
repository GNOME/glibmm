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

sub _output_h ($$$$$$$)
{
  my ($wrap_parser, $static, $cpp_ret_type, $cpp_func_name, $cpp_param_types, $cpp_param_names, $const) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $code_string = '';

  die if (scalar (@{$cpp_param_types}) != scalar(@{$cpp_param_names}));
  die if ($static and $const);

  if ($static)
  {
    $code_string += 'static ';
  }
  $code_string += $cpp_ret_type . ' ' . $cpp_func_name;

  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;

  $code_string += '(' . $cpp_params_str . ')';
  if ($const)
  {
    $code_string += ' const';
  }
  $code_string += ';';
  $section_manager->append_string_to_section (nl ($code_string), $main_section);
}

sub _output_cc ($$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $static, $cpp_ret_type, $cpp_func_name, $cpp_param_types, $cpp_param_names, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $code_string = '';
  my $ret_void = ($cpp_ret_type eq 'void');

# TODO: replace with exception throwing
  # if dies then it is internal error. should not happen here.
  die if ($static and ($const or $constversion));
  die if (scalar (@{$types_list}) != scalar(@{$names_list}));
  die if (scalar (@{$c_param_types}) != scalar(@{$types_list}));

  if ($deprecated)
  {
    $code_string += Common::Output::Shared::deprecate_start $wrap_parser;
  }
  if ($ifdef)
  {
    $code_string += nl ('#ifdef ' . $ifdef);
  }
  if ($static)
  {
    $code_string += nl ('// static');
  }

  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $c_type = Common::Output::Shared::get_c_type;

  $code_string += nl ($cpp_ret_type . ' ' . $full_cpp_type . '::' . $cpp_func_name . '(' . $cpp_param_list_str . ')' . ($const ? ' const' : '')) .
                  nl ('{');

  my $names_only = join ', ', @{$cpp_param_names};

  if ($constversion)
  {
    my $ret = '';

    unless ($ret_void)
    {
      $ret = 'return ';
    }
    $code_string += nl ('  ' . $ret . 'const_cast< ' . $full_cpp_type . '* >(this)->' . $cpp_func_name . '(' . $names_only . ');');
  }
  else
  {
    my $this_param = '';

    if ($const)
    {
      $this_param = 'const_cast< ' . $c_type . '* >(gobj()), ';
    }
    elsif (not $static)
    {
      $this_param = 'gobj(), ';
    }

    my $conversions_store = $wrap_parser->get_conversions_store;
    my $c_param_list_str = $this_param . (Common::Output::Shared::convzipstr $cpp_param_types, $c_param_types, $c_param_transfers, $cpp_param_names) . ($errthrow ? ', &gerror' . '');
    my $c_func_invocation = $c_func_name . '(' . $c_param_list_str . ')';
    my $ret_convert = $conversions_store->get_conversion ($c_ret_type, $cpp_ret_type, $ret_transfer, $c_func_invocation);

    if ($errthrow)
    {
      $code_string += nl ('  GError* gerror(0);');

      unless ($ret_void)
      {
        $code_string += nl ('  ' . $cpp_ret_type . ' retvalue(' . $ret_convert . ');');
      }
      else
      {
        $code_string += nl () .
                        nl ('  ' . $c_func_invocation . ';');
      }
      if ($errthrow)
      {
        $code_string += nl () .
                        nl ('  if (gerror)') .
                        nl ('  {') .
                        nl ('    ::Glib::Error::throw_exception(gerror);') .
                        nl ('  }');
      }
      unless ($ret_void)
      {
        $code_string += nl () .
                        nl ('return retvalue;');
      }
    }
    else
    {
      if ($ret_void)
      {
        $code_string += nl ('  return ' . $ret_convert . ';');
      }
      else
      {
        $code_string += nl ('  ' . $c_func_invocation . ';');
      }
    }
  }
  $code_string += nl ('}');
  if ($ifdef)
  {
    $code_string += nl ('#endif // ' . $ifdef);
  }
  if ($deprecated)
  {
    $code_string += Common::Output::Shared::deprecate_end $wrap_parser;
  }

  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_NAMESPACE;

  $section_manager->append_string_to_section ($code_string, $section);
}

sub output ($$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $static, $cpp_ret_type, $cpp_func_name, $cpp_param_types, $cpp_param_names, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow) = @_;

  _output_h $wrap_parser, $static, $cpp_ret_type, $cpp_func_name, $cpp_param_types, $cpp_param_names, $const;
  _output_cc $wrap_parser, $static, $cpp_ret_type, $cpp_func_name, $cpp_param_types, $cpp_param_names, $const, $constversion, $deprecated, $ifdef, $c_ret_type, $ret_transfer, $c_func_name, $c_param_types, $c_param_transfers, $errthrow;
}

1; # indicate proper module load.
