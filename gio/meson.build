# gio

# Input: pkg_conf_data, giomm_pcname, install_libdir
# Output: install_giommconfigdir, giommconfig_h_meson

giommconfig_h_meson = files('giommconfig.h.meson')
install_giommconfigdir = install_libdir / giomm_pcname / 'include'
configure_file(
  input: giommconfig_h_meson,
  output: 'giommconfig.h',
  configuration: pkg_conf_data,
  install: true,
  install_dir: install_giommconfigdir,
  install_tag: 'devel',
)
