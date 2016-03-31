#include <glibmm.h>

using type_key_value = Glib::ustring;
using type_p_key_value = type_key_value*;

static int
my_search(const type_key_value& key_a, const type_key_value& key_b)
{
  return key_b.compare(key_a);
}

static bool
my_traverse(const type_key_value& /*key*/, const type_key_value& value)
{
  g_assert(value.size() == 1 && value[0] > 0);
  return false;
}

const type_key_value str("0123456789"
                         "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                         "abcdefghijklmnopqrstuvwxyz");

const type_key_value str2("0123456789"
                          "abcdefghijklmnopqrstuvwxyz");

static bool
check_order(
  const type_key_value& key, const type_key_value& /*value*/, type_key_value::const_iterator& i)
{
  g_assert(key == type_key_value(1, *(i++)));
  return false;
}

static int
my_p_search(const type_p_key_value& key_a, const type_p_key_value& key_b)
{
  return my_search(*key_a, *key_b);
}

static bool
my_p_traverse(const type_p_key_value& key, const type_p_key_value& value)
{
  return my_traverse(*key, *value);
}

std::vector<type_p_key_value> pstr;
std::vector<type_p_key_value> pstr2;

static bool
check_p_order(const type_p_key_value& key, const type_p_key_value& /*value*/,
  std::vector<type_p_key_value>::const_iterator& i)
{
  g_assert(*key == **(i++));
  return false;
}

static int
my_p_key_compare(const type_p_key_value& key_a, const type_p_key_value& key_b)
{
  if (*key_a < *key_b)
    return -1;

  if (*key_a > *key_b)
    return 1;

  return EXIT_SUCCESS;
}

int
main()
{
  auto tree = Glib::BalancedTree<type_key_value, type_key_value>::create();

  for (type_key_value::size_type i = 0; i < str.size(); ++i)
    tree->insert(str.substr(i, 1), str.substr(i, 1));

  tree->foreach (sigc::ptr_fun(my_traverse));

  g_assert(tree->nnodes() == gint(str.size()));
  g_assert(tree->height() == 6);

  tree->foreach (sigc::bind(sigc::ptr_fun(check_order), str.begin()));

  for (type_key_value::size_type i = 0; i < 26; i++)
    g_assert(tree->remove(str.substr(i + 10, 1)));

  g_assert(!tree->remove(""));

  tree->foreach (sigc::ptr_fun(my_traverse));

  g_assert(tree->nnodes() == gint(str2.size()));
  g_assert(tree->height() == 6);

  tree->foreach (sigc::bind(sigc::ptr_fun(check_order), str2.begin()));

  for (int i = 25; i >= 0; i--)
    tree->insert(str.substr(i + 10, 1), str.substr(i + 10, 1));

  tree->foreach (sigc::bind(sigc::ptr_fun(check_order), str.begin()));

  type_key_value* value;

  value = tree->lookup("0");
  g_assert(value && *value == "0");
  value = tree->lookup("A");
  g_assert(value && *value == "A");
  value = tree->lookup("a");
  g_assert(value && *value == "a");
  value = tree->lookup("z");
  g_assert(value && *value == "z");

  value = tree->lookup("!");
  g_assert(value == NULL);
  value = tree->lookup("=");
  g_assert(value == NULL);
  value = tree->lookup("|");
  g_assert(value == NULL);

  value = tree->search(sigc::ptr_fun(my_search), "0");
  g_assert(value && *value == "0");
  value = tree->search(sigc::ptr_fun(my_search), "A");
  g_assert(value && *value == "A");
  value = tree->search(sigc::ptr_fun(my_search), "a");
  g_assert(value && *value == "a");
  value = tree->search(sigc::ptr_fun(my_search), "z");
  g_assert(value && *value == "z");

  value = tree->search(sigc::ptr_fun(my_search), "!");
  g_assert(value == NULL);
  value = tree->search(sigc::ptr_fun(my_search), "=");
  g_assert(value == NULL);
  value = tree->search(sigc::ptr_fun(my_search), "|");
  g_assert(value == NULL);

  auto ptree =
    Glib::BalancedTree<type_p_key_value, type_p_key_value>::create(sigc::ptr_fun(my_p_key_compare));

  for (type_key_value::size_type i = 0; i < str.size(); ++i)
    pstr.emplace_back(new type_key_value(str.substr(i, 1)));
  for (type_key_value::size_type i = 0; i < str2.size(); ++i)
    pstr2.emplace_back(new type_key_value(str2.substr(i, 1)));

  for (type_key_value::size_type i = 0; i < str.size(); ++i)
    ptree->insert(pstr[i], pstr[i]);

  ptree->foreach (sigc::ptr_fun(my_p_traverse));

  g_assert(ptree->nnodes() == gint(pstr.size()));
  g_assert(ptree->height() == 6);

  std::vector<type_p_key_value>::const_iterator j = pstr.begin();
  ptree->foreach (sigc::bind(sigc::ptr_fun(check_p_order), j));

  g_assert(ptree->lookup(new Glib::ustring("l")));

  for (std::vector<type_p_key_value>::size_type i = 0; i < 26; i++)
    g_assert(ptree->remove(pstr[i + 10]));

  Glib::ustring pstr3("");
  g_assert(!ptree->remove(&pstr3));

  ptree->foreach (sigc::ptr_fun(my_p_traverse));

  g_assert(ptree->nnodes() == gint(str2.size()));
  g_assert(ptree->height() == 6);

  j = pstr2.begin();
  ptree->foreach (sigc::bind(sigc::ptr_fun(check_p_order), j));

  for (int i = 25; i >= 0; i--)
    ptree->insert(pstr[i + 10], pstr[i + 10]);

  j = pstr.begin();
  ptree->foreach (sigc::bind(sigc::ptr_fun(check_p_order), j));

  type_p_key_value* pvalue;

  pstr3 = "0";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue && **pvalue == "0");
  pstr3 = "A";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue && **pvalue == "A");
  pstr3 = "a";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue && **pvalue == "a");
  pstr3 = "z";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue && **pvalue == "z");

  pstr3 = "!";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue == NULL);
  pstr3 = "=";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue == NULL);
  pstr3 = "|";
  pvalue = ptree->lookup(&pstr3);
  g_assert(pvalue == NULL);

  pstr3 = "0";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue && **pvalue == "0");
  pstr3 = "A";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue && **pvalue == "A");
  pstr3 = "a";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue && **pvalue == "a");
  pstr3 = "z";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue && **pvalue == "z");

  pstr3 = "!";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue == NULL);
  pstr3 = "=";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue == NULL);
  pstr3 = "|";
  pvalue = ptree->search(sigc::ptr_fun(my_p_search), &pstr3);
  g_assert(pvalue == NULL);

  return EXIT_SUCCESS;
}
