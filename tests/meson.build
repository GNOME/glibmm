glibmm_tests = [
  'glibmm_mainloop',
  'glibmm_nodetree',
  'glibmm_null_vectorutils',
  'glibmm_object',
  'glibmm_objectbase',
  'glibmm_objectbase_move',
  'glibmm_object_move',
  'glibmm_refptr',
  'glibmm_base64',
  'glibmm_refptr_sigc_bind',
  'glibmm_bool_vector',
  'glibmm_ustring_compose',
  'glibmm_btree',
  'glibmm_ustring_format',
  'glibmm_buildfilename',
  'glibmm_ustring_make_valid',
  'glibmm_bytearray',
  'glibmm_value',
  'glibmm_date',
  'glibmm_variant',
  'glibmm_interface_implementation',
  'glibmm_vector',
  'glibmm_interface_move']

giomm_tests = [
  'giomm_asyncresult_sourceobject',
  'giomm_ioerror',
  'giomm_ioerror_and_iodbuserror',
  'giomm_listmodel',
  'giomm_memoryinputstream',
  'giomm_simple',
  'giomm_stream_vfuncs',
  'giomm_tls_client']

all_tests = glibmm_tests + giomm_tests
foreach test_name : all_tests
  test_exec = executable('test-' + test_name, join_paths(test_name, 'main.cc'), dependencies : giomm_dep)
  test(test_name, test_exec)
endforeach