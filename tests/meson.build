# tests

# input: glibmm_dep, giomm_dep

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
  [['glibmm_btree'], 'test', ['main.cc'], false],
  [['glibmm_buildfilename'], 'test', ['main.cc'], false],
  [['glibmm_bytearray'], 'test', ['main.cc'], false],
  [['glibmm_date'], 'test', ['main.cc'], false],
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
  [['glibmm_ustring_make_valid'], 'test', ['main.cc'], false],
  [['glibmm_ustring_sprintf'], 'test', ['main.cc'], false],
  [['glibmm_value'], 'test', ['main.cc'], false],
  [['glibmm_variant'], 'test', ['main.cc'], false],
  [['glibmm_vector'], 'test', ['main.cc'], true],
]

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

  exe_file = executable(ex_name, ex_sources,
    cpp_args: ['-DGLIBMM_DISABLE_DEPRECATED', '-DGIOMM_DISABLE_DEPRECATED'],
    dependencies: ex[3] ? giomm_dep : glibmm_dep,
    gui_app: false,
    build_by_default: true,
    install: false,
  )

  test(ex_name, exe_file)
endforeach
