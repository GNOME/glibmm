# tools/extra_defs_gen

# Input: is_msvc, glibmm_build_dep, giomm_build_dep, glibmm_api_version,
#        glibmm_libversion
# Output: -

glibmm_generate_extra_defs_library_int = static_library(
  'glibmm_generate_extra_defs_int',
  'generate_extra_defs.cc',
  dependencies: glibmm_build_dep,
  install: false,
)

glibmm_generate_extra_defs = []
glibmm_generate_extra_defs_extra_link_args = []

if is_msvc
  glibmm_generate_extra_defs = custom_target(
    'glibmm_generate_extra_defs.def',
    output: 'glibmm_generate_extra_defs.def',
    depends: glibmm_generate_extra_defs_library_int,
    command: [ gendef,
      '@OUTPUT@',
      '@0@-@1@.dll'.format('glibmm_generate_extra_defs-' +
	                       glibmm_api_version, glibmm_libversion.split('.')[0]),
      glibmm_generate_extra_defs_library_int.full_path(),
    ],
    install: false,
  )
  glibmm_generate_extra_defs_extra_link_args = [
    '/def:@0@'.format(glibmm_generate_extra_defs.full_path())
  ]
endif

glibmm_generate_extra_defs_library = library(
  'glibmm_generate_extra_defs-' + glibmm_api_version,
  objects: glibmm_generate_extra_defs_library_int.extract_all_objects(),
  version: glibmm_libversion,
  link_depends: glibmm_generate_extra_defs,
  link_args: glibmm_generate_extra_defs_extra_link_args,
  dependencies: glibmm_build_dep,
  install: true,
)

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
