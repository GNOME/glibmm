# MSVC_NMake/gendef

# Input: is_msvc
# Output: gendef

# Used to generate the .def file required to obtain the import .lib file
if is_msvc
  gendef = executable('gendef', 'gendef.cc', cpp_args: '/wd4828', install: false)
endif
