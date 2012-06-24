#include <glibmm/init.h>

#include "init.h"
#include "wrap_init.h"

namespace Gm
{

void
init ()
{
  static bool s_init = false;

  if (!s_init)
  {
    Glib::init ();
    Gm::wrap_init ();
    s_init = true;
  }
}

} // namespace Gm
