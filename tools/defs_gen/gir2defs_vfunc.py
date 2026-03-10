#!/usr/bin/env python3

# Extracts vfunc definitions from GIR files and writes a .defs file
# that gmmproc can read.

# gir2defs_vfunc.py  gir_files...
# Writes to stdout, error messages to stderr.

# The GIR format is described in gobject-introspection/docs/gir-1.2.rnc

# From the documentation of xml.etree.ElementTree.Element:
# Caution: Elements with no subelements will test as False. In a future release
# of Python, all elements will test as True regardless of whether subelements
# exist. Instead, prefer explicit len(elem) or elem is not None tests.:

import os
import sys
import xml.etree.ElementTree as xmltree

# Globals
exitcode = 0
CORE_NS = "http://www.gtk.org/introspection/core/1.0"
C_NS = "http://www.gtk.org/introspection/c/1.0"
GLIB_NS = "http://www.gtk.org/introspection/glib/1.0"

def add_corens(tag):
  # Return {CORE_NS}tag
  return '{{{}}}{}'.format(CORE_NS, tag)

def add_cns(tag):
  # Return {C_NS}tag
  return '{{{}}}{}'.format(C_NS, tag)

def add_glibns(tag):
  # Return {GLIB_NS}tag
  return '{{{}}}{}'.format(GLIB_NS, tag)


def parse_file(filepath):
  '''parse vfuncs in a GIR file'''

  tree = xmltree.parse(filepath)
  root = tree.getroot()

  if root.tag != add_corens('repository'):
    exitcode = 1
    print(filepath, 'Not a GIR file. Root element is', root.tag, file=sys.stderr)
    return

  for ns in root.findall(add_corens('namespace')):
    ns_name = ns.get('name')
    print(';; From file', os.path.basename(filepath), end='')
    if ns_name:
      print(', namespace', ns_name, end='\n\n')
    else:
      print(', anonymous namespace', end='\n\n')
    parse_namespace(ns)

def parse_namespace(namespace):
  for interface in namespace.findall(add_corens('interface')):
    parse_interface(interface)
  for klass in namespace.findall(add_corens('class')):
    parse_class(klass)

def parse_interface(interface):
  interface_name = interface.attrib[add_glibns('type-name')]
  print(';; From interface', interface_name, end='\n\n')
  for vfunc in interface.findall(add_corens('virtual-method')):
    parse_vfunc(vfunc, interface_name)

def parse_class(klass):
  class_name = klass.attrib[add_glibns('type-name')]
  print(';; From class', class_name, end='\n\n')
  for vfunc in klass.findall(add_corens('virtual-method')):
    parse_vfunc(vfunc, class_name)

def parse_vfunc(vfunc, object_name):
  print('(define-vfunc ', vfunc.attrib['name'], sep='')
  print('  (of-object "', object_name, '")', sep='')

  # Find return value.
  return_type = 'void'
  return_value = vfunc.find(add_corens('return-value'))
  if return_value is not None:
    return_type2 = return_value.find(add_corens('type'))
    if return_type2 is None:
      return_type2 = return_value.find(add_corens('array'))
    if return_type2 is not None:
      return_ctype = return_type2.get(add_cns('type'))
      if return_ctype:
        return_type = return_ctype.replace(' ', '-')
  print('  (return-type "', return_type, '")', sep='')

  # Check if this vfunc can throw an exception.
  # This is not shown as a separate parameter in the gir file,
  # but it is in the defs file.
  throws = vfunc.get('throws', '0') != '0'  

  # Find parameters, if any.
  parameters = vfunc.find(add_corens('parameters'))
  parameter_list = []
  if parameters is not None:
    parameter_list = parameters.findall(add_corens('parameter'))
  if parameter_list or throws:
    print('  (parameters')
    for parameter in parameter_list:
      par_name = parameter.get('name')
      par_type = None
      par_type2 = parameter.find(add_corens('type'))
      if par_type2 is None:
        par_type2 = parameter.find(add_corens('array'))
      if par_type2 is not None:
        par_type = par_type2.get(add_cns('type'))
      if par_name and par_type:
        print('   \'("', par_type.replace(' ', '-'), '" "', par_name, '")', sep='')
      else:
        print('Parameter type and/or name missing for', object_name,
          vfunc.attrib['name'], file=sys.stderr)
    if throws:
      print('   \'("GError**" "error")')
    print('  )')
  print(')\n')

# ----- Main -----
if __name__ == '__main__':
  for filepath in sys.argv[1:]:
    try:
      parse_file(filepath)
    except FileNotFoundError as err:
      exitcode = 1
      print(err, file=sys.stderr)
    except xmltree.ParseError as err:
      exitcode = 1
      print(err, file=sys.stderr)
      print(filepath, 'line', err.position[0], 'column', err.position[1], file=sys.stderr)

  sys.exit(exitcode)
