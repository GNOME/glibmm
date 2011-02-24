#include <glibmm.h>
#include <iostream>

//Use this line if you want debug output:
//std::ostream& ostr = std::cout;

//This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

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

  return 0;
}
