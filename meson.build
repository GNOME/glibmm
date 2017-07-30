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

conf = configuration_data()
conf.set_quoted('PACKAGE_NAME', 'glibmm')
conf.set('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('PACKAGE_DOCDIR', join_paths(get_option('prefix'), get_option('datadir'), 'doc/glibmm'))
conf.set_quoted('PACKAGE_LIBDIR', join_paths(get_option('prefix'), get_option('libdir')))
conf.set_quoted('PACKAGE_LOCALE_DIR', join_paths(get_option('prefix'), get_option('datadir'), 'locale'))
conf.set_quoted('PACKAGE_LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir')))
conf.set_quoted('PACKAGE_URL', 'https://bugzilla.gnome.org/enter_bug.cgi?product=glibmm')
conf.set('GETTEXT_PACKAGE', 'PACKAGE_NAME')
conf.set('LOCALEDIR', 'PACKAGE_LOCALE_DIR')

conf.set('GLIBMM_API', '')
conf.set('M4', 'm4')

configure_file(output : 'config.h',
               configuration : conf)

config_inc_dir = include_directories('.')

global_cxx_args = [
  '-Wno-unused-parameter'
]

add_project_arguments(global_cxx_args, language: 'cpp')

subdir('tools')
subdir('glib')
