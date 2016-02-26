
#include <condition_variable>
#include <iostream>
#include <memory>
#include <mutex>
#include <queue>
#include <thread>
#if defined(_MSC_VER) && (_MSC_VER < 1900)
/* For using noexcept on Visual Studio 2013 */
#include <glibmmconfig.h>
#endif
#include <glibmm/init.h>
#include <glibmm/random.h>
#include <glibmm/timer.h>

namespace
{

class MessageQueue
{
public:
  MessageQueue();
  ~MessageQueue();

  void producer();
  void consumer();

private:
  std::mutex mutex_;
  std::condition_variable cond_push_;
  std::condition_variable cond_pop_;
  std::queue<int> queue_;
};

MessageQueue::MessageQueue()
{
}

MessageQueue::~MessageQueue()
{
}

void
MessageQueue::producer()
{
  Glib::Rand rand(1234);

  for (auto i = 0; i < 200; ++i)
  {
    {
      std::unique_lock<std::mutex> lock(mutex_);

      cond_pop_.wait(lock, [this]() -> bool { return queue_.size() < 64; });

      queue_.push(i);
      std::cout << '*';
      std::cout.flush();

      // We unlock before notifying, because that is what the documentation suggests:
      // http://en.cppreference.com/w/cpp/thread/condition_variable
      lock.unlock();
      cond_push_.notify_one();
    }

    if (rand.get_bool())
      continue;

    Glib::usleep(rand.get_int_range(0, 100000));
  }
}

void
MessageQueue::consumer()
{
  Glib::Rand rand(4567);

  for (;;)
  {
    {
      std::unique_lock<std::mutex> lock(mutex_);

      cond_push_.wait(lock, [this]() -> bool { return !queue_.empty(); });

      const int i = queue_.front();
      queue_.pop();
      std::cout << "\x08 \x08";
      std::cout.flush();

      // We unlock before notifying, because that is what the documentation suggests:
      // http://en.cppreference.com/w/cpp/thread/condition_variable
      lock.unlock();
      cond_pop_.notify_one();

      if (i >= 199)
        break;
    }

    if (rand.get_bool())
      continue;

    Glib::usleep(rand.get_int_range(10000, 200000));
  }
}
}

int
main(int, char**)
{
  Glib::init();

  MessageQueue queue;

  // TODO: Use std::make_unique() when we use C++14:
  const auto producer =
    std::unique_ptr<std::thread>(new std::thread(&MessageQueue::producer, &queue));

  const auto consumer =
    std::unique_ptr<std::thread>(new std::thread(&MessageQueue::consumer, &queue));

  producer->join();
  consumer->join();

  std::cout << std::endl;

  return 0;
}
