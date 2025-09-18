# gio/giomm

# Input: giomm_build_dep, giomm_pcname, maintainer_mode, project_source_root,
#        generate_binding_py, handle_built_files_py, m4_files, pm_files,
#        glibmm_libversion, install_includedir, python3, giomm_rc, gmmproc_dir,
#        is_host_windows, gmmproc, generate_wrap_init_pl, giomm_libname,
#        macos_darwin_versions, glibmm_api_version, pkgconfig
# Output: giomm_hg_ccg_basenames, giomm_extra_h_files, built_files_root,
#         giomm_built_h_file_targets, giomm_own_dep

giomm_defs_basefiles = [
  'gio.defs',
  'gio_enums.defs',
  'gio_methods.defs',
  'gio_signals.defs',
  'gio_extra_objects.defs',
  'gio_vfuncs.defs',
  'gio_docs.xml',
  'gio_docs_override.xml',
]

giomm_defs_files = []
foreach file : giomm_defs_basefiles
  giomm_defs_files += '..' / 'src' / file
endforeach

# Generated from pairs of .hg and .ccg files.
giomm_any_hg_ccg_basenames = [
  'action',
  'actiongroup',
  'actionmap',
  'appinfo',
  'appinfomonitor',
  'applaunchcontext',
  'application',
  'applicationcommandline',
  'asyncinitable',
  'asyncresult',
  'bufferedinputstream',
  'bufferedoutputstream',
  'bytesicon',
  'cancellable',
  'charsetconverter',
  'converter',
  'converterinputstream',
  'converteroutputstream',
  'credentials',
  'datainputstream',
  'dataoutputstream',
  'dbusactiongroup',
  'dbusaddress',
  'dbusauthobserver',
  'dbusconnection',
  'dbuserror',
  'dbuserrorutils',
  'dbusinterface',
  'dbusinterfaceskeleton',
  'dbusinterfacevtable',
  'dbusintrospection',
  'dbusmenumodel',
  'dbusmessage',
  'dbusmethodinvocation',
  'dbusobject',
  'dbusobjectmanager',
  'dbusobjectmanagerclient',
  'dbusobjectmanagerserver',
  'dbusobjectproxy',
  'dbusobjectskeleton',
  'dbusownname',
  'dbusproxy',
  'dbusserver',
  'dbussubtreevtable',
  'dbusutils',
  'dbuswatchname',
  'drive',
  'emblem',
  'emblemedicon',
  'enums',
  'error',
  'file',
  'fileattributeinfo',
  'fileattributeinfolist',
  'fileenumerator',
  'fileicon',
  'fileinfo',
  'fileinputstream',
  'fileiostream',
  'filemonitor',
  'filenamecompleter',
  'fileoutputstream',
  'filterinputstream',
  'filteroutputstream',
  'icon',
  'inetaddress',
  'inetsocketaddress',
  'initable',
  'inputstream',
  'iostream',
  'listmodel',
  'liststore',
  'loadableicon',
  'memoryinputstream',
  'memoryoutputstream',
  'menuattributeiter',
  'menulinkiter',
  'menu',
  'menuitem',
  'menumodel',
  'mount',
  'mountoperation',
  'networkaddress',
  'networkmonitor',
  'networkservice',
  'notification',
  'outputstream',
  'permission',
  'pollableinputstream',
  'pollableoutputstream',
  'propertyaction',
  'proxy',
  'proxyaddress',
  'proxyresolver',
  'remoteactiongroup',
  'resolver',
  'resource',
  'seekable',
  'settings',
  'settingsschema',
  'settingsschemakey',
  'settingsschemasource',
  'simpleaction',
  'simpleactiongroup',
  'simpleiostream',
  'simplepermission',
  'socket',
  'socketaddress',
  'socketaddressenumerator',
  'socketclient',
  'socketconnectable',
  'socketconnection',
  'socketcontrolmessage',
  'socketlistener',
  'socketservice',
  'srvtarget',
  'subprocess',
  'subprocesslauncher',
  'tcpconnection',
  'tcpwrapperconnection',
  'threadedsocketservice',
  'themedicon',
  'tlscertificate',
  'tlsclientconnection',
  'tlsconnection',
  'tlsdatabase',
  'tlsinteraction',
  'tlspassword',
  'tlsserverconnection',
  'volume',
  'volumemonitor',
  'zlibdecompressor',
  'zlibcompressor',
]

giomm_posix_hg_ccg_basenames = [
  'filedescriptorbased',
  'unixconnection',
  'unixcredentialsmessage',
  'unixfdlist',
  'unixfdmessage',
  'unixinputstream',
  'unixoutputstream',
  'unixsocketaddress',
]

giomm_not_mac_hg_ccg_basenames = [
  'desktopappinfo',
]

# All .hg/.ccg files, regardless of type of host.
giomm_hg_ccg_basenames = \
  giomm_any_hg_ccg_basenames + \
  giomm_posix_hg_ccg_basenames + \
  giomm_not_mac_hg_ccg_basenames

# Used .hg/.ccg files in present type of host.
giomm_used_hg_ccg_basenames = giomm_any_hg_ccg_basenames
if not is_host_windows
  giomm_used_hg_ccg_basenames += giomm_posix_hg_ccg_basenames
  if not is_os_cocoa
    giomm_used_hg_ccg_basenames += giomm_not_mac_hg_ccg_basenames
  endif
endif

# Pairs of hand-coded .h and .cc files.
giomm_extra_h_cc_basenames = [
  'contenttype',
  'init',
  'slot_async',
  'socketsource',
  'tlsclientconnectionimpl',
  'tlsserverconnectionimpl',
]

giomm_extra_h_files = [
  'wrap_init.h',
]

giomm_extra_cc_files = []

foreach file : giomm_extra_h_cc_basenames
  giomm_extra_h_files += file + '.h'
  giomm_extra_cc_files += file + '.cc'
endforeach

install_headers('..' / 'giomm.h', subdir: giomm_pcname)
install_headers(giomm_extra_h_files, subdir: giomm_pcname / 'giomm')

untracked_giomm = 'untracked' / 'gio' / 'giomm'
rel_untracked_giomm = '..' / '..' / untracked_giomm
src_untracked_giomm = project_source_root / untracked_giomm

extra_giomm_objects = []
giomm_cpp_flags = [ '-DGIOMM_BUILD=1' ]

# Build the .rc file for Windows builds and link to it
if is_host_windows
  windows = import('windows')
  giomm_res = windows.compile_resources(giomm_rc)
  extra_giomm_objects += giomm_res
endif

if maintainer_mode

  # Maintainer mode. Generate .h and .cc files from .hg and .ccg files in ../src.

  # docs/reference/meson.build needs these.
  built_files_root = project_build_root
  giomm_built_h_file_targets = []

  # Force meson+ninja to generate source files before anything is compiled.
  # Compilation must depend on these targets.
  giomm_used_built_cc_file_targets = []
  giomm_used_built_h_file_targets = []

  hg_files = []
  foreach file : giomm_hg_ccg_basenames
    hg_files += '..' / 'src' / file + '.hg'
  endforeach

  # Create wrap_init.cc in project_build_root/gio/giomm.
  giomm_used_built_cc_file_targets += custom_target('giomm-wrap_init.cc',
    input: hg_files,
    output: 'wrap_init.cc',
    command: [
      python3, generate_binding_py, 'generate_wrap_init',
      gmmproc_dir,
      '@OUTPUT@',
      'Gio', # namespace
      '@INPUT@',
    ],
    depend_files: generate_wrap_init_pl,
    build_by_default: maintainer_mode,
    install: false,
  )

  # Create .h/_p.h/.cc files in project_build_root/gio/giomm
  # from .hg/.ccg files in project_source_root/gio/src.
  foreach file : giomm_hg_ccg_basenames
    hg_file = '..' / 'src' / file + '.hg'
    ccg_file = '..' / 'src' / file + '.ccg'
    built_file_target = custom_target('giomm-' + file + '.cc',
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
      depend_files: giomm_defs_files + m4_files + [gmmproc] + pm_files,
      build_by_default: maintainer_mode,
      install: false,
    )
    giomm_built_h_file_targets += built_file_target[2]
    if giomm_used_hg_ccg_basenames.contains(file)
      giomm_used_built_cc_file_targets += built_file_target[1]
      giomm_used_built_h_file_targets += built_file_target[2]
    endif
  endforeach

  # Create dummy_header.h, depending on all generated headers.
  # It's created if it does not exist, but it's never updated.
  # It guarantees that all generated headers are built before giomm_library
  # is built, at the same time avoiding unnecessary recompilations.
  # If giomm_used_built_h_file_targets would be listed as sources to giomm_library,
  # all generated .cc files could be recompiled if one generated .h file has
  # been changed.
  built_dummy_h_file_target = custom_target('giomm-dummy_header.h',
    input: giomm_built_h_file_targets,
    output: 'dummy_header.h',
    command: [
      python3, dummy_header_py,
      '@OUTPUT@',
    ],
    build_by_default: maintainer_mode,
    install: false,
  )

  extra_include_dirs = ['..', '..' / '..' / 'glib']

  giomm_library = library(giomm_libname, extra_giomm_objects,
    giomm_used_built_cc_file_targets, giomm_extra_cc_files, built_dummy_h_file_target,
    version: glibmm_libversion,
    darwin_versions: macos_darwin_versions,
    implicit_include_directories: false,
    include_directories: extra_include_dirs,
    cpp_args: giomm_cpp_flags,
    dependencies: giomm_build_dep,
    link_with: glibmm_library,
    install: true,
  )

  built_h_cc_dir = meson.current_build_dir()

else # not maintainer_mode

  # Not maintainer mode. Compile built source code files in
  # project_source_root/untracked/gio/giomm.

  giomm_used_built_h_file_targets = []

  # docs/reference/meson.build needs these.
  built_files_root = project_source_root / 'untracked'
  giomm_built_h_file_targets = []

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
    src_untracked_giomm,
    giomm_hg_ccg_basenames,
    check: true,
  )

  built_cc_files = [ rel_untracked_giomm / 'wrap_init.cc' ]
  foreach file : giomm_used_hg_ccg_basenames
    built_cc_files += rel_untracked_giomm / file + '.cc'
  endforeach

  extra_include_dirs = [ '..', '..' / '..' / 'untracked' / 'gio',
         '..' / '..' / 'glib', '..' / '..' / 'untracked' / 'glib',
  ]

  giomm_library = library(giomm_libname, extra_giomm_objects,
    built_cc_files, giomm_extra_cc_files,
    version: glibmm_libversion,
    darwin_versions: macos_darwin_versions,
    implicit_include_directories: false,
    include_directories: extra_include_dirs,
    cpp_args: giomm_cpp_flags,
    dependencies: giomm_build_dep,
    link_with: glibmm_library,
    install: true,
  )

  built_h_cc_dir = src_untracked_giomm

endif

pkgconfig.generate(
  giomm_library,
  name: 'giomm',
  url: 'https://gtkmm.gnome.org/',
  description: 'C++ wrapper for gio',
  filebase: giomm_pcname,
  requires: ['gio-2.0', glibmm_pcname],
  subdirs: giomm_pcname,
  extra_cflags: '-I${libdir}/@0@/include'.format(giomm_pcname),
  variables: base_pkgconfig_vars,
  uninstalled_variables: base_pkgconfig_uninstalled_vars,
)

# Install built .h and _p.h files.
meson.add_install_script(
  python3, generate_binding_py, 'install_built_h_files',
  built_h_cc_dir,
  install_includedir / giomm_pcname / 'giomm', # subdir below {prefix}
  giomm_used_hg_ccg_basenames,
  install_tag: 'devel',
)

# Distribute built files.
meson.add_dist_script(
  python3, generate_binding_py, 'dist_built_files',
  built_h_cc_dir,
  untracked_giomm,
  giomm_hg_ccg_basenames,
)

# This is used when building example programs and test programs.
# It's also a part of giomm_dep, when glibmm is a subproject.
giomm_own_dep = declare_dependency(
  sources: glibmm_built_h_file_targets + giomm_used_built_h_file_targets,
  link_with: [glibmm_library, giomm_library],
  include_directories: extra_include_dirs,
  dependencies: giomm_build_dep,
)
