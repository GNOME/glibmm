#!/usr/bin/env python3

# Extracts enum definitions from C header files and writes a .defs file
# that gmmproc can read.

# enumextract.py  [--module modname] [--omit-deprecated] header_files...

import os
import sys
import re

# Globals

# dictionary with enum names and values.
tokens = {}

# A long warning is printed at most once.
has_warned_unknown_token = False

# Part of a regular expression.
optional_cast = r'(?:\([a-z ]+\)\s*)?'

# Compiled regular expressions.
comment_begin = re.compile(r'^(.*)/\*')
comment_end = re.compile(r'\*/(.*)')
deprecate_if_begin = re.compile(r'^\s*#\s*(:?if\s*!\s*defined|ifndef)\s*\(?\s*[A-Z_]+_DISABLE_DEPRECATED\s*\)?')
if_begin = re.compile(r'^\s*#\s*if')
if_end = re.compile(r'^\s*#\s*endif')
pp_directive = re.compile(r'^\s*#')
single_line_comment_c = re.compile(r'/\*.*?\*/')
single_line_comment_cpp = re.compile(r'//.*$')
enum_begin = re.compile(r'^\s*typedef\s+enum')
deprecated_type = re.compile(r'[A-Z]+_DEPRECATED_TYPE')
extract_enum_name = re.compile(r'^.*?(\w+)')
white_spaces = re.compile(r'\s+')
opening_bracket = re.compile(r'\s*{\s*')
extract_module_name = re.compile(r'^([A-Z][a-z]*)')
deprecated_enumerator = re.compile(r'[A-Z]+_DEPRECATED_ENUMERATOR')
dep_or_avail_enumerator = re.compile(r'^\s*(\w+)\s+\w+?_(:?DEPRECATED|AVAILABLE)_ENUMERATOR\w*(:?\s*\(.*?\))?')
parenthesis_value = re.compile(r"^\s*\S+\s*=\s*'[\(\)]'\s*$")
only_name = re.compile(r'^\w+$')
name_and_value1 = re.compile(r'^(\w+)\s*=?\s*(0x[0-9a-fA-F]+[\s0-9a-fx<-]*)$')
name_and_value2 = re.compile(r'^(\w+)\s*=?\s*(-?\s*[0-9]+)$')
name_and_value3 = re.compile(r'^(\w+)\s*=?\s*(' + optional_cast + r'\(?1[uU]?\s*<<\s*[0-9]+\s*\)?[\s0-9a-fx<-]*)$')
cast_or_unsigned1 = re.compile(optional_cast + r'(\(?1)[uU]')
cast_or_unsigned2 = re.compile(optional_cast + r'\(?1[uU]?\s*<<')
name_with_other_name = re.compile(r'^(\w+)\s*=?\s*(-?[ _x0-9a-fA-Z|()<~+,]+)$')
other_name = re.compile(r'([A-Z][_A-Z0-9]+)')
name_with_char = re.compile(r"^(\w+)\s*=\s*'(.)'$")
comma_or_rbrace = re.compile(r'^(\w+)\s*=\s*(\%\%[A-Z]+\%\%)$')

def parse(filepath, module, omit):
  '''parse enums in a C file'''

  with open(filepath, mode='r') as file:
    # if we are inside enum.
    in_enum = False
    # 1 or more, if we are inside deprecated lines.
    in_deprecated = 0
    # if we are inside multiline comment.
    in_comment = False
    # line containing whole enum preprocessed definition to be processed.
    line = ''
    # line containing whole enum raw definition.
    raw_line = ''
    # if we already printed comment about basename of header file containing enums.
    printed_from = False
    # if only right bracket was found, not name.
    rbracket_only = False

    for current_rawline in file:
      current_line = current_rawline
      if in_enum:
        raw_line += ';; ' + current_rawline
      if in_comment:
        # end of multiline comment.
        is_comment_end = comment_end.search(current_line)
        if is_comment_end:
          in_comment = False
          if in_enum:
            line += is_comment_end.group(1)
        continue

      # omit deprecated stuff.
      if omit and deprecate_if_begin.search(current_line):
        in_deprecated += 1
        continue
      if in_deprecated:
        if if_begin.search(current_line):
          in_deprecated += 1
        elif if_end.search(current_line):
          in_deprecated -= 1
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
      # process(). They are reset to the original strings when they are written
      # to the output file.
      # typedef enum { V1 = ',', V2 = '}' } E1; // is a legal definition.
      current_line = current_line.replace("','", r'\%\%COMMA\%\%', 1)
      current_line = current_line.replace("'}'", r'\%\%RBRACE\%\%', 1)

      # we have found an enum.
      if enum_begin.search(current_line):
        basename = os.path.basename(filepath)
        if not printed_from:
          print(';; From', basename, end='\n\n')
          printed_from = True
        in_enum = True
        raw_line += ';; ' + current_rawline
        continue

      # we have found the end of an enum.
      if (in_enum and ('}' in current_line)) or rbracket_only:
        # if the same line also contains ';' - that means there is a typedef name
        # between '}' and ';'.
        if ';' in current_line:
          if not (omit and deprecated_type.search(current_line)):
            enum_def = '} ' if rbracket_only else ''
            enum_def += current_line
            print(';; Original typedef:')
            print(raw_line)
            process(line, enum_def, module, omit)
          in_enum = False
          line = ''
          raw_line = ''
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
          # don't append useless lines to $line.
          continue

      if in_enum:
        line += current_line

def process(line, enum_def, module, omit):
  '''convert enums to lisp'''

  global tokens, has_warned_unknown_token
  # The name is the first word after the closing bracket.
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
  # lets employ some heuristics. :)
  perhaps_enum = 0
  perhaps_flags = 0
  # c_name = module + enum_def.
  if not module:
    is_module_name = extract_module_name.search(c_name)
    if is_module_name:
      module = is_module_name.group(1)
    else:
      module = ''
  enum_def = enum_def.replace(module, '')
  # names and their values.
  c_names = []
  values = []
  # val - default value for enum, gets incremented after every value processed.
  val = 0
  # these are just for case when enum value is equal to some sort of unknown
  # value - preprocessor define or other enum.
  unknown_flag = False
  unknown_val = ''
  unknown_base = ''
  unknown_increment = 0

  lines = line.split(',')
  iter = 0
  while iter < len(lines):
    # The enumerator name can be followed by *_DEPRECATED_ENUMERATOR*,
    # *_DEPRECATED_ENUMERATOR*_FOR(*) or *_AVAILABLE_ENUMERATOR*
    # before the equal sign or comma.
    omit_enumerator = omit and deprecated_enumerator.search(lines[iter])
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

    if omit_enumerator:
      continue

    # join with comma and remove leading and trailing spaces.
    # also remove backslashes as some people like to add them before newlines...
    i = ','.join(lines[begin:iter]).strip().replace('\\', '')

    # if only name exists [like MY_ENUM_VALUE].
    if only_name.search(i):
      c_names.append(i)
      if unknown_flag:
        values.append(unknown_val)
        tokens[i] = unknown_val
      else:
        values.append(str(val))
        tokens[i] = val
      perhaps_enum += 1
    # if name with value exists [like MY_FLAG_VALUE = 0x2 or 0x5 << 22
    # or 42 or -13 (in this case entity is still enum, not flags)
    # or 1 << 2 or (1 << 4) or (1 << 5) - 1].
    else:
      m = name_and_value1.search(i) or name_and_value2.search(i) or name_and_value3.search(i)
      if m:
        tmp1 = m.group(1)
        tmp2 = m.group(2)
        c_names.append(tmp1)
        # I do not know who thought that writing '- 1' as enum value is grrreat
        # idea - strip whitespaces between unary minus and a digit.
        if tmp2.startswith('- '):
          tmp2 = re.sub(r'^-\s+', '', tmp2)
        tmp3 = tmp2
        # Python does not understand C-style cast or the u suffix for unsigned.
        tmp3 = cast_or_unsigned1.sub(r'\1', tmp3)
        val = eval(tmp3)
        if cast_or_unsigned2.search(tmp2):
          perhaps_flags += 10
        elif tmp2.startswith('0x'):
          perhaps_flags += 1
        else:
          perhaps_enum += 1
        values.append(tmp2)
        tokens[tmp1] = val
        unknown_flag = False
      else:
        # if name with other name exists [like MY_FLAG_VALUE = MY_PREV_FLAG_VALUE
        # or ~(MY_PREV_FLAG_VALUE | MY_EARLIER_VALUE | (1 << 5) + 1 | 0x200)].
        # [MY_FLAG MY_OTHER_FLAG is also supported - note lack of equal char.]
        # [SOME_DEFINITION([X, [Y, [...]]]) definition is also supported.]
        m = name_with_other_name.search(i)
        if m:
          tmp1 = m.group(1)
          tmp2 = m.group(2)
          c_names.append(tmp1)
          # split r-values on "logical or" and for each splitted r-value check its
          # numeric value and replace a name with it if possible.
          tmps = tmp2.split('|')
          # dont_eval is True if unknown token is found, so whole value is copied
          # verbatim, without evaling.
          dont_eval = False
          if len(tmps) > 1:
            perhaps_flags += 1
          else:
            perhaps_enum += 1

          for tmpval in tmps:
            # if r-value is something like MY_FLAG or MY_DEFINE_VALUE3.
            m = other_name.search(tmpval)
            if m:
              tmp3 = m.group(1)
              if tmp3 not in tokens:
                dont_eval = True
                print('WARNING:', tmp3, 'value of', tmp1, "element in '",  c_name,
                      "' enum is an unknown token.", file=sys.stderr)
                if not has_warned_unknown_token:
                  has_warned_unknown_token = True
                  print("It probably is one of:",
                        "  - preprocessor value - make sure that header defining this value is included in sources wrapping the enum.",
                        "  - enum value from other header or module - see 'preprocessor value'.",
                        "  - typo (happens rarely) - send a patch fixing this to maintainer of this module.",
                        sep='\n', file=sys.stderr)
                # unknown value often makes a flag.
                perhaps_flags += 1
              else:
                tmp2 = tmp2.replace(tmp3, str(tokens[tmp3]))
            else:
              # else is a numeric value, so we do not do anything.
              pass

          # check if there are still some non-numerical values.
          if re.search(r'[_A-Z]+', tmp2):
            dont_eval = True

          if not dont_eval:
            val = eval(tmp2)
            values.append(val)
            tokens[tmp1] = val
            unknown_flag = False
          else:
            values.append(tmp2)
            unknown_flag = True
            # wrapping in safety parens.
            unknown_base = '(' + tmp2 + ')'
            unknown_increment = 0
            tokens[tmp1] = unknown_base

        # if name with char exists (like MY_ENUM_VALUE = 'a').
        else:
          m = name_with_char.search(i)
          if m:
            c_names.append(m.group(1))
            values.append("'" + m.group(2) + "'")
            val = ord(m.group(2))
            tokens[m.group(1)] = val
            unknown_flag = False
            perhaps_enum += 1

          # if it's one of the char values that were replaced by
          # %%COMMA%% or %%RBRACE%%.
          else:
            m = comma_or_rbrace.search(i)
            if m:
              c_names.append(m.group(1))
              if m.group(2) == r'%%COMMA%%':
                values.append("','")
                val = ord(',')
              elif m.group(2) == r'%%RBRACE%%':
                values.append("'}'")
                val = ord('}')
              else:
                values.append(m.group(2))
              tokens[m.group(1)] = val
              unknown_flag = False
              perhaps_enum += 1

            # it should not get here,
            # except if the last enumerator is followed by a comma.
            elif not(not i and iter == len(lines)):
              print("WARNING: I do not know how to parse it: '", i, "' in '", c_name, "'.",
                    sep='', file=sys.stderr)

    if unknown_flag:
      unknown_increment += 1
      unknown_val = unknown_base + ' + ', + unknown_increment
    else:
      val += 1

  entity = 'flags' if c_name.endswith('Flags') or perhaps_flags >= perhaps_enum else 'enum'
  # get nick names.
  ref_names = form_names(c_name, c_names)
  # set format - decimal for enums, hexadecimal for flags.
  vformat = '{0:d}' if entity == 'enum' else '{0:#x}'
  # evaluate any unevaluated values and format them properly, if applicable.
  for j in range(len(values)):
    # if values[j] is a string that can be interpreted as a decimal integer,
    # convert it to an integer, so the format (decimal or hexadecimal)
    # can be selected by vformat.
    if isinstance(values[j], str):
      try:
        values[j] = int(values[j])
      except ValueError:
        pass    
    if isinstance(values[j], int):
      values[j] = vformat.format(values[j])

  # print the defs.
  print('(define-', entity, '-extended ', enum_def, sep='')
  print('  (in-module "', module, '")', sep='')
  print('  (c-name "', c_name, '")', sep='')
  print('  (values')
  for j in range(len(c_names)):
    value = ''
    if values[j]:
      value = ' "' + values[j] + '"'
    print('    \'("', ref_names[j], '" "', c_names[j], '"', value, ')', sep='')
  print('  )')
  print(')\n')

def form_names(c_name, c_names):
  '''form nick names from C names'''

  names = []
  # no values in enum means no names.
  if not c_names:
    return names
    
  # search for length of a prefix.
  leng = len(c_names[0]) - 1
  # if there is more than one value in enum, search for a common part.
  if len(c_names) > 1:
    for j in range(len(c_names)-1):
      while c_names[j][leng-1] != '_' or c_names[j][0:leng] != c_names[j+1][0:leng]:
        leng -= 1
        if leng <= 0:
          break
      if leng <= 0:
        break
  # if there is only one value in enum, we have to use name of the enum.
  else:
    subvals = c_names[0].split('_')
    for j in range(len(subvals)):
      subvals[j] = subvals[j].capitalize()
    false_c_name = ''.join(subvals)
    while leng > 0 and c_name[0:leng] != false_c_name[0:leng]:
      leng -= 1
    tmpleng = leng
    for subval in subvals:
      leng += 1
      l = len(subval)
      if tmpleng <= l:
        break
      tmpleng -= l

  # get prefix with given length.
  prefix = c_names[0][0:leng]
  # generate names.
  for c_n in c_names:
    if c_n[0:len(prefix)] == prefix:
      # remove prefix.
      c_n = c_n[len(prefix):]
    c_n = c_n.lower().replace('_', '-')
    names.append(c_n)

  return names

# ----- Main -----
if __name__ == '__main__':
  import argparse

  parser = argparse.ArgumentParser(
    description='Extract enum definitions from C/C++ header files and write a .defs file.')
  parser.add_argument('--module', help='module name')
  parser.add_argument('--omit-deprecated', action='store_true', dest='omit',
    help='omit deprecated enums and enum values')
  parser.add_argument('header_files', nargs='+', help='header file(s) to parse')
  args = parser.parse_args()

  exitcode = 0
  for filepath in args.header_files:
    try:
      parse(filepath, args.module, args.omit)
    except FileNotFoundError as err:
      exitcode = 1
      print(err, file=sys.stderr)

  sys.exit(exitcode)
