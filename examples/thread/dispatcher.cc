/*
 * Glib::Dispatcher example -- cross thread signalling
 * by Daniel Elstner  <daniel.elstner@gmx.net>
 *
 * Copyright (c) 2002  Free Software Foundation
 */

#include <sigc++/class_slot.h>
#include <glibmm.h>
#include <gtkmm/box.h>
#include <gtkmm/button.h>
#include <gtkmm/buttonbox.h>
#include <gtkmm/main.h>
#include <gtkmm/progressbar.h>
#include <gtkmm/stock.h>
#include <gtkmm/window.h>

#include <algorithm>
#include <functional>
#include <list>


namespace
{

class ThreadProgress : public Gtk::ProgressBar
{
public:
  ThreadProgress();
  virtual ~ThreadProgress();

  void launch();
  SigC::Signal0<void>& signal_finished();

private:
  unsigned int        progress_;
  Glib::Dispatcher    signal_increment_;
  SigC::Signal0<void> signal_finished_;

  void progress_increment();
  void thread_function();
};

class MainWindow : public Gtk::Window
{
public:
  MainWindow();
  virtual ~MainWindow();

  void launch_threads();

protected:
  virtual bool on_delete_event(GdkEventAny* event);

private:
  std::list<ThreadProgress*>  progress_bars_;
  Gtk::Button*                close_button_;

  void on_progress_finished(ThreadProgress* progress);
};


ThreadProgress::ThreadProgress()
:
  progress_ (0)
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

SigC::Signal0<void>& ThreadProgress::signal_finished()
{
  return signal_finished_;
}

void ThreadProgress::progress_increment()
{
  // Use an integer because floating point arithmetic is inaccurate --
  // we want to finish *exactly* after the 1000th increment.
  ++progress_;

  const double fraction = double(progress_) / 1000.0;
  set_fraction(std::min(fraction, 1.0));

  if(progress_ >= 1000)
    signal_finished_();
}

void ThreadProgress::thread_function()
{
  Glib::Rand rand;
  int usecs = 5000;

  for(int i = 0; i < 1000; ++i)
  {
    usecs = rand.get_int_range(std::max(0, usecs - 1000 - i), std::min(20000, usecs + 1000 + i));
    Glib::usleep(usecs);

    // Tell the GUI thread to increment the progress bar value.
    signal_increment_();
  }
}


MainWindow::MainWindow()
:
  close_button_ (0)
{
  set_title("Thread Dispatcher Example");

  Gtk::VBox *const vbox = new Gtk::VBox(false, 10);
  add(*Gtk::manage(vbox));
  vbox->set_border_width(10);

  for(int i = 0; i < 5; ++i)
  {
    ThreadProgress *const progress = new ThreadProgress();
    vbox->pack_start(*Gtk::manage(progress), Gtk::PACK_SHRINK);
    progress_bars_.push_back(progress);

    progress->signal_finished().connect(
        SigC::bind(SigC::slot(*this, &MainWindow::on_progress_finished), progress));
  }

  Gtk::ButtonBox *const button_box = new Gtk::HButtonBox();
  vbox->pack_end(*Gtk::manage(button_box), Gtk::PACK_SHRINK);

  close_button_ = new Gtk::Button(Gtk::Stock::CLOSE);
  button_box->pack_start(*Gtk::manage(close_button_), Gtk::PACK_SHRINK);
  close_button_->set_flags(Gtk::CAN_DEFAULT);
  close_button_->grab_default();
  close_button_->set_sensitive(false);
  close_button_->signal_clicked().connect(SigC::slot(*this, &Gtk::Widget::hide));

  show_all_children();
  set_default_size(300, -1);
}

MainWindow::~MainWindow()
{}

void MainWindow::launch_threads()
{
  std::for_each(
      progress_bars_.begin(), progress_bars_.end(),
      std::mem_fun(&ThreadProgress::launch));
}

bool MainWindow::on_delete_event(GdkEventAny*)
{
  // Don't allow closing the window before all threads finished.
  return !progress_bars_.empty();
}

void MainWindow::on_progress_finished(ThreadProgress* progress)
{
  progress_bars_.remove(progress);

  // Enable the close button when all threads finished.
  if(progress_bars_.empty())
    close_button_->set_sensitive(true);
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
      SigC::bind_return(SigC::slot(window, &MainWindow::launch_threads), false));

  Gtk::Main::run(window);

  return 0;
}

