#include <cstring>
#include <giomm.h>
#include <glibmm.h>
#include <iostream>

namespace
{

Glib::RefPtr<Glib::MainLoop> loop;

bool verbose = false;
bool non_blocking = false;
bool use_udp = false;
bool use_source = false;
bool use_ipv6 = false;
int cancel_timeout = 0;

class ClientOptionGroup : public Glib::OptionGroup
{
public:
  ClientOptionGroup()
  : Glib::OptionGroup("client_group", "", "")
  {
    Glib::OptionEntry entry;
    entry.set_long_name("cancel");
    entry.set_short_name('c');
    entry.set_description("Cancel any op after the specified amount of seconds");
    add_entry(entry, cancel_timeout);

    entry.set_long_name("udp");
    entry.set_short_name('u');
    entry.set_description("Use UDP instead of TCP");
    add_entry(entry, use_udp);

    entry.set_long_name("verbose");
    entry.set_short_name('v');
    entry.set_description("Be verbose");
    add_entry(entry, verbose);

    entry.set_long_name("non-blocking");
    entry.set_short_name('n');
    entry.set_description("Enable non-blocking I/O");
    add_entry(entry, non_blocking);

    entry.set_long_name("use-source");
    entry.set_short_name('s');
    entry.set_description("Use Gio::SocketSource to wait for non-blocking I/O");
    add_entry(entry, use_source);

    entry.set_long_name("use-ipv6");
    entry.set_short_name('6');
    entry.set_description("Use IPv6 address family");
    add_entry(entry, use_ipv6);
  }
};  

Glib::ustring
socket_address_to_string (const Glib::RefPtr<Gio::SocketAddress>& address)
{
    Glib::RefPtr<Gio::InetAddress> inet_address;
    Glib::ustring str, res;
    int port;

    Glib::RefPtr<Gio::InetSocketAddress> isockaddr =
        Glib::RefPtr<Gio::InetSocketAddress>::cast_dynamic (address);
    if (!isockaddr)
        return Glib::ustring ();
    inet_address = isockaddr->get_address ();
    str = inet_address->to_string ();
    port = isockaddr->get_port ();
    res = Glib::ustring::compose ("%1:%2", str, port);
    return res;
}

static bool
source_ready(Glib::IOCondition /*condition*/)
{
  loop->quit ();
  return false;
}

static void
ensure_condition (const Glib::RefPtr<Gio::Socket>& socket,
                  const Glib::ustring& where,
                  const Glib::RefPtr<Gio::Cancellable>& cancellable,
                  Glib::IOCondition condition)
{
    if (!non_blocking)
        return;

    if (use_source)
    {
      Glib::RefPtr<Gio::SocketSource> source = socket->create_source(condition, cancellable);
      source->connect(sigc::ptr_fun(&source_ready));
      source->attach();
      loop->run();
    }
    else
    {
        try {
            socket->condition_wait (condition, cancellable);
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose("condition wait error for %1: %2\n",
                        where, error.what ());
            exit (1);
        }
    }
}

static void
cancel_thread (Glib::RefPtr<Gio::Cancellable> cancellable)
{
    g_usleep (1000*1000*cancel_timeout);
    std::cout << "Cancelling\n";
    cancellable->cancel ();
}

} // end anonymous namespace

int
main (int argc,
      char *argv[])
{
    Glib::RefPtr<Gio::Socket> socket;
    Glib::RefPtr<Gio::SocketAddress> src_address;
    Glib::RefPtr<Gio::SocketAddress> address;
    Gio::SocketType socket_type;
    Gio::SocketFamily socket_family;
    Glib::RefPtr<Gio::Cancellable> cancellable;
    Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator;
    Glib::RefPtr<Gio::SocketConnectable> connectable;

    Gio::init ();

    Glib::OptionContext option_context(" <hostname>[:port] - Test Gio::Socket client stuff");
    option_context.set_summary("Default port: 7777\n"
    "For a local test with socket-server:\n"
    "  ./socket-client [option...] localhost\n"
    "or, if that fails\n"
    "  ./socket-client [option...] 127.0.0.1  (IPv4)\n"
    "  ./socket-client [option...] ::1        (IPv6)");
    ClientOptionGroup option_group;
    option_context.set_main_group(option_group);
    try
    {
      option_context.parse(argc, argv);
    }
    catch (const Glib::Error& error)
    {
      std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error.what());
      return 1;
    }

    if (argc != 2)
    {
        const char* error_message = "Need to specify hostname";
        std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error_message);
        return 1;
    }

    if (cancel_timeout)
    {
        cancellable = Gio::Cancellable::create ();
        Glib::Threads::Thread::create (sigc::bind (sigc::ptr_fun (cancel_thread), cancellable));
    }

    loop = Glib::MainLoop::create ();

    socket_type = use_udp ? Gio::SOCKET_TYPE_DATAGRAM : Gio::SOCKET_TYPE_STREAM;
    socket_family = use_ipv6 ? Gio::SOCKET_FAMILY_IPV6 : Gio::SOCKET_FAMILY_IPV4;

    try {
        socket = Gio::Socket::create (socket_family, socket_type, Gio::SOCKET_PROTOCOL_DEFAULT);
    } catch (const Gio::Error& error)
    {
        std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error.what ());
        return 1;
    }

    try {
        connectable = Gio::NetworkAddress::parse (argv[1], 7777);
    } catch (const Gio::Error& error)
    {
        std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error.what ());
        return 1;
    }

    enumerator = connectable->enumerate ();
    while (true)
    {
        try {
            address = enumerator->next (cancellable);
            if (!address) {
                std::cerr << Glib::ustring::compose ("%1: No more addresses to try\n", argv[0]);
                return 1;
            }
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error.what ());
            return 1;
        }

        try {
            socket->connect (address, cancellable);
            break;
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("%1: Connection to %2 failed: %3, trying next\n",
                                                 argv[0], socket_address_to_string (address),
                                                 error.what ());
        }
    }

    std::cout << Glib::ustring::compose ("Connected to %1\n",
                                         socket_address_to_string (address));

    /* TODO: Test non-blocking connect */
    if (non_blocking)
        socket->set_blocking (false);

    try {
        src_address = socket->get_local_address ();
    } catch (const Gio::Error& error)
    {
        std::cerr << Glib::ustring::compose ("Error getting local address: %1\n",
                    error.what ());
        return 1;
    }
    std::cout << Glib::ustring::compose ("local address: %1\n",
                                         socket_address_to_string (src_address));

    while (true)
    {
        gchar buffer[4096] = { };
        gssize size;
        gsize to_send;

        if (!std::cin.getline (buffer, sizeof buffer - 1))
            break;

        to_send = strlen (buffer);
        buffer[to_send++] = '\n';
        buffer[to_send] = '\0';
        while (to_send > 0)
        {
            ensure_condition (socket, "send", cancellable, Glib::IO_OUT);
            try {
                if (use_udp)
                    size = socket->send_to (address, buffer, to_send,
                                            cancellable);
                else
                    size = socket->send (buffer, to_send, cancellable);

            } catch (const Gio::Error& error)
            {
                if (error.code () == Gio::Error::WOULD_BLOCK)
                {
                    std::cout << "socket send would block, handling\n";
                    continue;
                }
                else
                {
                    std::cerr << Glib::ustring::compose ("Error sending to socket: %1\n",
                                                         error.what ());
                    return 1;
                }
            }

            std::cout << Glib::ustring::compose ("sent %1 bytes of data\n", size);

            if (size == 0)
            {
                std::cerr << "Unexpected short write\n";
                return 1;
            }

            to_send -= size;
        }

        ensure_condition (socket, "receive", cancellable, Glib::IO_IN);
        try {
            if (use_udp)
                size = socket->receive_from (src_address, buffer, sizeof buffer,
                                             cancellable);
            else
                size = socket->receive (buffer, sizeof buffer, cancellable);

        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("Error receiving from socket: %1\n",
                                                 error.what ());
            return 1;
        }

        if (size == 0)
            break;

        std::cout << Glib::ustring::compose ("received %1 bytes of data", size);
        if (use_udp)
            std::cout << Glib::ustring::compose (" from %1", socket_address_to_string (src_address));
        std::cout << std::endl;

        if (verbose)
            g_print ("-------------------------\n"
                     "%.*s"
                     "-------------------------\n",
                     (int)size, buffer);

    }

    std::cout << "closing socket\n";

    try {
        socket->close ();
    } catch (const Gio::Error& error)
    {
        std::cerr << Glib::ustring::compose ("Error closing master socket: %1\n",
                                             error.what ());
        return 1;
    }

    return 0;
}
