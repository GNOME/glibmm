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
  auto tuple1_variant = Glib::create_variant(t1);

  // Second tuple
  const guint16 q2 = 3;
  const Glib::ustring s2 = "Hello";
  const bool b2 = true;
  auto t2 = std::make_tuple(q2, s2, b2);
  auto tuple2_variant = Glib::create_variant(t2);

  // Insert the tuples in a map.
  MapType m;
  m[4] = t1;
  m[5] = t2;
  auto map_variant = Glib::create_variant(m);

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
  auto q3 = std::get<guint16>(extracted_tuple);
  auto s3 = std::get<Glib::ustring>(extracted_tuple);
  auto b3 = std::get<bool>(extracted_tuple);
  ostr << "Extracted tuple1 from map: (" << q3 << ", " << s3 << ", " << b3 << ")" << std::endl;
  result_ok &= q3 == q1 && s3 == s1 && b3 == b1;

  // Extract from a tuple.
  auto q4 = tuple2_variant.get_child<guint16>(0);
  auto s4 = tuple2_variant.get_child_variant<Glib::ustring>(1).get();
  auto b4 = std::get<bool>(tuple2_variant.get());
  ostr << "Extracted tuple2: (" << q4 << ", " << s4 << ", " << b4 << ")" << std::endl;
  result_ok &= q4 == q2 && s4 == s2 && b4 == b2;

  return result_ok;
}

bool test_object_path()
{
  bool result_ok = true;

  // Object path vector
  std::vector<Glib::DBusObjectPathString> vec1 {"/object/path1", "/object/path_two", "/object/pathIII" };
  auto variantvec1 = Glib::create_variant(vec1);

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
  map1["map1_1"] = Glib::create_variant(Glib::ustring("value1"));
  std::map<Glib::ustring, std::map<Glib::ustring, Glib::VariantBase>> map2;
  map2["map2_1"] = map1;
  three_leveled_map map3;
  map3["/map3/path1"] = map2;
  // Create the corresponding Variant and check its type
  auto variantmap = Glib::create_variant(map3);
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

bool test_comparison()
{
  bool result_ok = true;

  std::vector<int> int_vector1 = { 1, 2, 3, 4, 5, 6, 7, 8 };
  std::vector<int> int_vector2 = { 1, 2, 3, 4, 5, 6, 7 };

  auto int_variant1 = Glib::create_variant(int_vector1);
  auto int_variant2 = Glib::create_variant(int_vector2);
  auto int_variant3 = Glib::create_variant(int_vector1);

  // Equality and inequality operators
  ostr << "int_variant1 == int_variant2 (0): " << (int_variant1 == int_variant2) << std::endl;
  result_ok &= !(int_variant1 == int_variant2);
  ostr << "int_variant1 != int_variant2 (1): " << (int_variant1 != int_variant2) << std::endl;
  result_ok &= (int_variant1 != int_variant2);

  ostr << "int_variant1 == int_variant3 (1): " << (int_variant1 == int_variant3) << std::endl;
  result_ok &= (int_variant1 == int_variant3);
  ostr << "int_variant1 != int_variant3 (0): " << (int_variant1 != int_variant3) << std::endl;
  result_ok &= !(int_variant1 != int_variant3);

#if 0
  // Less than (activate if operator<() exists)
  ostr << "int_variant2 < int_variant1 (1): " << (int_variant2 < int_variant1) << std::endl;
  result_ok &= (int_variant2 < int_variant1);
  ostr << "int_variant1 < int_variant3 (0): " << (int_variant1 < int_variant3) << std::endl;
  result_ok &= !(int_variant1 < int_variant3);
#endif
  return result_ok;
}

// Check that there are Variant specializations for all expected integer
// types, usually all of short, int, long and long long and the
// corresponding unsigned types.
bool test_integer_types()
{
  bool result_ok = true;
  bool shall_fail = false;

  // If GLIBMM_SIZEOF_SHORT < 2 there is no Variant<short>.
#if GLIBMM_SIZEOF_SHORT >= 2
  auto var_short = Glib::Variant<short>::create(1);
  auto var_ushort = Glib::Variant<unsigned short>::create(2U);
  result_ok &= var_short.get() == 1;
  result_ok &= var_ushort.get() == 2U;
#endif

  auto var_int = Glib::Variant<int>::create(3);
  auto var_uint = Glib::Variant<unsigned int>::create(4U);
  auto var_long = Glib::Variant<long>::create(5L);
  auto var_ulong = Glib::Variant<unsigned long>::create(6UL);
  result_ok &= var_int.get() == 3;
  result_ok &= var_uint.get() == 4U;
  result_ok &= var_long.get() == 5L;
  result_ok &= var_ulong.get() == 6UL;

  // If GLIBMM_SIZEOF_LONG_LONG > 8 there is no Variant<long long>.
#if GLIBMM_SIZEOF_LONG_LONG <= 8
  auto var_llong = Glib::Variant<long long>::create(7LL);
  auto var_ullong = Glib::Variant<unsigned long long>::create(8ULL);
  result_ok &= var_llong.get() == 7LL;
  result_ok &= var_ullong.get() == 8ULL;

#if GLIBMM_SIZEOF_LONG == GLIBMM_SIZEOF_LONG_LONG
  try
  {
    // Test some casts between equivalent types.
    shall_fail = false;
    auto var_llong2 = Glib::VariantBase::cast_dynamic<Glib::Variant<long long>>(var_long);
    auto var_long2 = Glib::VariantBase::cast_dynamic<Glib::Variant<long>>(var_llong);
    // Test a cast between non-equivalent types.
    shall_fail = true;
    auto var_short2 = Glib::VariantBase::cast_dynamic<Glib::Variant<short>>(var_llong);
    result_ok = false;
  }
  catch (const std::bad_cast& e)
  {
    result_ok &= shall_fail;
  }
#endif
#endif

  // Test Glib::DBusHandle and Glib::Variant<Glib::DBusHandle>.
  Glib::DBusHandle handle1 = 3;
  auto handle2 = handle1;
  auto handle3 = Glib::DBusHandle(3);
  gint32 i1 = handle3;
  auto var_handle1 = Glib::Variant<Glib::DBusHandle>::create(handle2);
  auto var_int1 = Glib::Variant<gint32>::create(i1);
  result_ok &= (var_handle1.get() == var_int1.get());
  try
  {
    // A Variant<gint32> can contain a VARIANT_TYPE_INT32 or a VARIANT_TYPE_HANDLE.
    // A Variant<DBusHandle> can only contain a VARIANT_TYPE_HANDLE.
    shall_fail = false;
    auto var_int2 = Glib::VariantBase::cast_dynamic<Glib::Variant<gint32>>(var_handle1);
    ostr << "VariantTypes of var_handle1,var_int1,var_int2: "
         << var_handle1.get_type_string() << "," << var_int1.get_type_string()
         << "," << var_int2.get_type_string() << std::endl;
    shall_fail = true;
    auto var_handle2 = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::DBusHandle>>(var_int1);
    result_ok = false;
  }
  catch (const std::bad_cast& e)
  {
    result_ok &= shall_fail;
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

  auto integers_variant = Glib::create_variant(int_vector);

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
  auto variant_vec_strings = Glib::create_variant(vec_strings);

  // Dict:

  using TypeDictEntry = std::pair<Glib::ustring, Glib::ustring>;

  TypeDictEntry dict_entry("A key", "A value");

  ostr << "The original dictionary entry is (" << dict_entry.first << ", " << dict_entry.second
       << ")." << std::endl;

  auto dict_entry_variant = Glib::create_variant(dict_entry);

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

  auto orig_dict_variant = Glib::create_variant(orig_dict);

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

    auto v = Glib::create_variant(i);

    complex_dict1.insert(std::pair<Glib::ustring, Glib::Variant<int>>("Map 1 " + s, v));

    complex_dict2.insert(std::pair<Glib::ustring, Glib::Variant<int>>("Map 2 " + s, v));
  }

  using ComplexVecType = std::vector<std::map<Glib::ustring, Glib::Variant<int>>>;

  ComplexVecType complex_vector = { complex_dict1, complex_dict2 };

  auto complex_variant = Glib::create_variant(complex_vector);

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
  result_ok &= test_comparison();
  result_ok &= test_integer_types();
  return result_ok ? EXIT_SUCCESS : EXIT_FAILURE;
}

// Test casting of multiple types to a ustring:
static void
test_dynamic_cast_ustring_types()
{
  Glib::VariantBase vbase_string = Glib::wrap(g_variant_new("s", "somestring"));

  try
  {
    auto derived_get = vbase_string.get_dynamic<Glib::ustring>();
    ostr << "Casted string Glib::Variant<Glib::ustring>: " << derived_get << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_objectpath = Glib::wrap(g_variant_new_object_path("/remote/object/path"));

  try
  {
    auto derived_get = vbase_objectpath.get_dynamic<Glib::ustring>();
    ostr << "Casted object path Glib::Variant<Glib::ustring>: " << derived_get << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_signature = Glib::wrap(g_variant_new_signature("aas"));

  try
  {
    auto derived_get = vbase_signature.get_dynamic<Glib::ustring>();
    ostr << "Casted signature Glib::Variant<Glib::ustring>: " << derived_get << std::endl;
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
    auto derived_get = vbase_string.get_dynamic<std::string>();
    ostr << "Casted string Glib::Variant<std::string>: " << derived_get << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_objectpath = Glib::wrap(g_variant_new_object_path("/remote/object/path"));

  try
  {
    auto derived_get = vbase_objectpath.get_dynamic<std::string>();
    ostr << "Casted object path Glib::Variant<std::string>: " << derived_get << std::endl;
  }
  catch (const std::bad_cast& e)
  {
    g_assert_not_reached();
  }

  Glib::VariantBase vbase_signature = Glib::wrap(g_variant_new_signature("aas"));

  try
  {
    auto derived_get = vbase_signature.get_dynamic<std::string>();
    ostr << "Casted signature Glib::Variant<std::string>: " << derived_get << std::endl;
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

  try
  {
    auto derived_get = cppdict.get_dynamic<std::map<Glib::ustring, std::string>>();
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }
}

static void
test_dynamic_cast()
{
  auto v1 = Glib::create_variant(10);
  Glib::VariantBase& v2 = v1;
  g_assert(v2.get_dynamic<int>() == 10);

  Glib::VariantBase v5 = v1;
  g_assert(v5.get_dynamic<int>() == 10);

  Glib::Variant<double> v4;
  // v4 does not contain a GVariant: The cast succeeds
  auto v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v4);
  // v4 does not contain a GVariant: The get_dynamic fails
  try
  {
    (void)v4.get_dynamic<int>();
    g_assert_not_reached();
  }
  catch (const std::invalid_argument& e)
  {
  }

  v4 = Glib::create_variant(1.0);
  try
  {
    v3 = Glib::VariantBase::cast_dynamic<Glib::Variant<int>>(v4);
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  try
  {
    (void)v4.get_dynamic<int>();
    g_assert_not_reached();
  }
  catch (const std::bad_cast& e)
  {
  }

  // A tuple
  std::vector<Glib::VariantBase> vec_var(2);
  vec_var[0] = Glib::create_variant(1);
  vec_var[1] = Glib::create_variant<Glib::ustring>("coucou");
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
  g_assert(get_map["test key"].get_dynamic<Glib::ustring>() == "test variant");

  // A variant of type v
  auto var_v = Glib::Variant<Glib::VariantBase>::create(var_string);
  g_assert(var_v.get_type_string() == "v");
  auto var_s2 = Glib::VariantBase::cast_dynamic<Glib::Variant<Glib::ustring>>(var_v.get());
  g_assert(var_s2.get() == "test variant");
  g_assert(var_v.get().get_dynamic<Glib::ustring>() == "test variant");

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
  explicit WarnCatcher(const std::string& domain)
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
