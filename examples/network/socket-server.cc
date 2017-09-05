#include <chrono>
#include <condition_variable>
#include <giomm.h>
#include <glibmm.h>
#include <iostream>
#include <memory>
#include <mutex>
#include <thread>

namespace
{

Glib::RefPtr<Glib::MainLoop> loop;

int port = 7777;
bool verbose = false;
bool dont_reuse_address = false;
bool non_blocking = false;
bool use_udp = false;
bool use_source = false;
bool use_ipv6 = false;
int cancel_timeout = 0;
bool stop_thread = false;
std::mutex mutex_thread;
std::condition_variable cond_thread;

class ServerOptionGroup : public Glib::OptionGroup
{
public:
  ServerOptionGroup() : Glib::OptionGroup("server_group", "", "")
  {
    Glib::OptionEntry entry;
    entry.set_long_name("port");
    entry.set_short_name('p');
    entry.set_description("Local port to bind to, default: 7777");
    add_entry(entry, port);

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

    entry.set_long_name("no-reuse");
    entry.set_short_name('\0');
    entry.set_description("Don't SOADDRREUSE");
    add_entry(entry, dont_reuse_address);

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
socket_address_to_string(const Glib::RefPtr<Gio::SocketAddress>& address)
{
  auto isockaddr = std::dynamic_pointer_cast<Gio::InetSocketAddress>(address);
  if (!isockaddr)
    return Glib::ustring();

  auto inet_address = isockaddr->get_address();
  auto str = inet_address->to_string();
  auto the_port = isockaddr->get_port();
  auto res = Glib::ustring::compose("%1:%2", str, the_port);
  return res;
}

static bool source_ready(Glib::IOCondition /*condition*/)
{
  loop->quit();
  return false;
}

static void
ensure_condition(const Glib::RefPtr<Gio::Socket>& socket, const Glib::ustring& where,
  const Glib::RefPtr<Gio::Cancellable>& cancellable, Glib::IOCondition condition)
{
  if (!non_blocking)
    return;

  if (use_source)
  {
    Gio::signal_socket().connect(sigc::ptr_fun(&source_ready), socket, condition);
    loop->run();
  }
  else
  {
    try
    {
      socket->condition_wait(condition, cancellable);
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("condition wait error for %1: %2\n", where, error.what());
      exit(1);
    }
  }
}

static void
cancel_thread(Glib::RefPtr<Gio::Cancellable> cancellable)
{
  std::unique_lock<std::mutex> lock(mutex_thread);
  if (!cond_thread.wait_for(
        lock, std::chrono::seconds(cancel_timeout), []() { return stop_thread; }))
  {
    // !stop_thread, i.e. timeout
    std::cout << "Cancelling\n";
    cancellable->cancel();
  }
}

class JoinAndDelete
{
public:
  void operator()(std::thread* thread) const
  {
    stop_thread = true;
    cond_thread.notify_all();
    thread->join();
    delete thread;
  }
};

} // end anonymous namespace

int
main(int argc, char* argv[])
{
  Glib::RefPtr<Gio::Socket> socket, new_socket, recv_socket;
  Glib::RefPtr<Gio::SocketAddress> address;
  Glib::RefPtr<Gio::Cancellable> cancellable;

  Gio::init();

  Glib::OptionContext option_context(" - Test Gio::Socket server stuff");
  ServerOptionGroup option_group;
  option_context.set_main_group(option_group);
  try
  {
    option_context.parse(argc, argv);
  }
  catch (const Glib::Error& error)
  {
    std::cerr << Glib::ustring::compose("%1: %2\n", argv[0], error.what());
    return 1;
  }

  std::unique_ptr<std::thread, JoinAndDelete> thread;
  if (cancel_timeout)
  {
    cancellable = Gio::Cancellable::create();
    thread.reset(new std::thread(&cancel_thread, cancellable));
  }

  loop = Glib::MainLoop::create();

  auto socket_type = use_udp ? Gio::Socket::Type::DATAGRAM : Gio::Socket::Type::STREAM;
  auto socket_family = use_ipv6 ? Gio::SocketFamily::IPV6 : Gio::SocketFamily::IPV4;

  try
  {
    socket = Gio::Socket::create(socket_family, socket_type, Gio::Socket::Protocol::DEFAULT);
  }
  catch (const Gio::Error& error)
  {
    std::cerr << Glib::ustring::compose("%1: %2\n", argv[0], error.what());
    return 1;
  }

  if (non_blocking)
    socket->set_blocking(false);

  auto src_address =
    Gio::InetSocketAddress::create(Gio::InetAddress::create_any(socket_family), port);
  try
  {
    socket->bind(src_address, !dont_reuse_address);
  }
  catch (const Gio::Error& error)
  {
    std::cerr << Glib::ustring::compose("Can't bind socket: %1\n", error.what());
    return 1;
  }

  if (!use_udp)
  {
    try
    {
      socket->listen();
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("Can't listen on socket: %1\n", error.what());
      return 1;
    }

    std::cout << Glib::ustring::compose("listening on port %1...\n", port);

    ensure_condition(socket, "accept", cancellable, Glib::IOCondition::IO_IN);
    try
    {
      new_socket = socket->accept(cancellable);
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("Error accepting socket: %1\n", error.what());
      return 1;
    }

    if (non_blocking)
      new_socket->set_blocking(false);

    try
    {
      address = new_socket->get_remote_address();
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("Error getting remote address: %1\n", error.what());
      return 1;
    }

    std::cout << Glib::ustring::compose(
      "got a new connection from %1\n", socket_address_to_string(address));

    recv_socket = new_socket;
  }
  else
  {
    recv_socket = socket;
  }

  while (true)
  {
    gchar buffer[4096] = {};
    gssize size;

    ensure_condition(recv_socket, "receive", cancellable, Glib::IOCondition::IO_IN);
    try
    {
      if (use_udp)
        size = recv_socket->receive_from(address, buffer, sizeof buffer, cancellable);
      else
        size = recv_socket->receive(buffer, sizeof buffer, cancellable);
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("Error receiving from socket: %1\n", error.what());
      return 1;
    }

    if (size == 0)
      break;

    std::cout << Glib::ustring::compose("received %1 bytes of data", size);
    if (use_udp)
      std::cout << Glib::ustring::compose(" from %1", socket_address_to_string(address));
    std::cout << std::endl;

    if (verbose)
      g_print("-------------------------\n"
              "%.*s\n"
              "-------------------------\n",
        (int)size, buffer);

    auto to_send = size;

    while (to_send > 0)
    {
      ensure_condition(recv_socket, "send", cancellable, Glib::IOCondition::IO_OUT);
      try
      {
        if (use_udp)
          size = recv_socket->send_to(address, buffer, to_send, cancellable);
        else
          size = recv_socket->send(buffer, to_send, cancellable);
      }
      catch (const Gio::Error& error)
      {
        if (error.code() == Gio::Error::WOULD_BLOCK)
        {
          std::cout << "socket send would block, handling\n";
          continue;
        }
        else
        {
          std::cerr << Glib::ustring::compose("Error sending to socket: %1\n", error.what());
          return 1;
        }
      }

      std::cout << Glib::ustring::compose("sent %1 bytes of data\n", size);

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
    try
    {
      new_socket->close();
    }
    catch (const Gio::Error& error)
    {
      std::cerr << Glib::ustring::compose("Error closing connection socket: %1\n", error.what());
      return 1;
    }
  }

  try
  {
    socket->close();
  }
  catch (const Gio::Error& error)
  {
    std::cerr << Glib::ustring::compose("Error closing master socket: %1\n", error.what());
    return 1;
  }

  return 0;
}
