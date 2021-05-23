#include <glibmm.h>
#include <iostream>

int
main(int, char**)
{
  Glib::Environ env1;
  Glib::Environ env2(env1.to_vector());
  g_assert_true(env1.to_vector() == env2.to_vector());

  // Empty environment.
  const std::vector<std::string> empty_vector;
  Glib::Environ env3(empty_vector);
  g_assert_true(env3.to_vector().size() == 0);

  auto path = env1.get("PATH");
  if (!path)
  {
    // There ought to be a PATH. If there isn't, add one.
    std::cout << "No PATH!" << std::endl;
    env1.set("PATH", "/a/b/c");
  }

  path = env1["PATH"];
  if (!path)
  {
    // Now there really must be a PATH.
    std::cerr << "Still no PATH!" << std::endl;
    return EXIT_FAILURE;
  }

  const std::string name = "GLIBMM_TEST_VAR";
  const std::string value = "This is a test value";
  env1.set(name, value);
  g_assert_true(env1[name] == value);
  env1.set(name, "Second value", false);
  g_assert_true(env1.get(name) == value);
  env1.set(name, "Second value");
  g_assert_true(env1.get(name) == "Second value");
  env1.unset(name);
  if (env1.get(name))
  {
    std::cerr << name << " not removed" << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
