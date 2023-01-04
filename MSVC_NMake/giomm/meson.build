# MSVC_NMake/giomm

# Input: pkg_conf_data, giommconfig_h_meson
# Output: giomm_rc

giomm_rc = configure_file(
  input: 'giomm.rc.in',
  output: '@BASENAME@',
  configuration: pkg_conf_data,
)

# Make a copy of the generated configuration header in the MSVC project directory.
configure_file(
  input: giommconfig_h_meson,
  output: 'giommconfig.h',
  configuration: pkg_conf_data,
)
