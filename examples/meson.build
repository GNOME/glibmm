# examples

# input: glibmm_own_dep, giomm_own_dep, build_examples, compile_schemas_py,
#        sigcxx_dep, is_host_windows

examples = [
# [[dir-name], exe-name, [sources], giomm-example (not just glibmm-example)]
  [['compose'], 'example', ['main.cc'], false],
  [['dbus'], 'session_bus_service', ['session_bus_service.cc'], true],
  [['dbus'], 'server_without_bus', ['server_without_bus.cc'], true],
  [['dbus'], 'client_bus_listnames', ['client_bus_listnames.cc'], true],
  [['keyfile'], 'example', ['main.cc'], false],
  [['markup'], 'parser', ['parser.cc'], false],
  [['network'], 'socket-client', ['socket-client.cc'], true],
  [['network'], 'socket-server', ['socket-server.cc'], true],
  [['options'], 'example', ['main.cc'], false],
  [['properties'], 'example', ['properties_example.cc'], false],
  [['regex'], 'example', ['main.cc'], false],
  [['settings'], 'settings', ['settings.cc', 'org.gtkmm.demo.gschema.xml'], true],
  [['thread'], 'dispatcher', ['dispatcher.cc'], false],
  [['thread'], 'dispatcher2', ['dispatcher2.cc'], false],
  [['thread'], 'thread', ['thread.cc'], false],
  [['thread'], 'threadpool', ['threadpool.cc'], false],
]

# Can't compile resolver.cc if sigc++-2.0 is a subproject and meson.version() < 0.58.0.
# See https://github.com/mesonbuild/meson/issues/8562
if sigcxx_dep.type_name() != 'internal' or meson.version().version_compare('>= 0.58.0')
  examples += [
    [['network'], 'resolver', ['resolver.cc'], true],
  ]
endif

if not is_host_windows
  examples += [
    [['child_watch'], 'child_watch', ['main.cc'], false],
    [['iochannel_stream'], 'example', ['fdstream.cc', 'main.cc'], false],
  ]
endif

thread_dep = dependency('threads')

# import('gnome').compile_schemas() can't be use here.
# It can only compile schemas in the current directory.
glib_compile_schemas = find_program('glib-compile-schemas', required: false)

foreach ex : examples
  dir = ''
  foreach dir_part : ex[0]
    dir = dir / dir_part
  endforeach
  ex_name = (dir / ex[1]).underscorify()
  ex_sources = []
  foreach src : ex[2]
    if src.endswith('.gschema.xml')
      if glib_compile_schemas.found()
        custom_target(dir.underscorify() + '_schemas',
          input: dir / src,
          output: dir.underscorify() + '_gschemas.compiled',
          command: [
            python3, compile_schemas_py,
            meson.current_source_dir() / dir,
            meson.current_build_dir() / dir,
            '@OUTPUT@'
          ],
          build_by_default: build_examples,
          install: false,
        )
      endif
    else
      ex_sources += dir / src
    endif
  endforeach

  is_multithread = ex[0][0] == 'network' or ex[0][0] == 'thread'
  mm_dep = ex[3] ? giomm_own_dep : glibmm_own_dep

  executable(ex_name, ex_sources,
    cpp_args: ['-DGLIBMM_DISABLE_DEPRECATED', '-DGIOMM_DISABLE_DEPRECATED'],
    dependencies: is_multithread ? [mm_dep, thread_dep] : mm_dep,
    implicit_include_directories: false,
    gui_app: false,
    build_by_default: build_examples,
    install: false,
  )
endforeach
