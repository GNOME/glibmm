#include <glibmm.h>
#include <iostream>

//Use this line if you want debug output:
//std::ostream& ostr = std::cout;

//This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

static void test_dynamic_cast();

int main(int, char**)
{
  Glib::init();

  int int_list[] = {1, 2, 3, 4, 5, 6, 7, 8};

  std::vector<int> int_vector(int_list,
    int_list + sizeof(int_list) / sizeof(int));

  ostr << "The elements of the original vector are:" << std::endl;

  for(guint i = 0; i < int_vector.size(); i++)
    ostr << int_vector[i] << std::endl;

  Glib::Variant< std::vector<int> > integers_variant =
    Glib::Variant< std::vector<int> >::create(int_vector);

  std::vector<int> int_vector2 = integers_variant.get();

  ostr << "The size of the copied vector is " << int_vector2.size() <<
    '.' << std::endl;

  ostr << "The elements of the copied vector are:" << std::endl;

  for(guint i = 0; i < int_vector2.size(); i++)
    ostr << int_vector2[i] << std::endl;

  ostr << "The number of children in the iterator of the " <<
    "variant are " << integers_variant.get_iter().get_n_children() <<
    '.' << std::endl;

  unsigned index = 4;
  ostr << "Element number " << index + 1 << " in the copy is " <<
    integers_variant.get(index) << '.' << std::endl;

  ostr << std::endl;

  typedef std::pair<Glib::ustring, Glib::ustring> TypeDictEntry;

  TypeDictEntry dict_entry("A key", "A value");

  ostr << "The original dictionary entry is (" << dict_entry.first <<
    ", " << dict_entry.second << ")." << std::endl;

  Glib::Variant<TypeDictEntry> dict_entry_variant =
    Glib::Variant<TypeDictEntry>::create(dict_entry);

  TypeDictEntry copy_entry = dict_entry_variant.get();

  ostr << "The copy dictionary entry is (" << copy_entry.first <<
    ", " << copy_entry.second << ")." << std::endl;

  ostr << std::endl;

  typedef std::map<unsigned, Glib::ustring> TypeDict;

  TypeDict orig_dict;

  for(unsigned i = 0; i < 10; i++)
  {
    std::string x_repeated(i, 'x');
    orig_dict.insert(std::pair<unsigned, Glib::ustring>(i, x_repeated));
  }

  ostr << "The original dictionary:" << std::endl;

  for(unsigned i = 0; i < orig_dict.size(); i++)
  {
    ostr << "(" << i << ", " << orig_dict[i] << ")." << std::endl;
  }

  Glib::Variant<TypeDict> orig_dict_variant =
    Glib::Variant<TypeDict>::create(orig_dict);

  TypeDict dict_copy = orig_dict_variant.get();

  ostr << "The copy of the dictionary:" << std::endl;

  for(unsigned i = 0; i < dict_copy.size(); i++)
  {
    ostr << "(" << i << ", " << dict_copy[i] << ")." << std::endl;
  }

  index = 3;

  std::pair<unsigned, Glib::ustring> a_pair = orig_dict_variant.get(index);

  ostr << "Element number " << index + 1 << " in the variant is: (" <<
    a_pair.first << ", " << a_pair.second << ")." << std::endl;


  Glib::ustring value;

  if(orig_dict_variant.lookup(index, value))
  {
    ostr << "The x's of element number " << index + 1 <<
      " in the variant are: " << value << '.' << std::endl;
  }

  test_dynamic_cast();

  return EXIT_SUCCESS;
}

static void test_dynamic_cast()
{
  Glib::Variant< int > v1 = Glib::Variant< int >::create(10);
  Glib::VariantBase& v2 = v1;
  Glib::Variant< int > v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int> >(v2);
  g_assert(v3.get() == 10);

  Glib::VariantBase v5 = v1;
  v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int> >(v5);
  g_assert(v3.get() == 10);

  Glib::Variant< double > v4;
  // v4 contain a NULL GVariant: The cast succeed
  v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int> >(v4);

  v4 = Glib::Variant< double >::create(1.0);
  try
  {
    v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int> >(v4);
    g_assert_not_reached();
  }
  catch(const std::bad_cast& e)
  {
  }

  // A t-uple
  std::vector<Glib::VariantBase> vec_var(2);
  vec_var[0] = Glib::Variant<int>::create(1);
  vec_var[1] = Glib::Variant<Glib::ustring>::create("coucou");
  Glib::VariantContainerBase var_tuple = Glib::VariantContainerBase::create_tuple(vec_var);
  g_assert(var_tuple.get_type_string() == "(is)");
  
  v5 = var_tuple;
  Glib::VariantContainerBase v6 = Glib::VariantBase::cast_dynamic<Glib::VariantContainerBase >(v5);
  
  try
  {
    v6 = Glib::VariantBase::cast_dynamic<Glib::VariantContainerBase >(v1);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  // A variant of type a{sv}
  typedef std::map<Glib::ustring, Glib::VariantBase> type_map_sv;
  typedef Glib::Variant<type_map_sv> type_dict_sv;
  g_assert((type_dict_sv::variant_type().get_string()) == "a{sv}");

  type_dict_sv var_map;
  type_map_sv map;
  Glib::Variant<Glib::ustring> var_string =
    Glib::Variant<Glib::ustring>::create("test variant");
  map["test key"] = var_string;
  var_map = type_dict_sv::create(map);
  g_assert(var_map.get_type_string() == "a{sv}");

  Glib::VariantBase& ref_var_base = var_map;
  type_dict_sv var_map_cast = Glib::VariantBase::cast_dynamic<type_dict_sv>(ref_var_base);

  try
  {
    Glib::Variant<std::map<Glib::ustring, Glib::ustring> > var_wrong_map =
      Glib::VariantBase::cast_dynamic<Glib::Variant<std::map<Glib::ustring, Glib::ustring> > >(ref_var_base);
    g_assert_not_reached();
  }
  catch(const std::bad_cast& e)
  {
  }

  type_map_sv get_map = var_map_cast.get();
  var_string = Glib::VariantBase::cast_dynamic<Glib::Variant< Glib::ustring > >(get_map["test key"]);
  g_assert(var_string.get() == "test variant");

  // A variant of type v
  Glib::Variant< Glib::VariantBase > var_v = Glib::Variant< Glib::VariantBase >::create(var_string);
  g_assert(var_v.get_type_string() == "v");
  Glib::Variant< Glib::ustring > var_s2 =
    Glib::VariantBase::cast_dynamic<Glib::Variant< Glib::ustring > >(var_v.get());
  g_assert(var_s2.get() == "test variant");
}
