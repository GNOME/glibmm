// Configuration-time test program, used in Meson build.
// Check whether a static member variable may be initialized inline to std::string::npos.
// The MipsPro (IRIX) compiler does not like this.
// Corresponds to the M4 macro GLIBMM_CXX_ALLOWS_STATIC_INLINE_NPOS.

#include <string>
#include <iostream>

class ustringtest
{
public:
  // The MipsPro compiler (IRIX) says "The indicated constant value is not known",
  // so we need to initialize the static member data elsewhere.
  static const std::string::size_type ustringnpos = std::string::npos;
};

int main()
{
  std::cout << "npos=" << ustringtest::ustringnpos << std::endl;
  return 0;
}
