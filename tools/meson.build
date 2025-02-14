# tools

# Input: perl, m4, install_prefix, install_libdir, glibmm_pcname
# Output: install_procdir, m4_basefiles, m4_files, pm_basefiles, pm_files,
#         gmmproc_conf_data, gmmproc, generate_wrap_init_pl

subdir('extra_defs_gen')

install_procdir = install_libdir / glibmm_pcname / 'proc'

# Configuration data for gmmproc.
gmmproc_conf_data = configuration_data()
gmmproc_conf_data.set('PERL', perl.found() ? perl.full_path() : '')
gmmproc_conf_data.set('configure_input', 'tools/gmmproc.  Generated from gmmproc.in')
gmmproc_conf_data.set('prefix', install_prefix)
gmmproc_conf_data.set('exec_prefix', '${prefix}')
gmmproc_conf_data.set('libdir', '${exec_prefix}' / install_libdir)
gmmproc_conf_data.set('GLIBMM_MODULE_NAME', glibmm_pcname)
gmmproc_conf_data.set('M4', m4.found() ? '/'.join(m4.full_path().split('\\')) : '')
gmmproc_conf_data.set('PACKAGE_VERSION', meson.project_version())

gmmproc = configure_file(
  input: 'gmmproc.in',
  output: '@BASENAME@',
  configuration: gmmproc_conf_data,
  install: true,
  install_dir: install_procdir,
  install_tag: 'bin-devel',
)

# Configuration data for generate_wrap_init.pl.
gen_wrap_init_conf_data = configuration_data()
gen_wrap_init_conf_data.set('PERL', perl.found() ? perl.full_path() : '')
gen_wrap_init_conf_data.set('configure_input',
  'tools/generate_wrap_init.pl.  Generated from generate_wrap_init.pl.in')

generate_wrap_init_pl = configure_file(
  input: 'generate_wrap_init.pl.in',
  output: '@BASENAME@',
  configuration: gen_wrap_init_conf_data,
  install: true,
  install_dir: install_procdir,
  install_tag: 'bin-devel',
)

# Install m4 files for reuse by other *mm projects, when building from git.
m4_basefiles = [
  'base.m4',
  'class_boxedtype.m4',
  'class_boxedtype_static.m4',
  'class_generic.m4',
  'class_gobject.m4',
  'class_interface.m4',
  'class_opaque_copyable.m4',
  'class_opaque_refcounted.m4',
  'class_shared.m4',
  'compare.m4',
  'convert.m4',
  'convert_base.m4',
  'convert_gio.m4',
  'convert_glib.m4',
  'convert_glibmm.m4',
  'ctor.m4',
  'doc.m4',
  'enum.m4',
  'gerror.m4',
  'initialize.m4',
  'initialize_base.m4',
  'initialize_gio.m4',
  'initialize_glib.m4',
  'initialize_glibmm.m4',
  'member.m4',
  'method.m4',
  'property.m4',
  'signal.m4',
  'vfunc.m4',
]
m4_files = []
foreach file : m4_basefiles
  m4_files += 'm4' / file
endforeach
m4_files = files(m4_files)
install_data(m4_files,
  install_dir: install_procdir / 'm4',
  install_tag: 'bin-devel',
)

# Install pm files for reuse by other *mm projects, when building from git.
pm_basefiles = [
  'DocsParser.pm',
  'Enum.pm',
  'Function.pm',
  'FunctionBase.pm',
  'GtkDefs.pm',
  'Object.pm',
  'Output.pm',
  'Property.pm',
  'Util.pm',
  'WrapParser.pm',
]
pm_files = []
foreach file : pm_basefiles
  pm_files += 'pm' / file
endforeach
pm_files = files(pm_files)
install_data(pm_files,
  install_dir: install_procdir / 'pm',
  install_tag: 'bin-devel',
)
