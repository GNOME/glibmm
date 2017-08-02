project('glibmm', 'cpp',
  license: 'LGPL',
  version: '2.53.2',
  meson_version: '>= 0.40.1',
  default_options: [
    'c_std=gnu14',
    'cpp_std=c++14',
    'warning_level=1',
  ],
)

glibdep = dependency('glib-2.0')
gmoduledep = dependency('gmodule-2.0')
gobjectdep = dependency('gobject-2.0')
sigcppdep = dependency('sigc++-3.0')

python = import('python3').find_python()
perl = find_program('perl')
m4 = find_program('m4')

wrap_output = join_paths(meson.source_root(), 'tools', 'wrap_output.py')

version_arr = meson.project_version().split('.')
glibmm_version_major = version_arr[0].to_int()
glibmm_version_minor = version_arr[1].to_int()
glibmm_version_micro = version_arr[2].to_int()

compiler = meson.get_compiler('cpp')

conf = configuration_data()

conf.set('GLIBMM_MAJOR_VERSION', glibmm_version_major)
conf.set('GLIBMM_MINOR_VERSION', glibmm_version_minor)
conf.set('GLIBMM_MICRO_VERSION', glibmm_version_micro)
conf.set('GIOMM_MAJOR_VERSION', glibmm_version_major)
conf.set('GIOMM_MINOR_VERSION', glibmm_version_minor)
conf.set('GIOMM_MICRO_VERSION', glibmm_version_micro)

conf.set('GLIBMM_DISABLE_DEPRECATED', get_option('disable-deprecated-api'))
conf.set('GIOMM_DISABLE_DEPRECATED', get_option('disable-deprecated-api'))

conf.set('SIZEOF_WCHAR_T', compiler.sizeof('wchar_t'))

member_function_member_template_src = '''struct foo
{
  template <class C> inline void doit();
  void thebug();
};

template <class C>
inline void foo::doit()
{}

struct bar
{
  void neitherabug();
};

void bar::neitherabug()
{
  void (foo::*func)();
  func = &foo::doit<int>;
  (void)func;
}

void foo::thebug()
{
  void (foo::*func)();
  func = &foo::doit<int>; // the compiler bugs usually show here
  (void)func;
}
int main() {
  void (foo::*func)();
  func = &foo::doit<int>;
  (void)func;
  return 0;
}
'''

if compiler.compiles(member_function_member_template_src)
  conf.set('GLIBMM_MEMBER_FUNCTIONS_MEMBER_TEMPLATES', 1)
endif

have_disambiguous_const_template_specializations_src = '''
template <class T> class Foo {};

template <class T> class Traits
{
public:
  const char* whoami() { return "generic template"; }
};

template <class T> class Traits< Foo<T> >
{
public:
  const char* whoami() { return "partial specialization for Foo<T>"; }
};

template <class T> class Traits< Foo<const T> >
{
public:
  const char* whoami() { return "partial specialization for Foo<const T>"; }
};

int main() {
  Traits<int> it;
  Traits< Foo<int> > fit;
  Traits< Foo<const int> > cfit;

  (void) it.whoami();
  (void) fit.whoami();
  (void) cfit.whoami();

  return 0;
}
'''
if compiler.compiles(have_disambiguous_const_template_specializations_src)
  conf.set('GLIBMM_HAVE_DISAMBIGUOUS_CONST_TEMPLATE_SPECIALIZATIONS', 1)
endif

can_use_dynamic_cast_in_unused_template_without_definition_src = '''
class SomeClass;

SomeClass* some_function();

template <class T>
class SomeTemplate
{
  static bool do_something()
  {
    // This does not compile with the MipsPro (IRIX) compiler
    // even if we don't use this template at all.
    return (dynamic_cast<T*>(some_function()) != 0);
  }
};
'''
if compiler.compiles(can_use_dynamic_cast_in_unused_template_without_definition_src)
  conf.set('GLIBMM_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION', 1)
endif

if compiler.has_type('std::wostringstream', prefix : '#include<sstream>')
  conf.set('GLIBMM_HAVE_WIDE_STREAM', 1)
endif

conf.set('GLIBMM_API', '')
conf.set('M4', 'm4')

configure_file(output : 'config.h',
               configuration : conf)

config_inc_dir = include_directories('.')

add_project_arguments(language: 'cpp')

subdir('tools')
subdir('glib')
subdir('gio')
subdir('examples')
subdir('tests')
