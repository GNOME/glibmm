# MSVC_NMake/giomm

# Input: pkg_conf_data, giommconfig_h
# Output: giomm_rc

giomm_rc = configure_file(
  input: 'giomm.rc.in',
  output: '@BASENAME@',
  configuration: pkg_conf_data,
)

# Copy the generated configuration header into the MSVC project directory.
configure_file(
  input: giommconfig_h,
  output: 'giommconfig.h',
  copy: true,
)
