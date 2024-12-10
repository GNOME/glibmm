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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/* This is a basic server providing a clock like functionality.  Clients can
 * get the current time, set the alarm and get notified when the alarm time is
 * reached.  It is basic because there is only one global alarm which any
 * client can set.  Clients listening for the alarm signal will be notified by
 * use of the global alarm signal.  The server should be easily modifiable to
 * allow per-client alarms, but that is left as an exercise.
 *
 * Along with the above it provides a method to get its stdout's file
 * descriptor to test the Gio::DBus::Message API.
 *
 * Only the GetTime and SetAlarm methods have been implemented so far.
 */

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

namespace
{
static Glib::RefPtr<Gio::DBus::NodeInfo> introspection_data;

static Glib::ustring introspection_xml = "<node>"
                                         "  <interface name='org.glibmm.DBusExample.Clock'>"
                                         "    <method name='GetTime'>"
                                         "      <arg type='s' name='iso8601' direction='out'/>"
                                         "    </method>"
                                         "    <method name='SetAlarm'>"
                                         "      <arg type='s' name='iso8601' direction='in'/>"
                                         "    </method>"
                                         "  </interface>"
                                         "</node>";

guint registered_id = 0;

// Stores the current alarm.
static Glib::DateTime curr_alarm;

} // anonymous namespace

static void
on_method_call(const Glib::RefPtr<Gio::DBus::Connection>& /* connection */,
  const Glib::ustring& /* sender */, const Glib::ustring& /* object_path */,
  const Glib::ustring& /* interface_name */, const Glib::ustring& method_name,
  const Glib::VariantContainerBase& parameters,
  const Glib::RefPtr<Gio::DBus::MethodInvocation>& invocation)
{
  if (method_name == "GetTime")
  {
    const auto curr_time = Glib::DateTime::create_now_local();
    const Glib::ustring time_str = curr_time.format_iso8601();
    const auto time_var = Glib::Variant<Glib::ustring>::create(time_str);

    // Create the tuple.
    const auto response = Glib::VariantContainerBase::create_tuple(time_var);

    // Return the tuple with the included time.
    invocation->return_value(response);
  }
  else if (method_name == "SetAlarm")
  {
    // Get the variant string.
    Glib::Variant<Glib::ustring> param;
    parameters.get_child(param, 0);

    // Get the time string.
    const Glib::ustring time_str = param.get();

    curr_alarm = Glib::DateTime::create_from_iso8601(time_str,
      Glib::TimeZone::create_local());
    if (!curr_alarm)
    {
      // If setting alarm was not successful, return an error.
      Gio::DBus::Error error(Gio::DBus::Error::INVALID_ARGS,
        "Alarm string \"" + time_str + "\" is not in ISO8601 format.");
      invocation->return_error(error);
    }
    else
    {
      // Success. Return an empty reply.
      const auto response = Glib::VariantContainerBase::create_tuple(
        std::vector<Glib::VariantBase>());
      invocation->return_value(response);
    }
  }
  else
  {
    // Non-existent method on the interface.
    Gio::DBus::Error error(Gio::DBus::Error::UNKNOWN_METHOD, "Method does not exist.");
    invocation->return_error(error);
  }
}

void
on_bus_acquired(
  const Glib::RefPtr<Gio::DBus::Connection>& connection, const Glib::ustring& /* name */)
{
  // Export an object to the bus:

  // See https://bugzilla.gnome.org/show_bug.cgi?id=646417 about avoiding
  // the repetition of the interface name:
  try
  {
    registered_id = connection->register_object(
      "/org/glibmm/DBus/TestObject", introspection_data->lookup_interface(),
      sigc::ptr_fun(&on_method_call));
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Registration of object failed." << std::endl;
  }

  return;
}

void
on_name_acquired(
  const Glib::RefPtr<Gio::DBus::Connection>& /* connection */, const Glib::ustring& /* name */)
{
  // TODO: What is this good for? See https://bugzilla.gnome.org/show_bug.cgi?id=646427
}

void
on_name_lost(const Glib::RefPtr<Gio::DBus::Connection>& connection, const Glib::ustring& /* name */)
{
  connection->unregister_object(registered_id);
}

int
main(int, char**)
{
  Gio::init();

  try
  {
    introspection_data = Gio::DBus::NodeInfo::create_for_xml(introspection_xml);
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Unable to create introspection data: " << ex.what() << "." << std::endl;
    return 1;
  }

  const auto id = Gio::DBus::own_name(Gio::DBus::BusType::SESSION, "org.glibmm.DBusExample",
    sigc::ptr_fun(&on_bus_acquired), sigc::ptr_fun(&on_name_acquired),
    sigc::ptr_fun(&on_name_lost));

  // Keep the service running until the process is killed:
  auto loop = Glib::MainLoop::create();
  loop->run();

  Gio::DBus::unown_name(id);

  return EXIT_SUCCESS;
}
