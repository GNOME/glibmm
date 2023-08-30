#include <glibmm.h>
#include <glibmm/ustring_hash.h>
#include <iostream>
#include <iomanip>
#include <unordered_map>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

int main(int, char**)
{
  Glib::init();

  std::unordered_map<Glib::ustring, unsigned int> colors =
  {
    {"red", 0xff0000},
    {"green", 0x00ff00},
    {"blue", 0x0000ff}
  };

  // Iterate and print key-value pairs using C++17 structured binding.
  for (const auto& [key, value] : colors)
    ostr << "colors[" << key << "] = 0x" << std::hex << std::setfill('0')
         << std::setw(6) << value << "\n";

  // Use operator[] with non-existent key to insert a new key-value pair.
  ostr << "colors[blank] = " << colors["blank"] << "\n";

  // Identical strings shall have identical hash values, even if the hash values
  // are computed by different instances of std::hash<Glib::ustring>.
  Glib::ustring string1 = "A string";
  Glib::ustring string2 = "A string";
  const auto hash1 = std::hash<Glib::ustring>{}(string1);
  const std::hash<Glib::ustring> ustring_hash;
  const auto hash2 = ustring_hash(string2);
  ostr << "hash(string1) = " << hash1 << "\n";
  ostr << "hash(string2) = " << hash2 << "\n";

  return (hash1 == hash2) ? EXIT_SUCCESS : EXIT_FAILURE;
}
