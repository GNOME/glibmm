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
 * Note:  This example is special stuff that's seldomly needed by the
 * vast majority of applications.  Don't bother working out what this
 * code does unless you know for sure you need 2 main loops running in
 * 2 distinct main contexts.
 *
 * Copyright (c) 2002  Free Software Foundation
 */

#include <sigc++/class_slot.h>
#include <glibmm.h>
#include <gtkmm/box.h>
#include <gtkmm/button.h>
#include <gtkmm/buttonbox.h>
#include <gtkmm/main.h>
#include <gtkmm/label.h>
#include <gtkmm/stock.h>
#include <gtkmm/window.h>
#include <sstream>


namespace
{

class ThreadTimer : public Gtk::Label
{
public:
  ThreadTimer();
  ~ThreadTimer();

  Glib::Thread* launch();
  void signal_finished_emit();

private:
  unsigned int      time_;
  Glib::Dispatcher  signal_increment_;  
  Glib::Dispatcher* signal_finished_ptr_;

  Glib::Mutex       startup_mutex_;
  Glib::Cond        startup_cond_;

  void timer_increment();
  bool timeout_handler();
  static void finished_handler(Glib::RefPtr<Glib::MainLoop> mainloop);
  void thread_function();
};

class MainWindow : public Gtk::Window
{
public:
  MainWindow();

  void launch_thread();

protected:
  bool on_delete_event(GdkEventAny* event);
  void on_button_clicked();

private:
  Glib::Thread*   producer_;

  ThreadTimer*    timer_label_;
  Gtk::Button*    close_button_;
};


ThreadTimer::ThreadTimer()
:
  time_ (0),
  // Create a new dispatcher that is attached to the default main context,
  // which is the one Gtk::Main is using.
  signal_increment_ (),
  // This pointer will be initialized later by the 2nd thread.
  signal_finished_ptr_ (0)
{
  // Connect the cross-thread signal.
  signal_increment_.connect(SigC::slot(*this, &ThreadTimer::timer_increment));
}

ThreadTimer::~ThreadTimer()
{}

Glib::Thread* ThreadTimer::launch()
{
  // Unfortunately, the thread creation has to be fully synchronized in
  // order to access the Dispatcher object instantiated by the 2nd thread.
  // So, let's do some kind of hand-shake using a mutex and a condition
  // variable.
  Glib::Mutex::Lock lock (startup_mutex_);

  // Create a joinable thread -- it needs to be joined, otherwise it's a memory leak.
  Glib::Thread *const thread = Glib::Thread::create(
      SigC::slot_class(*this, &ThreadTimer::thread_function), true);

  // Wait for the 2nd thread's startup notification.
  while(signal_finished_ptr_ == 0)
    startup_cond_.wait(startup_mutex_);

  return thread;
}

void ThreadTimer::signal_finished_emit()
{
  // Cause the 2nd thread's main loop to quit.
  signal_finished_ptr_->emit();
  signal_finished_ptr_ = 0;
}

void ThreadTimer::timer_increment()
{
  // another second has passed since the start of the program
  ++time_;

  std::ostringstream out;
  out << time_ << " seconds since start";

  set_text(out.str());
}

// static
void ThreadTimer::finished_handler(Glib::RefPtr<Glib::MainLoop> mainloop)
{
  // quit the timer thread mainloop
  mainloop->quit();
}

bool ThreadTimer::timeout_handler()
{
  // inform the UI thread that another second has passed
  signal_increment_();

  // this timer should stay alive
  return true;
}

void ThreadTimer::thread_function()
{
  // create a new Main Context
  Glib::RefPtr<Glib::MainContext> context = Glib::MainContext::create();
  // create a new Main Loop
  Glib::RefPtr<Glib::MainLoop> mainloop = Glib::MainLoop::create(context, true);

  // attach a timeout handler, that is called every second, to the
  // newly created MainContext
  context->signal_timeout().connect(SigC::slot(*this, &ThreadTimer::timeout_handler), 1000);

  // We need to lock while creating the Dispatcher instance,
  // in order to ensure memory visibility.
  Glib::Mutex::Lock lock (startup_mutex_);

  // create a new dispatcher, that is connected to the newly
  // created MainContext
  Glib::Dispatcher signal_finished (context);
  signal_finished.connect(SigC::bind(SigC::slot(&ThreadTimer::finished_handler), mainloop));

  signal_finished_ptr_ = &signal_finished;

  // Tell the launcher thread that everything is in place now.
  startup_cond_.signal();
  lock.release();

  // start the mainloop
  mainloop->run();
}


MainWindow::MainWindow()
:
  producer_     (0),
  timer_label_  (0),
  close_button_ (0)
{
  set_title("Thread Dispatcher Example #2");

  Gtk::VBox *const vbox = new Gtk::VBox(false, 10);
  add(*Gtk::manage(vbox));
  vbox->set_border_width(10);

  timer_label_ = new ThreadTimer();
  vbox->pack_start(*Gtk::manage(timer_label_), Gtk::PACK_SHRINK);
  timer_label_->set_text("0 seconds since start");

  Gtk::ButtonBox *const button_box = new Gtk::HButtonBox();
  vbox->pack_end(*Gtk::manage(button_box), Gtk::PACK_SHRINK);

  close_button_ = new Gtk::Button(Gtk::Stock::CLOSE);
  button_box->pack_start(*Gtk::manage(close_button_), Gtk::PACK_SHRINK);
  close_button_->set_flags(Gtk::CAN_DEFAULT);
  close_button_->grab_default();
  close_button_->signal_clicked().connect(SigC::slot(*this, &MainWindow::on_button_clicked));

  show_all_children();
  set_default_size(300, -1);
}

void MainWindow::launch_thread()
{
  // launch the timer thread
  producer_ = timer_label_->launch();
}

bool MainWindow::on_delete_event(GdkEventAny*)
{ 
  // signal the timer thread to stop
  timer_label_->signal_finished_emit();

  // wait for the timer thread to join
  producer_->join();

  return false;
}

void MainWindow::on_button_clicked()
{
  // signal the timer thread to stop
  timer_label_->signal_finished_emit();

  // wait for the timer thread to join
  producer_->join();

  // hide toplevel, thus stop the UI thread main loop
  hide();
}

} // anonymous namespace


int main(int argc, char** argv)
{
  Glib::thread_init();
  Gtk::Main main_instance (&argc, &argv);

  MainWindow window;

  // Install a one-shot idle handler to launch the threads
  // right after the main window has been displayed.
  Glib::signal_idle().connect(
      SigC::bind_return(SigC::slot(window, &MainWindow::launch_thread), false));

  Gtk::Main::run(window);

  return 0;
}

