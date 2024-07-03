// This test case fails unless an implementation of TLS backend is installed.
// (Exception caught: TLS support is not available.)
// Module glib-networking implements TLS backend.
//
// Even if glib-networking is installed, it's possible that glib does not find it.
// That's very probable if glib and glib-networking are installed with different
// directory prefixes, e.g. glib in /opt/gnome and glib-networking in /usr.
// You can fix that by setting the GIO_EXTRA_MODULES environment variable to
// the directory to search for implementations of gio extension points.
// Example:
//   export GIO_EXTRA_MODULES=/usr/lib/x86_64-linux-gnu/gio/modules
// If you don't know where the implementations of gio extension points are stored,
// search for a file named giomodule.cache.
//
// https://docs.gtk.org/gio/const.TLS_BACKEND_EXTENSION_POINT_NAME.html
// https://docs.gtk.org/gio/struct.IOExtensionPoint.html
// https://docs.gtk.org/gio/gio-querymodules.html (2024-07-02: broken link)

#include <cstdlib>
#include <giomm.h>
#include <iostream>

bool
on_accept_certificate(const Glib::RefPtr<const Gio::TlsCertificate>& cert, Gio::TlsCertificateFlags)
{
  std::cout << "Handshake is ocurring." << std::endl
            << "The server is requesting that its certificate be accepted." << std::endl;

  std::cout << "Outputing certificate data:" << std::endl
            << cert->property_certificate_pem().get_value();

  auto issuer = cert->get_issuer();

  std::cout << "Outputing the issuer's certificate data:" << std::endl
            << issuer->property_certificate_pem().get_value();

  std::cout << "Accepting the certificate (completing the handshake)." << std::endl;

  return true;
}

int
main(int, char**)
{
  Gio::init();

  const Glib::ustring test_host = "www.gnome.org";

  std::vector<Glib::RefPtr<Gio::InetAddress>> inet_addresses;

  try
  {
    inet_addresses = Gio::Resolver::get_default()->lookup_by_name(test_host);
  }
  catch (const Gio::ResolverError& ex)
  {
    // This happens if it could not resolve the name,
    // for instance if we are not connected to the internet.
    // TODO: Change this test so it can do something useful and succeed even
    // if the testing computer is not connected to the internet.
    std::cerr << "Gio::Resolver::lookup_by_name() threw exception: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }

  // Actually, it would throw an exception instead of reaching here with 0 addresses resolved.
  if (inet_addresses.size() == 0)
  {
    std::cerr << "Could not resolve test host '" << test_host << "'." << std::endl;
    return EXIT_FAILURE;
  }

  std::cout << "Successfully resolved address of test host '" << test_host << "'." << std::endl;

  auto first_inet_address = inet_addresses[0];

  std::cout << "First address of test host is " << first_inet_address->to_string() << "."
            << std::endl;

  Glib::RefPtr<Gio::Socket> socket;
  try
  {
    socket = Gio::Socket::create(
      first_inet_address->get_family(), Gio::Socket::Type::STREAM, Gio::Socket::Protocol::TCP);
  }
  catch (const Gio::Error& ex)
  {
    std::cout << "Could not create socket. Exception: " << ex.what() << std::endl;
    return EXIT_FAILURE;
  }

  Glib::RefPtr<Gio::InetSocketAddress> address;
  try
  {
    address = Gio::InetSocketAddress::create(first_inet_address, 443);
    socket->connect(address);
  }
  catch (const Gio::Error& ex)
  {
    if (!address)
      std::cout << "Could not create socket address. Exception: " << ex.what() << std::endl;
    else
      std::cout << "Could not connect socket to " << address->get_address()->to_string() << ":"
                << address->get_port() << ". Exception: " << ex.what() << std::endl;

    // When running CI (continuous integration), socket->connect(address)
    // sometimes fails. Skip this test.
    return 77;
  }

  if (!socket->is_connected())
  {
    std::cout << "Could not connect socket to " << address->get_address()->to_string() << ":"
              << address->get_port() << "." << std::endl;
  }

  auto conn = std::dynamic_pointer_cast<Gio::TcpConnection>(Gio::SocketConnection::create(socket));

  if (!conn || !conn->is_connected())
  {
    std::cout << "Could not establish connection to " << address->get_address()->to_string() << ":"
              << address->get_port() << "." << std::endl;
    socket->close();
    return EXIT_FAILURE;
  }

  std::cout << "Successfully established connection to " << address->get_address()->to_string()
            << ":" << address->get_port() << "." << std::endl;

  try
  {
    auto tls_connection = Gio::TlsClientConnection::create(conn, address);

    tls_connection->signal_accept_certificate().connect(sigc::ptr_fun(&on_accept_certificate), false);

    tls_connection->handshake();

    std::cout << "Attempting to get the issuer's certificate from the "
                 "connection."
              << std::endl;

    auto issuer_certificate = tls_connection->get_peer_certificate()->get_issuer();

    if (!issuer_certificate)
    {
      std::cout << "Could not get the issuer's certificate of the peer." << std::endl;
      return EXIT_FAILURE;
    }
    std::cout << "Successfully retrieved the issuer's certificate." << std::endl;

    std::cout << "Attempting to use the connection's database." << std::endl;
    auto database = tls_connection->get_database();

    std::cout << "Looking up the certificate's issuer in the database." << std::endl;

    auto db_certificate = database->lookup_certificate_issuer(issuer_certificate);

    if (!db_certificate)
    {
      std::cout << "The issuer's certificate was not found in the database." << std::endl;
    }
    else
    {
      std::cout << "Successfully found the issuer's certificate in the database." << std::endl;
    }
  }
  catch (const Gio::TlsError& error)
  {
    std::cout << "Exception caught: " << error.what() << "." << std::endl;
    return EXIT_FAILURE;
  }

  conn->close();

  return EXIT_SUCCESS;
}
