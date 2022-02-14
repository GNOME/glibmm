# tools/extra_defs_gen

# Input: glibmm_build_dep, giomm_build_dep, glibmm_api_version,
#        glibmm_libversion, glibmm_pcname, msvc14x_toolset_ver,
#        macos_darwin_versions, handle_built_files_py, project_build_root
# Output: -

glibmm_generate_extra_defs_library = library(
  'glibmm_generate_extra_defs' + msvc14x_toolset_ver + '-' + glibmm_api_version,
  'generate_extra_defs.cc',
  version: glibmm_libversion,
  darwin_versions: macos_darwin_versions,
  implicit_include_directories: false,
  cpp_args: '-DGLIBMM_GEN_EXTRA_DEFS_BUILD',
  dependencies: glibmm_build_dep,
  install: true,
)

if meson.is_subproject()
  glibmm_generate_extra_defs_dep = declare_dependency(
    link_with: glibmm_generate_extra_defs_library,
  )

  # Copy the header file to a place where a main project can find it.
  run_command(
    python3, handle_built_files_py, 'copy_built_files',
    meson.current_source_dir(),
    project_build_root / 'glib' / 'glibmm_generate_extra_defs',
    'generate_extra_defs.h',
    check: true,
  )
endif

install_headers('generate_extra_defs.h', subdir: glibmm_pcname / 'glibmm_generate_extra_defs')

executable('generate_defs_glib', 'generate_defs_glib.cc',
  dependencies: glibmm_build_dep,
  link_with: glibmm_generate_extra_defs_library,
  implicit_include_directories: false,
  install: false,
)

executable('generate_defs_gio', 'generate_defs_gio.cc',
  dependencies: giomm_build_dep,
  link_with: glibmm_generate_extra_defs_library,
  implicit_include_directories: false,
  install: false,
)
