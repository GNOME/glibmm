#!/usr/bin/env python3
# -*- Mode: Python; py-indent-offset: 4 -*-
#
# This litte script outputs the C doc comments to an XML format.
# So far it's only used by gtkmm (The C++ bindings). Murray Cumming.
# Usage example:
# # ./docextract_to_xml.py -s /gnome/head/cvs/gtk+/gtk/ -s /gnome/head/cvs/gtk+/docs/reference/gtk/tmpl/ > gtk_docs.xml

import getopt
import re
import sys

import docextract

def usage():
    sys.stderr.write('usage: docextract_to_xml.py ' +
        '[-s /src/dir | --source-dir=/src/dir] ' +
        '[-x /src/dir/file-to-exclude | --exclude-file=/src/dir/file-to-exclude] ' +
        '[-a | --with-annotations] [-p | --with-properties] ' +
        '[-c | --with-sections] [-r | --no-recursion] ' +
        '[-n | --no-since] [-i | --no-signals ] [-e | --no-enums ]\n')
    sys.exit(1)

# Translates special texts to &... HTML acceptable format.  Also replace
# occurrences of '/*' and '*/' with '/ *' and '* /' respectively to avoid
# comment errors (note the spaces).  Some function descriptions include C++
# multi-line comments which cause errors when the description is included in a
# C++ Doxygen comment block.
def escape_text(unescaped_text):
    # Escape every "&" not part of an entity reference
    escaped_text = re.sub(r'&(?![A-Za-z]+;)', '&amp;', unescaped_text)

    # These weird entities turn up in the output...
    escaped_text = escaped_text.replace('&mdash;', '&#8212;')
    escaped_text = escaped_text.replace('&ast;', '*')
    escaped_text = escaped_text.replace('&percnt;', '%')
    escaped_text = escaped_text.replace('&commat;', '@')
    escaped_text = escaped_text.replace('&colon;', ':')
    escaped_text = escaped_text.replace('&num;', '&#35;')
    escaped_text = escaped_text.replace('&nbsp;', '&#160;')
    escaped_text = escaped_text.replace('&solidus;', '&#47;')
    escaped_text = escaped_text.replace('&pi;', '&#8719;')
    escaped_text = escaped_text.replace('&rArr;', '&#8658;')
    # This represents a '/' before or after an '*' so replace with slash but
    # with spaces.
    escaped_text = escaped_text.replace('&sol;', ' / ')

    # Escape for both tag contents and attribute values
    escaped_text = escaped_text.replace('<', '&lt;')
    escaped_text = escaped_text.replace('>', '&gt;')
    escaped_text = escaped_text.replace('"', '&quot;')

    # Replace C++ comment begin and ends to ones that don't affect Doxygen.
    escaped_text = escaped_text.replace('/*', '/ *')
    escaped_text = escaped_text.replace('*/', '* /')

    return escaped_text

def print_annotations(annotations):
    for annotation in annotations:
        print("<annotation name=" + annotation[0] +  ">" + \
                escape_text(annotation[1]) + "</annotation>")

if __name__ == '__main__':
    try:
        opts, args = getopt.getopt(sys.argv[1:], "s:x:apcrnie",
                                   ["source-dir=", "exclude-file=",
                                    "with-annotations", "with-properties",
                                    "with-sections", "no-recursion", "no-since",
                                    "no-signals", "no-enums"])
    except getopt.error as e:
        sys.stderr.write('docextract_to_xml.py: %s\n' % e)
        usage()
    source_dirs = []
    exclude_files = []
    with_annotations = False
    with_signals = True
    with_properties = False
    with_sections = False
    with_enums = True
    for opt, arg in opts:
        if opt in ('-s', '--source-dir'):
            source_dirs.append(arg)
        elif opt in ('-x', '--exclude-file'):
            exclude_files.append(arg)
        elif opt in ('-a', '--with-annotations'):
            with_annotations = True
        elif opt in ('-p', '--with-properties'):
            with_properties = True
        elif opt in ('-c', '--with-sections'):
            with_sections = True
        elif opt in ('-r', '--no-recursion'):
            docextract.no_recursion = True
        elif opt in ('-n', '--no-since'):
            docextract.no_since = True
        elif opt in ('-i', '--no-signals'):
            with_signals = False
        elif opt in ('-e', '--no-enums'):
            with_enums = False
    if len(args) != 0:
        usage()

    docs = docextract.extract(source_dirs, exclude_files);
    docextract.extract_tmpl(source_dirs, exclude_files, docs); #Try the tmpl sgml files too.

    # print d.docs

    if docs:

        print("<root>")

        for name, value in sorted(docs.items()):
            # Get the type of comment block ('function', 'signal',
            # 'property', 'section' or 'enum') (the value is a GtkDoc).
            block_type = value.get_type()

            # Skip signals if the option was not specified.
            if block_type == 'signal' and not with_signals:
                continue
            # Likewise for properties.
            elif block_type == 'property' and not with_properties:
                continue
            # Likewise for sections.
            elif block_type == 'section':
                if not with_sections:
                    continue
                # Delete 'SECTION:' from the name.
                # (It could easily be deleted by docextract.extract(), but then
                # there would be a theoretical risk that a section name would
                # be identical to a function name, when all kinds of elements
                # are stored in the docs dictionary with their names as key.)
                last_colon_pos = name.rfind(':')
                if last_colon_pos >= 0:
                    name = name[last_colon_pos+1:]
            # Likewise for enums.
            elif block_type == 'enum' and not with_enums:
                continue

            print("<" + block_type + " name=\"" + escape_text(name) + "\">")

            print("<description>")
            print(escape_text(value.get_description()))
            print("</description>")

            # Loop through the parameters if not dealing with a property:
            if block_type != 'property':
                print("<parameters>")
                for name, description, annotations in value.params:
                        print("<parameter name=\"" + escape_text(name) + "\">")
                        print("<parameter_description>" + escape_text(description) + "</parameter_description>")

                        if with_annotations:
                            print_annotations(annotations)

                        print("</parameter>")

                print("</parameters>")

            if block_type not in ('property', 'section', 'enum'):
              # Show the return-type if not dealing with a property, section
              # or enum:
              if with_annotations:
                  print("<return>")
                  print("<return_description>" + escape_text(value.ret[0]) + \
                          "</return_description>")
                  print_annotations(value.ret[1])
                  print("</return>")
              else:
                  print("<return>" + escape_text(value.ret[0]) + "</return>")

            if with_annotations:
                print_annotations(value.get_annotations())

            print("</" + block_type + ">\n")

        print("</root>")
