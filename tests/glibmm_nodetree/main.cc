#include <iostream>
#include <glibmm.h>

bool echo(Glib::NodeTree<std::string>& i)
{
  std::cout << i.data() << ' ';
  return false;
}

void echol(Glib::NodeTree<std::string>& i, bool is_leaf)
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

  Glib::NodeTree<std::string> ta(a),
                          tb(b),
                          tc(c),
                          te(e);

  sigc::slot<bool, Glib::NodeTree<std::string>&> echoslot = sigc::ptr_fun(echo);


  ta.insert(0, tc);
  ta.prepend(tb);
  ta.append_data(d);
  tc.append(te);
  te.prepend_data(f);

  std::cout << "Breadth-first:" << std::endl;
  ta.traverse(Glib::LEVEL_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (pre):" << std::endl;
  ta.traverse(Glib::PRE_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (in):" << std::endl;
  ta.traverse(Glib::IN_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Depth-first (post):" << std::endl;
  ta.traverse(Glib::POST_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, INT_MAX, echoslot);
  std::cout << std::endl;

  std::cout << "Leaf children of 'a':" << std::endl;
  ta.foreach(Glib::TRAVERSE_ALL, sigc::bind<bool>(sigc::ptr_fun(echol), true));
  std::cout << std::endl;

  std::cout << "Non-leaf children of 'a':" << std::endl;
  ta.foreach(Glib::TRAVERSE_ALL, sigc::bind<bool>(sigc::ptr_fun(echol), false));
  std::cout << std::endl;

  Glib::NodeTree<std::string>* tmp = ta.find(Glib::IN_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, e);
  if(!tmp)
    std::cout << e << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find(Glib::IN_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, a);
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find(Glib::IN_ORDER, Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, "f");
  if(!tmp)
    std::cout << a << " not found" << std::endl;
  else
    std::cout << "Found " << (tmp->data()) << std::endl;

  tmp = ta.find_child(Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, e);
  if(!tmp)
    std::cout << e << " is not a child of " << (ta.data()) << std::endl;
  else
    std::cout << "Mistakenly found " << e << " in " << (ta.data()) << "'s children" << std::endl;

  tmp = ta.find_child(Glib::TRAVERSE_LEAVES | Glib::TRAVERSE_NON_LEAVES, c);
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
