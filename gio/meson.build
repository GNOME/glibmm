# gio

# Input: pkg_conf_data, giomm_pcname, install_pkgconfigdir,
# Output: install_giommconfigdir, giommconfig_h

configure_file(
  input: 'giomm.pc.in',
  output: giomm_pcname + '.pc',
  configuration: pkg_conf_data,
  install_dir: install_pkgconfigdir,
)

giomm_pkg_uninst_conf_data = configuration_data()
giomm_pkg_uninst_conf_data.merge_from(pkg_conf_data)
giomm_pkg_uninst_conf_data.set('srcdir', meson.current_source_dir())

configure_file(
  input: 'giomm-uninstalled.pc.in',
  output: giomm_pcname + '-uninstalled.pc',
  configuration: giomm_pkg_uninst_conf_data,
)

install_giommconfigdir = install_libdir / giomm_pcname / 'include'
giommconfig_h = configure_file(
  input: 'giommconfig.h.meson',
  output: 'giommconfig.h',
  configuration: pkg_conf_data,
  install_dir: install_giommconfigdir,
)
