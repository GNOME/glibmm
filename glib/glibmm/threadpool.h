#ifndef _GLIBMM_THREADPOOL_H
#define _GLIBMM_THREADPOOL_H

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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmmconfig.h>

#ifndef GLIBMM_DISABLE_DEPRECATED

#include <sigc++/sigc++.h>

extern "C" {
using GThreadPool = struct _GThreadPool;
}

namespace Glib
{

/** @defgroup ThreadPools Thread Pools
 * Pools of threads to execute work concurrently.
 *
 * @deprecated This is deprecated in favor of the standard C++ concurrency API in C++11 and C++14.
 *
 * @{
 */

// TODO: Is std::async() an appropriate replacement to mention for this deprecated API?

/** A pool of threads to execute work concurrently.
 *
 * @deprecated This is deprecated in favor of the standard C++ concurrency API in C++11 and C++14.
 */
class ThreadPool
{
public:
  /** Constructs a new thread pool.
   * Whenever you call ThreadPool::push(), either a new thread is created or an
   * unused one is reused. At most @a max_threads threads are running
   * concurrently for this thread pool. @a max_threads&nbsp;=&nbsp;-1 allows
   * unlimited threads to be created for this thread pool.
   *
   * The parameter @a exclusive determines, whether the thread pool owns all
   * threads exclusive or whether the threads are shared globally. If @a
   * exclusive is <tt>true</tt>, @a max_threads threads are started immediately
   * and they will run exclusively for this thread pool until it is destroyed
   * by ~ThreadPool(). If @a exclusive is <tt>false</tt>, threads are created
   * when needed and shared between all non-exclusive thread pools.  This
   * implies that @a max_threads may not be -1 for exclusive thread pools.
   *
   * @param max_threads The maximal number of threads to execute concurrently
   * in the new thread pool, -1 means no limit.
   * @param exclusive Should this thread pool be exclusive?
   * @throw Glib::ThreadError An error can only occur when @a exclusive is
   * set to <tt>true</tt> and not all @a max_threads threads could be created.
   */
  explicit ThreadPool(int max_threads = -1, bool exclusive = false);
  virtual ~ThreadPool() noexcept;

  // See http://bugzilla.gnome.org/show_bug.cgi?id=512348 about the sigc::trackable issue.
  // TODO: At the next ABI break, consider changing const sigc::slot<void>& slot
  // to const std::function<void()>& func, if it can be assumed that all supported
  // compilers understand the C++11 template class std::function<>.
  /** Inserts @a slot into the list of tasks to be executed by the pool.
   * When the number of currently running threads is lower than the maximal
   * allowed number of threads, a new thread is started (or reused).  Otherwise
   * @a slot stays in the queue until a thread in this pool finishes its
   * previous task and processes @a slot.
   *
   * Because sigc::trackable is not thread-safe, if the slot represents a
   * non-static class method and is created by sigc::mem_fun(), the class concerned
   * should not derive from sigc::trackable. You can use, say, boost::bind() or,
   * in C++11, std::bind() or a C++11 lambda expression instead of sigc::mem_fun().
   *
   * @param slot A new task for the thread pool.
   * @throw Glib::ThreadError An error can only occur when a new thread
   * couldn't be created. In that case @a slot is simply appended to the
   * queue of work to do.
   */
  void push(const sigc::slot<void>& slot);

  /** Sets the maximal allowed number of threads for the pool.
   * A value of -1 means that the maximal number of threads is unlimited.
   * Setting @a max_threads to 0 means stopping all work for pool. It is
   * effectively frozen until @a max_threads is set to a non-zero value again.
   *
   * A thread is never terminated while it is still running. Instead the
   * maximal number of threads only has effect for the allocation of new
   * threads in ThreadPool::push().  A new thread is allocated whenever the
   * number of currently running threads in the pool is smaller than the
   * maximal number.
   *
   * @param max_threads A new maximal number of threads for the pool.
   * @throw Glib::ThreadError An error can only occur when a new thread
   * couldn't be created.
   */
  void set_max_threads(int max_threads);

  /** Returns the maximal number of threads for the pool.
   * @return The maximal number of threads.
   */
  int get_max_threads() const;

  /** Returns the number of threads currently running in the pool.
   * @return The number of threads currently running.
   */
  unsigned int get_num_threads() const;

  /** Returns the number of tasks still unprocessed in the pool.
   * @return The number of unprocessed tasks.
   */
  unsigned int unprocessed() const;

  /** Returns whether all threads are exclusive to this pool.
   * @return Whether all threads are exclusive to this pool.
   */
  bool get_exclusive() const;

  /** Frees all resources allocated for the pool.
   * If @a immediately is <tt>true</tt>, no new task is processed.  Otherwise the
   * pool is not freed before the last task is processed.  Note however, that no
   * thread of this pool is interrupted while processing a task. Instead at least
   * all still running threads can finish their tasks before the pool is freed.
   *
   * This method does not return before all tasks to be processed (dependent on
   * @a immediately, whether all or only the currently running) are ready.
   * After calling shutdown() the pool must not be used anymore.
   *
   * @param immediately Should the pool shut down immediately?
   */
  void shutdown(bool immediately = false);

  /** Sets the maximal number of unused threads to @a max_threads.
   * If @a max_threads is -1, no limit is imposed on the number of unused threads.
   * @param max_threads Maximal number of unused threads.
   */
  static void set_max_unused_threads(int max_threads);

  /** Returns the maximal allowed number of unused threads.
   * @return The maximal number of unused threads.
   */
  static int get_max_unused_threads();

  /** Returns the number of currently unused threads.
   * @return The number of currently unused threads.
   */
  static unsigned int get_num_unused_threads();

  /** Stops all currently unused threads.
   * This does not change the maximal number of unused threads.  This function can
   * be used to regularly stop all unused threads e.g. from Glib::signal_timeout().
   */
  static void stop_unused_threads();

  GThreadPool* gobj() { return gobject_; }
  const GThreadPool* gobj() const { return gobject_; }

#ifndef DOXYGEN_SHOULD_SKIP_THIS
  class SlotList;
#endif

private:
  GThreadPool* gobject_;
  SlotList* slot_list_;

  ThreadPool(const ThreadPool&);
  ThreadPool& operator=(const ThreadPool&);
};

/** @} group ThreadPools */

/***************************************************************************/
/*  inline implementation                                                  */
/***************************************************************************/

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/**** Glib::Private ********************************************************/

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

} // namespace Glib

#endif // GLIBMM_DISABLE_DEPRECATED

#endif /* _GLIBMM_THREADPOOL_H */
