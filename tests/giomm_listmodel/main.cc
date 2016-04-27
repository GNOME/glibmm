/* Copyright (C) 2016 The giomm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

// This test is similar to glib/gio/tests/glistmodel.c.

#include <giomm.h>
#include <cstdlib>
#include <iostream>

namespace
{
int result = EXIT_SUCCESS;

void check_store_boundaries_n_items(int icall,
  const Glib::RefPtr<const Gio::ListStoreBase>& store, unsigned int expected)
{
  if (store->get_n_items() != expected)
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_boundaries(), " << icall << ": get_n_items()="
      << store->get_n_items() << std::endl;
  }
}

void test_store_boundaries()
{
  auto store = Gio::ListStore<Gio::MenuItem>::create();
  auto item = Gio::MenuItem::create("", "");
  auto weakref_item = Glib::WeakRef<Gio::MenuItem>(item);

  // Remove an item from an empty list.
  store->remove(0);
  check_store_boundaries_n_items(1, store, 0);

  // Don't allow inserting an item past the end ...
  store->insert(1, item);
  check_store_boundaries_n_items(2, store, 0);

  // ... except exactly at the end.
  store->insert(0, item);
  check_store_boundaries_n_items(3, store, 1);

  // Remove a non-existing item at exactly the end of the list.
  store->remove(1);
  check_store_boundaries_n_items(4, store, 1);

  // Remove an existing item.
  store->remove(0);
  check_store_boundaries_n_items(5, store, 0);

  // Splice beyond the end of the list.
  store->splice(1, 0, std::vector<Glib::RefPtr<Gio::MenuItem>>());
  check_store_boundaries_n_items(6, store, 0);

  // Remove items from an empty list.
  store->splice(0, 1, std::vector<Glib::RefPtr<Gio::MenuItem>>());
  check_store_boundaries_n_items(7, store, 0);

  // Append an item, remove it, and insert it by splicing.
  store->append(item);
  {
    std::vector<Glib::RefPtr<Gio::MenuItem>> v;
    v.push_back(item);
    store->splice(0, 1, v);
  }
  check_store_boundaries_n_items(8, store, 1);

  // Remove more items than exist.
  store->splice(0, 5, std::vector<Glib::RefPtr<Gio::MenuItem>>());
  check_store_boundaries_n_items(9, store, 1);

  store.reset();
  item.reset();
  if (weakref_item)
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_boundaries(), 10: weakref_item is not null" << std::endl;
  }
} // end test_store_boundaries()

void check_store_refcounts_n_items(int icall,
  const Glib::RefPtr<const Gio::ListStoreBase>& store, unsigned int expected)
{
  if (store->get_n_items() != expected)
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_refcounts(), " << icall << ": get_n_items()="
      << store->get_n_items() << std::endl;
  }
  if (store->get_object(expected))
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_refcounts(), " << icall << ": get_object("
      << expected << ") is not null" << std::endl;
  }
}

void test_store_refcounts()
{
  auto store = Gio::ListStore<Gio::MenuItem>::create();

  check_store_refcounts_n_items(1, store, 0);

  const std::size_t n_items = 10;
  std::vector<Glib::RefPtr<Gio::MenuItem>> items;
  std::vector<Glib::WeakRef<Gio::MenuItem>> weakref_items;
  for (std::size_t i = 0; i < n_items; ++i)
  {
    items.push_back(Gio::MenuItem::create("", ""));
    weakref_items.push_back(Glib::WeakRef<Gio::MenuItem>(items[i]));
    store->append(items[i]);
  }
  check_store_refcounts_n_items(2, store, n_items);

  if (store->get_item(3).operator->() != items[3].operator->())
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_refcounts(), 3: get_item(3) != items[3]" << std::endl;
  }

  for (std::size_t i = 0; i < n_items; ++i)
  {
    items[i].reset();
    if (!weakref_items[i])
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_refcounts(), 4: weakref_items[" << i << "] is null" << std::endl;
    }
  }

  store->remove(4);
  if (weakref_items[4])
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_refcounts(), 5: weakref_items[4] is not null" << std::endl;
  }
  check_store_refcounts_n_items(6, store, n_items-1);

  store.reset();
  for (std::size_t i = 0; i < n_items; ++i)
  {
    if (weakref_items[i])
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_refcounts(), 7: weakref_items[" << i << "] is not null" << std::endl;
    }
  }
} // end test_store_refcounts()

// All returned numbers are different as long as the number of calls are < 15000.
gint32 get_next_number()
{
  static gint32 n_calls = 0;

  ++n_calls;
  const gint32 n1 = n_calls;
  const gint32 n2 = 30000 - n_calls;
  gint32 res = (n2 << 16) | n1;
  if (n_calls & 1)
    res = (n1 << 16) | n2;

  return res;
}

int compare_items1(const Glib::RefPtr<const Glib::Object>& a,
  const Glib::RefPtr<const Glib::Object>& b)
{
  const auto action_a = Glib::RefPtr<const Gio::SimpleAction>::cast_dynamic(a);
  const auto action_b = Glib::RefPtr<const Gio::SimpleAction>::cast_dynamic(b);
  if (!action_a || !action_b)
  {
    result = EXIT_FAILURE;
    std::cerr << "compare_items1(): cast_dynamic() failed" << std::endl;
    return 0;
  }
  gint32 value_a = 0;
  gint32 value_b = 0;
  action_a->get_state(value_a);
  action_b->get_state(value_b);
  return value_a - value_b;
}

void insert_item_sorted1(const Glib::RefPtr<Gio::ListStore<Glib::Object>>& store, gint32 n)
{
  auto obj = Gio::SimpleAction::create_radio_integer("dummy", n);
  store->insert_sorted(obj, sigc::ptr_fun(compare_items1));
}

void test_store_sorted1()
{
  // Test that a subclass of Glib::Object can be stored in and retrieved from
  // a Gio::ListStore<Glib::Object>.
  auto store = Gio::ListStore<Glib::Object>::create();

  const std::size_t n_items2 = 100; // n_items2*2 items are stored.
  for (std::size_t i = 0; i < n_items2; ++i)
  {
    const auto n = get_next_number();
    insert_item_sorted1(store, n);
    insert_item_sorted1(store, n);  // Multiple copies of the same are OK
  }
  if (store->get_n_items() != n_items2*2)
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_sorted1(), 1: get_n_items()=" << store->get_n_items() << std::endl;
  }

  for (std::size_t i = 0; i < n_items2; ++i)
  {
    // Should see our two copies.
    auto a = store->get_item(i * 2);
    auto b = store->get_item(i * 2 + 1);
    if (compare_items1(a, b) != 0)
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_sorted1(), 2: i=" << i << ", items are not equal" << std::endl;
    }
    if (a.operator->() == b.operator->())
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_sorted1(), 3: i=" << i << ", items are the same" << std::endl;
    }

    if (i > 0)
    {
      auto c = store->get_item(i * 2 - 1);
      if (c.operator->() == a.operator->() || c.operator->() == b.operator->())
      {
        result = EXIT_FAILURE;
        std::cerr << "test_store_sorted1(), 4: i=" << i << ", items are the same" << std::endl;
      }
      if (!(compare_items1(a, c) > 0 && compare_items1(b, c) > 0))
      {
        result = EXIT_FAILURE;
        std::cerr << "test_store_sorted1(), 5: i=" << i << ", c is not less than a and b" << std::endl;
      }
    }
  }
} // end test_store_sorted1()

// User-defined class
class MyObject : public Glib::Object
{
protected:
  MyObject(int id) : m_id(id) {}

public:
  static Glib::RefPtr<MyObject> create(int id)
  {
    return Glib::RefPtr<MyObject>(new MyObject(id));
  }

  int get_id() const { return m_id; }

  static int compare(const Glib::RefPtr<const MyObject>& a,
    const Glib::RefPtr<const MyObject>& b)
  {
    if (!a || !b)
    {
      result = EXIT_FAILURE;
      std::cerr << "MyObject::compare(): Empty RefPtr" << std::endl;
      return 0;
    }
    return a->get_id() - b->get_id();
  }

private:
  int m_id;
};

void test_store_sorted2()
{
  // Test that a user-defined class, derived from Glib::Object, can be stored in
  // and retrieved from a Gio::ListStore<>.
  auto store = Gio::ListStore<MyObject>::create();

  const std::size_t n_items2 = 100; // n_items2*2 items are stored.
  for (std::size_t i = 0; i < n_items2; ++i)
  {
    const auto n = get_next_number();
    // Multiple copies of the same are OK
    store->insert_sorted(MyObject::create(n), sigc::ptr_fun(&MyObject::compare));
    store->insert_sorted(MyObject::create(n), sigc::ptr_fun(&MyObject::compare));
  }
  if (store->get_n_items() != n_items2*2)
  {
    result = EXIT_FAILURE;
    std::cerr << "test_store_sorted2(), 1: get_n_items()=" << store->get_n_items() << std::endl;
  }

  for (std::size_t i = 0; i < n_items2; ++i)
  {
    // Should see our two copies.
    auto a = store->get_item(i * 2);
    auto b = store->get_item(i * 2 + 1);
    if (MyObject::compare(a, b) != 0)
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_sorted2(), 2: i=" << i << ", items are not equal" << std::endl;
    }
    if (a.operator->() == b.operator->())
    {
      result = EXIT_FAILURE;
      std::cerr << "test_store_sorted2(), 3: i=" << i << ", items are the same" << std::endl;
    }

    if (i > 0)
    {
      auto c = store->get_item(i * 2 - 1);
      if (c.operator->() == a.operator->() || c.operator->() == b.operator->())
      {
        result = EXIT_FAILURE;
        std::cerr << "test_store_sorted2(), 4: i=" << i << ", items are the same" << std::endl;
      }
      if (!(MyObject::compare(a, c) > 0 && MyObject::compare(b, c) > 0))
      {
        result = EXIT_FAILURE;
        std::cerr << "test_store_sorted2(), 5: i=" << i << ", c is not less than a and b" << std::endl;
      }
    }
  }
} // end test_store_sorted2()

} // anonymous namespace

int main(int, char**)
{
  Gio::init();

  test_store_boundaries();
  test_store_refcounts();
  test_store_sorted1();
  test_store_sorted2();

  return result;
}
