# glib

# Input: install_libdir, glibmm_pcname, giomm_pcname, build_deprecated_api,
#        is_os_cocoa, cpp_compiler, glibmm_major_version, glibmm_minor_version,
#        glibmm_micro_version
# Output: pkg_conf_data, glibmm_config_conf_data, install_glibmmconfigdir,
#         glibmmconfig_h_meson

pkg_conf_data = configuration_data()
pkg_conf_data.set('PACKAGE_VERSION', meson.project_version())
pkg_conf_data.set('GLIBMM_MODULE_NAME', glibmm_pcname)
pkg_conf_data.set('GIOMM_MODULE_NAME', giomm_pcname)
if not build_deprecated_api
  pkg_conf_data.set('GLIBMM_DISABLE_DEPRECATED', 1)
  pkg_conf_data.set('GIOMM_DISABLE_DEPRECATED', 1)
endif
pkg_conf_data.set('GLIBMM_MAJOR_VERSION', glibmm_major_version)
pkg_conf_data.set('GLIBMM_MINOR_VERSION', glibmm_minor_version)
pkg_conf_data.set('GLIBMM_MICRO_VERSION', glibmm_micro_version)
pkg_conf_data.set('GIOMM_MAJOR_VERSION', glibmm_major_version)
pkg_conf_data.set('GIOMM_MINOR_VERSION', glibmm_minor_version)
pkg_conf_data.set('GIOMM_MICRO_VERSION', glibmm_micro_version)

library_build_type = get_option('default_library')

if cpp_compiler.get_argument_syntax() == 'msvc'
  if library_build_type == 'static' or library_build_type == 'both'
    error('Static builds are not supported by MSVC-style builds')
  endif
endif

if library_build_type == 'static'
  pkg_conf_data.set('GLIBMM_STATIC_LIB', 1)
  pkg_conf_data.set('GIOMM_STATIC_LIB', 1)
endif

glibmm_config_conf_data = configuration_data()
glibmm_config_conf_data.merge_from(pkg_conf_data)
if get_option('debug-refcounting')
  glibmm_config_conf_data.set('GLIBMM_DEBUG_REFCOUNTING', 1)
endif
if is_os_cocoa
  glibmm_config_conf_data.set('GLIBMM_OS_COCOA', 1)
endif
glibmm_config_conf_data.set('GLIBMM_SIZEOF_WCHAR_T', cpp_compiler.sizeof('wchar_t'))
glibmm_config_conf_data.set('GLIBMM_SIZEOF_SHORT', cpp_compiler.sizeof('short'))
glibmm_config_conf_data.set('GLIBMM_SIZEOF_INT', cpp_compiler.sizeof('int'))
glibmm_config_conf_data.set('GLIBMM_SIZEOF_LONG', cpp_compiler.sizeof('long'))
glibmm_config_conf_data.set('GLIBMM_SIZEOF_LONG_LONG', cpp_compiler.sizeof('long long'))

conf_tests = [
# [preprocessor-macro-name, file-name, message]
  ['GLIBMM_HAVE_WIDE_STREAM', 'have_wide_stream.cc', 'Wide stream support'],
  ['GLIBMM_HAVE_STD_ITERATOR_TRAITS', 'have_std_iterator_traits.cc',
     'std::iterator_traits<> is standard-conforming'],
  ['GLIBMM_HAVE_SUN_REVERSE_ITERATOR', 'have_sun_reverse_iterator.cc',
    'std::reverse_iterator is in Sun libCstd style'],
  ['GLIBMM_HAVE_TEMPLATE_SEQUENCE_CTORS', 'have_template_sequence_ctors.cc',
    'STL containers have templated sequence ctors'],
  ['GLIBMM_HAVE_DISAMBIGUOUS_CONST_TEMPLATE_SPECIALIZATIONS', 
    'have_disambiguous_const_template_specializations.cc',
    'Disambiguates template specializations for const and non-const types'],
  ['GLIBMM_CAN_USE_DYNAMIC_CAST_IN_UNUSED_TEMPLATE_WITHOUT_DEFINITION',
    'can_use_dynamic_cast_in_unused_template_wo_def.cc',
    'Non-instantiated templates may dynamic_cast<> to an undefined type'],
  ['GLIBMM_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS',
    'can_assign_non_extern_c_functions_to_extern_c_cb.cc',
    'extern "C" and extern "C++" function pointers are compatible'],
  ['GLIBMM_HAVE_ALLOWS_STATIC_INLINE_NPOS', 'allows_static_inline_npos.cc',
    'A static member variable may be initialized inline to std::string::npos'],
]

foreach conf_test : conf_tests
  if cpp_compiler.compiles(
      files('..' / 'tools' / 'conf_tests' / conf_test[1]),
      name: conf_test[2])
    glibmm_config_conf_data.set(conf_test[0], 1)
  endif
endforeach

glibmmconfig_h_meson = files('glibmmconfig.h.meson')
install_glibmmconfigdir = install_libdir / glibmm_pcname / 'include'
configure_file(
  input: glibmmconfig_h_meson,
  output: 'glibmmconfig.h',
  configuration: glibmm_config_conf_data,
  install: true,
  install_dir: install_glibmmconfigdir,
  install_tag: 'devel',
)
