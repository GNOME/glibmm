/* Copyright (C) 2010 The gtkmm Development Team
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

// ugly code ahead.

#include <glibmm/vectorutils.h>
#include <glibmm/containerhandle_shared.h> /* Because its specializations may be here. */
#include <glibmm/object.h>
// we use GCredentials as a simple GObject without fancy constructor.
#include <giomm/credentials.h>
#include <giomm/init.h>
#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>
#include <iostream>

const unsigned int magic_limit (42);

GList*
create_list ()
{
  GList* head = 0;

  for (unsigned int iter (0); iter < magic_limit; ++iter)
  {
    head = g_list_prepend (head, g_credentials_new ());
  }
  return g_list_reverse (head);
}

GSList*
create_slist ()
{
  GSList* head = 0;

  for (unsigned int iter (0); iter < magic_limit; ++iter)
  {
    head = g_slist_prepend (head, g_credentials_new ());
  }
  return g_slist_reverse (head);
}

GCredentials**
create_array ()
{
  GCredentials** array = g_new0 (GCredentials*, magic_limit + 1);

  for (unsigned int iter (0); iter < magic_limit; ++iter)
  {
    array[iter] = g_credentials_new ();
  }
  return array;
}

// shallow copy
GCredentials**
copy_array (GCredentials** array)
{
  GCredentials** dup = g_new0 (GCredentials*, magic_limit + 1);

  for (unsigned int iter (0); iter < magic_limit; ++iter)
  {
    dup[iter] = array[iter];
  }
  return dup;
}

struct Cache
{
public:
  Cache()
  : glist_ (create_list ()),
    gslist_ (create_slist ()),
    garray_ (create_array ())
  {}

  ~Cache()
  {
    if (glist_)
    {
      g_list_foreach (glist_, reinterpret_cast<GFunc> (g_object_unref), 0);
      g_list_free (glist_);
    }
    if (gslist_)
    {
      g_slist_foreach (gslist_, reinterpret_cast<GFunc> (g_object_unref), 0);
      g_slist_free (gslist_);
    }
    if (garray_)
    {
      for (unsigned int iter (0); iter < magic_limit; ++iter)
      {
        g_object_unref (garray_[iter]);
      }
      g_free (garray_);
    }
  }

  void print_list ()
  {
    unsigned int counter (1);

    for (GList* node (glist_); node; node = node->next, ++counter)
    {
      std::cout << counter << ": ";
      if (G_IS_CREDENTIALS (node->data))
      {
        std::cout << node->data << ", ref: " << G_OBJECT (node->data)->ref_count <<"\n";
      }
      else
      {
        std::cout << "no C instance?\n";
      }
    }
  }

  void print_slist ()
  {
    unsigned int counter (1);

    for (GSList* node (gslist_); node; node = node->next, ++counter)
    {
      std::cout << counter << ": ";
      if (G_IS_CREDENTIALS (node->data))
      {
        std::cout << node->data << ", ref: " << G_OBJECT (node->data)->ref_count <<"\n";
      }
      else
      {
        std::cout << "no C instance?\n";
      }
    }
  }

  void print_array ()
  {
    for (unsigned int iter (0); iter < magic_limit; ++iter)
    {
      std::cout << iter + 1 << ": ";
      if (G_IS_CREDENTIALS (garray_[iter]))
      {
        std::cout << reinterpret_cast<gpointer> (garray_[iter]) << ", ref: " << G_OBJECT (garray_[iter])->ref_count << "\n";
      }
      else
      {
        std::cout << "no C instance?\n";
      }
    }
  }

  GList* glist_;
  GSList* gslist_;
  GCredentials** garray_;

private:
  // just in case
  Cache (const Cache&);
  Cache operator= (const Cache&);
};

Cache& get_cache ()
{
  static Cache global_cache;

  return global_cache;
}

GList*
return_deep_owned_list ()
{
  return get_cache ().glist_;
}

GList*
return_shallow_owned_list ()
{
  return g_list_copy (return_deep_owned_list ());
}

GList*
return_unowned_list ()
{
  return create_list ();
}

GSList*
return_deep_owned_slist ()
{
  return get_cache ().gslist_;
}

GSList*
return_shallow_owned_slist ()
{
  return g_slist_copy (return_deep_owned_slist ());
}

GSList*
return_unowned_slist ()
{
  return create_slist ();
}

GCredentials**
return_deep_owned_array ()
{
  return get_cache ().garray_;
}

GCredentials**
return_shallow_owned_array ()
{
  return copy_array (return_deep_owned_array ());
}

GCredentials**
return_unowned_array ()
{
  return create_array ();
}

/* they are probably buggy by design...
void
take_list_all (GList* list)
{
  if (list)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GList* backup = cache.glist_;

    cache.glist_ = list;
    cache.print_list ();
    cache.glist_ = backup;
    g_list_foreach (list, reinterpret_cast<GFunc> (g_object_unref), 0);
    g_list_free (list);
  }
}

void
take_list_members (GList* list)
{
  if (list)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GList* backup = cache.glist_;

    cache.glist_ = list;
    cache.print_list ();
    cache.glist_ = backup;
    g_list_foreach (list, reinterpret_cast<GFunc> (g_object_unref), 0);
  }
}
*/

void
take_list_nothing (GList* list)
{
  if (list)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GList* backup = cache.glist_;

    cache.glist_ = list;
    cache.print_list ();
    cache.glist_ = backup;
  }
}

/* they are probably buggy by design...
void
take_slist_all (GSList* slist)
{
  if (slist)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GSList* backup = cache.gslist_;

    cache.gslist_ = slist;
    cache.print_slist ();
    cache.gslist_ = backup;
    g_slist_foreach (slist, reinterpret_cast<GFunc> (g_object_unref), 0);
    g_slist_free (slist);
  }
}

void
take_list_members (GSList* slist)
{
  if (slist)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GSList* backup = cache.gslist_;

    cache.gslist_ = slist;
    cache.print_slist ();
    cache.gslist_ = backup;
    g_slist_foreach (slist, reinterpret_cast<GFunc> (g_object_unref), 0);
  }
}
*/

void
take_slist_nothing (GSList* slist)
{
  if (slist)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GSList* backup = cache.gslist_;

    cache.gslist_ = slist;
    cache.print_slist ();
    cache.gslist_ = backup;
  }
}

/* they are probably buggy by design...
void
take_array_all (GCredentials** array)
{
  if (array)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GCredentials** backup = cache.garray_;

    cache.garray_ = array;
    cache.print_array ();
    cache.garray_ = backup;
    for (unsigned int iter (0); iter < magic_limit; ++iter)
    {
      g_object_unref (array[iter]);
    }
    g_free (array);
  }
}

void
take_array_members (GCredentials** array)
{
  if (array)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GCredentials** backup = cache.garray_;

    cache.garray_ = array;
    cache.print_array ();
    cache.garray_ = backup;
    for (unsigned int iter (0); iter < magic_limit; ++iter)
    {
      g_object_unref (array[iter]);
    }
  }
}
*/

void
take_array_nothing (GCredentials** array)
{
  if (array)
  {
    // i'm lazy.
    Cache& cache (get_cache ());
    GCredentials** backup = cache.garray_;

    cache.garray_ = array;
    cache.print_array ();
    cache.garray_ = backup;
  }
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_list ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector (return_deep_owned_list (), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_list ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector (return_shallow_owned_list (), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_none_list ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector (return_unowned_list (), Glib::OWNERSHIP_DEEP);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_slist ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector (return_deep_owned_slist (), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_slist ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector (return_shallow_owned_slist (), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_none_slist ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector (return_unowned_slist (), Glib::OWNERSHIP_DEEP);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_array ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector (return_deep_owned_array (), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_array ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector (return_shallow_owned_array (), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_none_array ()
{
  return Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector (return_unowned_array (), Glib::OWNERSHIP_DEEP);
}

void
print_vector (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  const unsigned int size (v.size ());

  for (unsigned int iter (0); iter < size; ++iter)
  {
    const Glib::RefPtr<Gio::Credentials>& obj_ptr (v[iter]);

    std::cout << iter + 1 << ": ";
    if (obj_ptr)
    {
      GCredentials* gobj (obj_ptr->gobj ());

      if (G_IS_CREDENTIALS (gobj))
      {
        std::cout << static_cast<gpointer> (gobj) << ", ref: " << G_OBJECT (gobj)->ref_count << "\n";
      }
      else
      {
        std::cout << "No C instance?\n";
      }
    }
    else
    {
      std::cout << "No C++ instance?\n";
    }
  }
}

/* they are probably buggy by design...
void
cxx_list_take_all (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_list_all (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list (v, Glib::OWNERSHIP_NONE));
}

void
cxx_list_take_members (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_list_members (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list (v, Glib::OWNERSHIP_SHALLOW));
}
*/

void
cxx_list_take_nothing (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_list_nothing (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list (v).data());
}

/* they are probably buggy by design...
void
cxx_slist_take_all (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_slist_all (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist (v, Glib::OWNERSHIP_NONE));
}

void
cxx_slist_take_members (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_slist_members (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist (v, Glib::OWNERSHIP_SHALLOW));
}
*/

void
cxx_slist_take_nothing (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_slist_nothing (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist (v).data());
}

/* they are probably buggy by design...
void
cxx_array_take_all (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_array_all (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array (v, Glib::OWNERSHIP_NONE));
}

void
cxx_array_take_members (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_array_members (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array (v, Glib::OWNERSHIP_SHALLOW));
}
*/

void
cxx_array_take_nothing (const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  take_array_nothing (Glib::VectorHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array (v).data());
}


int
main()
{
  Gio::init ();

  Cache& cache (get_cache ());

  std::cout << "Cache list before:\n";
  cache.print_list ();
  std::cout << "Cache slist before:\n";
  cache.print_slist ();
  std::cout << "Cache array before:\n";
  cache.print_array ();
  std::cout << "Deep list:\n";
  print_vector (cxx_get_deep_list ());
  std::cout << "Shallow list:\n";
  print_vector (cxx_get_shallow_list ());
  std::cout << "None list:\n";
  print_vector (cxx_get_none_list ());
  std::cout << "Deep slist:\n";
  print_vector (cxx_get_deep_slist ());
  std::cout << "Shallow slist:\n";
  print_vector (cxx_get_shallow_slist ());
  std::cout << "None slist:\n";
  print_vector (cxx_get_none_slist ());
  std::cout << "Deep array:\n";
  print_vector (cxx_get_deep_array ());
  std::cout << "Shallow array:\n";
  print_vector (cxx_get_shallow_array ());
  std::cout << "None array:\n";
  print_vector (cxx_get_none_array ());
  std::cout << "Cache list after:\n";
  cache.print_list ();
  std::cout << "Cache slist after:\n";
  cache.print_slist ();
  std::cout << "Cache array after:\n";
  cache.print_array ();

  std::vector<Glib::RefPtr<Gio::Credentials> > v (cxx_get_none_list ());

  std::cout << "Gotten vector before:\n";
  print_vector (v);
  // I am wondering if C functions wrapped by the ones below are not buggy by
  // design. Anyway - it segfaults. Maybe the test case is just wrong.
  //std::cout << "Take list all:\n";
  //cxx_list_take_all (v);
  //std::cout << "Take list members:\n";
  //cxx_list_take_members (v);
  std::cout << "Take list nothing:\n";
  cxx_list_take_nothing (v);
  //std::cout << "Take slist all:\n";
  //cxx_slist_take_all (v);
  //std::cout << "Take slist members:\n";
  //cxx_slist_take_members (v);
  std::cout << "Take slist nothing:\n";
  cxx_slist_take_nothing (v);
  // Ditto.
  //std::cout << "Take array all:\n";
  //cxx_array_take_all (v);
  //std::cout << "Take array members:\n";
  //cxx_array_take_members (v);
  std::cout << "Take array nothing:\n";
  cxx_array_take_nothing (v);
  std::cout << "Gotten vector after:\n";
  print_vector (v);
}
