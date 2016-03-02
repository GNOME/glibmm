
#include <iostream>
#include <mutex>
#include <thread>

// TODO: Remove this example sometime. Glib::ThreadPool is deprecated.
// TODO: Maybe use std::async() instead?
#undef GLIBMM_DISABLE_DEPRECATED

#include <glibmmconfig.h>

#ifdef GLIBMM_DISABLE_DEPRECATED
int
main(int, char**)
{
  // If glibmm is configured with --disable-deprecated-api,
  // GLIBMM_DISABLE_DEPRECATED is defined in glibmmconfig.h.
  std::cout << "Glib::ThreadPool not available because deprecated API has been disabled."
            << std::endl;
  return 77; // Tell automake's test harness to skip this test.
}

#else

#include <glibmm/random.h>
#include <glibmm/threadpool.h>
#include <glibmm/timer.h>

namespace
{

std::mutex mutex;

void
print_char(char c)
{
  Glib::Rand rand;

  for (auto i = 0; i < 100; ++i)
  {
    {
      std::lock_guard<std::mutex> lock(mutex);
      std::cout << c;
      std::cout.flush();
    }
    Glib::usleep(rand.get_int_range(10000, 100000));
  }
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::ThreadPool pool(10);

  for (auto c = 'a'; c <= 'z'; ++c)
  {
    pool.push(sigc::bind(sigc::ptr_fun(&print_char), c));
  }

  pool.shutdown();

  std::cout << std::endl;

  return 0;
}
#endif // GLIBMM_DISABLE_DEPRECATED
