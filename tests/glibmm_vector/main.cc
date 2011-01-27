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

#include <iostream>

#include <gio/gio.h>

#include <glibmm/vectorutils.h>

#include <giomm/credentials.h>
#include <giomm/init.h>

// utilities

const unsigned int magic_limit(5);

GList*
create_list()
{
  GList* head = 0;

  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    head = g_list_prepend(head, g_credentials_new());
  }
  
  return g_list_reverse(head);
}

void
print_list(GList* list)
{
  unsigned int counter(1);

  for(GList* node(list); node; node = node->next, ++counter)
  {
    std::cout << counter << ": ";
    if(G_IS_CREDENTIALS(node->data))
    {
      std::cout << node->data << ", ref: " << G_OBJECT(node->data)->ref_count <<"\n";
    }
    else
    {
      std::cout << "no C instance?\n";
    }
  }
}

GSList*
create_slist()
{
  GSList* head = 0;

  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    head = g_slist_prepend(head, g_credentials_new());
  }
  
  return g_slist_reverse(head);
}

void
print_slist(GSList* slist)
{
  unsigned int counter(1);

  for(GSList* node(slist); node; node = node->next, ++counter)
  {
    std::cout << counter << ": ";
    if(G_IS_CREDENTIALS(node->data))
    {
      std::cout << node->data << ", ref: " << G_OBJECT(node->data)->ref_count <<"\n";
    }
    else
    {
      std::cout << "no C instance?\n";
    }
  }
}

GCredentials**
create_array()
{
  GCredentials** array = g_new0(GCredentials*, magic_limit + 1);

  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    array[iter] = g_credentials_new();
  }
  return array;
}

void
print_array(GCredentials** array)
{
  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    GCredentials* credentials(array[iter]);

    std::cout << iter + 1 << ": ";
    if(G_IS_CREDENTIALS(credentials))
    {
      std::cout << reinterpret_cast<gpointer>(credentials) << ", ref: " << G_OBJECT(credentials)->ref_count << "\n";
    }
    else
    {
      std::cout << "no C instance?\n";
    }
  }
}

// shallow copy
GCredentials**
copy_array(GCredentials** array)
{
  GCredentials** dup = g_new0(GCredentials*, magic_limit + 1);

  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    dup[iter] = array[iter];
  }
  dup[magic_limit] = 0;
  return dup;
}

void
free_array(GCredentials** array, bool container_too = true)
{
  for(unsigned int iter(0); iter < magic_limit; ++iter)
  {
    g_object_unref(array[iter]);
  }
  if(container_too)
  {
    g_free(array);
  }
}

void
print_vector(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  const unsigned int size(v.size());

  for(unsigned int iter(0); iter < size; ++iter)
  {
    const Glib::RefPtr<Gio::Credentials>& obj_ptr(v[iter]);

    std::cout << iter + 1 << ": ";
    if(obj_ptr)
    {
      GCredentials* gobj(obj_ptr->gobj());

      if(G_IS_CREDENTIALS(gobj))
      {
        std::cout << static_cast<gpointer>(gobj) << ", ref: " << G_OBJECT(gobj)->ref_count << "\n";
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

struct Cache
{
public:
  Cache()
  : glist_(create_list()),
    gslist_(create_slist()),
    garray_(create_array())
  {}

  ~Cache()
  {
    if(glist_)
    {
      g_list_foreach(glist_, reinterpret_cast<GFunc>(g_object_unref), 0);
      g_list_free(glist_);
    }
    if(gslist_)
    {
      g_slist_foreach(gslist_, reinterpret_cast<GFunc>(g_object_unref), 0);
      g_slist_free(gslist_);
    }
    if(garray_)
    {
      free_array(garray_);
    }
  }

  GList*
  get_list() const
  {
    return glist_;
  }

  GSList*
  get_slist() const
  {
    return gslist_;
  }

  GCredentials**
  get_array() const
  {
    return garray_;
  }

private:
  // just in case
  Cache(const Cache&);
  Cache operator=(const Cache&);

  GList* glist_;
  GSList* gslist_;
  GCredentials** garray_;
};

Cache&
get_cache()
{
  static Cache global_cache;

  return global_cache;
}

// C functions

GList*
c_get_deep_owned_list()
{
  return get_cache().get_list();
}

GList*
c_get_shallow_owned_list()
{
  return g_list_copy(c_get_deep_owned_list());
}

GList*
c_get_unowned_list()
{
  return create_list();
}

GSList*
c_get_deep_owned_slist()
{
  return get_cache().get_slist();
}

GSList*
c_get_shallow_owned_slist()
{
  return g_slist_copy(c_get_deep_owned_slist());
}

GSList*
c_get_unowned_slist()
{
  return create_slist();
}

GCredentials**
c_get_deep_owned_array()
{
  return get_cache().get_array();
}

GCredentials**
c_get_shallow_owned_array()
{
  return copy_array(c_get_deep_owned_array());
}

GCredentials**
c_get_unowned_array()
{
  return create_array();
}

/* these are probably buggy by design...
void
c_take_list_all(GList* list)
{
  if(list)
  {
    print_list(list);
    g_list_foreach(list, reinterpret_cast<GFunc>(g_object_unref), 0);
    g_list_free(list);
  }
}

void
c_take_list_members(GList* list)
{
  if(list)
  {
    print_list(list);
    g_list_foreach(list, reinterpret_cast<GFunc>(g_object_unref), 0);
  }
}
*/

void
c_take_list_nothing(GList* list)
{
  if(list)
  {
    print_list(list);
  }
}

/* they are probably buggy by design...
void
c_take_slist_all(GSList* slist)
{
  if(slist)
  {
    print_slist(slist);
    g_slist_foreach(slist, reinterpret_cast<GFunc>(g_object_unref), 0);
    g_slist_free(slist);
  }
}

void
c_take_list_members(GSList* slist)
{
  if(slist)
  {
    print_slist(slist);
    g_slist_foreach(slist, reinterpret_cast<GFunc>(g_object_unref), 0);
  }
}
*/

void
c_take_slist_nothing(GSList* slist)
{
  if(slist)
  {
    print_slist(slist);
  }
}

/* they are probably buggy by design...
void
c_take_array_all(GCredentials** array)
{
  if(array)
  {
    print_array(array);
    free_array(array);
  }
}

void
c_take_array_members(GCredentials** array)
{
  if(array)
  {
    print_array(array);
    free_array(array, false);
  }
}
*/

void
c_take_array_nothing(GCredentials** array)
{
  if(array)
  {
    print_array(array);
  }
}

// C++ wrappers.

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_owned_list()
{
  return Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector(c_get_deep_owned_list(), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_owned_list()
{
  return Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector(c_get_shallow_owned_list(), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_unowned_list()
{
  return Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::list_to_vector(c_get_unowned_list(), Glib::OWNERSHIP_DEEP);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_owned_slist()
{
  return Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector(c_get_deep_owned_slist(), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_owned_slist()
{
  return Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector(c_get_shallow_owned_slist(), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_unowned_slist()
{
  return Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::slist_to_vector(c_get_unowned_slist(), Glib::OWNERSHIP_DEEP);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_deep_owned_array()
{
  return Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector(c_get_deep_owned_array(), Glib::OWNERSHIP_NONE);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_shallow_owned_array()
{
  return Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector(c_get_shallow_owned_array(), Glib::OWNERSHIP_SHALLOW);
}

std::vector<Glib::RefPtr<Gio::Credentials> >
cxx_get_unowned_array()
{
  return Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::array_to_vector(c_get_unowned_array(), Glib::OWNERSHIP_DEEP);
}

/* they are probably buggy by design...
void
cxx_list_take_all(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_list_all(Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list(v).data());
}

void
cxx_list_take_members(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_list_members(Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list(v).data());
}
*/

void
cxx_list_take_nothing(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_list_nothing(Glib::ListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_list(v).data());
}

/* they are probably buggy by design...
void
cxx_slist_take_all(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_slist_all(Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist(v).data());
}

void
cxx_slist_take_members(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_slist_members(Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist(v).data());
}
*/

void
cxx_slist_take_nothing(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_slist_nothing(Glib::SListHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_slist(v).data());
}

/* they are probably buggy by design...
void
cxx_array_take_all(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_array_all(Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array(v).data());
}

void
cxx_array_take_members(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_array_members(Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array(v).data());
}
*/

void
cxx_array_take_nothing(const std::vector<Glib::RefPtr<Gio::Credentials> >& v)
{
  c_take_array_nothing(Glib::ArrayHandler<Glib::RefPtr<Gio::Credentials> >::vector_to_array(v).data());
}


int
main()
{
  Gio::init();

  Cache& cache(get_cache());

  std::cout << "Cache list before:\n";
  print_list(cache.get_list());
  std::cout << "Cache slist before:\n";
  print_slist(cache.get_slist());
  std::cout << "Cache array before:\n";
  print_array(cache.get_array());
  std::cout << "Deep owned list:\n";
  print_vector(cxx_get_deep_owned_list());
  std::cout << "Shallow owned list:\n";
  print_vector(cxx_get_shallow_owned_list());
  std::cout << "Unowned list:\n";
  print_vector(cxx_get_unowned_list());
  std::cout << "Deep owned slist:\n";
  print_vector(cxx_get_deep_owned_slist());
  std::cout << "Shallow owned slist:\n";
  print_vector(cxx_get_shallow_owned_slist());
  std::cout << "Unowned slist:\n";
  print_vector(cxx_get_unowned_slist());
  std::cout << "Deep owned array:\n";
  print_vector(cxx_get_deep_owned_array());
  std::cout << "Shallow owned array:\n";
  print_vector(cxx_get_shallow_owned_array());
  std::cout << "Unowned array:\n";
  print_vector(cxx_get_unowned_array());
  std::cout << "Cache list after:\n";
  print_list(cache.get_list());
  std::cout << "Cache slist after:\n";
  print_slist(cache.get_slist());
  std::cout << "Cache array after:\n";
  print_array(cache.get_array());

  std::vector<Glib::RefPtr<Gio::Credentials> > v(cxx_get_unowned_list());

  std::cout << "Gotten vector before:\n";
  print_vector(v);
  // I am wondering if C functions wrapped by the ones below are not buggy by
  // design. Anyway - it segfaults. Maybe the test case is just wrong.
  //std::cout << "Take list all:\n";
  //cxx_list_take_all(v);
  //std::cout << "Take list members:\n";
  //cxx_list_take_members(v);
  std::cout << "Take list nothing:\n";
  cxx_list_take_nothing(v);
  // Ditto.
  //std::cout << "Take slist all:\n";
  //cxx_slist_take_all(v);
  //std::cout << "Take slist members:\n";
  //cxx_slist_take_members(v);
  std::cout << "Take slist nothing:\n";
  cxx_slist_take_nothing(v);
  // Ditto.
  //std::cout << "Take array all:\n";
  //cxx_array_take_all(v);
  //std::cout << "Take array members:\n";
  //cxx_array_take_members(v);
  std::cout << "Take array nothing:\n";
  cxx_array_take_nothing(v);
  std::cout << "Gotten vector after:\n";
  print_vector(v);
}
