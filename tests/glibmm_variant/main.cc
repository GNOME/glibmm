#include <glibmm.h>
#include <iostream>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

static void test_variant_floating();
static void test_dynamic_cast();

namespace
{

bool test_tuple()
{
  using TupleType = std::tuple<guint16, Glib::ustring, bool>;
  using MapType = std::map<guint16, TupleType>;
  bool result_ok = true;

  // First tuple
  const guint16 q1 = 2;
  const Glib::ustring s1 = "Hi there";
  const bool b1 = false;
  auto t1 = std::make_tuple(q1, s1, b1);
  auto tuple1_variant = Glib::Variant<TupleType>::create(t1);

  // Second tuple
  const guint16 q2 = 3;
  const Glib::ustring s2 = "Hello";
  const bool b2 = true;
  auto t2 = std::make_tuple(q2, s2, b2);
  auto tuple2_variant = Glib::Variant<TupleType>::create(t2);

  // Insert the tuples in a map.
  MapType m;
  m[4] = t1;
  m[5] = t2;
  auto map_variant = Glib::Variant<MapType>::create(m);

  std::string type_string = tuple1_variant.variant_type().get_string();
  ostr << "Type string of tuple1: " << type_string << std::endl;
  result_ok &= type_string == "(qsb)";

  type_string = tuple2_variant.get_type_string();
  ostr << "Type string of tuple2: " << type_string << std::endl;
  result_ok &= type_string == "(qsb)";

  type_string = map_variant.variant_type().get_string();
  ostr << "Type string of map of tuples: " << type_string << std::endl;
  result_ok &= map_variant.get_type_string() == "a{q(qsb)}";

  // Extract from the map of tuples.
  std::pair<guint16, TupleType> child0 = map_variant.get_child(0);
  ostr << "Index of first map entry: " << child0.first << std::endl;
  result_ok &= child0.first == 4;
  auto extracted_tuple = child0.second;
#if __cplusplus > 201103L // C++14 or higher
  auto q3 = std::get<guint16>(extracted_tuple);
  auto s3 = std::get<Glib::ustring>(extracted_tuple);
  auto b3 = std::get<bool>(extracted_tuple);
#else // C++11
  auto q3 = std::get<0>(extracted_tuple);
  auto s3 = std::get<1>(extracted_tuple);
  auto b3 = std::get<2>(extracted_tuple);
#endif
  ostr << "Extracted tuple1 from map: (" << q3 << ", " << s3 << ", " << b3 << ")" << std::endl;
  result_ok &= q3 == q1 && s3 == s1 && b3 == b1;

  // Extract from a tuple.
  auto q4 = tuple2_variant.get_child<guint16>(0);
  auto s4 = tuple2_variant.get_child_variant<Glib::ustring>(1).get();
#if __cplusplus > 201103L // C++14 or higher
  auto b4 = std::get<bool>(tuple2_variant.get());
#else // C++11
  auto b4 = std::get<2>(tuple2_variant.get());
#endif
  ostr << "Extracted tuple2: (" << q4 << ", " << s4 << ", " << b4 << ")" << std::endl;
  result_ok &= q4 == q2 && s4 == s2 && b4 == b2;

  return result_ok;
}

bool test_object_path()
{
  bool result_ok = true;

  // Object path vector
  std::vector<Glib::DBusObjectPathString> vec1 {"/object/path1", "/object/path_two", "/object/pathIII" };
  auto variantvec1 = Glib::Variant<std::vector<Glib::DBusObjectPathString>>::create(vec1);

  auto vec2 = variantvec1.get();
  ostr << "Extracted object paths: " << vec2[0] << ", " << vec2[1] << ", " << vec2[2] << std::endl;

  for (std::size_t i = 0; i < vec1.size(); ++i)
    result_ok &= vec1[i] == vec2[i];

  // Complicated structure of variant type a{oa{sa{sv}}}
  // Glib::Variant<std::map<Glib::DBusObjectPathString, std::map<Glib::ustring, std::map<Glib::ustring, Glib::VariantBase>>>>
  using three_leveled_map =
    std::map<Glib::DBusObjectPathString, std::map<Glib::ustring, std::map<Glib::ustring, Glib::VariantBase>>>;

  // Create the map
  std::map<Glib::ustring, Glib::VariantBase> map1;
  map1["map1_1"] = Glib::Variant<Glib::ustring>::create("value1");
  std::map<Glib::ustring, std::map<Glib::ustring, Glib::VariantBase>> map2;
  map2["map2_1"] = map1;
  three_leveled_map map3;
  map3["/map3/path1"] = map2;
  // Create the corresponding Variant and check its type
  auto variantmap = Glib::Variant<three_leveled_map>::create(map3);
  ostr << "variantmap.get_type_string() = " << variantmap.get_type_string() << std::endl;
  result_ok &= variantmap.get_type_string() == "a{oa{sa{sv}}}";
  // Extract the map and check that the stored value remains.
  auto map4 = variantmap.get();
  auto variant1 = map4["/map3/path1"]["map2_1"]["map1_1"];
  ostr << "variant1.get_type_string() = " << variant1.get_type_string() << std::endl;
  auto variantstring = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(variant1);
  if (variantstring && variantstring.get_type_string() == "s")
  {
    ostr << "Extracted map value: " << variantstring.get() << std::endl;
    result_ok &= variantstring.get() == "value1";
  }
  else
  {
    result_ok = false;
  }
  return result_ok;
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();

  // vector<int>:
  const int int_list[] = { 1, 2, 3, 4, 5, 6, 7, 8 };

  std::vector<int> int_vector(int_list, int_list + sizeof(int_list) / sizeof(int));

  ostr << "The elements of the original vector are:" << std::endl;

  for (guint i = 0; i < int_vector.size(); i++)
    ostr << int_vector[i] << std::endl;

  auto integers_variant = Glib::Variant<std::vector<int>>::create(int_vector);

  auto int_vector2 = integers_variant.get();

  ostr << "The size of the copied vector is " << int_vector2.size() << '.' << std::endl;

  ostr << "The elements of the copied vector are:" << std::endl;

  for (guint i = 0; i < int_vector2.size(); i++)
    ostr << int_vector2[i] << std::endl;

  ostr << "The number of children in the iterator of the "
       << "variant are " << integers_variant.get_iter().get_n_children() << '.' << std::endl;

  unsigned index = 4;
  ostr << "Element number " << index + 1 << " in the copy is " << integers_variant.get_child(index)
       << '.' << std::endl;

  ostr << std::endl;

  // vector<std::string>:
  std::vector<std::string> vec_strings = { "a" };
  auto variant_vec_strings = Glib::Variant<std::vector<std::string>>::create(vec_strings);

  // Dict:

  using TypeDictEntry = std::pair<Glib::ustring, Glib::ustring>;

  TypeDictEntry dict_entry("A key", "A value");

  ostr << "The original dictionary entry is (" << dict_entry.first << ", " << dict_entry.second
       << ")." << std::endl;

  auto dict_entry_variant = Glib::Variant<TypeDictEntry>::create(dict_entry);

  TypeDictEntry copy_entry = dict_entry_variant.get();

  ostr << "The copy dictionary entry is (" << copy_entry.first << ", " << copy_entry.second << ")."
       << std::endl;

  ostr << std::endl;

  using TypeDict = std::map<unsigned, Glib::ustring>;

  TypeDict orig_dict;

  for (unsigned i = 0; i < 10; i++)
  {
    std::string x_repeated(i, 'x');
    orig_dict.insert(std::pair<unsigned, Glib::ustring>(i, x_repeated));
  }

  ostr << "The original dictionary:" << std::endl;

  for (unsigned i = 0; i < orig_dict.size(); i++)
  {
    ostr << "(" << i << ", " << orig_dict[i] << ")." << std::endl;
  }

  auto orig_dict_variant = Glib::Variant<TypeDict>::create(orig_dict);

  TypeDict dict_copy = orig_dict_variant.get();

  ostr << "The copy of the dictionary:" << std::endl;

  for (unsigned i = 0; i < dict_copy.size(); i++)
  {
    ostr << "(" << i << ", " << dict_copy[i] << ")." << std::endl;
  }

  index = 3;

  auto a_pair = orig_dict_variant.get_child(index);

  ostr << "Element number " << index + 1 << " in the variant is: (" << a_pair.first << ", "
       << a_pair.second << ")." << std::endl;

  Glib::ustring value;

  if (orig_dict_variant.lookup(index, value))
  {
    ostr << "The x's of element number " << index + 1 << " in the variant are: " << value << '.'
         << std::endl;
  }

  // std::vector< std::map< Glib::ustring, Glib::Variant<int> > >
  using ComplexDictType = std::map<Glib::ustring, Glib::Variant<int>>;

  ComplexDictType complex_dict1;
  ComplexDictType complex_dict2;

  for (int i = 0; i < 10; i++)
  {
    // Convert integer i to string.
    std::stringstream ss;
    ss << i;

    Glib::ustring s = "String " + ss.str();

    auto v = Glib::Variant<int>::create(i);

    complex_dict1.insert(std::pair<Glib::ustring, Glib::Variant<int>>("Map 1 " + s, v));

    complex_dict2.insert(std::pair<Glib::ustring, Glib::Variant<int>>("Map 2 " + s, v));
  }

  using ComplexVecType = std::vector<std::map<Glib::ustring, Glib::Variant<int>>>;

  ComplexVecType complex_vector = { complex_dict1, complex_dict2 };

  auto complex_variant = Glib::Variant<ComplexVecType>::create(complex_vector);

  // This will output the type string aa{sv}.
  ostr << "The type string of the variant containing a vector of "
          "dictionaries is: "
       << std::endl
       << complex_variant.get_type_string() << "." << std::endl
       << std::endl;

  ComplexVecType copy_complex_vector = complex_variant.get();

  for (guint i = 0; i < copy_complex_vector.size(); i++)
  {
    ostr << "Printing dictionary # " << i + 1 << ":" << std::endl;

    ComplexDictType map = copy_complex_vector[i];

    for (const auto& entry : map)
    {
      ostr << entry.first << " -> " << entry.second.get() << "." << std::endl;
    }
    ostr << std::endl;
  }

  test_variant_floating();
  test_dynamic_cast();

  bool result_ok = test_tuple();
  result_ok &= test_object_path();
  return result_ok ? EXIT_SUCCESS : EXIT_FAILURE;
}

// Test casting of multiple types to a ustring:
static void
test_dynamic_cast_ustring_types()
{
  Glib::VariantBase vbase_string = Glib::wrap(g_variant_new("s", "somestring"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(vbase_string);
    ostr << "Casted string Glib::Variant<Glib::ustring>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_objectpath = Glib::wrap(g_variant_new_object_path("/remote/object/path"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(vbase_objectpath);
    ostr << "Casted object path Glib::Variant<Glib::ustring>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_signature = Glib::wrap(g_variant_new_signature("aas"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(vbase_signature);
    ostr << "Casted signature Glib::Variant<Glib::ustring>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }
}

// Test casting of multiple types to a std::string:
static void
test_dynamic_cast_string_types()
{
  Glib::VariantBase vbase_string = Glib::wrap(g_variant_new("s", "somestring"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<std::string>>(vbase_string);
    ostr << "Casted string Glib::Variant<std::string>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_objectpath = Glib::wrap(g_variant_new_object_path("/remote/object/path"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<std::string>>(vbase_objectpath);
    ostr << "Casted object path Glib::Variant<std::string>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_signature = Glib::wrap(g_variant_new_signature("aas"));

  try
  {
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<std::string>>(vbase_signature);
    ostr << "Casted signature Glib::Variant<std::string>: " << derived.get() << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }
}

// Test casting a complicated type, containing an object path and a DBus type signature.
void
test_dynamic_cast_composite_types()
{
  // Build a GVaraint of type a{oag}, and cast it to
  // Glib::Variant<std::map<Glib::ustring, std::vector<std::string>>>.
  // 'o' is VARIANT_TYPE_OBJECT_PATH and 'g' is VARIANT_TYPE_SIGNATURE.

  GVariantBuilder dict_builder;
  GVariantBuilder array_builder;
  g_variant_builder_init(&dict_builder, G_VARIANT_TYPE("a{oag}"));

  g_variant_builder_init(&array_builder, G_VARIANT_TYPE("ag"));
  g_variant_builder_add(&array_builder, "g", "id");
  g_variant_builder_add(&array_builder, "g", "isi");
  g_variant_builder_add(&array_builder, "g", "ia{si}");
  g_variant_builder_add(&dict_builder, "{oag}", "/remote/object/path1", &array_builder);

  g_variant_builder_init(&array_builder, G_VARIANT_TYPE("ag"));
  g_variant_builder_add(&array_builder, "g", "i(d)");
  g_variant_builder_add(&array_builder, "g", "i(si)");
  g_variant_builder_add(&dict_builder, "{oag}", "/remote/object/path2", &array_builder);

  Glib::VariantBase cppdict(g_variant_builder_end(&dict_builder));

  try
  {
    using composite_type = std::map<Glib::ustring, std::vector<std::string>>;
    auto derived = Glib::VariantBase::cast_dynamic<Glib::Variant<composite_type>>(cppdict);

    ostr << "Cast composite type (get_type_string()=" << derived.get_type_string()
         << ", variant_type().get_string()=" << derived.variant_type().get_string() << "): ";
    composite_type var = derived.get();
    for (const auto& the_pair : var)
    {
      ostr << "\n  " << the_pair.first << ":";
      const auto& vec = the_pair.second;
      for (const auto& str : vec)
        ostr << "  " << str;
    }
    ostr << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  try
  {
    auto derived =
      Glib::VariantBase::cast_dynamic<Glib::Variant<std::map<Glib::ustring, std::string>>>(cppdict);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }
}

static void
test_dynamic_cast()
{
  auto v1 = Glib::Variant<int>::create(10);
  Glib::VariantBase& v2 = v1;
  auto v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v2);
  g_assert(v3.get() == 10);

  Glib::VariantBase v5 = v1;
  v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v5);
  g_assert(v3.get() == 10);

  Glib::Variant<double> v4;
  // v4 contain a NULL GVariant: The cast succeed
  v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v4);

  v4 = Glib::Variant<double>::create(1.0);
  try
  {
    v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v4);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  // A tuple
  std::vector<Glib::VariantBase> vec_var(2);
  vec_var[0] = Glib::Variant<int>::create(1);
  vec_var[1] = Glib::Variant<Glib::ustring>::create("coucou");
  Glib::VariantContainerBase var_tuple = Glib::VariantContainerBase::create_tuple(vec_var);
  g_assert(var_tuple.get_type_string() == "(is)");

  v5 = var_tuple;
  Glib::VariantContainerBase v6 = Glib::VariantBase::cast_dynamic<Glib::VariantContainerBase>(v5);

  try
  {
    v6 = Glib::VariantBase::cast_dynamic<Glib::VariantContainerBase>(v1);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  // A variant of type a{sv}
  using type_map_sv = std::map<Glib::ustring, Glib::VariantBase>;
  using type_dict_sv = Glib::Variant<type_map_sv>;
  g_assert((type_dict_sv::variant_type().get_string()) == "a{sv}");

  type_dict_sv var_map;
  type_map_sv map;
  auto var_string = Glib::Variant<Glib::ustring>::create("test variant");
  map["test key"] = var_string;
  var_map = type_dict_sv::create(map);
  g_assert(var_map.get_type_string() == "a{sv}");

  Glib::VariantBase& ref_var_base = var_map;
  type_dict_sv var_map_cast = Glib::VariantBase::cast_dynamic<type_dict_sv>(ref_var_base);

  try
  {
    auto var_wrong_map =
      Glib::VariantBase::cast_dynamic<Glib::Variant<std::map<Glib::ustring, Glib::ustring>>>(
        ref_var_base);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  type_map_sv get_map = var_map_cast.get();
  var_string = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(get_map["test key"]);
  g_assert(var_string.get() == "test variant");

  // A variant of type v
  auto var_v = Glib::Variant<Glib::VariantBase>::create(var_string);
  g_assert(var_v.get_type_string() == "v");
  auto var_s2 = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(var_v.get());
  g_assert(var_s2.get() == "test variant");

  test_dynamic_cast_ustring_types();
  test_dynamic_cast_string_types();
  test_dynamic_cast_composite_types();
}

static GLogLevelFlags
get_log_flags()
{
  return static_cast<GLogLevelFlags>(
    static_cast<unsigned>(G_LOG_LEVEL_CRITICAL) | static_cast<unsigned>(G_LOG_LEVEL_WARNING));
}

struct WarnCatcher
{
  WarnCatcher(const std::string& domain)
  : m_domain(domain), m_old_flags(g_log_set_fatal_mask(m_domain.c_str(), get_log_flags()))
  {
  }

  ~WarnCatcher() { g_log_set_fatal_mask(m_domain.c_str(), m_old_flags); }

  std::string m_domain;
  GLogLevelFlags m_old_flags;
};

static void
test_variant_floating()
{
  WarnCatcher warn_catcher("GLib");

  {
    GVariant* cv = g_variant_new("i", 42);
    Glib::VariantBase cxxv = Glib::wrap(cv, false);

    g_assert(!cxxv.is_floating());
  }

  {
    GVariant* cv = g_variant_new("i", 42);
    Glib::VariantBase cxxv = Glib::wrap(cv, true);

    g_assert(!cxxv.is_floating());

    g_variant_unref(cv);
  }

  {
    GVariant* cv = g_variant_new("i", 42);

    if (g_variant_is_floating(cv))
    {
      g_variant_ref_sink(cv);
    }

    Glib::VariantBase cxxv = Glib::wrap(cv, false);

    g_assert(!cxxv.is_floating());
  }

  {
    GVariant* cv = g_variant_new("i", 42);

    if (g_variant_is_floating(cv))
    {
      g_variant_ref_sink(cv);
    }

    Glib::VariantBase cxxv = Glib::wrap(cv, true);

    g_assert(!cxxv.is_floating());

    g_variant_unref(cv);
  }
}
