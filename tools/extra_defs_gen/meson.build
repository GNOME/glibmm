# tools/extra_defs_gen

# Input: is_msvc, glibmm_build_dep, giomm_build_dep, glibmm_api_version,
#        glibmm_libversion
# Output: -

glibmm_generate_extra_defs_library = library(
  'glibmm_generate_extra_defs-' + glibmm_api_version,
  'generate_extra_defs.cc',
  version: glibmm_libversion,
  dependencies: glibmm_build_dep,
  install: true,
)

if not is_msvc
  executable('generate_defs_glib', 'generate_defs_glib.cc',
    dependencies: glibmm_build_dep,
    link_with: glibmm_generate_extra_defs_library,
    install: false,
  )

  executable('generate_defs_gio', 'generate_defs_gio.cc',
    dependencies: giomm_build_dep,
    link_with: glibmm_generate_extra_defs_library,
    install: false,
  )
endif
