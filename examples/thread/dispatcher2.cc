/*
 * original Glib::Dispatcher example -- cross thread signalling
 * by Daniel Elstner  <daniel.elstner@gmx.net>
 *
 * Modified by Stephan Puchegger <stephan.puchegger@ap.univie.ac.at>
 * to contain 2 mainloops in 2 different threads, that communicate
 * via cross thread signalling in both directions. The timer thread
 * sends the UI thread a cross thread signal every second, which in turn
 * updates the label stating how many seconds have passed since the start
 * of the program.
 *
 * Modified by J. Abelardo Gutierrez <jabelardo@cantv.net>
 * to cast all gtkmm out and make it glibmm only
 *
 * Note:  This example is special stuff that's seldomly needed by the
 * vast majority of applications.  Don't bother working out what this
 * code does unless you know for sure you need 2 main loops running in
 * 2 distinct main contexts.
 *
 * Copyright (c) 2002-2003  Free Software Foundation
 */

#include <condition_variable>
#include <glibmm.h>
#include <iostream>
#include <mutex>
#include <sstream>
#include <thread>

namespace
{
Glib::RefPtr<Glib::MainLoop> main_loop;

class ThreadTimer : public sigc::trackable
{
public:
  ThreadTimer();
  ~ThreadTimer();

  void launch();
  void signal_finished_emit();
  void print() const;

  using type_signal_end = sigc::signal<void()>;
  static type_signal_end& signal_end();

private:
  unsigned int time_;
  Glib::Dispatcher signal_increment_;
  const Glib::Dispatcher* signal_finished_ptr_;

  std::mutex startup_mutex_;
  std::condition_variable startup_cond_;
  std::thread* thread_;

  static type_signal_end signal_end_;

  void timer_increment();
  bool timeout_handler();
  static void finished_handler(Glib::RefPtr<Glib::MainLoop> mainloop);
  void thread_function();
};

class ThreadDispatcher : public sigc::trackable
{
public:
  ThreadDispatcher();

  void launch_thread();
  void end();

private:
  ThreadTimer* timer_;
};

ThreadTimer::ThreadTimer()
: time_(0),
  // Create a new Glib::Dispatcher that is attached to the default main context,
  signal_increment_(),
  // This pointer will be initialized later by the 2nd thread.
  signal_finished_ptr_(nullptr),
  thread_(nullptr)
{
  // Connect the cross-thread signal.
  signal_increment_.connect(sigc::mem_fun(*this, &ThreadTimer::timer_increment));
}

void
ThreadTimer::launch()
{
  // Unfortunately, the thread creation has to be fully synchronized in
  // order to access the Glib::Dispatcher object instantiated by the 2nd thread.
  // So, let's do some kind of hand-shake using a mutex and a condition
  // variable.
  std::unique_lock<std::mutex> lock(startup_mutex_);

  // Create a joinable thread -- it needs to be joined, otherwise its destructor will block.
  thread_ = new std::thread([this]() { thread_function(); });

  // Wait for the 2nd thread's startup notification.
  startup_cond_.wait(lock, [this]() -> bool { return signal_finished_ptr_; });
}

void
ThreadTimer::signal_finished_emit()
{
  // Cause the 2nd thread's main loop to quit.
  signal_finished_ptr_->emit();

  // wait for the thread to join
  if (thread_)
  {
    thread_->join();
    delete thread_;
    thread_ = nullptr;
  }

  signal_finished_ptr_ = nullptr;
}

void
ThreadTimer::print() const
{
  std::cout << time_ << " seconds since start" << std::endl;
}

sigc::signal<void()>&
ThreadTimer::signal_end()
{
  return signal_end_;
}

void
ThreadTimer::timer_increment()
{
  // another second has passed since the start of the program
  ++time_;
  print();

  if (time_ >= 10)
    signal_finished_emit();
}

// static
void
ThreadTimer::finished_handler(Glib::RefPtr<Glib::MainLoop> mainloop)
{
  // quit the timer thread mainloop
  mainloop->quit();
  std::cout << "timer thread mainloop finished" << std::endl;
  ThreadTimer::signal_end().emit();
}

bool
ThreadTimer::timeout_handler()
{
  // inform the printing thread that another second has passed
  signal_increment_();

  // this timer should stay alive
  return true;
}

void
ThreadTimer::thread_function()
{
  // create a new Main Context
  auto context = Glib::MainContext::create();
  // create a new Main Loop
  auto mainloop = Glib::MainLoop::create(context, true);

  // attach a timeout handler, that is called every second, to the
  // newly created MainContext
  context->signal_timeout().connect(sigc::mem_fun(*this, &ThreadTimer::timeout_handler), 1000);

  // We need to lock while creating the Glib::Dispatcher instance,
  // in order to ensure memory visibility.
  std::unique_lock<std::mutex> lock(startup_mutex_);

  // create a new dispatcher, that is connected to the newly
  // created MainContext
  Glib::Dispatcher signal_finished(context);

  signal_finished.connect(sigc::bind(sigc::ptr_fun(&ThreadTimer::finished_handler), mainloop));

  signal_finished_ptr_ = &signal_finished;

  // Tell the launcher thread that everything is in place now.
  // We unlock before notifying, because that is what the documentation suggests:
  // http://en.cppreference.com/w/cpp/thread/condition_variable
  lock.unlock();
  startup_cond_.notify_one();

  // start the mainloop
  mainloop->run();
}

// initialize static member:
ThreadTimer::type_signal_end ThreadTimer::signal_end_;

ThreadDispatcher::ThreadDispatcher() : timer_(nullptr)
{
  std::cout << "Thread Dispatcher Example #2" << std::endl;

  timer_ = new ThreadTimer();
  timer_->signal_end().connect(sigc::mem_fun(*this, &ThreadDispatcher::end));
  timer_->print();
}

void
ThreadDispatcher::launch_thread()
{
  // launch the timer thread
  timer_->launch();
}

void
ThreadDispatcher::end()
{
  // quit the main mainloop
  main_loop->quit();
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();
  main_loop = Glib::MainLoop::create();

  ThreadDispatcher dispatcher;

  // Install a one-shot idle handler to launch the threads
  Glib::signal_idle().connect_once(sigc::mem_fun(dispatcher, &ThreadDispatcher::launch_thread));

  main_loop->run();

  return 0;
}
