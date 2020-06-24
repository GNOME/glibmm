# glib

# Input: install_prefix, install_libdir, install_datadir, install_includedir,
#        glibmm_pcname, giomm_pcname, glibmm_api_version, glibmm_requires,
#        giomm_requires, build_deprecated_api, install_pkgconfigdir,
#        is_os_cocoa, cpp_compiler, glibmm_major_version, glibmm_minor_version,
#        glibmm_micro_version, msvc14x_toolset_ver
# Output: pkg_conf_data, install_glibmmconfigdir, glibmmconfig_h

pkg_conf_data = configuration_data()
pkg_conf_data.set('prefix', install_prefix)
pkg_conf_data.set('exec_prefix', '${prefix}')
pkg_conf_data.set('libdir', '${exec_prefix}' / install_libdir)
pkg_conf_data.set('datarootdir', '${prefix}' / install_datadir)
pkg_conf_data.set('datadir', '${datarootdir}')
pkg_conf_data.set('includedir', '${prefix}' / install_includedir)
pkg_conf_data.set('PACKAGE_TARNAME', meson.project_name())
pkg_conf_data.set('PACKAGE_VERSION', meson.project_version())
pkg_conf_data.set('GLIBMM_MODULE_NAME', glibmm_pcname)
pkg_conf_data.set('GLIBMM_API_VERSION', glibmm_api_version)
pkg_conf_data.set('GLIBMM_MODULES', glibmm_requires)
pkg_conf_data.set('GIOMM_MODULE_NAME', giomm_pcname)
pkg_conf_data.set('GIOMM_API_VERSION', glibmm_api_version)
pkg_conf_data.set('GIOMM_MODULES', giomm_requires)
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
pkg_conf_data.set('MSVC_TOOLSET_VER', msvc14x_toolset_ver)

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

configure_file(
  input: 'glibmm.pc.in',
  output: glibmm_pcname + '.pc',
  configuration: pkg_conf_data,
  install_dir: install_pkgconfigdir,
)

glibmm_pkg_uninst_conf_data = configuration_data()
glibmm_pkg_uninst_conf_data.merge_from(pkg_conf_data)
glibmm_pkg_uninst_conf_data.set('srcdir', meson.current_source_dir())

configure_file(
  input: 'glibmm-uninstalled.pc.in',
  output: glibmm_pcname + '-uninstalled.pc',
  configuration: glibmm_pkg_uninst_conf_data,
)

glibmm_config_conf_data = configuration_data()
glibmm_config_conf_data.merge_from(pkg_conf_data)
if get_option('debug-refcounting')
  glibmm_config_conf_data.set('GLIBMM_DEBUG_REFCOUNTING', 1)
endif
if is_os_cocoa
  glibmm_config_conf_data.set('GLIBMM_OS_COCOA', 1)
endif
glibmm_config_conf_data.set('GLIBMM_SIZEOF_WCHAR_T', cpp_compiler.sizeof('wchar_t'))

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

install_glibmmconfigdir = install_libdir / glibmm_pcname / 'include'
glibmmconfig_h = configure_file(
  input: 'glibmmconfig.h.meson',
  output: 'glibmmconfig.h',
  configuration: glibmm_config_conf_data,
  install_dir: install_glibmmconfigdir,
)
