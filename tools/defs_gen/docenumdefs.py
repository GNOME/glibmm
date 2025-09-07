#!/usr/bin/env python3

# Extracts enum definitions from C header files.
# This file is approximately a subset of enumextract.py.

# docenumdefs.py header_files...
# or call parse_file() from docextract.py.

import sys
import re

__all__ = ['parse_file']

# Compiled regular expressions.
comment_begin = re.compile(r'^(.*)/\*')
comment_end = re.compile(r'\*/(.*)')
pp_directive = re.compile(r'^\s*#')
single_line_comment_c = re.compile(r'/\*.*?\*/')
single_line_comment_cpp = re.compile(r'//.*$')
enum_begin = re.compile(r'^\s*typedef\s+enum')
extract_enum_name = re.compile(r'^.*?(\w+)')
white_spaces = re.compile(r'\s+')
opening_bracket = re.compile(r'\s*{\s*')
dep_or_avail_enumerator = re.compile(r'^\s*(\w+)\s+\w+?_(:?DEPRECATED|AVAILABLE)_ENUMERATOR\w*(:?\s*\(.*?\))?')
parenthesis_value = re.compile(r"^\s*\S+\s*=\s*'[\(\)]'\s*$")
enum_element_name = re.compile(r'^(\w+)')

def parse_file(fp, enum_dict):
  '''parse enums in a C file'''

  # if we are inside enum.
  in_enum = False
  # if we are inside multiline comment.
  in_comment = False
  # line containing whole enum preprocessed definition to be processed.
  line = ''
  # if only right bracket was found, not name.
  rbracket_only = False

  for current_rawline in fp:
    current_line = current_rawline
    if in_comment:
      # end of multiline comment.
      is_comment_end = comment_end.search(current_line)
      if is_comment_end:
        in_comment = False
        if in_enum:
          line += is_comment_end.group(1)
      continue

    # discard any preprocessor directives inside enums.
    if pp_directive.search(current_line):
      continue

    # filter single-line comments.
    current_line = single_line_comment_c.sub('', current_line)
    current_line = single_line_comment_cpp.sub('', current_line, 1)

    # beginning of multiline comment.
    is_comment_begin = comment_begin.search(current_line)
    if is_comment_begin:
      in_comment = True
      if in_enum:
        line += is_comment_begin.group(1) + '\n'
      continue

    # Replace the enumerator values ',' and '}' by strings that won't confuse
    # process_enum_def().
    # typedef enum { V1 = ',', V2 = '}' } E1; // is a legal definition.
    current_line = current_line.replace("','", r'\%\%COMMA\%\%', 1)
    current_line = current_line.replace("'}'", r'\%\%RBRACE\%\%', 1)

    # we have found an enum.
    if enum_begin.search(current_line):
      in_enum = True
      continue

    # we have found the end of an enum.
    if (in_enum and ('}' in current_line)) or rbracket_only:
      # if the same line also contains ';' - that means there is a typedef name
      # between '}' and ';'.
      if ';' in current_line:
        enum_def = '} ' if rbracket_only else ''
        enum_def += current_line
        process_enum_def(line, enum_def, enum_dict)
        in_enum = False
        line = ''
        rbracket_only = False
      # we assume there is no such definition formed like this:
      # typedef enum
      # {
      # ...
      # } MyTypedef
      # ;
      # that would be stupid.
      else:
        rbracket_only = True
        # don't append useless lines to line.
        continue

    if in_enum:
      line += current_line

def process_enum_def(line, enum_def, enum_dict):
  '''find enum element names'''

  # The enum name is the first word after the closing bracket.
  # The name can be followed by *_DEPRECATED_TYPE* or *_AVAILABLE_TYPE*
  # before the semicolon.
  is_enum_name = extract_enum_name.search(enum_def)
  if is_enum_name:
    enum_def = is_enum_name.group(1)
  c_name = enum_def
  # replace all excessive whitespaces with one space.
  line = white_spaces.sub(' ', line)
  # get rid of any comments.
  line = single_line_comment_c.sub('', line)
  # get rid of opening bracket.
  line = opening_bracket.sub('', line, 1)

  lines = line.split(',')
  iter = 0
  while iter < len(lines):
    # The enumerator name can be followed by *_DEPRECATED_ENUMERATOR*,
    # *_DEPRECATED_ENUMERATOR*_FOR(*) or *_AVAILABLE_ENUMERATOR*
    # before the equal sign or comma.
    lines[iter] = dep_or_avail_enumerator.sub(r'\1', lines[iter], 1)

    brackets_count = 0
    begin = iter

    # ignore ',' inside () brackets
    # except '(' and ')' enum values
    if parenthesis_value.search(lines[iter]):
      iter += 1
    else:
      first = True
      while first or (iter < len(lines) and brackets_count != 0):
        first = False
        brackets_count += lines[iter].count('(')
        brackets_count -= lines[iter].count(')')
        iter += 1

    # join with comma and remove leading and trailing spaces.
    # also remove backslashes as some people like to add them before newlines...
    i = ','.join(lines[begin:iter]).strip().replace('\\', '')

    # The first (possibly only) word in i is the enum element name.
    m = enum_element_name.search(i)
    if m:
      element_name = m.group(1)
      enum_dict[element_name] = c_name

# ----- Main -----
if __name__ == '__main__':
  import argparse

  parser = argparse.ArgumentParser(
    description='Extract enum definitions from C/C++ header files.')
  parser.add_argument('header_files', nargs='+', help='header file(s) to parse')
  args = parser.parse_args()

  exitcode = 0
  enum_dict = {}
  for filepath in args.header_files:
    try:
      parse_file(open(filepath, 'r'), enum_dict)
    except FileNotFoundError as err:
      exitcode = 1
      print(err, file=sys.stderr)

  print(enum_dict)
  sys.exit(exitcode)
