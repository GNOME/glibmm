# This file is part of glibmm.

project('glibmm', 'cpp',
  version: '2.62.0',
  license: 'LGPLv2.1+',
  default_options: [
    'cpp_std=c++11'
  ],
  meson_version: '>= 0.50.0', # required for python3.path()
)

glibmm_api_version = '2.4'
glibmm_pcname = meson.project_name() + '-' + glibmm_api_version
giomm_pcname = 'giomm-' + glibmm_api_version

glibmm_version_array = meson.project_version().split('.')
glibmm_major_version = glibmm_version_array[0].to_int()
glibmm_minor_version = glibmm_version_array[1].to_int()
glibmm_micro_version = glibmm_version_array[2].to_int()

# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
# The relation between libtool's current:revison:age interface versioning
# and the .so filename, .so.x.y.z, is
# x = current - age
# y = age
# z = revision
# If libtool_soversion is updated as described in libtool's documentation,
# x.y.z will usually *not* be equal to meson.project_version().
libtool_soversion = [4, 0, 3]
glibmm_libversion = '@0@.@1@.@2@'.format(
  libtool_soversion[0] - libtool_soversion[2],
  libtool_soversion[2],
  libtool_soversion[1])

# Use these instead of meson.source_root() and meson.build_root() in subdirectories.
# source_root() and build_root() are not useful, if this is a subproject.
project_source_root = meson.current_source_dir()
project_build_root = meson.current_build_dir()

cpp_compiler = meson.get_compiler('cpp')
is_msvc = cpp_compiler.get_id() == 'msvc'
is_host_windows = host_machine.system() == 'windows'

is_os_cocoa = false
if not is_host_windows
  # This test for Mac OS is copied from glib. If the result of glib's test
  # is ever made available outside glib, use glib's result instead of this test.
  # glib: https://bugzilla.gnome.org/show_bug.cgi?id=780309
  # glibmm: https://bugzilla.gnome.org/show_bug.cgi?id=781947
  is_os_cocoa = cpp_compiler.compiles(
    '''#include <Cocoa/Cocoa.h>
    #ifdef GNUSTEP_BASE_VERSION
    #error "Detected GNUstep, not Cocoa"
    #endif''',
    name: 'Mac OS X Cocoa support'
  )
endif

python3 = import('python').find_installation()
python_version = python3.language_version()
python_version_req = '>= 3.5'
if not python_version.version_compare(python_version_req)
  error('Requires Python @0@, found @1@.'.format(python_version_req, python_version))
endif

# Do we build from a git repository?
# Suppose we do if and only if a '.git' directory or file exists.
cmd_py = '''
import os
import sys
sys.exit(os.path.isdir("@0@") or os.path.isfile("@0@"))
'''.format(project_source_root / '.git')
is_git_build = run_command(python3, '-c', cmd_py).returncode() != 0

# Options.
maintainer_mode_opt = get_option('maintainer-mode')
maintainer_mode = maintainer_mode_opt == 'true' or \
                 (maintainer_mode_opt == 'if-git-build' and is_git_build)
warning_level = get_option('warnings')
build_deprecated_api = get_option('build-deprecated-api')
build_documentation_opt = get_option('build-documentation')
build_documentation = build_documentation_opt == 'true' or \
                     (build_documentation_opt == 'if-maintainer-mode' and maintainer_mode)
build_examples = get_option('build-examples')

# Installation directories are relative to {prefix}.
install_prefix = get_option('prefix')
install_includedir = get_option('includedir')
install_libdir = get_option('libdir')
install_datadir = get_option('datadir')
install_pkgconfigdir = install_libdir / 'pkgconfig'

# Dependencies. <pkg> = glib and gio
# <pkg>mm_build_dep: Dependencies when building the <pkg>mm library.
# <pkg>mm_dep (created in <pkg>/<pkg>mm/meson.build):
#   Dependencies when using the <pkg>mm library.

sigcxx_req = '>= 2.9.1'
glib_req = '>= 2.61.2'

# There are pkg-config files for sigc++ and glib on MSVC, so just use that.
sigcxx_dep = dependency('sigc++-2.0', version: sigcxx_req)
glib_dep = dependency('glib-2.0', version: glib_req)
gobject_dep = dependency('gobject-2.0', version: glib_req)
gmodule_dep = dependency('gmodule-2.0', version: glib_req)

glibmm_build_dep = [sigcxx_dep, glib_dep, gobject_dep, gmodule_dep]
glibmm_requires = [
  'sigc++-2.0', sigcxx_req,
  'glib-2.0', glib_req,
  'gobject-2.0', glib_req,
  'gmodule-2.0', glib_req,
]

gio_dep = dependency('gio-2.0', version: glib_req)
giomm_build_dep = glibmm_build_dep + [gio_dep]
giomm_requires = glibmm_requires + ['gio-2.0', glib_req]
if not is_host_windows
  gio_unix_dep = dependency('gio-unix-2.0', version: glib_req)
  giomm_build_dep += gio_unix_dep
  giomm_requires += ['gio-unix-2.0', glib_req]
endif

glibmm_requires = ' '.join(glibmm_requires)
giomm_requires = ' '.join(giomm_requires)

# Some dependencies are required only in maintainer mode and/or if
# reference documentation shall be built.
mm_common_get = find_program('mm-common-get', required: maintainer_mode)
m4 = find_program('m4', required: maintainer_mode) # Used by gmmproc
perl = find_program('perl', required: maintainer_mode or build_documentation)
doxygen = find_program('doxygen', required: build_documentation)
dot = find_program('dot', required: build_documentation) # Used by Doxygen
xsltproc = find_program('xsltproc', required: build_documentation)

# Where to find gmmproc and generate_wrap_init.pl.
gmmproc_dir = project_build_root / 'tools'

# Script files copied to 'untracked' by mm-common-get.
script_dir = project_source_root / 'untracked' / 'build_scripts'
generate_binding_py = script_dir / 'generate-binding.py'
doc_reference_py = script_dir / 'doc-reference.py'
dist_changelog_py = script_dir / 'dist-changelog.py'
dist_build_scripts_py = script_dir / 'dist-build-scripts.py'

if maintainer_mode and mm_common_get.found()
  # Copy files to untracked/build_scripts and untracked/docs.
  run_command(mm_common_get, '--force', script_dir,
    project_source_root / 'untracked' / 'docs')
endif

# glibmm's own script files.
glibmm_script_dir = project_source_root / 'tools' / 'build_scripts'
handle_built_files_py = glibmm_script_dir / 'handle-built-files.py'
dummy_header_py = glibmm_script_dir / 'dummy-header.py'
compile_schemas_py = glibmm_script_dir / 'compile-schemas.py'

# Set compiler warnings.
warning_flags = []
if warning_level == 'min'
  if is_msvc
    warning_flags = ['/W3']
  else
    warning_flags = ['-Wall']
  endif
elif warning_level == 'max' or warning_level == 'fatal'
  if is_msvc
    warning_flags = ['/W4']
  else
    warning_flags = '-pedantic -Wall -Wextra -Wformat-security -Wsuggest-override -Wshadow -Wno-long-long'.split()
  endif
  if warning_level == 'fatal'
    if is_msvc
      warning_flags += ['/WX']
    else
      warning_flags += ['-Werror']
    endif
    deprecations = 'G SIGCXX'.split()
    foreach d : deprecations
      warning_flags += '-D@0@_DISABLE_DEPRECATED'.format(d)
    endforeach
  endif
endif

warning_flags = cpp_compiler.get_supported_arguments(warning_flags)
add_project_arguments(warning_flags, language: 'cpp')

# MSVC: Ignore warnings that aren't really harmful, but make those
#       that should not be overlooked stand out.
if is_msvc
  disabled_warnings = cpp_compiler.get_supported_arguments([
    '/FImsvc_recommended_pragmas.h', '/wd4146', '/wd4267', '/wd4530', '/wd4589', '/utf-8'
  ])
  add_project_arguments(disabled_warnings, language: 'cpp')
endif

subdir('tools')
subdir('MSVC_NMake/gendef')
subdir('glib')
subdir('MSVC_NMake/glibmm')
subdir('glib/glibmm')
subdir('gio')
subdir('MSVC_NMake/giomm')
subdir('gio/giomm')
subdir('examples')
subdir('tests')
subdir('docs/reference')

if not meson.is_subproject()
  # Add a ChangeLog file to the distribution directory.
  # (add_dist_script() is not allowed in a subproject)
  meson.add_dist_script(
    python3.path(), dist_changelog_py,
    project_source_root,
  )
  # Add build scripts to the distribution directory, and delete .gitignore
  # files and an empty $MESON_DIST_ROOT/build/ directory.
  meson.add_dist_script(
    python3.path(), dist_build_scripts_py,
    project_source_root,
    'untracked' / 'build_scripts',
  )
endif

# Print a summary.
real_maintainer_mode = ''
if maintainer_mode_opt == 'if-git-build'
  real_maintainer_mode = ' (@0@)'.format(maintainer_mode)
endif

real_build_documentation = ''
if build_documentation_opt == 'if-maintainer-mode'
  real_build_documentation = ' (@0@)'.format(build_documentation)
endif

summary = [
  '',
  '------',
  meson.project_name() + ' ' + meson.project_version(),
  '',
  '         Maintainer mode: @0@@1@'.format(maintainer_mode_opt, real_maintainer_mode),
  '       Compiler warnings: @0@'.format(warning_level),
  '    Build deprecated API: @0@'.format(build_deprecated_api),
  'Build HTML documentation: @0@@1@'.format(build_documentation_opt, real_build_documentation),
  '  Build example programs: @0@'.format(build_examples),
  'Directories:',
  '                  prefix: @0@'.format(install_prefix),
  '              includedir: @0@'.format(install_prefix / install_includedir),
  '        includeglibmmdir: @0@'.format(install_prefix / install_includedir / glibmm_pcname),
  '         includegiommdir: @0@'.format(install_prefix / install_includedir / giomm_pcname),
  '                  libdir: @0@'.format(install_prefix / install_libdir),
  '         glibmmconfigdir: @0@'.format(install_prefix / install_glibmmconfigdir),
  '          giommconfigdir: @0@'.format(install_prefix / install_giommconfigdir),
  '                   m4dir: @0@'.format(install_prefix / install_m4dir),
  '            pkgconfigdir: @0@'.format(install_prefix / install_pkgconfigdir),
  '                 datadir: @0@'.format(install_prefix / install_datadir),
  '                  docdir: @0@'.format(install_prefix / install_docdir),
  '              devhelpdir: @0@'.format(install_prefix / install_devhelpdir),
  '------'
]

message('\n'.join(summary))
