/* Copyright (C) 2011 The giomm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/* This is a basic server providing a clock like functionality.  Clients can
 * get the current time, set the alarm and get notified when the alarm time is
 * reached.  It is basic because there is only one global alarm which any
 * client can set.  Clients listening for the alarm signal will be notified by
 * use of the global alarm signal.  The server should be easily modifiable to
 * allow per-client alarms, but that is left as an exercise.
 *
 * Along with the above it provides a method to get its stdout's file
 * descriptor to test the Gio::DBusMessage API.
 */

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

namespace
{

static Glib::RefPtr<Gio::DBusNodeInfo> introspection_data;

static Glib::ustring introspection_xml =
  "<node>"
  "  <interface name='org.glibmm.DBus.Clock'>"
  "    <method name='GetTime'>"
  "    <method name='SetAlarm'>"
  "      <arg type='s' name='iso8601' direction='in'/>"
  "    </method>"
  "    <method name='GetStdout'>"
  "    <signal name='OnAlarm'>"
  "      <arg type='s' name='iso8601'/>"
  "    </signal>"
       // The time of the alarm as an iso8601 string.
  "    <property type='s' name='Alarm' access='readwrite'/>"
  "  </interface>"
  "</node>";

// Stores the current alarm.
static Glib::TimeVal curr_alarm;

} // anonymous namespace

static void on_method_call(const Glib::RefPtr<Gio::DBusConnection>& connection,
  const Glib::ustring& /* sender */, const Glib::ustring& /* object_path */,
  const Glib::ustring& /* interface_name */, const Glib::ustring& method_name,
  const Glib::VariantBase& /* parameters */,
  const Glib::RefPtr<Gio::DBusMethodInvocation>& invocation)
{
  if(method_name == "GetTime")
  {
    Glib::TimeVal curr_time;
    curr_time.assign_current_time();

    Glib::ustring time_str = curr_time.as_iso8601();

    Glib::Variant<Glib::ustring> time_var =
      Glib::Variant<Glib::ustring>::create(time_str);

    // Create a variant array to create a tuple to be returned to the client.
    std::vector<Glib::VariantBase> var_array;
    var_array.push_back(time_var);

    // Create the tuple.
    Glib::VariantContainerBase response =
      Glib::VariantContainerBase::create_tuple(var_array);

    // Return the tuple with the included time.
    invocation->return_value(response);
  }
  else if(method_name == "SetAlarm")
  {
    // Get the parameter tuple.
    Glib::VariantContainerBase parameters;
    invocation->get_parameters(parameters);

    // Get the variant string.
    Glib::Variant<Glib::ustring> param;
    parameters.get(param);

    // Get the time string.
    Glib::ustring time_str = param.get();

    if(!curr_alarm.assign_from_iso8601(time_str))
    {
      // If setting alarm was not successful, return an error.
      Gio::DBusError error(Gio::DBusError::INVALID_ARGS,
          "Alarm string is not in ISO8601 format.");
      invocation->return_gerror(error);
    }
  }
  else if(method_name == "GetStdout")
  {
#ifndef G_OS_WIN32
    if(connection->get_capabilities() &
      Gio::DBUS_CAPABILITY_FLAGS_UNIX_FD_PASSING)
    {
      Glib::RefPtr<Gio::UnixFDList> list = Gio::UnixFDList::create();
      try
      {
        list->append(STDOUT_FILENO);

        Glib::RefPtr<Gio::DBusMessage> reply =
          Gio::DBusMessage::create_method_reply(invocation->get_message());

        reply->set_unix_fd_list(list);

        connection->send_message(reply);
      }
      catch(const Glib::Error& ex)
      {
        std::cerr << "Error trying to send stdout to client: " << ex.what() <<
          std::endl;
        return;
      }
    }
    else
    {
      invocation->return_dbus_error("org.glibmm.DBus.Failed", "Your message "
        "bus daemon does not support file descriptor passing (need D-Bus >= "
        "1.3.0)");
    }
#else
    invocation->return_dbus_error("org.glibmm.DBus.Failed", "Your message bus "
      "daemon does not support file descriptor passing (need D-Bus >= 1.3.0)");
#endif
  }
  else
  {
    // Non-existent method on the interface.
    Gio::DBusError error(Gio::DBusError::UNKNOWN_METHOD,
      "Method does not exist.");
    invocation->return_gerror(error);
  }
}

void on_get_property(Glib::VariantBase& property,
  const Glib::RefPtr<Gio::DBusConnection>& /* connection */,
  const Glib::ustring& /* sender */, const Glib::ustring& /* object_path */,
  const Glib::ustring& /* interface_name */, const Glib::ustring& property_name)
{
  if(property_name == "Alarm")
  {
    if(curr_alarm.valid())
    {
      Glib::ustring alarm_str = curr_alarm.as_iso8601();

      Glib::Variant<Glib::ustring> alarm_var =
        Glib::Variant<Glib::ustring>::create(alarm_str);

      property = alarm_var;
    }
    else
    {
      throw Gio::Error(Gio::Error::FAILED, "Alarm has not been set.");
    }
  }
  else
  {
    throw Gio::DBusError(Gio::DBusError::FAILED, "Unknown property name.");
  }
}

bool on_set_property(const Glib::RefPtr<Gio::DBusConnection>& connection,
  const Glib::ustring& sender, const Glib::ustring& object_path,
  const Glib::ustring& interface_name, const Glib::ustring& property_name,
  const Glib::VariantBase& value)
{
  if(property_name == "Alarm")
  {
  }
  else
  {
  }
}

int main(int, char**)
{
  std::locale::global(std::locale(""));
  Gio::init();

  return 0;
}
