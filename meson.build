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

python = find_program('python')
perl = find_program('perl')
m4 = find_program('m4')

wrap_output = join_paths(meson.source_root(), 'tools', 'wrap_output.py')

conf = configuration_data()

conf.set('GLIBMM_API', '')
conf.set('M4', 'm4')

configure_file(output : 'config.h',
               configuration : conf)

config_inc_dir = include_directories('.')

add_project_arguments(language: 'cpp')

subdir('tools')
subdir('glib')
subdir('gio')