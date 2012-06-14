# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Output::Signal module
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

package Common::Output::Signal;

use strict;
use warnings;

sub nl
{
  return Common::Output::Shared::nl @_;
}

sub _output_h ($$$$$$)
{
  my ($wrap_parser, $ifdef, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $default_signal_handler_enabled) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $main_section = $wrap_parser->get_main_section;
  my $cxx_param_types_str = join ', ', @{$cxx_param_types};
  my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                    nl ('  Glib::SignalProxy' . (scalar @{$cxx_param_types}) . '< ' . $cxx_return_type . ', ' . $cxx_param_types_str . ' > signal_' . $cxx_signal_name . '();') .
                    nl () .
                    Common::Output::Shared::endif $ifdef;

  $section_manager->append_string_to_section ($code_string, $main_section);

  if ($default_signal_handler_enabled)
  {
    $code_string = (Common::Output::Shared::ifdef $ifdef) .
                   nl ('  virtual ' . $cxx_return_type . ' on_' . $cxx_signal_name . '(' . $cxx_param_types_str . ');') .
                   nl () .
                   Common::Output::Shared::endif $ifdef;

    my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::H_DEFAULT_SIGNAL_HANDLERS;

    $section_manager->append_string_to_section ($code_string, $section);
  }
}

sub _output_p_h ($$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_signal_name, $c_param_types, $c_param_names, $default_signal_handler_enabled) = @_;

  if ($default_signal_handler_enabled)
  {
    my $section_manager = $wrap_parset->get_section_manager;
    my $c_params_str = Common::Output::Shared::paramzipstr $c_param_types, $c_param_names;
    my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                      nl ('  static ' . $c_return_type . ' ' . $c_signal_name . '_callback(' . $c_params_str . ');') .
                      nl () .
                      Common::Output::Shared::endif $ifdef;
    my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_H_DEFAULT_SIGNAL_HANDLERS;

    $section_manager->append_string_to_section ($code_string, $section);
  }
}

sub _output_cc ($$$$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_signal_name, $c_signal_string, $c_param_types, $c_param_names, $c_param_transfers, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $custom_c_callback, $default_signal_handler_enabled) = @_;
  my $section_manager = $wrap_parser->get_section_manager;
  my $full_cxx_type = Common::Output::Shared::get_full_cxx_type $wrap_parser;
  my $signal_prefix = $full_cxx_type;
  my $c_type = Common::Output::Shared::get_c_type $wrap_parser;

  $signal_prefix =~ s/::/_/g;

  my $proxy_info = $signal_prefix . '_signal_' . $cxx_signal_name . '_info';
  my $ret_void = ($c_return_type eq 'void');
  my $cxx_param_types_str = join ', ', @cxx_param_types;
  my $type_info_local = $wrap_parser->get_type_info_local ();
  my $code_string = Common::Output::Shared::ifdef $ifdef;

  if ($ret_void and not @{$c_param_types} and $cxx_return_type eq 'void' and not @{$cxx_param_types})
  {
    $code_string .= nl ('// Use predefined callback for SignalProxy0<void> to reduce code size.') .
                    nl ('const Glib::SignalProxyInfo ' . $proxy_info . ' =') .
                    nl ('{') .
                    nl ('  ' . $c_signal_string . ',') .
                    nl ('  G_CALLBACK(&Glib::SignalProxyNormal::slot0_void_callback),') .
                    nl ('  G_CALLBACK(&Glib::SignalProxyNormal::slot0_void_callback)') .
                    nl ('};') .
                    nl ();
  }
  else
  {
    my $signal_callback = $signal_prefix . '_signal_' . $cxx_signal_name . '_callback';
    my $signal_notify = undef;

    if ($ret_void)
    {
      $signal_notify = $signal_callback;
    }
    else
    {
      $signal_notify = $signal_prefix . '_signal_' . $cxx_signal_name . '_notify_callback';
    }
    unless ($custom_c_callback)
    {
      my $callback_cxx_params_str = Common::Output::Shared::convzipstr $wrap_parser, $c_param_types, $cxx_param_types, $c_param_transfers, $c_param_names;
      my $c_params_str = Common::Output::Shared::paramzipstr $c_param_types, $c_param_names;
      my $partial_return_string = '(*static_cast<SlotType*>(slot))(' . $callback_cxx_params_str . ')';
      my $return_string = $partial_return_string;
      my $last_return = '';

      unless ($ret_void)
      {
        if ($c_return_transfer == Common::TypeInfo::Common::TRANSFER_NONE and $c_return_type =~ /\*$/)
        {
# TODO: print a warning - pointers returned from signals ought to have ownership transferred fully.
# TODO continued: need warning or error with fixed line number for this.
        }
        my $conv = $type_info_local->get_conversion ($cxx_return_type, $c_return_type, $c_return_transfer, $return_string);

        $return_string = 'return ' . $conv;
        $last_return = nl () .
                       nl ('  typedef ' . $c_return_type . ' RType;') .
                       nl ('  return RType();');
      }
      $code_string .= nl ($c_return_type . ' ' . $signal_callback . '(' . $c_type . '* self, ' . $c_params_str . ', gpointer data)') .
                      nl ('{') .
                      nl ('  using namespace ' . (Common::Output::Shared::get_full_namespace $wrap_parser) . ';') .
                      nl ('  typedef sigc::slot< ' . $cxx_return_type . ', ' . $cxx_param_types_str . ' > SlotType;') .
                      nl () .
                      nl ('  // Do not try to call a signal on a disassociated wrapper.') .
                      nl ('  if (Glib::ObjectBase::_get_current_wrapper(static_cast<GObject*>(self)))') .
                      nl ('  {') .
                      nl ('    try') .
                      nl ('    {') .
                      nl ('      sigc::slot_base* const slot(Glib::SignalProxyNormal::data_to_slot(data));') .
                      nl () .
                      nl ('      if (slot)') .
                      nl ('      {') .
                      nl ('        ' . $return_string . ';') .
                      nl ('      }') .
                      nl ('    }') .
                      nl ('    catch (...)') .
                      nl ('    {') .
                      nl ('      Glib::exception_handlers_invoke();') .
                      nl ('    }') .
                      nl ('  }') .
                      nl ($last_return . '}') .
                      nl ();
      unless ($ret_void)
      {
        $code_string .= nl ($c_return_type . ' ' . $signal_notify . '(' . $c_type . '* self, ' . $c_params_str . ', gpointer data)') .
                        nl ('{') .
                        nl ('  using namespace ' . (Common::Output::Shared::get_full_namespace $wrap_parser) . ';') .
                        nl ('  typedef sigc::slot< void, ' . $cxx_param_types_str . ' > SlotType;') .
                        nl () .
                        nl ('  // Do not try to call a signal on disassociated wrapper.') .
                        nl ('  if (Glib::ObjectBase::_get_current_wrapper(static_cast<GObject*>(self)))') .
                        nl ('  {') .
                        nl ('    try') .
                        nl ('    {') .
                        nl ('      if (sigc::slot_base* const slot = Glib::SignalProxyNormal::data_to_slot(data))') .
                        nl ('      {') .
                        nl ('        ' . $partial_return_string . ';') .
                        nl ('      }') .
                        nl ('    }') .
                        nl ('    catch (...)') .
                        nl ('    {') .
                        nl ('      Glib::exception_handlers_invoke();') .
                        nl ('    }') .
                        nl ('  }') .
                        nl () .
                        nl ('  typedef ' . $c_return_type . ' RType;') .
                        nl ('  return RType();') .
                        nl ('}') .
                        nl ();
      }
    }
    $code_string .= nl ('const Glib::SignalProxyInfo ' . $proxy_info . ' =') .
                    nl ('{') .
                    nl ('  ' . $c_signal_string . ',') .
                    nl ('  G_CALLBACK(&' . $signal_callback . '),') .
                    nl ('  G_CALLBACK(&' . $signal_notify . ')') .
                    nl ('};') .
                    nl ();
  }

  $code_string .= Common::Output::Shared::endif $ifdef;

  my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_UNNAMED_NAMESPACE;

  $section_manager->append_string_to_section ($code_string, $section);

  my $signal_proxy_type = 'Glib::SignalProxy' . (scalar @{$cxx_param_types}) . '< ' . $cxx_return_type . ', ' . $cxx_param_types_str . ' >';

  $code_string = (Common::Output::Shared::ifdef $ifdef) .
                 nl ($signal_proxy_type . ' ' . $full_cxx_type . '::signal_' . $cxx_signal_name . '()') .
                 nl ('{') .
                 nl ('  ' . $signal_proxy_type . '(this, &' . $proxy_info . ');') .
                 nl ('}') .
                 nl () .
                 Common::Output::Shared::endif $endif;
  $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_SIGNAL_PROXIES;
  $section_manager->append_string_to_section ($code_string, $section);

  if ($default_signal_handler_enabled)
  {
    $code_string = Common::Output::Shared::ifdef $ifdef;

    my $parent_from_object = Common::Output::Shared::get_parent_from_object $wrap_parser, 'gobject_';
    my $cxx_params_str = Common::Output::paramzipstr $cxx_param_types, $cxx_param_names;
    my $cxx_to_c_params_str = Common::Output::Shared::convzipstr $cxx_param_types, $c_param_types, $c_param_transfers, $cxx_param_names;
    my $c_func_invocation = '(*base->' . $c_signal_name . ')(gobj(), ' . $cxx_to_c_params_str . ')';
    my $last_return = '';

    $code_string .= nl ($cxx_return_type . ' ' . $full_cxx_type . '::on_' . $cxx_signal_name . '(' . $cxx_params_str . ')') .
                    nl ('{') .
                    nl ('  BaseClassType* const base(static_cast<BaseClassType*>(' . $parent_from_object . '));') .
                    nl () .
                    nl ('  if (base && base->' . $c_signal_name . ')') .
                    nl ('  {');

    if ($ret_void)
    {
      $code_string .= nl ('    ' . $c_func_invocation . ';') .
    }
    else
    {
      my $conv = $type_info_local->get_conversion ($c_return_type, $cxx_return_type, $c_return_transfer, $c_func_invocation);

      $code_string .= nl ('    return ' . $conv . ';');
      $last_return = nl () .
                     nl ('  typedef ' . $cxx_return_type . ' RType;') .
                     nl ('  return RType();');

    }

    $code_string .= nl ('  }') .
                    nl($last_return . '}') .
                    Common::Output::Shared::endif $ifdef;

    $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::CC_DEFAULT_SIGNAL_HANDLERS;
    $section_manager->append_string_to_section ($code_string, $section);
  }
}

sub _output_p_cc ($$$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_signal_name, $c_param_types, $c_param_names, $c_param_transfers, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $default_signal_handler_enabled) = @_;

  if ($default_signal_handler_enabled)
  {
    my $section_manager = $wrap_parser->get_section_manager;
    my $cxx_class_type = Common::Output::Shared::get_cxx_class_type $wrap_parser;
    my $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_INIT_DEFAULT_SIGNAL_HANDLERS;
    my $code_string = (Common::Output::Shared::ifdef $ifdef) .
                      nl ('  klass->' . $c_signal_name . ' = &' . $c_signal_name . '_callback;') .
                      nl () .
                      Common::Output::Shared::endif $ifdef;

    $section_manager->append_string_to_section ($code_string, $section);

    my $c_params_str = Common::Output::Shared::zupstr $c_param_types, $c_param_names, ' ', ', ';
    my $ret_void = ($c_return_type eq 'void');
    my $type_info_local = $wrap_parser->get_type_info_local ();
    my $convs_str = Common::Output::Shared::convzipstr $c_param_types, $cxx_param_types, $c_param_transfers, $c_param_names;
    my $vfunc_call = 'obj->on_' . $cxx_signal_name . '(' . $convs_str . ')';
    my $c_callback_call = '(*base->' . $c_signal_name . '(self, ' . (join ', ', @{$c_param_names}) . ')';
    my $last_return = '';

    unless ($ret_void)
    {
      $vfunc_call = 'return ' . $type_info_local->get_conversion ($cxx_return_type, $c_return_type, $c_return_transfer, $vfunc_call);
      $c_callback_call = 'return ' . $c_callback_call;
      $last_return = nl () .
                     nl ('  typedef ' . $c_return_type . ' RType;') .
                         '  return RType();';
    }
    else
    {
      $vfunc_call = nl ($vfunc_call . ';') .
                    nl ('        return');
    }

    my $parent_from_object = Common::Output::Shared::get_parent_from_object $wrap_parser, 'self';
    my $c_type = Common::Output::Shared::get_c_type $wrap_parser;

    $code_string = (Common::Output::Shared::ifdef $ifdef) .
                   nl ($c_return_type . ' ' . $cxx_class_type . '::' . $c_signal_name . '_callback(' . $c_type . '* self, ' . $c_params_str . ')') .
                   nl ('{') .
                   nl ('  // First, do a simple cast to ObjectBase. We will have to do a dynamic cast') .
                   nl ('  // eventually, but it is not necessary to check whether we need to call') .
                   nl ('  // the vfunc.') .
                   nl ('  Glib::ObjectBase* const obj_base(static_cast<Glib::ObjectBase*>(') .
                   nl ('    Glib::ObjectBase::_get_current_wrapper(static_cast<GObject*>(self))));') .
                   nl ('  // Non-gmmproc-generated custom classes implicitly call the default') .
                   nl ('  // Glib::ObjectBase constructor, which sets is_derived_. But gmmproc-generated') .
                   nl ('  // classes can use this optimisation, which avoids the unnecessary parameter') .
                   nl ('  // parameter conversions if there is no possibility of the virtual function being') .
                   nl ('  // overriden:') .
                   nl ('  if (obj_base && obj_base->is_derived_())') .
                   nl ('  {') .
                   nl ('    // We need to do a dynamic cast to get the real object type, to call the C++') .
                   nl ('    // vfunc on it.') .
                   nl ('    CppObjectBase* const obj(dynamic_cast<CppObjectType* const>(obj_base));') .
                   nl () .
                   nl ('    if (obj) // This can be NULL during destruction.') .
                   nl ('    {') .
                   nl ('      try // Trap C++ exceptions which would normally be lost because this is a C callback.') .
                   nl ('      {') .
                   nl ('        // Call the virtual member method, which derived classes might override.') .
                   nl ('        ' . $vfunc_call . ';')
                   nl ('      }') .
                   nl ('      catch (...)') .
                   nl ('      {') .
                   nl ('        Glib::exception_handlers_invoke();') .
                   nl ('      }') .
                   nl ('    }') .
                   nl ('  }') .
                   nl () .
                   nl ('  BaseClassType* const base(static_cast<BaseClassType*>(' . $parent_from_object . '));') .
                   nl () .
                   nl ('  // Call the original underlying C function:') .
                   nl ('  if (base && base->' . $c_signal_name . ')') .
                   nl ('  {') .
                   nl ('    ' . $c_callback_call . ';') .
                   nl ('  }' ) .
                   nl ($last_return . '}') .
                   nl () .
                   (Common::Output::Shared::endif $ifdef);

    $section = Common::Output::Shared::get_section $wrap_parser, Common::Sections::P_CC_DEFAULT_SIGNAL_HANDLERS;
    $section_manager->append_string_to_section ($code_string, $section);
  }
}

# TODO: Add custom_signal_handler.
sub output ($$$$$$$$$$$$$$$$)
{
  my ($wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_signal_name, $c_signal_string, $c_param_types, $c_param_names, $c_param_transfers, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $cxx_param_names, $custom_c_callback, $default_signal_handler_enabled) = @_;

  _output_h $wrap_parser, $ifdef, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $default_signal_handler_enabled;
  _output_p_h $wrap_parser, $ifdef, $c_return_type, $c_signal_name, $c_param_types, $c_param_names, $default_signal_handler_enabled;
  _output_cc $wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_signal_name, $c_signal_string, $c_param_types, $c_param_names, $c_param_transfers, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $custom_c_callback, $default_signal_handler_enabled;
  _output_p_cc $wrap_parser, $ifdef, $c_return_type, $c_return_transfer, $c_signal_name, $c_param_types, $c_param_names, $c_param_transfers, $cxx_return_type, $cxx_signal_name, $cxx_param_types, $default_signal_handler_enabled;
}

1; # indicate proper module load.
