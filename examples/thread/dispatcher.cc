/*
 * Glib::Dispatcher example -- cross thread signalling
 * by Daniel Elstner  <daniel.elstner@gmx.net>
 *
 * modified to only use glibmm
 * by J. Abelardo Gutierrez <jabelardo@cantv.net>
 *
 * Copyright (c) 2002-2003  Free Software Foundation
 */

#include <sigc++/class_slot.h>
#include <glibmm.h>

#include <iostream>
#include <algorithm>
#include <functional>
#include <list>

namespace
{
Glib::RefPtr<Glib::MainLoop> main_loop;

class ThreadProgress : public SigC::Object
{
public:
  ThreadProgress(int id, Glib::Mutex& mtx);
  virtual ~ThreadProgress();

  void launch();
  SigC::Signal1<void, ThreadProgress*>& signal_finished();
  int id() const;

private:
  unsigned int        progress_;
  Glib::Dispatcher    signal_increment_;
  SigC::Signal1<void, ThreadProgress*>	signal_finished_;
  int                 id_;
  Glib::Mutex&        cout_mutex_;

  void progress_increment();
  void thread_function();
};

class Dispatcher : public SigC::Object
{
public:
  Dispatcher();
  virtual ~Dispatcher();

  void launch_threads();

private:
  std::list<ThreadProgress*>  progress_list_;
  Glib::Mutex                 cout_mutex_;

  void on_progress_finished(ThreadProgress* progress);
};


ThreadProgress::ThreadProgress(int id, Glib::Mutex& mtx)
: 
  progress_ (0), id_ (id), cout_mutex_ (mtx)
{
  // Connect to the cross-thread signal.
  signal_increment_.connect(SigC::slot(*this, &ThreadProgress::progress_increment));
}

ThreadProgress::~ThreadProgress()
{}

void ThreadProgress::launch()
{
  // Create a non-joinable thread -- it's deleted automatically on thread exit.
  Glib::Thread::create(SigC::slot_class(*this, &ThreadProgress::thread_function), false);
}

SigC::Signal1<void, ThreadProgress*>& ThreadProgress::signal_finished()
{
  return signal_finished_;
}

int ThreadProgress::id() const
{
  return id_;
}

void ThreadProgress::progress_increment()
{
  // Use an integer because floating point arithmetic is inaccurate --
  // we want to finish *exactly* after the 100th increment.
  ++progress_;

  cout_mutex_.lock();
  std::cout << "Thread " << id_ << ": " << progress_ << " %" << std::endl;
  cout_mutex_.unlock();

  if(progress_ >= 100)
    signal_finished().emit(this);
}

void ThreadProgress::thread_function()
{
  Glib::Rand rand;
  int usecs = 5000;

  for(int i = 0; i < 100; ++i)
  {
    usecs = rand.get_int_range(std::max(0, usecs - 1000 - i), std::min(20000, usecs + 1000 + i));
    Glib::usleep(usecs);

    // Tell the thread to increment the progress value.
    signal_increment_();
  }
}

Dispatcher::Dispatcher()
: 
  cout_mutex_ ()
{
  std::cout << "Thread Dispatcher Example." << std::endl;

  for(int i = 0; i < 5; ++i)
  {
    ThreadProgress *const progress = new ThreadProgress(i, cout_mutex_);
    progress_list_.push_back(progress);

    progress->signal_finished().connect(
        SigC::slot(*this, &Dispatcher::on_progress_finished));
  }
}

Dispatcher::~Dispatcher()
{}

void Dispatcher::launch_threads()
{
  std::for_each(
      progress_list_.begin(), progress_list_.end(),
      std::mem_fun(&ThreadProgress::launch));
}

void Dispatcher::on_progress_finished(ThreadProgress* progress)
{
  cout_mutex_.lock();
  std::cout << "Thread " << progress->id() << ": finished." << std::endl;
  cout_mutex_.unlock();

  progress_list_.remove(progress);

  if(progress_list_.empty())
    main_loop->quit();
}

} // anonymous namespace


int main(int argc, char** argv)
{
  Glib::thread_init();
  main_loop = Glib::MainLoop::create();

  Dispatcher dispatcher;

  // Install a one-shot idle handler to launch the threads
  Glib::signal_idle().connect(
      SigC::bind_return(SigC::slot(dispatcher, &Dispatcher::launch_threads), false));

  main_loop->run();

  return 0;
}

