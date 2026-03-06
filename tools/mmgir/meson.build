cli11_dep = dependency('cli11', required : true)
fmt_dep = dependency('fmt', required : true)
tinyxml2_dep = dependency('tinyxml2', required : true)

mmgir_sources = files(
  'main.cc',
  'gen_defs.cc',
  'parse_gir.cc',
  'type_resolver.cc',
)

# Define the executable
mmgir = executable('mmgir',
  mmgir_sources,
  dependencies: [cli11_dep, fmt_dep, tinyxml2_dep],
  override_options: ['cpp_std=c++17'],
  install : false,
)
meson.override_find_program('mmgir', mmgir)
