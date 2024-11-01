# tests

# input: glibmm_own_dep, giomm_own_dep

test_programs = [
# [[dir-name], exe-name, [sources], giomm-example (not just glibmm-example)]
  [['giomm_asyncresult_sourceobject'], 'test', ['main.cc'], true],
  [['giomm_ioerror'], 'test', ['main.cc'], true],
  [['giomm_ioerror_and_iodbuserror'], 'test', ['main.cc'], true],
  [['giomm_listmodel'], 'test', ['main.cc'], true],
  [['giomm_memoryinputstream'], 'test', ['main.cc'], true],
  [['giomm_simple'], 'test', ['main.cc'], true],
  [['giomm_stream_vfuncs'], 'test', ['main.cc'], true],
  [['giomm_tls_client'], 'test', ['main.cc'], true],
  [['glibmm_base64'], 'test', ['main.cc'], false],
  [['glibmm_binding'], 'test', ['main.cc'], false],
  [['glibmm_bool_vector'], 'test', ['main.cc'], false],
  [['glibmm_buildfilename'], 'test', ['main.cc'], false],
  [['glibmm_bytearray'], 'test', ['main.cc'], false],
  [['glibmm_date'], 'test', ['main.cc'], false],
  [['glibmm_environ'], 'test', ['main.cc'], false],
  [['glibmm_interface_implementation'], 'test', ['main.cc'], true],
  [['glibmm_interface_move'], 'test', ['main.cc'], false],
  [['glibmm_mainloop'], 'test', ['main.cc'], false],
  [['glibmm_nodetree'], 'test', ['main.cc'], false],
  [['glibmm_null_vectorutils'], 'test', ['main.cc'], true],
  [['glibmm_object'], 'test', ['main.cc'], false],
  [['glibmm_object_move'], 'test', ['main.cc'], false],
  [['glibmm_objectbase'], 'test', ['main.cc'], false],
  [['glibmm_objectbase_move'], 'test', ['main.cc'], false],
  [['glibmm_refptr'], 'test', ['main.cc'], false],
  [['glibmm_refptr_sigc_bind'], 'test', ['main.cc'], false],
  [['glibmm_regex'], 'test', ['main.cc'], false],
  [['glibmm_ustring_compare'], 'test', ['main.cc'], false],
  [['glibmm_ustring_compose'], 'test', ['main.cc'], false],
  [['glibmm_ustring_format'], 'test', ['main.cc'], false],
  [['glibmm_ustring_hash'], 'test', ['main.cc'], false],
  [['glibmm_ustring_make_valid'], 'test', ['main.cc'], false],
  [['glibmm_ustring_sprintf'], 'test', ['main.cc'], false],
  [['glibmm_value'], 'test', ['main.cc'], false],
  [['glibmm_variant'], 'test', ['main.cc'], false],
  [['glibmm_vector'], 'test', ['main.cc'], true],
]

thread_dep = dependency('threads')
meson_backend = find_program(meson.backend(), required: true)

foreach ex : test_programs
  dir = ''
  foreach dir_part : ex[0]
    dir = dir / dir_part
  endforeach
  ex_name = (dir / ex[1]).underscorify()
  ex_sources = []
  foreach src : ex[2]
    ex_sources += dir / src
  endforeach

  is_multithread = ex[0][0] == 'glibmm_mainloop'
  mm_dep = ex[3] ? giomm_own_dep : glibmm_own_dep

  exe_file = executable(ex_name, ex_sources,
    cpp_args: ['-DGLIBMM_DISABLE_DEPRECATED', '-DGIOMM_DISABLE_DEPRECATED'],
    dependencies: is_multithread ? [mm_dep, thread_dep] : mm_dep,
    implicit_include_directories: false,
    build_by_default: true,
    install: false,
  )

  test(ex_name, exe_file)

# It's now possible to compare Glib::ustring with std::string.
# It's no longer tested that such comparisons are impossible.
# See https://gitlab.gnome.org/GNOME/glibmm/-/issues/121

  if ex[0][0] == 'glibmm_value'

    # Tests that shall fail to compile.
    foreach suffix : ['1', '2']
      ex_name_s = ex_name + suffix
      exe_file = executable(ex_name_s, ex_sources,
        cpp_args: ['-DGLIBMM_DISABLE_DEPRECATED', '-DGIOMM_DISABLE_DEPRECATED',
                   '-DGLIBMM_TEST_THAT_COMPILATION_FAILS=' + suffix],
        dependencies: mm_dep,
        implicit_include_directories: false,
        build_by_default: false,
        install: false,
      )

      target_name = 'tests' / ex_name_s
      test(ex_name_s, meson_backend,
        args: target_name,
        should_fail: true,
      )
    endforeach
  endif
endforeach
