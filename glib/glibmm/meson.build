glibmm_modules = [
  'balancedtree',
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
  'varianttype']

glibmm_handwritten_sources = [
  'base64.cc',
  'class.cc',
  'debug.cc',
  'dispatcher.cc',
  'error.cc',
  'exception.cc',
  'exceptionhandler.cc',
  'init.cc',
  'interface.cc',
  'main.cc',
  'object.cc',
  'objectbase.cc',
  'pattern.cc',
  'property.cc',
  'propertyproxy.cc',
  'propertyproxy_base.cc',
  'quark.cc',
  'random.cc',
  'signalproxy.cc',
  'signalproxy_connectionnode.cc',
  'stringutils.cc',
  'timer.cc',
  'timeval.cc',
  'ustring.cc',
  'utility.cc',
  'value.cc',
  'value_custom.cc',
  'vectorutils.cc',
  'wrap.cc']

glibmm_m4_files = [
  'value_basictypes.cc',
  'value_basictypes.h',
  'variant_basictypes.cc',
  'variant_basictypes.h']

glibmm_targets = []

#TODO ugly hack, has to be implemented in other way in the future
private_dir = join_paths(meson.build_root(), 'glib', 'glibmm', 'private')
glibmm_targets += custom_target('glibmm_generate_priv_dir',
  output : 'private',
  command : [python, '-c',
            'import os\nos.makedirs("' + private_dir + '", exist_ok=True)'])

glibmm_hg_files = []
foreach module : glibmm_modules
  glibmm_hg_files += [join_paths(meson.current_source_dir(), '..', 'src', module + '.hg')]
endforeach

glibmm_targets += custom_target('glibmm_generate_wrap_init',
  input : glibmm_hg_files,
  output : 'wrap_init.cc',
  command : [python,
             wrap_output,
	     perl,
	     join_paths(meson.current_build_dir(), 'wrap_init.cc'),
             '--',
             join_paths(meson.build_root(), 'tools', 'generate_wrap_init.pl'),
             '--namespace=Glib', '--parent_dir=glibmm'] + glibmm_hg_files)

foreach glibmm_module : glibmm_modules
  glibmm_targets += custom_target('glibmm_generate_cc_' + glibmm_module,
    output : [glibmm_module + '.cc', glibmm_module + '.h'],
    input : join_paths('..', 'src', glibmm_module + '.hg'),
    command : [perl,
               '-I../tools/pm', '--', join_paths(meson.build_root(), 'tools', 'gmmproc'),
               '-I', join_paths(meson.source_root(), 'tools', 'm4'),
               '--defs', join_paths(meson.current_source_dir(), '..', 'src'),
               glibmm_module,
               join_paths(meson.current_source_dir(), '..', 'src'),
               join_paths('glib', 'glibmm')])
endforeach

# TODO: foreach above could be replaced with the following code in the future:
# TODO: we should be able to move generated files to user-specified directory
#source_gen = generator(perl,
#                output  : ['@BASENAME@.cc', '@BASENAME@.h'],
#		input : '@BASENAME@.ccg',
#                arguments : ['-I../tools/pm', '--', 'gmmproc', '-I', '../tools/m4', '--defs', '../glib/src', '@INPUT@', '../glib/src', '@BUILD_DIR@'])
#gen_sources = source_gen.process(glibmm_files_any_hg)
#glibmm = shared_library('glibmm', gen_sources,
#	include_directories : glibmm_inc, dependencies : [glibdep, gmoduledep, sigcppdep])

foreach m4_file : glibmm_m4_files
  glibmm_targets += custom_target('generate_from_m4' + m4_file,
    output : m4_file,
    input : join_paths('..', 'src', m4_file + '.m4'),
    command : [python,
               wrap_output,
               m4,
               join_paths(meson.build_root(), '@OUTPUT@'),
               '@INPUT@',
               '-I' + join_paths(meson.source_root(), 'glib', 'src')])
endforeach


glibmm_includes = include_directories('..')

glibmm_deps = [glibdep, sigcppdep, gobjectdep, gmoduledep]

glibmm_library = shared_library(
  'glibmm',
  glibmm_targets, glibmm_handwritten_sources,
  include_directories : glibmm_includes,
  dependencies : glibmm_deps)

glibmm_dep = declare_dependency(
  link_with : glibmm_library,
  include_directories : include_directories('..'),
  dependencies : glibmm_deps)
