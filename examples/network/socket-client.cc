#include <cstring>
#include <giomm.h>
#include <glibmm.h>
#include <iostream>

Glib::RefPtr<Glib::MainLoop> loop;

gboolean verbose = FALSE;
gboolean non_blocking = FALSE;
gboolean use_udp = FALSE;
gboolean use_source = FALSE;
int cancel_timeout = 0;

static GOptionEntry cmd_entries[] = {
  {"cancel", 'c', 0, G_OPTION_ARG_INT, &cancel_timeout,
   "Cancel any op after the specified amount of seconds", NULL},
  {"udp", 'u', 0, G_OPTION_ARG_NONE, &use_udp,
   "Use udp instead of tcp", NULL},
  {"verbose", 'v', 0, G_OPTION_ARG_NONE, &verbose,
   "Be verbose", NULL},
  {"non-blocking", 'n', 0, G_OPTION_ARG_NONE, &non_blocking,
   "Enable non-blocking i/o", NULL},
  {"use-source", 's', 0, G_OPTION_ARG_NONE, &use_source,
   "Use GSource to wait for non-blocking i/o", NULL},
  {0, 0, 0, G_OPTION_ARG_NONE, 0, 0, 0}
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
source_ready (gpointer /*data*/,
              GIOCondition /*condition*/)
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
    GSource *source;

    if (!non_blocking)
        return;

    if (use_source)
    {
        source = g_socket_create_source (socket->gobj (),
                                         (GIOCondition) condition,
                                         cancellable->gobj ());
        g_source_set_callback (source,
                               (GSourceFunc) source_ready,
                               NULL, NULL);
        g_source_attach (source, NULL);
        loop->run ();
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

int
main (int argc,
      char *argv[])
{
    Glib::RefPtr<Gio::Socket> socket;
    Glib::RefPtr<Gio::SocketAddress> src_address;
    Glib::RefPtr<Gio::SocketAddress> address;
    Gio::SocketType socket_type;
    GError *error = NULL;
    GOptionContext *context;
    Glib::RefPtr<Gio::Cancellable> cancellable;
    Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator;
    Glib::RefPtr<Gio::SocketConnectable> connectable;

    Gio::init ();

    context = g_option_context_new (" <hostname>[:port] - Test GSocket client stuff");
    g_option_context_add_main_entries (context, cmd_entries, NULL);
    if (!g_option_context_parse (context, &argc, &argv, &error))
    {
        std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error->message);
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

    if (use_udp)
        socket_type = Gio::SOCKET_TYPE_DATAGRAM;
    else
        socket_type = Gio::SOCKET_TYPE_STREAM;

    try {
        // FIXME: enum.pl has a problem generating the SocketFamily enum
        // correctly, so I'm using the C enum directly for now as a workaround.
        socket = Gio::Socket::create ((Gio::SocketFamily)G_SOCKET_FAMILY_IPV4, socket_type, Gio::SOCKET_PROTOCOL_DEFAULT);
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
