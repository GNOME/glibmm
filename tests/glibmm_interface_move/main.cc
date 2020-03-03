#include <glibmm.h>
#include <glibmm/private/interface_p.h>
#include <glibmm/private/object_p.h>
#include <iostream>
#include <stdlib.h>

// A basic derived GInterface, just to test Glib::Interface

G_DECLARE_INTERFACE(TestIface, test_Iface, TEST, IFACE, GObject)

struct _TestIface
{
  GTypeInterface g_iface;
};

static void test_Iface_init(gpointer)
{
}

GType
test_Iface_get_type(void)
{
  // Avoid compiler warnings about unused functions.
  // TODO: With C++17, use [[maybe unused]].
#ifndef _MSC_VER
  (void)TEST_IFACE;
  (void)TEST_IS_IFACE;
  (void)TEST_IFACE_GET_IFACE;
  (void)glib_autoptr_cleanup_TestIface;
#endif

  static GType type = 0;

  if (!type)
  {
    const GTypeInfo info = {
      sizeof(TestIface), // class_size
      test_Iface_init, // base_init
      nullptr, // base_finalize
      nullptr, // class_init
      nullptr, // class_finalize
      nullptr, // class_data
      0, // instance_size
      0, // n_preallocs
      nullptr, // instance_init
      nullptr // value_table
    };

    type = g_type_register_static(G_TYPE_INTERFACE, "TestIface", &info, GTypeFlags(0));
  }

  return type;
}

#define TEST_TYPE_IFACE (test_Iface_get_type())

// A basic derived GObject, just to test Glib::Object.
typedef struct
{
  GObject parent;
} TestDerived;

typedef struct
{
  GObjectClass parent;
} TestDerivedClass;

#define TEST_TYPE_DERIVED (test_derived_get_type())
#define TEST_DERIVED(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), TEST_TYPE_DERIVED, TestDerived))
#define TEST_DERIVED_CLASS(cls) \
  (G_TYPE_CHECK_CLASS_CAST((cls), TEST_TYPE_DERIVED, TestDerivedClass))
#define TEST_DERIVED_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS((obj), TEST_TYPE_DERIVED, TestDerivedClass))

static void
test_derived_class_init(TestDerivedClass*)
{
}
static void
test_derived_init(TestDerived*)
{
}

G_DEFINE_TYPE_EXTENDED(TestDerived, test_derived, G_TYPE_OBJECT, 0,
  G_IMPLEMENT_INTERFACE(TEST_TYPE_IFACE, test_Iface_init))

class TestInterface;

class TestInterface_Class : public Glib::Interface_Class
{
public:
  using BaseClassType = TestInterface;

  friend class TestInterface;

  const Glib::Interface_Class& init()
  {
    if (!gtype_) // create the GType if necessary
    {
      // Glib::Interface_Class has to know the interface init function
      // in order to add interfaces to implementing types.
      class_init_func_ = &TestInterface_Class::iface_init_function;

      // We can not derive from another interface, and it is not necessary anyway.
      gtype_ = test_Iface_get_type();
    }

    return *this;
  }

  static void iface_init_function(void* /* g_iface */, void* /* iface_data */) {}

  // static Glib::ObjectBase* wrap_new(GObject*);
};

class TestInterface : public Glib::Interface
{
protected:
  using CppClassType = TestInterface_Class;

  TestInterface() : Glib::Interface(derived_interface_class_.init()), i_(0) {}

public:
  // A real application would never make the constructor public.
  // It would instead have a protected constructor and a public create() method.
  TestInterface(GObject* gobject, int i) : Glib::Interface(gobject), i_(i) {}

  static void add_interface(GType gtype_implementer)
  {
    derived_interface_class_.init().add_interface(gtype_implementer);
  }

  TestInterface(const TestInterface& src) = delete;
  TestInterface& operator=(const TestInterface& src) = delete;

  TestInterface(TestInterface&& src) noexcept : Glib::Interface(std::move(src)),
                                                i_(std::move(src.i_))
  {
  }

  TestInterface& operator=(TestInterface&& src) noexcept
  {
    Glib::Interface::operator=(std::move(src));
    i_ = std::move(src.i_);

    return *this;
  }

  int i_;

private:
  friend class TestInterface_Class;
  static CppClassType derived_interface_class_;
};

class DerivedObject_Class : public Glib::Class
{
public:
  using BaseClassType = GObjectClass;
  using CppClassParent = Glib::Object_Class;

  static void class_init_function(void* g_class, void* class_data)
  {
    const auto klass = static_cast<BaseClassType*>(g_class);
    CppClassParent::class_init_function(klass, class_data);
  }

  const Glib::Class& init()
  {
    if (!gtype_) // create the GType if necessary
    {
      // Glib::Class has to know the class init function to clone custom types.
      class_init_func_ = &DerivedObject_Class::class_init_function;

      // This is actually just optimized away, apparently with no harm.
      // Make sure that the parent type has been created.
      // CppClassParent::CppObjectType::get_type();

      // Create the wrapper type, with the same class/instance size as the base type.
      register_derived_type(test_derived_get_type());

      // Add derived versions of interfaces, if the C type implements any interfaces:
      TestInterface::add_interface(get_type());
    }

    return *this;
  }
};

TestInterface::CppClassType TestInterface::derived_interface_class_; // initialize static member

class DerivedObject : public Glib::Object, public TestInterface
{
public:
  using CppClassType = DerivedObject_Class;

  // A real application would never make the constructor public.
  // It would instead have a protected constructor and a public create() method.
  explicit DerivedObject(int i)
  : Glib::ObjectBase(nullptr),
    Glib::Object(Glib::ConstructParams(derived_object_class_.init())),
    i_(i)
  {
  }

  DerivedObject(const DerivedObject& src) = delete;
  DerivedObject& operator=(const DerivedObject& src) = delete;

  DerivedObject(DerivedObject&& src) noexcept : Glib::Object(std::move(src)),
                                                TestInterface(std::move(src)),
                                                i_(std::move(src.i_))
  {
  }

  DerivedObject& operator=(DerivedObject&& src) noexcept
  {
    Glib::Object::operator=(std::move(src));
    TestInterface::operator=(std::move(src));
    i_ = std::move(src.i_);

    return *this;
  }

  int i_;

private:
  friend class DerivedObject_Class;
  static CppClassType derived_object_class_;
};

DerivedObject::CppClassType DerivedObject::derived_object_class_; // initialize static member

/* Shouldn't this work too?
 * No, because Glib::Interface::Interface(Interface&& src) does not call
 * Glib::ObjectBase::initialize_move(), and Glib::Interface::operator=(Interface&& src)
 * does not call Glib::ObjectBase::operator=(std::move(src)).
static
void test_interface_move_constructor()
{
  GObject *gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  g_object_ref(gobject);

  TestInterface derived(gobject, 5);
  std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);
  TestInterface derived2(std::move(derived));
  g_assert_cmpint(derived2.i_, ==, 5);
  std::cout << "debug: gobj(): " << derived2.gobj() << std::endl;
  g_assert(derived2.gobj() == gobject);
}

static
void test_interface_move_assignment_operator()
{
  GObject *gobject = G_OBJECT(g_object_new(TEST_TYPE_DERIVED, nullptr));
  g_object_ref(gobject);

  TestInterface derived(gobject, 5);
  //std::cout << "debug: gobj(): " << derived.gobj() << std::endl;
  g_assert(derived.gobj() == gobject);
  TestInterface derived2 = std::move(derived);
  g_assert_cmpint(derived2.i_, ==, 5);
  //std::cout << "debug: gobj(): " << derived2.gobj() << std::endl;
  g_assert(derived2.gobj() == gobject);
}
*/

static void
test_object_with_interface_move_constructor()
{
  DerivedObject derived(5);
  g_assert_cmpint(derived.i_, ==, 5);
  GObject* gobject = derived.gobj();
  g_assert(derived.gobj() == gobject);

  DerivedObject derived2(std::move(derived));
  g_assert_cmpint(derived2.i_, ==, 5);
  g_assert(derived2.gobj() == gobject);
  g_assert(derived.gobj() == nullptr);
}

static void
test_object_with_interface_move_assignment_operator()
{
  DerivedObject derived(5);
  g_assert_cmpint(derived.i_, ==, 5);
  GObject* gobject = derived.gobj();
  g_assert(derived.gobj() == gobject);

  DerivedObject derived2(6);
  derived2 = std::move(derived);
  g_assert_cmpint(derived2.i_, ==, 5);
  g_assert(derived2.gobj() == gobject);
  g_assert(derived.gobj() == nullptr);
}

int
main(int, char**)
{
  Glib::init();

  // test_interface_move_constructor();
  // test_interface_move_assignment_operator();

  test_object_with_interface_move_constructor();
  test_object_with_interface_move_assignment_operator();

  return EXIT_SUCCESS;
}
