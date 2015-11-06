
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <glibmm/random.h>
#include <glibmm/timer.h>
#include <glibmm/init.h>

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
{}

MessageQueue::~MessageQueue()
{}

void MessageQueue::producer()
{
  Glib::Rand rand (1234);

  for(auto i = 0; i < 200; ++i)
  {
    {
      std::unique_lock<std::mutex> lock (mutex_);

      cond_pop_.wait(lock,
        [this] () -> bool
        {
          return queue_.size() < 64;
        });

      queue_.push(i);
      std::cout << '*';
      std::cout.flush();

      //We unlock before notifying, because that is what the documentation suggests:
      //http://en.cppreference.com/w/cpp/thread/condition_variable
      lock.unlock();
      cond_push_.notify_one();
    }

    if(rand.get_bool())
      continue;

    Glib::usleep(rand.get_int_range(0, 100000));
  }
}

void MessageQueue::consumer()
{
  Glib::Rand rand (4567);

  for(;;)
  {
    {
      std::unique_lock<std::mutex> lock (mutex_);

      cond_push_.wait(lock,
        [this] () -> bool
        {
          return !queue_.empty();
        });

      const int i = queue_.front();
      queue_.pop();
      std::cout << "\x08 \x08";
      std::cout.flush();

      //We unlock before notifying, because that is what the documentation suggests:
      //http://en.cppreference.com/w/cpp/thread/condition_variable
      lock.unlock();
      cond_pop_.notify_one();

      if(i >= 199)
        break;
    }

    if(rand.get_bool())
      continue;

    Glib::usleep(rand.get_int_range(10000, 200000));
  }
}

}


int main(int, char**)
{
  Glib::init();

  MessageQueue queue;

  auto *const producer = new std::thread(
    [&queue] ()
    {
      queue.producer();
    });

  auto *const consumer = new std::thread(
    [&queue] ()
    {
      queue.consumer();
    });

  producer->join();
  delete producer;

  consumer->join();
  delete consumer;

  std::cout << std::endl;

  return 0;
}

