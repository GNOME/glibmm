# MSVC_NMake/glibmm

# Input: pkg_conf_data, glibmmconfig_h
# Output: glibmm_rc

glibmm_rc = configure_file(
  input: 'glibmm.rc.in',
  output: '@BASENAME@',
  configuration: pkg_conf_data,
)

# Copy the generated configuration header into the MSVC project directory.
configure_file(
  input: glibmmconfig_h,
  output: 'glibmmconfig.h',
  copy: true,
)
