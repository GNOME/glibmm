#include <iostream>
#include <glibmm.h>

typedef Glib::NodeTree<std::string> type_nodetree_string;

bool echo(type_nodetree_string& i)
{
  std::cout << i.data() << ' ';
  return false;
}

void echol(type_nodetree_string& i, bool is_leaf)
{
  if(i.is_leaf() == is_leaf)
    std::cout << i.data() << ' ';
}


int main()
{
  std::string a("a"),
              b("b"),
              c("c"),
              d("d"),
              e("e"),
              f("f");

  type_nodetree_string ta(a), tb(b), tc(c), te(e);

  sigc::slot<bool, type_nodetree_string&> echoslot = sigc::ptr_fun(echo);


  ta.insert(0, tc);
  ta.prepend(tb);
  ta.append_data(d);
  tc.append(te);
  te.prepend_data(f);

  const type_nodetree_string::TraverseFlags flags = 
     type_nodetree_string::TraverseFlags(type_nodetree_string::TRAVERSE_LEAVES | type_nodetree_string::TRAVERSE_NON_LEAVES);

  std::cout << "Breadth-first:" << std::endl;
  ta.traverse(Glib::LEVEL_ORDER, flags, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (pre):" << std::endl;
  ta.traverse(Glib::PRE_ORDER, flags, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (in):" << std::endl;
  ta.traverse(Glib::IN_ORDER, flags, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (post):" << std::endl;
  ta.traverse(Glib::POST_ORDER, flags, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Leaf children of 'a':" << std::endl;
  ta.foreach(type_nodetree_string::TRAVERSE_ALL, sigc::bind<bool>(sigc::ptr_fun(echol), true));
  std::cout << std::endl;

  std::cout << "Non-leaf children of 'a':" << std::endl;
  ta.foreach(type_nodetree_string::TRAVERSE_ALL, sigc::bind<bool>(sigc::ptr_fun(echol), false));
  std::cout << std::endl;

  type_nodetree_string* tmp = ta.find(Glib::IN_ORDER, flags, e);
  if(!tmp)
    std::cout << e << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find(Glib::IN_ORDER, flags, a);
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find(Glib::IN_ORDER, flags, "f");
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find_child(flags, e);
  if(!tmp)
    std::cout << e << " is not a child of " << (ta.data()) << std::endl;
  else
    std::cout << "Mistakenly found " << e << " in " << (ta.data()) << "'s children" << std::endl;

  tmp = ta.find_child(flags, c);
  if(!tmp)
    std::cout << c << " is the number " << ta.child_index(c) << " child of " << (ta.data()) << std::endl;
  else
   std::cout << "Mistakenly didn't find " << c << " in " << (ta.data()) << "'s children" << std::endl;

  tmp = tc.next_sibling();
  if(!tmp)
    std::cout << tc.data() << "'s next sibling is NULL" << std::endl;
  else
    std::cout << tc.data() << "'s next sibling is " << tmp->data() << std::endl;

  tmp = ta.get_root();
  std::cout << "Root is " << (tmp->data()) << std::endl;
  std::cout << "Depth is " << tmp->get_max_height() << std::endl;

  ta.unlink(tc);
  std::cout << "New depth is " << tmp->get_max_height() << std::endl;

  tmp = tc.get_root();
  std::cout << "Pruned root is " << (tmp->data()) << std::endl;
  std::cout << "Pruned depth is " << tmp->get_max_height() << std::endl;

  return 0;
}
