/*
 * Glib::Dispatcher example -- cross thread signalling
 * by Daniel Elstner  <daniel.kitta@gmail.com>
 *
 * modified to only use glibmm
 * by J. Abelardo Gutierrez <jabelardo@cantv.net>
 *
 * Copyright (c) 2002-2003  Free Software Foundation
 */

#include <glibmm.h>

#include <algorithm>
#include <functional>
#include <iostream>
#include <thread>
#include <vector>

namespace
{

/*
 * Note that it does not make sense for this class to inherit from
 * sigc::trackable, as doing so would only give a false sense of security.
 * Once the thread launch has been triggered, the object has to stay alive
 * until the thread has been joined again.  The code running in the thread
 * assumes the existence of the object.  If it is destroyed earlier, the
 * program will crash, with sigc::trackable or without it.
 */
class ThreadProgress
{
public:
  explicit ThreadProgress(int the_id);
  ~ThreadProgress();

  int id() const;
  void launch();
  void join();
  bool unfinished() const;

  sigc::signal<void()>& signal_finished();

private:
  enum
  {
    ITERATIONS = 100
  };

  // Note that the thread does not write to the member data at all.  It only
  // reads signal_increment_, which is only written to before the thread is
  // launched.  Therefore, no locking is required.
  std::thread* thread_;
  int id_;
  unsigned int progress_;
  Glib::Dispatcher signal_increment_;
  sigc::signal<void()> signal_finished_;

  void progress_increment();
  void thread_function();
};

class Application : public sigc::trackable
{
public:
  Application();
  ~Application();

  void run();

private:
  Glib::RefPtr<Glib::MainLoop> main_loop_;
  std::vector<ThreadProgress*> progress_threads_;

  void launch_threads();
  void on_progress_finished(ThreadProgress* thread_progress);
};

template <class T>
class DeletePtr
{
  typedef void argument_type;
  typedef T result_type;
public:
  void operator()(T ptr) const { delete ptr; }
};

ThreadProgress::ThreadProgress(int the_id) : thread_(nullptr), id_(the_id), progress_(0)
{
  // Connect to the cross-thread signal.
  signal_increment_.connect(sigc::mem_fun(*this, &ThreadProgress::progress_increment));
}

ThreadProgress::~ThreadProgress()
{
  // It is an error if the thread is still running at this point.
  g_return_if_fail(thread_ == nullptr);
}

int
ThreadProgress::id() const
{
  return id_;
}

void
ThreadProgress::launch()
{
  // Create a joinable thread.
  thread_ = new std::thread([this]() { thread_function(); });
}

void
ThreadProgress::join()
{
  thread_->join();
  delete thread_;
  thread_ = nullptr;
}

bool
ThreadProgress::unfinished() const
{
  return (progress_ < ITERATIONS);
}

sigc::signal<void()>&
ThreadProgress::signal_finished()
{
  return signal_finished_;
}

void
ThreadProgress::progress_increment()
{
  ++progress_;
  std::cout << "Thread " << id_ << ": " << progress_ << '%' << std::endl;

  if (progress_ >= ITERATIONS)
    signal_finished_();
}

void
ThreadProgress::thread_function()
{
  Glib::Rand rand;

  for (auto i = 0; i < ITERATIONS; ++i)
  {
    Glib::usleep(rand.get_int_range(2000, 20000));

    // Tell the main thread to increment the progress value.
    signal_increment_();
  }
}

Application::Application() : main_loop_(Glib::MainLoop::create()), progress_threads_(5)
{
  try
  {
    for (std::vector<ThreadProgress*>::size_type i = 0; i < progress_threads_.size(); ++i)
    {
      ThreadProgress* const progress = new ThreadProgress(i + 1);
      progress_threads_[i] = progress;

      progress->signal_finished().connect(
        sigc::bind(sigc::mem_fun(*this, &Application::on_progress_finished), progress));
    }
  }
  catch (...)
  {
    // In your own code, you should preferably use a smart pointer
    // to ensure exception safety.
    std::for_each(progress_threads_.begin(), progress_threads_.end(), DeletePtr<ThreadProgress*>());
    throw;
  }
}

Application::~Application()
{
  std::for_each(progress_threads_.begin(), progress_threads_.end(), DeletePtr<ThreadProgress*>());
}

void
Application::run()
{
  // Install a one-shot idle handler to launch the threads.
  Glib::signal_idle().connect_once(sigc::mem_fun(*this, &Application::launch_threads));

  main_loop_->run();
}

void
Application::launch_threads()
{
  std::cout << "Launching " << progress_threads_.size() << " threads:" << std::endl;

  std::for_each(
    progress_threads_.begin(), progress_threads_.end(), std::mem_fn(&ThreadProgress::launch));
}

void
Application::on_progress_finished(ThreadProgress* thread_progress)
{
  thread_progress->join();

  std::cout << "Thread " << thread_progress->id() << ": finished." << std::endl;

  // Quit if it was the last thread to be joined.
  if (std::find_if(progress_threads_.begin(), progress_threads_.end(),
        std::mem_fn(&ThreadProgress::unfinished)) == progress_threads_.end())
  {
    main_loop_->quit();
  }
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();

  Application application;
  application.run();

  return 0;
}
