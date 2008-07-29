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


  std::cout << "Breadth-first:" << std::endl;
  ta.traverse(echoslot, Glib::TRAVERSE_LEVEL_ORDER);
  std::cout << std::endl;

  std::cout << "Depth-first (pre):" << std::endl;
  ta.traverse(echoslot, Glib::TRAVERSE_PRE_ORDER);
  std::cout << std::endl;

  std::cout << "Depth-first (in):" << std::endl;
  ta.traverse(echoslot, Glib::TRAVERSE_IN_ORDER);
  std::cout << std::endl;

  std::cout << "Depth-first (post):" << std::endl;
  ta.traverse(echoslot, Glib::TRAVERSE_POST_ORDER);
  std::cout << std::endl;

  std::cout << "Leaf children of 'a':" << std::endl;
  ta.foreach(sigc::bind<bool>(sigc::ptr_fun(echol), true));
  std::cout << std::endl;

  std::cout << "Non-leaf children of 'a':" << std::endl;
  ta.foreach(sigc::bind<bool>(sigc::ptr_fun(echol), false));
  std::cout << std::endl;

  type_nodetree_string* tmp = ta.find(e);
  if(!tmp)
    std::cout << e << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find(a);
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find("f");
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find_child(e);
  if(!tmp)
    std::cout << e << " is not a child of " << (ta.data()) << std::endl;
  else
    std::cout << "Mistakenly found " << e << " in " << (ta.data()) << "'s children" << std::endl;

  tmp = ta.find_child(c);
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
