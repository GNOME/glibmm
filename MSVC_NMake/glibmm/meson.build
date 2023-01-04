# MSVC_NMake/glibmm

# Input: pkg_conf_data, glibmm_config_conf_data, glibmmconfig_h_meson
# Output: glibmm_rc

glibmm_rc = configure_file(
  input: 'glibmm.rc.in',
  output: '@BASENAME@',
  configuration: pkg_conf_data,
)

# Make a copy of the generated configuration header in the MSVC project directory.
configure_file(
  input: glibmmconfig_h_meson,
  output: 'glibmmconfig.h',
  configuration: glibmm_config_conf_data,
)
