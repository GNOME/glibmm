#include <iostream>
#include <giomm.h>
#include <glibmm.h>

Glib::RefPtr<Glib::MainLoop> loop;

int port = 7777;
gboolean verbose = FALSE;
gboolean dont_reuse_address = FALSE;
gboolean non_blocking = FALSE;
gboolean use_udp = FALSE;
gboolean use_source = FALSE;
int cancel_timeout = 0;

static GOptionEntry cmd_entries[] = {
  {"port", 'p', 0, G_OPTION_ARG_INT, &port,
   "Local port to bind to", NULL},
  {"cancel", 'c', 0, G_OPTION_ARG_INT, &cancel_timeout,
   "Cancel any op after the specified amount of seconds", NULL},
  {"udp", 'u', 0, G_OPTION_ARG_NONE, &use_udp,
   "Use udp instead of tcp", NULL},
  {"verbose", 'v', 0, G_OPTION_ARG_NONE, &verbose,
   "Be verbose", NULL},
  {"no-reuse", 0, 0, G_OPTION_ARG_NONE, &dont_reuse_address,
   "Don't SOADDRREUSE", NULL},
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
    Glib::RefPtr<Gio::Socket> socket, new_socket, recv_socket;
    Glib::RefPtr<Gio::SocketAddress> src_address;
    Glib::RefPtr<Gio::SocketAddress> address;
    Gio::SocketType socket_type;
    GError *error = NULL;
    GOptionContext *context;
    Glib::RefPtr<Gio::Cancellable> cancellable;

    Gio::init ();

    context = g_option_context_new (" - Test GSocket server stuff");
    g_option_context_add_main_entries (context, cmd_entries, NULL);
    if (!g_option_context_parse (context, &argc, &argv, &error))
    {
        std::cerr << Glib::ustring::compose ("%1: %1\n", argv[0], error->message);
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
        socket = Gio::Socket::create ((Gio::SocketFamily)G_SOCKET_FAMILY_IPV4, socket_type, Gio::SOCKET_PROTOCOL_DEFAULT);
    } catch (const Gio::Error& error)
    {
        std::cerr << Glib::ustring::compose ("%1: %2\n", argv[0], error.what ());
        return 1;
    }

    if (non_blocking)
        socket->set_blocking (false);

    src_address = Gio::InetSocketAddress::create (Gio::InetAddress::create_any ((Gio::SocketFamily) G_SOCKET_FAMILY_IPV4), port);
    try {
        socket->bind (src_address, !dont_reuse_address);
    } catch (const Gio::Error& error) {
        std::cerr << Glib::ustring::compose ("Can't bind socket: %1\n",
                                             error.what ());
        return 1;
    }

    if (!use_udp)
    {
        try {
            socket->listen ();
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("Can't listen on socket: %1\n",
                                                 error.what ());
            return 1;
        }

        std::cout << Glib::ustring::compose ("listening on port %1...\n", port);

        ensure_condition (socket, "accept", cancellable, Glib::IO_IN);
        try {
            new_socket = socket->accept (cancellable);
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("Error accepting socket: %1\n",
                                                 error.what ());
            return 1;
        }

        if (non_blocking)
            new_socket->set_blocking (false);

        try {
        address = new_socket->get_remote_address ();
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("Error getting remote address: %1\n",
                                                 error.what ());
            return 1;
        }

        std::cout << Glib::ustring::compose ("got a new connection from %1\n",
                                             socket_address_to_string (address));

        recv_socket = new_socket;
    }
    else
    {
        recv_socket = socket;
    }


    while (true)
    {
        gchar buffer[4096] = { };
        gssize size;
        gsize to_send;

        ensure_condition (recv_socket, "receive", cancellable, Glib::IO_IN);
        try {
            if (use_udp)
                size = recv_socket->receive_from (address,
                                                  buffer, sizeof buffer,
                                                  cancellable);
            else
                size = recv_socket->receive (buffer, sizeof buffer,
                                             cancellable);
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
            std::cout << Glib::ustring::compose (" from %1", socket_address_to_string (address));
        std::cout << std::endl;

        if (verbose)
            g_print ("-------------------------\n"
                     "%.*s\n"
                     "-------------------------\n",
                     (int)size, buffer);

        to_send = size;

        while (to_send > 0)
        {
            ensure_condition (recv_socket, "send", cancellable, Glib::IO_OUT);
            try {
                if (use_udp)
                    size = recv_socket->send_to (address,
                                                 buffer, to_send, cancellable);
                else
                    size = recv_socket->send (buffer, to_send,
                                              cancellable);
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
    }

    std::cout << "connection closed\n";

    if (new_socket)
    {
        try {
            new_socket->close ();
        } catch (const Gio::Error& error)
        {
            std::cerr << Glib::ustring::compose ("Error closing connection socket: %1\n",
                                                 error.what ());
            return 1;
        }
    }

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
