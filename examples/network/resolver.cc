/* GIO - GLib Input, Output and Streaming Library
 *
 * Copyright (C) 2008 Red Hat, Inc.
 * Copyright (C) 2009 Jonathon Jongsma
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <giomm.h>
#include <iostream>
#include <mutex>
#include <thread>

#include <cerrno>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#ifndef G_OS_WIN32
#include <unistd.h>
#endif

#include <gio/gio.h>

static Glib::RefPtr<Gio::Resolver> resolver;
static Glib::RefPtr<Gio::Cancellable> cancellable;
static Glib::RefPtr<Glib::MainLoop> loop;
static int nlookups = 0;

static void G_GNUC_NORETURN
usage(void)
{
  std::cerr
    << "Usage: resolver [-t] [-s] [hostname | IP | service/protocol/domain ] ...\n"
    << "       resolver [-t] [-s] -c [hostname | IP | service/protocol/domain ]\n"
    << "       Use -s to do synchronous lookups.\n"
    << "       Use -c (and only a single resolvable argument) to test GSocketConnectable.\n";
  exit(1);
}

static std::mutex response_mutex;

static bool
idle_quit()
{
  loop->quit();
  return false;
}

static void
done_lookup(void)
{
  nlookups--;
  if (nlookups == 0)
  {
    /* In the sync case we need to make sure we don't call
     * g_main_loop_quit before the loop is actually running...
     */
    Glib::signal_idle().connect(sigc::ptr_fun(idle_quit));
  }
}

static void
print_resolved_name(const Glib::ustring& phys, const Glib::ustring& name)
{
  std::lock_guard<std::mutex> lock_guard(response_mutex);
  std::cout << Glib::ustring::compose("Address: %1\n", phys)
            << Glib::ustring::compose("Name:    %1\n", name) << std::endl;

  done_lookup();
}

static void
print_resolved_addresses(
  const Glib::ustring& name, const std::vector<Glib::RefPtr<Gio::InetAddress>>& addresses)
{
  std::lock_guard<std::mutex> lock_guard(response_mutex);
  std::cout << Glib::ustring::compose("Name:    %1\n", name);
  for (const auto& i : addresses)
  {
    std::cout << Glib::ustring::compose("Address: %1\n", i->to_string());
  }
  std::cout << std::endl;

  done_lookup();
}

static void
print_resolved_service(const Glib::ustring& service, const std::vector<Gio::SrvTarget>& targets)
{
  std::lock_guard<std::mutex> lock_guard(response_mutex);
  std::cout << Glib::ustring::compose("Service: %1\n", service);
  for (const auto& i : targets)
  {
    std::cout << Glib::ustring::compose("%1:%2 (pri %3, weight %4)\n", i.get_hostname(),
      i.get_port(), i.get_priority(), i.get_weight());
  }
  std::cout << std::endl;

  done_lookup();
}

static std::vector<Glib::ustring>
split_service_parts(const Glib::ustring& arg)
{
  std::vector<Glib::ustring> parts;
  std::size_t delim1 = 0;
  std::size_t delim2 = 0;
  delim1 = arg.find('/', 0);
  if (delim1 == std::string::npos)
    return parts;
  delim2 = arg.find('/', delim1 + 1);
  if (delim2 == std::string::npos)
    return parts;
  parts.emplace_back(arg.substr(0, delim1));
  parts.emplace_back(arg.substr(delim1 + 1, delim2 - delim1 - 1));
  parts.emplace_back(arg.substr(delim2 + 1));

  return parts;
}

static void
lookup_one_sync(const Glib::ustring& arg)
{
  if (arg.find('/') != std::string::npos)
  {
    /* service/protocol/domain */
    const auto parts = split_service_parts(arg);
    if (parts.size() != 3)
    {
      usage();
      return;
    }

    try
    {
      const auto targets = resolver->lookup_service(parts[0], parts[1], parts[2], cancellable);
      print_resolved_service(arg, targets);
    }
    catch (const Gio::ResolverError& err)
    {
      std::cerr << err.what() << std::endl;
    }
  }
  else if (Gio::hostname_is_ip_address(arg))
  {
    auto addr = Gio::InetAddress::create(arg);
    try
    {
      Glib::ustring name = resolver->lookup_by_address(addr, cancellable);
      print_resolved_name(arg, name);
    }
    catch (const Gio::ResolverError& err)
    {
      std::cerr << err.what() << std::endl;
    }
  }
  else
  {
    try
    {
      const auto addresses = resolver->lookup_by_name(arg, cancellable);
      print_resolved_addresses(arg, addresses);
    }
    catch (const Gio::ResolverError& err)
    {
      std::cerr << err.what() << std::endl;
    }
  }
}

static void
lookup_thread(const Glib::ustring& arg)
{
  lookup_one_sync(arg);
}

static std::vector<std::thread*>
start_threaded_lookups(char** argv, int argc)
{
  std::vector<std::thread*> result;
  for (auto i = 0; i < argc; i++)
  {
    const Glib::ustring arg = argv[i];
    const auto thread = new std::thread(&lookup_thread, arg);
    result.emplace_back(thread);
  }

  return result;
}

static void
lookup_by_addr_callback(Glib::RefPtr<Gio::AsyncResult> result, const Glib::ustring& phys)
{
  try
  {
    print_resolved_name(phys, resolver->lookup_by_address_finish(result));
  }
  catch (const Gio::ResolverError& err)
  {
    std::cerr << err.what() << std::endl;
    done_lookup();
  }
}

static void
lookup_by_name_callback(Glib::RefPtr<Gio::AsyncResult> result, const Glib::ustring& name)
{
  try
  {
    print_resolved_addresses(name, resolver->lookup_by_name_finish(result));
  }
  catch (const Gio::ResolverError& err)
  {
    std::cerr << err.what() << std::endl;
  }
}

static void
lookup_service_callback(Glib::RefPtr<Gio::AsyncResult> result, const Glib::ustring& service)
{
  try
  {
    print_resolved_service(service, resolver->lookup_service_finish(result));
  }
  catch (const Gio::ResolverError& err)
  {
    std::cerr << err.what() << std::endl;
  }
}

static void
start_async_lookups(char** argv, int argc)
{
  for (auto i = 0; i < argc; i++)
  {
    Glib::ustring arg(argv[i]);
    if (arg.find('/') != std::string::npos)
    {
      /* service/protocol/domain */
      auto parts = split_service_parts(arg);
      if (parts.size() != 3)
      {
        usage();
        return;
      }

      resolver->lookup_service_async(parts[0], parts[1], parts[2],
        sigc::bind(sigc::ptr_fun(lookup_service_callback), Glib::ustring(argv[i])), cancellable);
    }
    else if (Gio::hostname_is_ip_address(argv[i]))
    {
      auto addr = Gio::InetAddress::create(argv[i]);

      resolver->lookup_by_address_async(
        addr, sigc::bind(sigc::ptr_fun(lookup_by_addr_callback), argv[i]), cancellable);
    }
    else
    {
      resolver->lookup_by_name_async(
        argv[i], sigc::bind(sigc::ptr_fun(lookup_by_name_callback), argv[i]), cancellable);
    }

    /* Stress-test the reloading code */
    // g_signal_emit_by_name (resolver, "reload");
  }
}

static void
print_connectable_sockaddr(Glib::RefPtr<Gio::SocketAddress> sockaddr)
{
  Glib::ustring phys;
  auto isa = std::dynamic_pointer_cast<Gio::InetSocketAddress>(sockaddr);

  if (!isa)
  {
    std::cerr << Glib::ustring::compose("Error: Unexpected sockaddr type '%1'\n",
      g_type_name_from_instance((GTypeInstance*)sockaddr->gobj()));
  }
  else
  {
    phys = isa->get_address()->to_string();
    std::cout << Glib::ustring::compose("Address: %1%2%3:%4\n",
      phys.find(':') != std::string::npos ? "[" : "", phys,
      phys.find(':') != std::string::npos ? "]" : "", isa->get_port());
  }
}

static void
do_sync_connectable(Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator)
{
  Glib::RefPtr<Gio::SocketAddress> sockaddr;

  while ((sockaddr = enumerator->next(cancellable)))
    print_connectable_sockaddr(sockaddr);

  done_lookup();
}

static void do_async_connectable(Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator);

static void
got_next_async(
  Glib::RefPtr<Gio::AsyncResult> result, Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator)
{
  try
  {
    const auto sockaddr = enumerator->next_finish(result);
    if (sockaddr)
    {
      print_connectable_sockaddr(sockaddr);
      do_async_connectable(enumerator);
    }
    else
    {
      done_lookup();
    }
  }
  catch (const Gio::ResolverError& err)
  {
    std::cerr << err.what() << std::endl;
  }
}

Glib::RefPtr<Gio::SocketAddressEnumerator> global_enumerator;
static void
do_async_connectable(Glib::RefPtr<Gio::SocketAddressEnumerator> enumerator)
{
  enumerator->next_async(cancellable, sigc::bind(sigc::ptr_fun(got_next_async), enumerator));
}

Glib::RefPtr<Gio::SocketConnectable> global_connectable;

static void
do_connectable(const Glib::ustring& arg, gboolean synchronous)
{
  std::vector<Glib::ustring> parts;
  Glib::RefPtr<Gio::SocketConnectable> connectable;

  if (arg.find('/') != Glib::ustring::npos)
  {
    /* service/protocol/domain */
    parts = split_service_parts(arg);
    if (parts.size() != 3)
    {
      usage();
      return;
    }

    connectable = Gio::NetworkService::create(parts[0], parts[1], parts[2]);
  }
  else
  {
    Glib::ustring host;
    guint16 port = 0;

    const auto pos = arg.find(':');
    if (pos != Glib::ustring::npos)
    {
      host = arg.substr(0, pos);
      auto port_str = arg.substr(pos);
      port = std::stoul(port_str.raw());
    }

    if (Gio::hostname_is_ip_address(host))
    {
      const auto addr = Gio::InetAddress::create(host);
      connectable = Gio::InetSocketAddress::create(addr, port);
    }
    else
      connectable = Gio::NetworkAddress::create(arg.raw(), port);
  }

  const auto enumerator = connectable->enumerate();
  if (synchronous)
    do_sync_connectable(enumerator);
  else
    do_async_connectable(enumerator);
}

#ifdef G_OS_UNIX
static volatile int cancel_fd;

static void
interrupted(int /*sig*/)
{
  const int save_errno = errno;
  while (write(cancel_fd, "", 1) < 0 && errno == EINTR)
  {
  }
  errno = save_errno;
}

static bool
async_cancel(Glib::IOCondition /*cond*/, Glib::RefPtr<Gio::Cancellable> the_cancellable)
{
  the_cancellable->cancel();
  return false;
}
#endif

int
main(int argc, char** argv)
{
  auto synchronous = false;
  auto use_connectable = false;
#ifdef G_OS_UNIX
  Glib::RefPtr<Glib::IOChannel> chan;
  sigc::connection watch_conn;
#endif

  // TODO: Use Glib::OptionContext.
  while (argc >= 2 && argv[1][0] == '-')
  {
    if (!strcmp(argv[1], "-s"))
      synchronous = true;
    else if (!strcmp(argv[1], "-c"))
      use_connectable = true;
    else
      usage();

    argv++;
    argc--;
  }

  Gio::init();

  if (argc < 2 || (argc > 2 && use_connectable))
    usage();

  resolver = Gio::Resolver::get_default();

  cancellable = Gio::Cancellable::create();

#ifdef G_OS_UNIX
  /* Set up cancellation; we want to cancel if the user ^C's the
   * program, but we can't cancel directly from an interrupt.
   */
  int cancel_fds[2];

  if (pipe(cancel_fds) < 0)
  {
    perror("pipe");
    exit(1);
  }
  cancel_fd = cancel_fds[1];
  signal(SIGINT, interrupted);

  chan = Glib::IOChannel::create_from_fd(cancel_fds[0]);
  const auto source = chan->create_watch(Glib::IOCondition::IO_IN);
  watch_conn = source->connect(sigc::bind(sigc::ptr_fun(async_cancel), cancellable));
#endif

  nlookups = argc - 1;
  loop = Glib::MainLoop::create(true);

  std::vector<std::thread*> threads;
  if (use_connectable)
    do_connectable(argv[1], synchronous);
  else
  {
    if (synchronous)
      threads = start_threaded_lookups(argv + 1, argc - 1);
    else
      start_async_lookups(argv + 1, argc - 1);
  }

  loop->run();

  // Join and delete each thread:
  std::for_each(threads.begin(), threads.end(), [](std::thread* thread) {
    thread->join();
    delete thread;
  });

#ifdef G_OS_UNIX
  watch_conn.disconnect();
#endif

  return 0;
}
