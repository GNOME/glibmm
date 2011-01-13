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

/* For some usage examples see the C API's GDBusServer's example from which
 * this example was adapted.
 */

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

static Glib::RefPtr<Gio::DBusNodeInfo> introspection_data;

static Glib::ustring introspection_xml =
  "<node>"
  "  <interface name='org.glibmm.GDBus.TestPeerInterface'>"
  "    <method name='HelloWorld'>"
  "      <arg type='s' name='greeting' direction='in'/>"
  "      <arg type='s' name='response' direction='out'/>"
  "    </method>"
  "  </interface>"
  "</node>";

// This variable is used to keep an incoming connection active until it is
// closed.
static Glib::RefPtr<Gio::DBusConnection> curr_connection;

static void on_method_call(const Glib::RefPtr<Gio::DBusConnection>&,
  const Glib::ustring& /* sender */, const Glib::ustring& /* object_path */,
  const Glib::ustring& /* interface_name */, const Glib::ustring& method_name,
  // Since the parameters are generally tuples, get them from the invocation.
  const Glib::VariantBase& /* parameters */,
  const Glib::RefPtr<Gio::DBusMethodInvocation>& invocation)
{
  if(method_name == "HelloWorld")
  {
    // Get parameters.
    Glib::VariantContainerBase parameters;
    invocation->get_parameters(parameters);

    // Get (expected) single string in tupple.
    Glib::Variant<Glib::ustring> param;
    parameters.get(param);

    Glib::ustring response = "You said: '" + param.get() + "'.";

    Glib::Variant<Glib::ustring> answer =
      Glib::Variant<Glib::ustring>::create(response);

    std::vector<Glib::VariantBase> var_array;
    var_array.push_back(answer);

    Glib::VariantContainerBase ret =
      Glib::VariantContainerBase::create_tuple(var_array);

    invocation->return_value(ret);

    std::cout << "Client said '" << param.get() << "'." << std::endl;
  }
}

// Create the interface VTable.
static const Gio::DBusInterfaceVTable
  interface_vtable(sigc::ptr_fun(&on_method_call));

bool on_new_connection(const Glib::RefPtr<Gio::DBusConnection>& connection)
{
  Glib::RefPtr<Gio::Credentials> credentials =
    connection->get_peer_credentials();

  std::string credentials_str;

  if(!credentials)
    credentials_str = "(no credentials received)";
  else
    credentials_str = credentials->to_string();

  std::cout <<
    "Client connected." << std::endl <<
    "Peer credentials: " << credentials_str << std::endl <<
    "Negotiated capabilities: unix-fd-passing=" << (connection->get_capabilities() & Gio::DBUS_CAPABILITY_FLAGS_UNIX_FD_PASSING) << std::endl;

  // If there is already an active connection, do not accept this new one.
  // There may be a better way to decide how to keep current incoming
  // connections.
  if(curr_connection && !curr_connection->is_closed())
  {
    std::cerr << "Unable to accept new incoming connection because one is "
      "already active." << std::endl;

    return false;
  }

  // In order for the connection to stay active the reference to the
  // connection must be kept so store the connection in a global variable.
  curr_connection = connection;

  guint reg_id = connection->register_object("/org/glibmm/GDBus/TestObject",
    introspection_data->lookup_interface("org.glibmm.GDBus.TestPeerInterface"),
    &interface_vtable);

  if(reg_id == 0)
  {
    std::cerr << "Registration of object for incoming connection not "
      "possible." << std::endl;
    return false;
  }

  return true;
}

void run_as_server(Glib::ustring address, bool allow_anonymous)
{
  Glib::ustring guid = Gio::DBus::generate_guid();
  Gio::DBusServerFlags flags = Gio::DBUS_SERVER_FLAGS_NONE;

  if(allow_anonymous)
    flags |= Gio::DBUS_SERVER_FLAGS_AUTHENTICATION_ALLOW_ANONYMOUS;

  Glib::RefPtr<Gio::DBusServer> server;

  try
  {
    server = Gio::DBusServer::create_sync(address, guid, flags);
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Error creating server at address: " << address <<
      ": " << ex.what() << "." << std::endl;
    return;
  }

  server->start();

  std::cout << "Server is listening at: " << server->get_client_address() <<
    "." << std::endl;

  server->signal_new_connection().connect(sigc::ptr_fun(&on_new_connection));

  Glib::RefPtr<Glib::MainLoop> loop = Glib::MainLoop::create();
  loop->run();
}

void run_as_client(Glib::ustring address)
{
  Glib::RefPtr<Gio::DBusConnection> connection;

  try
  {
    connection = Gio::DBusConnection::create_for_address_sync(address,
      Gio::DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT);
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Error connecting to D-Bus address " << address << ": " <<
      ex.what() << "." << std::endl;
    return;
  }

  std::cout << "Connected. " << std::endl <<
    "Negotiated capabilities: unix-fd-passing=" <<
    static_cast<bool>(connection->get_capabilities() & Gio::DBUS_CAPABILITY_FLAGS_UNIX_FD_PASSING) << "." << std::endl;

  // Get the current time to send as a greeting when calling a server's method.
  Glib::TimeVal time;
  time.assign_current_time();

  // Create the single string tuple parameter for the method call.

  Glib::ustring greeting("Hello, it's: "  + time.as_iso8601() + '.');

  Glib::Variant<Glib::ustring> param =
    Glib::Variant<Glib::ustring>::create(greeting);

  std::vector<Glib::VariantBase> variants;
  variants.push_back(param);

  Glib::VariantContainerBase parameters =
    Glib::VariantContainerBase::create_tuple(variants);

  try
  {
    Glib::VariantContainerBase result;
    connection->call_sync(result, "/org/glibmm/GDBus/TestObject",
      "org.glibmm.GDBus.TestPeerInterface",
      "HelloWorld", parameters);

    Glib::Variant<Glib::ustring> child;
    result.get(child);

    std::cout << "The server said: " << child.get() << "." << std::endl;

    connection->close_sync();
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Error calling the server's method: " << ex.what() << "." <<
      std::endl;
    return;
  }
}

int main(int argc, char** argv)
{
  std::locale::global(std::locale(""));
  Gio::init();

  bool opt_server = false;
  char* opt_address = 0;
  bool opt_allow_anonymous = false;

  static const GOptionEntry opt_entries[] =
  {
    { "server", 's', 0, G_OPTION_ARG_NONE, &opt_server, "Start a server instead of a client", NULL },
      { "address", 'a', 0, G_OPTION_ARG_STRING, &opt_address, "D-Bus address to use", NULL },
      { "allow-anonymous", 'n', 0, G_OPTION_ARG_NONE, &opt_allow_anonymous, "Allow anonymous authentication", NULL },
      { 0, '\0', 0, G_OPTION_ARG_NONE, 0, 0, 0 }
  };

  Glib::OptionContext opt_context("DBus peer-to-peer example");
  g_option_context_add_main_entries(opt_context.gobj(), opt_entries, 0);

  try
  {
    if(!opt_context.parse(argc, argv))
    {
      std::cerr << "Error parsing options and initializing.  Sorry." <<
        std::endl;
      return 1;
    }
  }
  catch(const Glib::OptionError& ex)
  {
    std::cerr << "Error parsing options: " << ex.what() << std::endl;
    return 1;
  }

  if(!opt_address)
  {
    std::cerr << "Incorrect usage, try the --help options." << std::endl;
    return 1;
  }

  if(!opt_server && opt_allow_anonymous)
  {
    std::cerr << "The --allow-anonymous option is only valid with the "
      "--server option." << std::endl;
    return 1;
  }

  try
  {
    introspection_data = Gio::DBusNodeInfo::create_for_xml(introspection_xml);
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Unable to create introspection data: " << ex.what() <<
      "." << std::endl;
    return 1;
  }

  if(opt_server)
    run_as_server(opt_address, opt_allow_anonymous);
  else
    run_as_client(opt_address);

  return 0;
}
