simple_examples = [
  'child_watch',
  'compose',
  'keyfile',
  'options',
  'regex']

foreach example : simple_examples
  executable(example + '-example', join_paths(example, 'main.cc'), dependencies : giomm_dep)
endforeach

subdir('dbus')
subdir('iochannel_stream')
subdir('markup')
subdir('network')
subdir('properties')
subdir('settings')
subdir('thread')
