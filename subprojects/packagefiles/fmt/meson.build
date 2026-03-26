project(
  'fmt',
  'cpp',
  version: '12.1.0',
  meson_version: '>=0.50.0',
  license: 'MIT WITH fmt-exception',
)

fmt_private_cpp_args = []
fmt_interface_cpp_args = []

if meson.get_compiler('cpp').get_id() == 'msvc'
  fmt_private_cpp_args += '/utf-8'
  fmt_interface_cpp_args += '/utf-8'
endif

fmt_lib = library(
  'fmt',
  'src/format.cc',
  'src/os.cc',
  include_directories: 'include',
  cpp_args: fmt_private_cpp_args,
  override_options: 'cpp_std=c++17',
  build_by_default: true,
  install: false,
)

fmt_dep = declare_dependency(
  include_directories: 'include',
  compile_args: fmt_interface_cpp_args,
  link_with: fmt_lib,
)
if meson.version().version_compare('>=0.54.0')
  meson.override_dependency('fmt', fmt_dep)
endif
