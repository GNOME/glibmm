/* Copyright (C) 2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmmconfig.h>
#ifndef GLIBMM_DISABLE_DEPRECATED

#include <glibmm/threadpool.h>
#include <glibmm/exceptionhandler.h>
#include <glibmm/threads.h>
#include <glib.h>
#include <list>

namespace Glib
{

// internal
class ThreadPool::SlotList
{
public:
  SlotList();
  ~SlotList() noexcept;

  // noncopyable
  SlotList(const ThreadPool::SlotList&) = delete;
  ThreadPool::SlotList& operator=(const ThreadPool::SlotList&) = delete;

  sigc::slot<void>* push(const sigc::slot<void>& slot);
  sigc::slot<void> pop(sigc::slot<void>* slot_ptr);

  void lock_and_unlock();

private:
  Glib::Threads::Mutex mutex_;
  std::list<sigc::slot<void>> list_;
};

ThreadPool::SlotList::SlotList()
{
}

ThreadPool::SlotList::~SlotList() noexcept
{
}

sigc::slot<void>*
ThreadPool::SlotList::push(const sigc::slot<void>& slot)
{
  Threads::Mutex::Lock lock(mutex_);

  list_.emplace_back(slot);
  return &list_.back();
}

sigc::slot<void>
ThreadPool::SlotList::pop(sigc::slot<void>* slot_ptr)
{
  sigc::slot<void> slot;

  {
    Threads::Mutex::Lock lock(mutex_);

    std::list<sigc::slot<void>>::iterator pslot = list_.begin();
    while (pslot != list_.end() && slot_ptr != &*pslot)
      ++pslot;

    if (pslot != list_.end())
    {
      slot = *pslot;
      list_.erase(pslot);
    }
  }

  return slot;
}

void
ThreadPool::SlotList::lock_and_unlock()
{
  mutex_.lock();
  mutex_.unlock();
}

} // namespace Glib

namespace
{

static void
call_thread_entry_slot(void* data, void* user_data)
{
  try
  {
    Glib::ThreadPool::SlotList* const slot_list =
      static_cast<Glib::ThreadPool::SlotList*>(user_data);

    sigc::slot<void> slot(slot_list->pop(static_cast<sigc::slot<void>*>(data)));

    slot();
  }
  catch (Glib::Threads::Thread::Exit&)
  {
    // Just exit from the thread.  The Thread::Exit exception
    // is our sane C++ replacement of g_thread_exit().
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }
}

} // anonymous namespace

namespace Glib
{

ThreadPool::ThreadPool(int max_threads, bool exclusive)
: gobject_(nullptr), slot_list_(new SlotList())
{
  GError* error = nullptr;

  gobject_ = g_thread_pool_new(&call_thread_entry_slot, slot_list_, max_threads, exclusive, &error);

  if (error)
  {
    delete slot_list_;
    slot_list_ = nullptr;
    Glib::Error::throw_exception(error);
  }
}

ThreadPool::~ThreadPool() noexcept
{
  if (gobject_)
    g_thread_pool_free(gobject_, 1, 1);

  if (slot_list_)
  {
    slot_list_->lock_and_unlock();
    delete slot_list_;
  }
}

void
ThreadPool::push(const sigc::slot<void>& slot)
{
  sigc::slot<void>* const slot_ptr = slot_list_->push(slot);

  GError* error = nullptr;
  g_thread_pool_push(gobject_, slot_ptr, &error);

  if (error)
  {
    slot_list_->pop(slot_ptr);
    Glib::Error::throw_exception(error);
  }
}

void
ThreadPool::set_max_threads(int max_threads)
{
  GError* error = nullptr;
  g_thread_pool_set_max_threads(gobject_, max_threads, &error);

  if (error)
    Glib::Error::throw_exception(error);
}

int
ThreadPool::get_max_threads() const
{
  return g_thread_pool_get_max_threads(gobject_);
}

unsigned int
ThreadPool::get_num_threads() const
{
  return g_thread_pool_get_num_threads(gobject_);
}

unsigned int
ThreadPool::unprocessed() const
{
  return g_thread_pool_unprocessed(gobject_);
}

bool
ThreadPool::get_exclusive() const
{
  g_return_val_if_fail(gobject_ != nullptr, false);

  return gobject_->exclusive;
}

void
ThreadPool::shutdown(bool immediately)
{
  if (gobject_)
  {
    g_thread_pool_free(gobject_, immediately, 1);
    gobject_ = nullptr;
  }

  if (slot_list_)
  {
    slot_list_->lock_and_unlock();
    delete slot_list_;
    slot_list_ = nullptr;
  }
}

// static
void
ThreadPool::set_max_unused_threads(int max_threads)
{
  g_thread_pool_set_max_unused_threads(max_threads);
}

// static
int
ThreadPool::get_max_unused_threads()
{
  return g_thread_pool_get_max_unused_threads();
}

// static
unsigned int
ThreadPool::get_num_unused_threads()
{
  return g_thread_pool_get_num_unused_threads();
}

// static
void
ThreadPool::stop_unused_threads()
{
  g_thread_pool_stop_unused_threads();
}

} // namespace Glib

#endif // GLIBMM_DISABLE_DEPRECATED
