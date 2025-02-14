# glib/glibmm

# Input: glibmm_build_dep, glibmm_pcname, maintainer_mode, project_source_root,
#        generate_binding_py, handle_built_files_py, m4_files, pm_files,
#        glibmm_libversion, install_includedir, python3, glibmm_rc, gmmproc_dir,
#        is_host_windows, gmmproc, generate_wrap_init_pl, glibmm_libname,
#        macos_darwin_versions, pkgconfig,
#        base_pkgconfig_vars, base_pkgconfig_uninstalled_vars
# Output: glibmm_hg_ccg_basenames, glibmm_extra_h_files, built_files_root,
#         glibmm_built_h_file_targets, glibmm_h_m4_files, glibmm_own_dep

glibmm_defs_basefiles = [
  'glib.defs',
  'glib_enums.defs',
  'glib_functions.defs',
  'glib_signals.defs',
  'glib_extra_objects.defs',
  'gmodule_enums.defs',
  'gmodule_functions.defs',
  'gobject_enums.defs',
  'gobject_functions.defs',
  'glib_docs.xml',
  'glib_docs_override.xml',
]

glibmm_defs_files = []
foreach file : glibmm_defs_basefiles
  glibmm_defs_files += '..' / 'src' / file
endforeach

# Generated from pairs of .hg and .ccg files.
glibmm_hg_ccg_basenames = [
  'binding',
  'bytes',
  'bytearray',
  'checksum',
  'convert',
  'date',
  'datetime',
  'enums',
  'fileutils',
  'iochannel',
  'keyfile',
  'markup',
  'miscutils',
  'module',
  'nodetree',
  'optioncontext',
  'optionentry',
  'optiongroup',
  'regex',
  'shell',
  'spawn',
  'timezone',
  'unicode',
  'uriutils',
  'variant',
  'variantdict',
  'variantiter',
  'varianttype',
]

# Generated from .m4 files.
glibmm_h_m4_files = [
  'value_basictypes.h',
  'variant_basictypes.h',
]

glibmm_cc_m4_files = [
  'value_basictypes.cc',
  'variant_basictypes.cc',
]

# Pairs of hand-coded .h and .cc files.
glibmm_extra_h_cc_basenames = [
  'base64',
  'class',
  'debug',
  'dispatcher',
  'environ',
  'error',
  'exceptionhandler',
  'extraclassinit',
  'init',
  'interface',
  'main',
  'object',
  'objectbase',
  'pattern',
  'property',
  'propertyproxy',
  'propertyproxy_base',
  'quark',
  'random',
  'signalproxy',
  'signalproxy_connectionnode',
  'stringutils',
  'timer',
  'ustring',
  'utility',
  'value',
  'value_custom',
  'variantdbusstring',
  'vectorutils',
  'wrap',
]

glibmm_extra_h_files = [
  'containerhandle_shared.h',
  'i18n-lib.h',
  'i18n.h',
  'priorities.h',
  'refptr.h',
  'ustring_hash.h',
  'version.h',
  'wrap_init.h',
]

glibmm_extra_ph_files = [
  'private' / 'interface_p.h',
  'private' / 'object_p.h',
]

glibmm_extra_cc_files = []

foreach file : glibmm_extra_h_cc_basenames
  glibmm_extra_h_files += file + '.h'
  glibmm_extra_cc_files += file + '.cc'
endforeach

install_headers('..' / 'glibmm.h', subdir: glibmm_pcname)
install_headers(glibmm_extra_h_files, subdir: glibmm_pcname / 'glibmm')
install_headers(glibmm_extra_ph_files, subdir: glibmm_pcname / 'glibmm' / 'private')

untracked_glibmm = 'untracked' / 'glib' / 'glibmm'
rel_untracked_glibmm = '..' / '..' / untracked_glibmm
src_untracked_glibmm = project_source_root / untracked_glibmm

extra_glibmm_objects = []
glibmm_cpp_args = [ '-DGLIBMM_BUILD=1' ]

# Build the .rc file for Windows builds and link to it
if is_host_windows
  windows = import('windows')
  glibmm_res = windows.compile_resources(glibmm_rc)
  extra_glibmm_objects += glibmm_res
endif

if maintainer_mode

  # Maintainer mode. Generate .h and .cc files from .hg and .ccg files in ../src.

  # docs/reference/meson.build needs these.
  built_files_root = project_build_root
  glibmm_built_h_file_targets = []

  # Force meson+ninja to generate source files before anything is compiled.
  # Compilation must depend on these targets.
  glibmm_built_cc_file_targets = []

  hg_files = []
  foreach file : glibmm_hg_ccg_basenames
    hg_files += '..' / 'src' / file + '.hg'
  endforeach

  # Create wrap_init.cc in project_build_root/glib/glibmm.
  glibmm_built_cc_file_targets += custom_target('glibmm-wrap_init.cc',
    input: hg_files,
    output: 'wrap_init.cc',
    command: [
      python3, generate_binding_py, 'generate_wrap_init',
      gmmproc_dir,
      '@OUTPUT@',
      'Glib', # namespace
      '@INPUT@',
    ],
    depend_files: generate_wrap_init_pl,
    build_by_default: maintainer_mode,
    install: false,
  )

  # Create .h/_p.h/.cc files in project_build_root/glib/glibmm
  # from .hg/.ccg files in project_source_root/glib/src.
  foreach file : glibmm_hg_ccg_basenames
    hg_file = '..' / 'src' / file + '.hg'
    ccg_file = '..' / 'src' / file + '.ccg'
    built_file_target = custom_target('glibmm-' + file + '.cc',
      input: [hg_file, ccg_file],
      output: [file + '.stamp', file + '.cc', file + '.h'],
      command: [
        python3, handle_built_files_py, 'gmmproc',
        gmmproc_dir,
        project_source_root / 'tools' / 'pm',
        '@OUTPUT0@',
        file,
        meson.current_source_dir() / '..' / 'src',
        project_source_root / 'tools' / 'm4',
      ],
      depend_files: glibmm_defs_files + m4_files + [gmmproc] + pm_files,
      build_by_default: maintainer_mode,
      install: false,
    )
    glibmm_built_cc_file_targets += built_file_target[1]
    glibmm_built_h_file_targets += built_file_target[2]
  endforeach

  # Create .h and .cc files in project_build_root/glib/glibmm
  # from .m4 files in project_source_root/glib/src.
  foreach output_file : glibmm_h_m4_files + glibmm_cc_m4_files
    input_file = '..' / 'src' / output_file + '.m4'
    built_file_target = custom_target('glibmm-' + output_file,
      input: input_file,
      output: output_file,
      command: [
        python3, handle_built_files_py, 'build_from_m4',
        meson.current_source_dir() / '..' / 'src',
        '@INPUT@',
        '@OUTPUT@',
      ],
      depend_files: '..' / 'src' / 'template.macros.m4',
      build_by_default: maintainer_mode,
      install: false,
    )
    if output_file.endswith('.cc')
      glibmm_built_cc_file_targets += built_file_target
    else
      glibmm_built_h_file_targets += built_file_target
    endif
  endforeach

  # Create dummy_header.h, depending on all generated headers.
  # It's created if it does not exist, but it's never updated.
  # It guarantees that all generated headers are built before glibmm_library
  # is built, at the same time avoiding unnecessary recompilations.
  # If glibmm_built_h_file_targets would be listed as sources to glibmm_library,
  # all generated .cc files could be recompiled if one generated .h file has
  # been changed.
  built_dummy_h_file_target = custom_target('glibmm-dummy_header.h',
    input: glibmm_built_h_file_targets,
    output: 'dummy_header.h',
    command: [
      python3, dummy_header_py,
      '@OUTPUT@',
    ],
    build_by_default: maintainer_mode,
    install: false,
  )

  extra_include_dirs = ['..']

  glibmm_library = library(glibmm_libname, extra_glibmm_objects,
    glibmm_built_cc_file_targets, glibmm_extra_cc_files, built_dummy_h_file_target,
    implicit_include_directories: false,
    include_directories: extra_include_dirs,
    cpp_args: glibmm_cpp_args,
    version: glibmm_libversion,
    darwin_versions: macos_darwin_versions,
    dependencies: glibmm_build_dep,
    install: true,
  )

  built_h_cc_dir = meson.current_build_dir()

else # not maintainer_mode

  # Not maintainer mode. Compile built source code files in
  # project_source_root/untracked/glib/glibmm.

  # docs/reference/meson.build needs these.
  built_files_root = project_source_root / 'untracked'
  glibmm_built_h_file_targets = []

  # Two cases:
  # 1. The source code comes from a tarball, where the built files
  #    are stored in project_source_root/untracked.
  #    There are no built files in the build tree.
  # 2. Files have been built in the build tree. Then maintainer_mode has
  #    been changed from true to false. Files that are missing or not up to date
  #    in project_source_root/untracked are copied from the build tree.

  # Try to copy built source code files to the source tree.
  run_command(
    python3, generate_binding_py, 'copy_built_files',
    meson.current_build_dir(),
    src_untracked_glibmm,
    glibmm_hg_ccg_basenames,
    check: true,
  )
  run_command(
    python3, handle_built_files_py, 'copy_built_files',
    meson.current_build_dir(),
    src_untracked_glibmm,
    glibmm_h_m4_files + glibmm_cc_m4_files,
    check: true,
  )

  built_cc_files = [ rel_untracked_glibmm / 'wrap_init.cc' ]
  foreach file : glibmm_hg_ccg_basenames
    built_cc_files += rel_untracked_glibmm / file + '.cc'
  endforeach
  foreach file : glibmm_cc_m4_files
    built_cc_files += rel_untracked_glibmm / file
  endforeach

  extra_include_dirs = [ '..', '..' / '..' / 'untracked' / 'glib' ]

  glibmm_library = library(glibmm_libname, extra_glibmm_objects,
    built_cc_files, glibmm_extra_cc_files,
    implicit_include_directories: false,
    include_directories: extra_include_dirs,
    cpp_args: glibmm_cpp_args,
    version: glibmm_libversion,
    darwin_versions: macos_darwin_versions,
    dependencies: glibmm_build_dep,
    install: true,
  )

  built_h_cc_dir = src_untracked_glibmm

endif

# Generate the pkg-config files
pkgconfig.generate(
  glibmm_library,
  name: 'glibmm',
  description: 'C++ wrapper for GLib',
  filebase: glibmm_pcname,
  requires: ['gobject-2.0', 'sigc++-3.0'],
  subdirs: glibmm_pcname,
  url: 'https://gtkmm.gnome.org/',
  extra_cflags: '-I${libdir}/@0@/include'.format(glibmm_pcname),
  variables: base_pkgconfig_vars + [
    'gmmprocdir=${libdir}/@0@/proc'.format(glibmm_pcname),
  ],
  uninstalled_variables: base_pkgconfig_uninstalled_vars + [
    'gmmprocdir=${prefix}/tools'
  ]
)

# Install built .h and _p.h files.
meson.add_install_script(
  python3, generate_binding_py, 'install_built_h_files',
  built_h_cc_dir,
  install_includedir / glibmm_pcname / 'glibmm', # subdir below {prefix}
  glibmm_hg_ccg_basenames,
  install_tag: 'devel',
)
# Install .h files built from .m4 files.
meson.add_install_script(
  python3, handle_built_files_py, 'install_built_h_files',
  built_h_cc_dir,
  install_includedir / glibmm_pcname / 'glibmm', # subdir below {prefix}
  glibmm_h_m4_files,
  install_tag: 'devel',
)

# Distribute built files.
meson.add_dist_script(
  python3, generate_binding_py, 'dist_built_files',
  built_h_cc_dir,
  untracked_glibmm,
  glibmm_hg_ccg_basenames,
)
meson.add_dist_script(
  python3, handle_built_files_py, 'dist_built_files',
  built_h_cc_dir,
  untracked_glibmm,
  glibmm_h_m4_files + glibmm_cc_m4_files,
)

# This is used when building example programs and test programs.
# It's also a part of glibmm_dep, when glibmm is a subproject.
glibmm_own_dep = declare_dependency(
  sources: glibmm_built_h_file_targets,
  link_with: glibmm_library,
  include_directories: extra_include_dirs,
  dependencies: glibmm_build_dep,
)
