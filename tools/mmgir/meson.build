catch2_dep = dependency('catch2-with-main',
  default_options : ['install=false', 'tests=false'],
  required : true,
)
cli11_dep = dependency('CLI11', required : true)
fmt_dep = dependency('fmt', required : true)
tinyxml2_dep = dependency('tinyxml2',
  default_options : ['tests=false'],
  required : true,
)

mmgir_sources = files(
  'gen_defs.cc',
  'parse_gir.cc',
  'type_resolver.cc',
)

# Define the executable
mmgir = executable('mmgir',
  'main.cc',
  mmgir_sources,
  dependencies: [catch2_dep, cli11_dep, fmt_dep, tinyxml2_dep],
  override_options: ['cpp_std=c++17'],
  install : false,
)
meson.override_find_program('mmgir', mmgir)

# Unit tests
mmgir_test_sources = files(
  'test_gen_defs.cc',
)

mmgir_test = executable('mmgir_test',
  mmgir_test_sources,
  mmgir_sources,
  dependencies : [catch2_dep, fmt_dep, tinyxml2_dep],
  override_options: ['cpp_std=c++17'],
  install : false,
)

test('mmgir_tests', mmgir_test)
