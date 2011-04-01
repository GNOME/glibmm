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

/*

Usage examples (modulo addresses / credentials) (copied from the C API's
GDBusServer's example).

UNIX domain socket transport:

 Server:
   $ ./peer --server --address unix:abstract=myaddr
   Server is listening at: unix:abstract=myaddr
   Client connected.
   Peer credentials: GCredentials:unix-user=500,unix-group=500,unix-process=13378
   Negotiated capabilities: unix-fd-passing=1
   Client said: Hey, it's 1273093080 already!

 Client:
   $ ./peer --address unix:abstract=myaddr
   Connected.
   Negotiated capabilities: unix-fd-passing=1
   Server said: You said 'Hey, it's 1273093080 already!'. KTHXBYE!

Nonce-secured TCP transport on the same host:

 Server:
   $ ./peer --server --address nonce-tcp:
   Server is listening at: nonce-tcp:host=localhost,port=43077,noncefile=/tmp/gdbus-nonce-file-X1ZNCV
   Client connected.
   Peer credentials: (no credentials received)
   Negotiated capabilities: unix-fd-passing=0
   Client said: Hey, it's 1273093206 already!

 Client:
   $ ./peer -address nonce-tcp:host=localhost,port=43077,noncefile=/tmp/gdbus-nonce-file-X1ZNCV
   Connected.
   Negotiated capabilities: unix-fd-passing=0
   Server said: You said 'Hey, it's 1273093206 already!'. KTHXBYE!

TCP transport on two different hosts with a shared home directory:

 Server:
   host1 $ ./peer --server --address tcp:host=0.0.0.0
   Server is listening at: tcp:host=0.0.0.0,port=46314
   Client connected.
   Peer credentials: (no credentials received)
   Negotiated capabilities: unix-fd-passing=0
   Client said: Hey, it's 1273093337 already!

 Client:
   host2 $ ./peer -a tcp:host=host1,port=46314
   Connected.
   Negotiated capabilities: unix-fd-passing=0
   Server said: You said 'Hey, it's 1273093337 already!'. KTHXBYE!

TCP transport on two different hosts without authentication:

 Server:
   host1 $ ./peer --server --address tcp:host=0.0.0.0 --allow-anonymous
   Server is listening at: tcp:host=0.0.0.0,port=59556
   Client connected.
   Peer credentials: (no credentials received)
   Negotiated capabilities: unix-fd-passing=0
   Client said: Hey, it's 1273093652 already!

 Client:
   host2 $ ./peer -a tcp:host=host1,port=59556
   Connected.
   Negotiated capabilities: unix-fd-passing=0
   Server said: You said 'Hey, it's 1273093652 already!'. KTHXBYE!
*/

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

static Glib::RefPtr<Gio::DBus::NodeInfo> introspection_data;

static Glib::ustring introspection_xml =
  "<node>"
  "  <interface name='org.glibmm.DBus.TestPeerInterface'>"
  "    <method name='HelloWorld'>"
  "      <arg type='s' name='greeting' direction='in'/>"
  "      <arg type='s' name='response' direction='out'/>"
  "    </method>"
  "  </interface>"
  "</node>";

// This variable is used to keep an incoming connection active until it is
// closed.
static Glib::RefPtr<Gio::DBus::Connection> curr_connection;

static void on_method_call(const Glib::RefPtr<Gio::DBus::Connection>&,
  const Glib::ustring& /* sender */, const Glib::ustring& /* object_path */,
  const Glib::ustring& /* interface_name */, const Glib::ustring& method_name,
  // Since the parameters are generally tuples, get them from the invocation.
  const Glib::VariantBase& /* parameters */,
  const Glib::RefPtr<Gio::DBus::MethodInvocation>& invocation)
{
  if(method_name == "HelloWorld")
  {
    // Get parameters.
    Glib::VariantContainerBase parameters;
    invocation->get_parameters(parameters);

    // Get (expected) single string in tupple.
    Glib::Variant<Glib::ustring> param;
    parameters.get_child(param);

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
static const Gio::DBus::InterfaceVTable
  interface_vtable(sigc::ptr_fun(&on_method_call));

bool on_new_connection(const Glib::RefPtr<Gio::DBus::Connection>& connection)
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
    "Negotiated capabilities: unix-fd-passing=" << (connection->get_capabilities() & Gio::DBus::CAPABILITY_FLAGS_UNIX_FD_PASSING) << std::endl;

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

  guint reg_id = connection->register_object("/org/glibmm/DBus/TestObject",
    introspection_data->lookup_interface("org.glibmm.DBus.TestPeerInterface"),
    &interface_vtable);

  if(reg_id == 0)
  {
    std::cerr << "Registration of object for incoming connection not "
      "possible." << std::endl;
    return false;
  }

  return true;
}

void run_as_server(const Glib::ustring& address, bool allow_anonymous)
{
  Glib::ustring guid = Gio::DBus::generate_guid();
  Gio::DBus::ServerFlags flags = Gio::DBus::SERVER_FLAGS_NONE;

  if(allow_anonymous)
    flags |= Gio::DBus::SERVER_FLAGS_AUTHENTICATION_ALLOW_ANONYMOUS;

  Glib::RefPtr<Gio::DBus::Server> server;

  try
  {
    server = Gio::DBus::Server::create_sync(address, guid, flags);
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

void run_as_client(const Glib::ustring& address)
{
  Glib::RefPtr<Gio::DBus::Connection> connection;

  try
  {
    connection = Gio::DBus::Connection::create_for_address_sync(address,
      Gio::DBus::CONNECTION_FLAGS_AUTHENTICATION_CLIENT);
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Error connecting to D-Bus address " << address << ": " <<
      ex.what() << "." << std::endl;
    return;
  }

  std::cout << "Connected. " << std::endl <<
    "Negotiated capabilities: unix-fd-passing=" <<
    static_cast<bool>(connection->get_capabilities() & Gio::DBus::CAPABILITY_FLAGS_UNIX_FD_PASSING) << "." << std::endl;

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
    const Glib::VariantContainerBase result =
      connection->call_sync( "/org/glibmm/DBus/TestObject",
      "org.glibmm.DBus.TestPeerInterface",
      "HelloWorld", parameters);

    Glib::Variant<Glib::ustring> child;
    result.get_child(child);

    std::cout << "The server said: " << child.get() << "." << std::endl;

    connection->close_sync();
  }
  catch(const Glib::Error& ex)
  {
    std::cerr << "Error communicating with the server: " << ex.what() <<
      "." << std::endl;
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
    introspection_data = Gio::DBus::NodeInfo::create_for_xml(introspection_xml);
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
