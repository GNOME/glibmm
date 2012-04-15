# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::VFunc module
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

package Common::Output::VFunc;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h ($$$$$$$)
{
  my ($wrap_parser, $ifdef, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $cpp_param_names, $const) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    (nl 'virtual ', $cpp_return_type, ' ', $cpp_vfunc_name, '(', $cpp_params_str, ($const ? ') const;' : ');')) .
                    (nl) .
                    Common::Output::Shared::endif $ifdef;

  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub _output_p_h ($$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_vfunc_name, $c_param_types, $c_param_names, $errthrow) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $c_params_str = (Common::Output::Shared::paramzipstr $c_param_types, $c_param_names) . ($errthrow ? ', GError** gerror' : '');
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    (nl '  static ', $c_return_type, ' ', $c_vfunc_name, '_vfunc_callback(', $c_params_str, ');') .
                      (nl) .
                      Common::Output::Shared::endif $ifdef;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_VFUNCS;

  $section_manager->append_string_to_section ($code_string, $section);
}

sub _output_cc ($$$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_vfunc_name, $c_param_types, $c_param_transfers, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $cpp_param_names, $const, $errthrow) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cpp_type = Common::Output::Shared::get_full_cpp_type $wrap_parser;
  my $parent_from_object = Common::Output::Shared::get_parent_from_object $wrap_parser, 'gobject_';
  my $cpp_params_str = Common::Output::Shared::paramzipstr $cpp_param_types, $cpp_param_names;
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    (nl $cpp_return_type, ' ', $full_cpp_type, '::', $cpp_vfunc_name, '(', $cpp_params_str, ($const ? ') const' : ')')) .
                    (nl '{') .
                    (nl '  BaseClassType* const base(static_cast<BaseClassType*>(' . $parent_from_object . '));') .
                    (nl) .
                    (nl '  if (base && base->' . $c_vfunc_name . ')') .
                    (nl '  {');
  my $ret_void = ($cpp_return_type eq 'void');
  my $c_type = Common::Output::Shared::get_c_type $wrap_parser;
  my $gobj = ($const ? 'const_cast< ' . $c_type . ' >(gobj())' : 'gobj()');
  my $cpp_to_c_params_str = (Common::Output::Shared::convzipstr $wrap_parser, $cpp_param_types, $c_param_types, $c_param_transfers, $cpp_param_names) . ($errthrow ? ', &temp_error' : '');
  my $c_func_invocation = join '', '(*base->', $c_vfunc_name, ')(', $gobj, ', ', $cpp_to_c_params_str . ')';
  my $last_return = '';
  my $conversions_store = $wrap_parser->get_conversions_store;
  my $error_init_string = (nl '    GError* temp_error(0);');
  my $errthrow_string = (nl '    if (temp_error)') .
                        (nl '    {') .
                        (nl '      ::Glib::Error::throw_exception(temp_error);') .
                        (nl '    }');

  if ($ret_void)
  {
    if ($errthrow)
    {
      $code_string .= $error_init_string .
                      (nl) .
                      (nl '    ', $c_func_invocation, ';') .
                      (nl) .
                      $errthrow_string .
                      (nl) .
                      (nl '    return;');
    }
    else
    {
      $code_string .= (nl '    ', $c_func_invocation, ';') .
                      (nl '    return;');
    }
  }
  else
  {
    my $conv = '';

    if ($errthrow)
    {
      $code_string .= $error_init_string .
                      (nl '    ', $c_return_type, ' temp_retval(', $c_func_invocation, ');') .
                      (nl) .
                      $errthrow_string .
                      (nl);
      $conv = $conversions_store->get_conversion ($c_return_type, $cpp_return_type, $c_return_transfer, 'temp_retval');
    }
    else
    {
      $conv = $conversions_store->get_conversion ($c_return_type, $cpp_return_type, $c_return_transfer, $c_func_invocation);
    }
    $code_string .= nl ('    return ' . $conv . ';');
    $last_return = (nl) .
                   (nl '  typedef ' . $cpp_return_type . ' RType;') .
                   (nl '  return RType();');
  }
  $code_string .= (nl '  }') .
                  (nl $last_return . '}') .
                  Common::Output::Shared::endif $ifdef;

  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_VFUNCS;

  $section_manager->append_string_to_section ($code_string, $section);
}

sub _output_p_cc ($$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_vfunc_name, $c_param_types, $c_param_names, $c_param_transfers, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $errthrow) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $cpp_class_type = Common::Output::Shared::get_cpp_class_type $wrap_parser;
  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_VFUNCS;
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    (nl '  klass->' . $c_vfunc_name . ' = &' . $c_vfunc_name . '_vfunc_callback;') .
                    (nl) .
                    Common::Output::Shared::endif $ifdef;

  $section_manager->append_string_to_section ($code_string, $section);

  my $c_params_str = (Common::Output::Shared::paramzipstr $c_param_types, $c_param_names) . ($errthrow ? ', GError** gerror' : '');
  my $ret_void = ($c_return_type eq 'void');
  my $conversions_store = $wrap_parser->get_conversions_store;
  my $convs_str = Common::Output::Shared::convzipstr $wrap_parser, $c_param_types, $cpp_param_types, $c_param_transfers, $c_param_names;
  my $vfunc_call = 'obj->' . $cpp_vfunc_name . '(' . $convs_str . ')';
  my $c_callback_call = '(*base->' . $c_vfunc_name . '(self, ' . (join ', ', @{$c_param_names}) . ($errthrow ? ', gerror' : '') . ')';
  my $last_return = '';
  my $after_catch_return = '';

  unless ($ret_void)
  {
    $vfunc_call = 'return ' . $conversions_store->get_conversion ($cpp_return_type, $c_return_type, $c_return_transfer, $vfunc_call);
    $c_callback_call = 'return ' . $c_callback_call;
    $after_catch_return = (nl) .
                          (nl '      typedef ', $c_return_type, ' RType;') .
                          (nl '      return RType();');
    $last_return = (nl) .
                   (nl '  typedef ' . $c_return_type . ' RType;') .
                       '  return RType();';
  }
  else
  {
    $vfunc_call = (nl $vfunc_call . ';') .
                  (nl '        return');
    $after_catch_return = (nl) .
                          (nl '      return;');
  }

  my $parent_from_object = Common::Output::Shared::get_parent_from_object $wrap_parser, 'self';
  my $c_type = Common::Output::Shared::get_c_type $wrap_parser;

  $code_string = (Common::Output::Shared::ifdef $ifdef) .
                 (nl $c_return_type, ' ', $cpp_class_type . '::' . $c_vfunc_name . '_vfunc_callback(', $c_type, '* self, ', $c_params_str, ')') .
                 (nl '{') .
                 (nl '  // First, do a simple cast to ObjectBase. We will have to do a dynamic cast') .
                 (nl '  // eventually, but it is not necessary to check whether we need to call') .
                 (nl '  // the vfunc.') .
                 (nl '  Glib::ObjectBase* const obj_base(static_cast<Glib::ObjectBase*>(') .
                 (nl '    Glib::ObjectBase::_get_current_wrapper(static_cast<GObject*>(self))));') .
                 (nl '  // Non-gmmproc-generated custom classes implicitly call the default') .
                 (nl '  // Glib::ObjectBase constructor, which sets is_derived_. But gmmproc-generated') .
                 (nl '  // classes can use this optimisation, which avoids the unnecessary parameter') .
                 (nl '  // parameter conversions if there is no possibility of the virtual function being') .
                 (nl '  // overriden:') .
                 (nl '  if (obj_base && obj_base->is_derived_())') .
                 (nl '  {') .
                 (nl '    // We need to do a dynamic cast to get the real object type, to call the C++') .
                 (nl '    // vfunc on it.') .
                 (nl '    CppObjectBase* const obj(dynamic_cast<CppObjectType* const>(obj_base));') .
                 (nl) .
                 (nl '    if (obj) // This can be NULL during destruction.') .
                 (nl '    {') .
                 (nl '      try // Trap C++ exceptions which would normally be lost because this is a C callback.') .
                 (nl '      {') .
                 (nl '        // Call the virtual member method, which derived classes might override.') .
                 (nl '        ' . $vfunc_call . ';') .
                 (nl '      }');

  if ($errthrow)
  {
    $code_string .= (nl '      catch (const Glib::Error& error)') .
                    (nl '      {') .
                    (nl '        error.propagate(gerror);') .
                    (nl '      }');
  }

  $code_string .= (nl '      catch (...)') .
                  (nl '      {') .
                  (nl '        Glib::exception_handlers_invoke();') .
                  (nl '      }') .
                  $after_catch_return .
                  (nl '    }') .
                  (nl '  }') .
                  (nl) .
                  (nl '  BaseClassType* const base(static_cast<BaseClassType*>(' . $parent_from_object . '));') .
                  (nl) .
                  (nl '  // Call the original underlying C function:') .
                  (nl '  if (base && base->' . $c_vfunc_name . ')') .
                  (nl '  {') .
                  (nl '    ' . $c_callback_call . ';') .
                  (nl '  }' ) .
                  (nl $last_return . '}') .
                  (nl) .
                  (Common::Output::Shared::endif $ifdef);

  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_VFUNCS;
  $section_manager->append_string_to_section ($code_string, $section);
}

sub output ($$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_vfunc_name, $c_param_types, $c_param_names, $c_param_transfers, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $cpp_param_names, $const, $custom_vfunc, $custom_vfunc_callback, $errthrow) = @_;

  _output_h $wrap_parser, $ifdef, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $cpp_param_names, $const;
  _output_p_h $wrap_parser, $ifdef, $c_return_type, $c_vfunc_name, $c_param_types, $c_param_names, $errthrow;

  unless ($custom_vfunc)
  {
    _output_cc $wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_vfunc_name, $c_param_types, $c_param_transfers, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $cpp_param_names, $const, $errthrow;
  }

  unless ($custom_vfunc_callback)
  {
    _output_p_cc $wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_vfunc_name, $c_param_types, $c_param_names, $c_param_transfers, $cpp_return_type, $cpp_vfunc_name, $cpp_param_types, $errthrow;
  }
}

1; # indicate proper module load.
