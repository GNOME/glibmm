#include <glibmm.h>
#include <iostream>

using type_nodetree_string = Glib::NodeTree<const std::string>;

static bool
node_build_string(type_nodetree_string& node, std::string& string)
{
  string += node.data();

  return false;
}

int
main()
{
  std::string tstring, cstring;
  type_nodetree_string* root;
  type_nodetree_string* node;
  type_nodetree_string* node_B;
  /* type_nodetree_string* node_D; */
  type_nodetree_string* node_F;
  type_nodetree_string* node_G;
  type_nodetree_string* node_J;

  root = new type_nodetree_string("A");
  g_assert(root->depth() == 1 && root->get_max_height() == 1);

  node_B = new type_nodetree_string("B");
  root->append(*node_B);
  g_assert(root->first_child() == node_B);

  node_B->append_data("E");
  node_B->prepend_data("C");
  /* node_D = & */ node_B->insert(1, *(new type_nodetree_string("D")));

  node_F = new type_nodetree_string("F");
  root->append(*node_F);
  g_assert(root->first_child()->next_sibling() == node_F);

  node_G = new type_nodetree_string("G");
  node_F->append(*node_G);
  node_J = new type_nodetree_string("J");
  node_G->prepend(*node_J);
  node_G->insert(42, *(new type_nodetree_string("K")));
  node_G->insert_data(0, "H");
  node_G->insert(1, *(new type_nodetree_string("I")));

  g_assert(root->depth() == 1);
  g_assert(root->get_max_height() == 4);
  g_assert(node_G->first_child()->next_sibling()->depth() == 4);
  g_assert(root->node_count(type_nodetree_string::TraverseFlags::LEAVES) == 7);
  g_assert(root->node_count(type_nodetree_string::TraverseFlags::NON_LEAVES) == 4);
  g_assert(root->node_count(type_nodetree_string::TraverseFlags::ALL) == 11);
  g_assert(node_F->get_max_height() == 3);
  g_assert(node_G->child_count() == 4);
  g_assert(root->find_child("F", type_nodetree_string::TraverseFlags::ALL) == node_F);
  g_assert(
    root->find("I", type_nodetree_string::TraverseType::LEVEL_ORDER, type_nodetree_string::TraverseFlags::NON_LEAVES) == NULL);
  g_assert(
    root->find("J", type_nodetree_string::TraverseType::IN_ORDER, type_nodetree_string::TraverseFlags::LEAVES) == node_J);

  for (guint i = 0; i < node_B->child_count(); i++)
  {
    node = node_B->nth_child(i);
    g_assert(node->data() == std::string(1, ('C' + i)));
  }

  for (guint i = 0; i < node_G->child_count(); i++)
    g_assert(node_G->child_position(*node_G->nth_child(i)) == (int)i);

  /* we have built:                    A
   *                                 /   \
   *                               B       F
   *                             / | \       \
   *                           C   D   E       G
   *                                         / /\ \
   *                                       H  I  J  K
   *
   * for in-order traversal, 'G' is considered to be the "left"
   * child of 'F', which will cause 'F' to be the last node visited.
   */

  tstring.clear();
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::PRE_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == "ABCDEFGHIJK");
  tstring.clear();
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::POST_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == "CDEBHIJKGFA");
  tstring.clear();
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::IN_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == "CBDEAHGIJKF");
  tstring.clear();
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::LEVEL_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == "ABFCDEGHIJK");
  tstring.clear();

  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::LEVEL_ORDER, type_nodetree_string::TraverseFlags::LEAVES, -1);
  g_assert(tstring == "CDEHIJK");
  tstring.clear();
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::PRE_ORDER, type_nodetree_string::TraverseFlags::NON_LEAVES, -1);
  g_assert(tstring == "ABFG");
  tstring.clear();

  node_B->reverse_children();
  node_G->reverse_children();

  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::LEVEL_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == "ABFEDCGKJIH");
  tstring.clear();

  node = new type_nodetree_string(*root); // A deep copy.
  g_assert(root->node_count(type_nodetree_string::TraverseFlags::ALL) ==
           node->node_count(type_nodetree_string::TraverseFlags::ALL));
  g_assert(root->get_max_height() == node->get_max_height());
  root->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(tstring)),
    type_nodetree_string::TraverseType::IN_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  node->traverse(sigc::bind(sigc::ptr_fun(node_build_string), std::ref(cstring)),
    type_nodetree_string::TraverseType::IN_ORDER, type_nodetree_string::TraverseFlags::ALL, -1);
  g_assert(tstring == cstring);

  delete node;

  delete root;

  /* allocation tests */

  root = new type_nodetree_string();
  node = root;

  for (guint i = 0; i < 2048; i++)
  {
    node->append(*(new type_nodetree_string()));
    if ((i % 5) == 4)
      node = node->first_child()->next_sibling();
  }
  g_assert(root->get_max_height() > 100);
  g_assert(root->node_count(type_nodetree_string::TraverseFlags::ALL) == 1 + 2048);

  delete root;

  return EXIT_SUCCESS;
}
