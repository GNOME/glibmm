#include <gio/gio.h> //For the C enum values.
#include <giomm.h>
#include <iostream>
#include <string.h>

// This tests that both Gio::Error and Gio::DBus::Error are registered in
// Gio::wrap_init(), and that they are properly registered.
// This was previously a problem, but is now fixed, and we want to make sure
// that we don't regress.

int
main(int, char**)
{
  Glib::init();
  Gio::init();

  // Check that Gio::Error is thrown:
  bool gio_error_thrown = false;
  try
  {
    GError* gerror =
      g_error_new_literal(G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT, "Arbitrary test error text.");
    ::Glib::Error::throw_exception(gerror);
  }
  catch (const Gio::Error& /* ex */)
  {
    gio_error_thrown = true;
  }
  catch (const Gio::DBus::Error& ex)
  {
    std::cerr << "Gio::DBus::Error caught when a Gio::Error was expected." << std::endl;
    return EXIT_FAILURE;
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Glib::Error caught when a Gio::Error was expected." << std::endl;
    return EXIT_FAILURE;
  }

  if (!gio_error_thrown)
  {
    std::cerr << "Gio::Error was not thrown, but should have been thrown." << std::endl;
    return EXIT_FAILURE;
  }

  // Check that Gio::DBus::Error is thrown:
  bool gio_dbus_error_thrown = false;
  try
  {
    GError* gerror =
      g_error_new_literal(G_DBUS_ERROR, G_DBUS_ERROR_FAILED, "Arbitrary test error text.");
    ::Glib::Error::throw_exception(gerror);
  }
  catch (const Gio::DBus::Error& /* ex */)
  {
    gio_dbus_error_thrown = true;
  }
  catch (const Gio::Error& ex)
  {
    std::cerr << "Gio::Error caught when a Gio::Dbus::Error was expected." << std::endl;
    return EXIT_FAILURE;
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Glib::Error caught when a Gio::DBus::Error was expected." << std::endl;
    return EXIT_FAILURE;
  }

  if (!gio_dbus_error_thrown)
  {
    std::cerr << "Gio::DBus::Error was not thrown, but should have been thrown." << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
