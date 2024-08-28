# gtkmm - DocsParser module
#
# Copyright 2001 Free Software Foundation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Based on XML::Parser tutorial found at http://www.devshed.com/Server_Side/Perl/PerlXML/PerlXML1/page1.html
# This module isn't properly Object Orientated because the XML Parser needs global callbacks.

package DocsParser;
use XML::Parser;
use strict;
use warnings;
use feature 'state';

use Util;
use Function;
use GtkDefs;
use Object;

BEGIN {
     use Exporter   ();
     our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

     # set the version for version checking
     $VERSION     = 1.00;

     @ISA         = qw(Exporter);
     @EXPORT      = ( );
     %EXPORT_TAGS = ( );

     # your exported package globals go here,
     # as well as any optionally exported functions
     @EXPORT_OK   = ( );
}
our @EXPORT_OK;

#####################################

use strict;
use warnings;

#####################################

$DocsParser::CurrentFile = "";

$DocsParser::refAppendTo = undef; # string reference to store the data into
$DocsParser::currentParam = undef;

$DocsParser::objCurrentFunction = undef; #Function
%DocsParser::hasharrayFunctions = (); #Function elements
%DocsParser::type_names = (); # Type names (e.g. enums) with non-standard C-to-C++ translation.
%DocsParser::enumerator_name_prefixes = (); # Enumerator name prefixes with non-standard C-to-C++ translation.
%DocsParser::enumerator_names = (); # Enumerator names with non-standard C-to-C++ translation.

$DocsParser::commentStart = "  /** ";
$DocsParser::commentMiddleStart = "   * ";
$DocsParser::commentEnd = "   */";

sub read_defs($$$)
{
  my ($path, $filename, $filename_override) = @_;

  my $objParser = new XML::Parser(ErrorContext => 0);
  $objParser->setHandlers(Start => \&parse_on_start, End => \&parse_on_end, Char => \&parse_on_cdata);

  # C documentation:
  $DocsParser::CurrentFile = "$path/$filename";
  if ( ! -r $DocsParser::CurrentFile)
  {
     print STDERR "DocsParser.pm: Warning: Can't read file \"" . $DocsParser::CurrentFile . "\".\n";
     return;
  }
  # Parse
  eval { $objParser->parsefile($DocsParser::CurrentFile) };
  if( $@ )
  {
    $@ =~ s/at \/.*?$//s;
    print STDERR "\nError in \"" . $DocsParser::CurrentFile . "\":$@\n";
    return;
  }

  # C++ override documentation:
  $DocsParser::CurrentFile = $path . '/' . $filename_override;

  # It is not an error if the documentation override file does not exist.
  return unless (-r $DocsParser::CurrentFile);

  # Parse
  eval { $objParser->parsefile($DocsParser::CurrentFile) };
  if( $@ )
  {
    $@ =~ s/at \/.*?$//s;
    print STDERR "\nError in \"" . $DocsParser::CurrentFile . "\":$@";
    return;
  }
}

sub parse_on_start($$%)
{
  my ($objParser, $tag, %attr) = @_;

  $tag = lc($tag);

  if($tag eq "function" or $tag eq "signal" or $tag eq "property" or $tag eq "enum")
  {
    if(defined $DocsParser::objCurrentFunction)
    {
      $objParser->xpcroak(
        "\nClose a function, signal, property or enum tag before you open another one.");
    }

    my $functionName = $attr{name};

    # Change signal name from Class::a-signal-name to Class::a_signal_name
    # and property name from Class:a-property-name to Class:a_property_name
    $functionName =~ s/-/_/g if ($tag eq "signal" or $tag eq "property");

    #Reuse existing Function, if it exists:
    #(For instance, if this is the override parse)
    $DocsParser::objCurrentFunction = $DocsParser::hasharrayFunctions{$functionName};
    if(!$DocsParser::objCurrentFunction)
    {
      #Make a new one if necessary:
      $DocsParser::objCurrentFunction = Function::new_empty();
      # The idea is to change the policy a bit:
      # If a function is redefined in a later parsing run only values which are redefined
      # will be overwritten. For the name this is trivial. The description is simply rewritten.
      # Same goes for the return description and the class mapping. Only exception is the
      # parameter list. Everytime we enter a <parameters> tag the list is emptied again.
      $$DocsParser::objCurrentFunction{name} = $functionName;
      $$DocsParser::objCurrentFunction{description} = "";
      $$DocsParser::objCurrentFunction{param_names} = [];
      $$DocsParser::objCurrentFunction{param_descriptions} = ();
      $$DocsParser::objCurrentFunction{return_description} = "";
      $$DocsParser::objCurrentFunction{mapped_class} = "";
    }
  }
  elsif($tag eq "parameters")
  {
    $$DocsParser::objCurrentFunction{param_names} = [];
    $$DocsParser::objCurrentFunction{param_descriptions} = ();
  }
  elsif($tag eq "parameter")
  {
    $DocsParser::currentParam = $attr{name};
    $$DocsParser::objCurrentFunction{param_descriptions}->{$DocsParser::currentParam} = "";
  }
  elsif($tag eq "description")
  {
    $$DocsParser::objCurrentFunction{description} = "";
    # Set destination for parse_on_cdata().
    $DocsParser::refAppendTo = \$$DocsParser::objCurrentFunction{description};
  }
  elsif($tag eq "parameter_description")
  {
    # Set destination for parse_on_cdata().
    my $param_desc = \$$DocsParser::objCurrentFunction{param_descriptions};
    $DocsParser::refAppendTo = \$$param_desc->{$DocsParser::currentParam};
  }
  elsif($tag eq "return")
  {
    $$DocsParser::objCurrentFunction{return_description} = "";
    # Set destination for parse_on_cdata().
    $DocsParser::refAppendTo = \$$DocsParser::objCurrentFunction{return_description};
  }
  elsif($tag eq "mapping")
  {
    $$DocsParser::objCurrentFunction{mapped_class} = $attr{class};
  }
  elsif($tag eq "substitute_type_name")
  {
    $DocsParser::type_names{$attr{from}} = $attr{to};
  }
  elsif($tag eq "substitute_enumerator_name")
  {
    if (exists $attr{from_prefix})
    {
      $DocsParser::enumerator_name_prefixes{$attr{from_prefix}} = $attr{to_prefix};
    }
    if (exists $attr{from})
    {
      $DocsParser::enumerator_names{$attr{from}} = $attr{to};
    }
  }
  elsif($tag ne "root")
  {
    $objParser->xpcroak("\nUnknown tag \"$tag\".");
  }
}


sub parse_on_end($$)
{
  my ($parser, $tag) = @_;

  # Clear destination for parse_on_cdata().
  $DocsParser::refAppendTo = undef;

  $tag = lc($tag);

  if($tag eq "function" or $tag eq "signal" or $tag eq "property" or $tag eq "enum")
  {
    # Store the Function structure in the array:
    my $functionName = $$DocsParser::objCurrentFunction{name};
    $DocsParser::hasharrayFunctions{$functionName} = $DocsParser::objCurrentFunction;
    $DocsParser::objCurrentFunction = undef;
  }
  elsif($tag eq "parameter")
  {
    # <parameter name="returns"> and <return> means the same.
    if($DocsParser::currentParam eq "returns")
    {
      my $param_descriptions = \$$DocsParser::objCurrentFunction{param_descriptions};
      my $return_description = \$$DocsParser::objCurrentFunction{return_description};
      $$return_description = delete $$param_descriptions->{"returns"};
    }
    else
    {
      # Append to list of parameters.
      push(@{$$DocsParser::objCurrentFunction{param_names}}, $DocsParser::currentParam);
    }

    $DocsParser::currentParam = undef;
  }
}


sub parse_on_cdata($$)
{
  my ($parser, $data) = @_;

  if(defined $DocsParser::refAppendTo)
  {
    # Dispatch $data to the current destination string.
    $$DocsParser::refAppendTo .= $data;
  }
}

sub lookup_enum_documentation($$$$$$$$)
{
  my ($c_enum_name, $cpp_enum_name, $indent, $ref_subst_in, $ref_subst_out,
    $is_enum_class, $deprecation_docs, $newin) = @_;

  my $objFunction = $DocsParser::hasharrayFunctions{$c_enum_name};
  if(!$objFunction)
  {
    #print "DocsParser.pm: Warning: enum not found: $enum_name\n";
    return ""
  }

  my $docs = "";

  my @param_names = @{$$objFunction{param_names}};
  my $param_descriptions = \$$objFunction{param_descriptions};

  # Scoped enum class or old-fashioned plain enum?
  my $var_delimiter = $is_enum_class ? "::" : " ";

  # Append the param docs first so that the enum description can come last and
  # the possible flag docs that the m4 _ENUM() macro appends goes in the right
  # place.
  foreach my $param (@param_names)
  {
    my $desc = $$param_descriptions->{$param};

    # Remove the initial prefix in the name of the enum constant. Would be something like GTK_.
    $param =~ s/\b[A-Z]+_//;

    # Now apply custom substitutions.
    for(my $i = 0; $i < scalar(@$ref_subst_in); ++$i)
    {
      $param =~ s/$$ref_subst_in[$i]/$$ref_subst_out[$i]/;
      $desc  =~ s/$$ref_subst_in[$i]/$$ref_subst_out[$i]/;
    }

    # Skip this element, if its name has been deleted.
    next if($param eq "");

    $param =~ s/([a-zA-Z0-9]*(_[a-zA-Z0-9]+)*)_?/$1/g;
    if(length($desc) > 0)
    {
      # Chop off leading and trailing whitespace.
      $desc =~ s/^\s+//;
      $desc =~ s/\s+$//;
      $desc .= '.' unless($desc =~ /(?:^|\.)$/);
      # \u = Convert next char to uppercase
      $docs .= "\@var $cpp_enum_name$var_delimiter${param}\n\u${desc}\n\n";
    }
  }
  DocsParser::convert_docs_to_cpp($c_enum_name, \$docs);

  # Replace @newin in the enum description, but don't in the element descriptions.
  my $description = $$objFunction{description};
  DocsParser::convert_docs_to_cpp($c_enum_name, \$description);
  DocsParser::replace_or_add_newin(\$description, $newin);

  # Add note about deprecation if we have specified that in our _WRAP_ENUM(),
  # _WRAP_ENUM_DOCS_ONLY() or _WRAP_GERROR() call:
  if($deprecation_docs ne "")
  {
    $description .= "\n\@deprecated $deprecation_docs\n";
  }

  DocsParser::add_m4_quotes(\$docs);
  DocsParser::add_m4_quotes(\$description);

  # Escape the space after "i.e." or "e.g." in the brief description.
  $description =~ s/^([^.]*\b(?:i\.e\.|e\.g\.))\s/$1\\ /;

  remove_example_code($c_enum_name, \$description);

  # Add indentation and an asterisk on all lines except the first.
  # $docs does not contain leading "/**" and trailing "*/".
  # That's added by the _ENUM() m4 macro.
  $docs =~ s/\n/\n${indent}\* /g;
  $description =~ s/\n/\n${indent}\* /g;

  # Append the enum description docs.
  # Add "*/"  and "/**" between the param docs and the enum docs.
  $docs .= "\n${indent}\*/\n${indent}/\*\* $description";

  return $docs;
}

# $strCommentBlock lookup_documentation($strFunctionName, $deprecation_docs,
#   $newin, $objCppfunc, $errthrow, $voidreturn)
# The parameters from objCppfunc are optional. If objCppfunc is passed, it is used for
# - deciding if the final C parameter shall be omitted if the C++ method
#   has a slot parameter,
# - converting C parameter names to C++ parameter names in the documentation,
#   if they differ,
# - deciding if the @return section shall be omitted.
sub lookup_documentation($$$;$$$)
{
  my ($functionName, $deprecation_docs, $newin, $objCppfunc, $errthrow, $voidreturn) = @_;

  my $objFunction = $DocsParser::hasharrayFunctions{$functionName};
  if(!$objFunction)
  {
    #print "DocsParser.pm: Warning: function not found: $functionName\n";
    return ""
  }

  my $text = $$objFunction{description};

  if(length($text) eq 0)
  {
    print "DocsParser.pm: Warning: No C docs for: \"$functionName\"\n";
  }

  DocsParser::convert_docs_to_cpp($functionName, \$text);
  DocsParser::replace_or_add_newin(\$text, $newin);
  # A blank line, marking the end of a paragraph, is needed after @newin.
  # Most @newins are at the end of a function description.
  $text .= "\n";

  # Add note about deprecation if we have specified that in our _WRAP_METHOD(),
  # _WRAP_SIGNAL(), _WRAP_PROPERTY() or _WRAP_CHILD_PROPERTY() call:
  if($deprecation_docs ne "")
  {
    $text .= "\n\@deprecated $deprecation_docs\n";
  }

  my %param_name_mappings = DocsParser::append_parameter_docs($objFunction, \$text, $objCppfunc);
  unless ((defined($objCppfunc) && $$objCppfunc{rettype} eq "void") || $voidreturn)
  {
    DocsParser::append_return_docs($objFunction, \$text);
  }
  DocsParser::add_throws(\$text, $errthrow);

  # Convert C parameter names to C++ parameter names where they differ.
  foreach my $key (keys %param_name_mappings)
  {
    $text =~ s/\@(param|a) $key\b/\@$1 $param_name_mappings{$key}/g;
  }

  # Remove leading and trailing white space.
  $text = string_trim($text);

  DocsParser::add_m4_quotes(\$text);

  # Escape the space after "i.e." or "e.g." in the brief description.
  $text =~ s/^([^.]*\b(?:i\.e\.|e\.g\.))\s/$1\\ /;

  remove_example_code($functionName, \$text);

  # Convert to Doxygen-style comment.
  $text =~ s/\n/\n${DocsParser::commentMiddleStart}/g;
  $text =  $DocsParser::commentStart . $text;
  $text .= "\n${DocsParser::commentEnd}\n";

  return $text;
}

# void convert_value_to_cpp(\$text)
# Converts e.g. a property's default value.
sub convert_value_to_cpp($)
{
  my ($text) = @_;

  $$text =~ s"`?\bFALSE\b`?"<tt>false</tt>"g;
  $$text =~ s"`?\bTRUE\b`?"<tt>true</tt>"g;
  $$text =~ s"`?\bNULL\b`?"<tt>nullptr</tt>"g;

  # Enumerator names
  $$text =~ s/\b([A-Z]+)_([A-Z\d_]+)\b/&DocsParser::substitute_enumerator_name($1, $2)/eg;
}

# void remove_example_code($obj_name, \$text)
# Removes example code from the text of docs (passed by reference).
sub remove_example_code($$)
{
  my ($obj_name, $text) = @_;

  # Remove C example code.
  my $example_removals =
    ($$text =~ s"<informalexample>.*?</informalexample>"[C example ellipted]"sg);
  $example_removals +=
    ($$text =~ s"<programlisting>.*?</programlisting>"\n[C example ellipted]"sg);
  $example_removals += ($$text =~ s"\|\[.*?]\|"\n[C example ellipted]"sg);
  # gi-docgen syntax.
  # remove_example_code() is called after add_m4_quotes().
  $example_removals += ($$text =~ s"(?:'__BT__`){3}[cC].*?(?:'__BT__`){3}"\n[C example ellipted]"sg);

  # See "MS Visual Studio" comment in gmmproc.in.
  print STDERR "gmmproc, $main::source, $obj_name: Example code discarded.\n"
    if ($example_removals);
}

sub add_m4_quotes($)
{
  my ($text) = @_;

  # __BT__ and __FT__ are M4 macros defined in the base.m4 file that produce
  # a "`" and a "'" resp. without M4 errors.
  my %m4_quotes = (
    "`" => "'__BT__`",
    "'" => "'__FT__`",
  );

  $$text =~ s/([`'])/$m4_quotes{$1}/g;
  $$text = "`" . $$text . "'";
}

# The final objCppfunc is optional.  If passed, it is used to determine
# if the final C parameter should be omitted if the C++ method has a
# slot parameter. It is also used for converting C parameter names to
# C++ parameter names in the documentation, if they differ.
sub append_parameter_docs($$;$)
{
  my ($obj_function, $text, $objCppfunc) = @_;

  my @docs_param_names = @{$$obj_function{param_names}};
  my $param_descriptions = \$$obj_function{param_descriptions};
  my $defs_method = GtkDefs::lookup_method_dont_mark($$obj_function{name});
  my @c_param_names = $defs_method ? @{$$defs_method{param_names}} : @docs_param_names;

  # The information in
  # $obj_function comes from the docs.xml file,
  # $objCppfunc comes from _WRAP_METHOD() or _WRAP_SIGNAL() in the .hg file,
  # $defs_method comes from the methods.defs file.

  # Ideally @docs_param_names and @c_param_names are identical.
  # In the real world the parameters in the C documentation are sometimes not
  # listed in the same order as the arguments in the C function declaration.
  # We try to handle that case to some extent. If no argument name is misspelt
  # in either the docs or the C function declaration, it usually succeeds for
  # methods, but not for signals. For signals there is no C function declaration
  # to compare with. If the docs of some method or signal get badly distorted
  # due to imperfections in the C docs, and it's difficult to get the C docs
  # corrected, correct docs can be added to the docs_override.xml file.

  if (scalar @docs_param_names != scalar @c_param_names)
  {
    # If the last parameter in @c_param_names is an error parameter,
    # it may be deliberately omitted in @docs_param_names.
    if (!(scalar @c_param_names == (scalar @docs_param_names)+1 && $c_param_names[-1] eq "error"))
    {
      print STDERR "DocsParser.pm: Warning, $$obj_function{name}\n" .
        "  Incompatible parameter lists in the docs.xml file and the methods.defs file.\n";
    }
  }

  # Skip first param if this is a signal.
  if ($$obj_function{name} =~ /\w+::/)
  {
    shift(@docs_param_names);
    shift(@c_param_names);
  }
  # Skip first parameter if this is a non-static method.
  elsif (defined($objCppfunc))
  {
    if (!$$objCppfunc{static})
    {
      shift(@docs_param_names);
      shift(@c_param_names);
    }
  }
  # The second alternative is for use with method-mappings meaning:
  # this function is mapped into this Gtk::class.
  elsif (($defs_method && $$defs_method{class} ne "") ||
         $$obj_function{mapped_class} ne "")
  {
    shift(@docs_param_names);
    shift(@c_param_names);
  }

  # Skip the last param if there is a slot because it would be a
  # gpointer user_data parameter.
  if (defined($objCppfunc) && $$objCppfunc{slot_name})
  {
    pop(@docs_param_names);
    pop(@c_param_names);
  }

  # Skip the last param if it's an error output param.
  if (scalar @docs_param_names && $docs_param_names[-1] eq "error")
  {
    # If the number of parameters in @docs_param_names is not greater than
    # the number of parameters in the _WRAP macro, the parameter called "error"
    # is probably not an error output parameter.
    if (!defined($objCppfunc) || scalar @docs_param_names > scalar @{$$objCppfunc{param_names}})
    {
      pop(@docs_param_names);
      pop(@c_param_names);
    }
  }

  my $cpp_param_names;
  my $param_mappings;
  my $out_param_index = 1000; # No method has that many arguments, hopefully.
  if (defined($objCppfunc))
  {
    $cpp_param_names = $$objCppfunc{param_names};
    $param_mappings = $$objCppfunc{param_mappings}; # C name -> C++ index
    if (exists $$param_mappings{OUT})
    {
      $out_param_index = $$param_mappings{OUT};
    }
    if (scalar @docs_param_names != scalar @$cpp_param_names)
    {
      print STDERR "DocsParser.pm: Warning, $$obj_function{name}\n" .
        "  Incompatible parameter lists in the docs.xml file and the _WRAP macro.\n";
    }
  }
  my %param_name_mappings; # C name -> C++ name

  for (my $i = 0; $i < @docs_param_names; ++$i)
  {
    my $param = $docs_param_names[$i];
    my $desc = $$param_descriptions->{$param};
    my $param_without_trailing_underscore = $param;
    $param_without_trailing_underscore =~ s/([a-zA-Z0-9]*(_[a-zA-Z0-9]+)*)_?/$1/g;

    if (defined($objCppfunc))
    {
      # If the C++ name is not equal to the C name, mark that the name
      # shall be changed in the documentation.
      my $cpp_name = $param;
      if (exists $$param_mappings{$param})
      {
        # Rename and/or reorder declaration ({c_name} or {.}) in _WRAP_*().
        $cpp_name = $$cpp_param_names[$$param_mappings{$param}];
      }
      elsif ($c_param_names[$i] eq $param)
      {
        # Location in docs coincides with location in C declaration.
        my $cpp_index = $i;
        $cpp_index++ if ($i >= $out_param_index);
        $cpp_name = $$cpp_param_names[$cpp_index];
      }
      else
      {
        # Search for the param in the C declaration.
        for (my $j = 0; $j < @c_param_names; ++$j)
        {
          if ($c_param_names[$j] eq $param)
          {
            my $cpp_index = $j;
            $cpp_index++ if ($j >= $out_param_index);
            $cpp_name = $$cpp_param_names[$cpp_index];
            last;
          }
        }
      }
      if ($cpp_name ne $param)
      {
        $param_name_mappings{$param_without_trailing_underscore} = $cpp_name;
      }
    }
    elsif ($param eq "callback")
    {
      # Deal with callback parameters converting the docs to a slot
      # compatible format.
      $param_name_mappings{$param} = "slot";
    }

    DocsParser::convert_docs_to_cpp($$obj_function{name}, \$desc);
    if(length($desc) > 0)
    {
      $desc  .= '.' unless($desc =~ /(?:^|\.)$/);
      $$text .= "\n\@param ${param_without_trailing_underscore} \u${desc}";
    }
  }
  return %param_name_mappings;
}


sub append_return_docs($$)
{
  my ($obj_function, $text) = @_;

  my $desc = $$obj_function{return_description};
  DocsParser::convert_docs_to_cpp($$obj_function{name}, \$desc);

  $desc  =~ s/\.$//;
  $$text .= "\n\@return \u${desc}." unless($desc eq "");
}


sub convert_docs_to_cpp($$)
{
  my ($doc_func, $text) = @_;

  # Chop off leading and trailing whitespace.
  $$text =~ s/^\s+//;
  $$text =~ s/\s+$//;

  # Convert C documentation to C++.
  DocsParser::remove_c_memory_handling_info($text);
  DocsParser::convert_tags_to_doxygen($text);
  DocsParser::substitute_identifiers($doc_func, $text);

  $$text =~ s/\bX\s+Window\b/X&nbsp;\%Window/g;
  $$text =~ s/\bWindow\s+manager/\%Window manager/g;
}

sub remove_c_memory_handling_info($)
{
  my ($text) = @_;

  # These C memory handling functions are removed, in most cases:
  # g_free, g_strfreev, g_list_free, g_slist_free
  my $mem_funcs = '\\bg_(?:free|strfreev|s?list_free)\\b';

  return if ($$text !~ /$mem_funcs/);

  # The text contains $mem_funcs. That's usually not relevant to C++ programmers.
  # Try to remove irrelevant text without removing too much.

  # This function is called separately for the description of each method,
  # parameter and return value. Let's assume that only one removal is necessary.

  # Don't modify the text, if $mem_funcs is part of example code.
  # remove_c_memory_handling_info() is called before remove_example_code().
  return if ($$text =~ m"(?:<informalexample>|<programlisting>|\|\[).*?$mem_funcs.*?(?:</informalexample>|</programlisting>|]\|)"s);
  # gi-docgen syntax.
  # remove_c_memory_handling_info() is called before add_m4_quotes().
  return if ($$text =~ m"\`\`\`[cC].*?$mem_funcs.*?\`\`\`"s);

  # First try to remove the sentence containing $mem_funcs.
  # For simplicity, assume that a sentence is any string ending with a period.
  my $tmp = $$text;
  if ($tmp =~ s/[^.]*$mem_funcs.*?(?:\.|$)//s)
  {
    if ($tmp =~ /\w/)
    {
      # A sentence contains $mem_funcs, and it's not the only sentence in the text.
      # Remove that sentence.
      $$text = $tmp;
      return;
    }
  }

  $tmp = $$text;
  if ($tmp =~ s/[^.,]*$mem_funcs.*?(?:\.|,|$)//s)
  {
    if ($tmp =~ /\w/)
    {
      # A clause, delimited by comma or period, contains $mem_funcs,
      # and it's not the only clause in the text. Remove that clause.
      $tmp =~ s/,\s*$/./;
      $$text = $tmp;
      return;
    }
  }

  # Last attempt. If this doesn't remove anything, don't modify the text.
  $$text =~ s/ that (?:must|should) be freed with g_free(?:\(\))?//;
}

sub convert_tags_to_doxygen($)
{
  my ($text) = @_;

  for($$text)
  {
    # Replace format tags.
    s"<(/?)(?:emphasis|replaceable)>"<$1em>"g;
    s"<(/?)(?:constant|envar|filename|function|guimenuitem|literal|option|structfield|varname)>"<$1tt>"g;

    # Some argument names are suffixed by "_" -- strip this.
    # gtk-doc uses @thearg, but doxygen uses @a thearg.
    s" ?\@([a-zA-Z0-9]*(_[a-zA-Z0-9]+)*)_?\b" \@a $1"g;

    # Don't convert Doxygen's @throw, @throws and @param, so these can be used
    # in the docs_override.xml.
    # Also don't convert @enum and @var which are used for enum documentation.
    s" \@a (throws?|param|enum|var)\b" \@$1"g;

    # gi-docgen uses [type@Module.*]. Don't convert them.
    s"(\[[a-z]+?) \@a (.+?])"$1\@$2"g;

    s"^Note ?\d?: "\@note "mg;
    s"</?programlisting>""g;
    s"<!>""g;

    # Remove all link tags.
    s"</?u?link[^&]*?>""g;

    # Remove all para tags and simpara tags (simple paragraph).
    s"</?(sim)?para>""g;

    # Convert <simplelist>, <itemizedlist> and <variablelist> to something that
    # Doxygen understands.
    s"<simplelist>\n?(.*?)</simplelist>\n?"&DocsParser::convert_simplelist($1)"esg;
    s"<itemizedlist>\n?(.*?)</itemizedlist>\n?"&DocsParser::convert_itemizedlist($1)"esg;
    s"<variablelist>\n?(.*?)</variablelist>\n?"&DocsParser::convert_variablelist($1)"esg;

    # Use our Doxygen @newin alias.
    # Accept "Since" with or without a following colon.
    # Require the Since clause to be
    # - at the end of the string,
    # - at the end of a line and followed by a blank line, or
    # - followed by "Deprecated".
    # If none of these requirements is met, "Since" may be embedded inside
    # a function description, referring to only a part of the description.
    # See e.g. g_date_time_format() and gdk_cursor_new_from_pixbuf().
    # Doxygen assumes that @newin is followed by a paragraph that describes
    # what is new, but we don't use it that way.
    my $first_part = '\bSince[:\h]\h*(\d+)\.(\d+)'; # \h == [\t ] (horizontal whitespace)
    my $last_part = '\.?(\s*$|\h*\n\h*\n|\s+Deprecated)';
    s/$first_part\.(\d+)$last_part/\@newin{$1,$2,$3}$4/g;
    s/$first_part$last_part/\@newin{$1,$2}$3/g;

    # Doxygen is too dumb to handle &mdash;
    s"&mdash;" \@htmlonly&mdash;\@endhtmlonly "g;

    s"`?\%?\bFALSE\b`?"<tt>false</tt>"g;
    s"`?\%?\bTRUE\b`?"<tt>true</tt>"g;
    s"`?\%?\bNULL\b`?"<tt>nullptr</tt>"g;

    s"#?\bgboolean\b"<tt>bool</tt>"g;
    s"#?\bg(int|short|long)\b"<tt>$1</tt>"g;
    s"#?\bgu(int|short|long)\b"<tt>unsigned $1</tt>"g;

    # Escape all backslashes, except in \throw, \throws and \param, which can
    # be Doxygen commands in the docs_override.xml.
    s"\\"\\\\"g;
    s"\\\\(throws?|param)\b"\\$1"g
  }
}

# void replace_or_add_newin(\$text, $newin)
# If $newin is not empty, replace the version numbers in an existing @newin
# Doxygen alias, or add one if there is none.
sub replace_or_add_newin($$)
{
  my ($text, $newin) = @_;

  return if ($newin eq "");

  if (!($$text =~ s/\@newin\{[\d,]+\}/\@newin{$newin}/))
  {
    $$text .= "\n\n\@newin{$newin}";
  }
}

# void add_throws(\$text, $errthrow)
# If $errthrow is defined and not empty, and $$text does not contain a @throw,
# @throws or @exception Doxygen command, add one or more @throws commands.
sub add_throws($$)
{
  my ($text, $errthrow) = @_;

  return if (!defined($errthrow) or $errthrow eq "");

  if (!($$text =~ /[\@\\](throws?|exception)\b/))
  {
    # Each comma, not preceded by backslash, creates a new @throws command.
    $errthrow =~ s/([^\\]),\s*/$1\n\@throws /g;
    $errthrow =~ s/\\,/,/g; # Delete backslash before comma
    $$text .= "\n\n\@throws $errthrow";
  }
}

# Convert <simplelist> tags to a list of newline-separated elements.
sub convert_simplelist($)
{
  my ($text) = @_;

  $text =~ s"<member>(.*?)(\n?)</member>(\n?)"$1<br>\n"sg;
  return "<br>\n" . $text . "<br>\n";
}

# Convert <itemizedlist> tags to Doxygen format.
sub convert_itemizedlist($)
{
  my ($text) = @_;

  $text =~ s"<listitem>(.*?)(\n?)</listitem>(\n?)"- $1\n"sg;
  return $text;
}

# Convert <variablelist> tags to an HTML definition list.
sub convert_variablelist($)
{
  my ($text) = @_;

  $text =~ s"</?varlistentry>\n?""g;
  $text =~ s"<(/?)term>"<$1dt>"g;
  $text =~ s"<(/?)listitem>"<$1dd>"g;
  return "<dl>\n" . $text . "</dl>\n";
}

sub substitute_identifiers($$)
{
  my ($doc_func, $text) = @_;

  for($$text)
  {
    # TODO: handle more than one namespace

    # The gi-docgen syntax for links to symbols is described at
    # https://gnome.pages.gitlab.gnome.org/gi-docgen/linking.html
    #
    # The gtk-doc syntax for links to symbols is described in the gtk-doc manual:
    # yelp gtk-doc/help/manual/C/index.docbook
    # then select "Documenting the code" and "Documenting symbols".

    # Convert property names to C++.
    # The standard (and correct) gtk-doc way of referring to properties.
    s/(#[A-Z]\w+):([a-z\d_-]+)/my $name = "$1::property_$2()"; $name =~ s"-"_"g; "$name";/ge;
    # This is an incorrect format but widely used so correctly treat as a property.
    s/(\s)::([a-z\d_-]+)(\s+property)/my $name = "$1property_$2()$3"; $name =~ s"-"_"g; "$name";/ge;
    # This one catches properties written in the gtk-doc block as for example
    # '#GtkActivatable::related-action property'. The correct way to write it
    # would be 'GtkActivatable:related-action' (with a single colon and not
    # two because the double colons are specifically for signals)
    # but a few are written with the double colon in the gtk docs so this
    # protects against those errors.
    s/([A-Z]\w+)::([a-z\d_-]+)(\s+property)/my $name = "$1::property_$2()$3"; $name =~ s"-"_"g; "$name";/ge;
    # gi-docgen syntax.
    s/\[(`?)property@(?:([A-Z]\w*)\.)?([A-Z]\w+):([a-z\d_-]+)\1]/"$1" . &DocsParser::substitute_property_or_signal_name($doc_func, $2, $3, "property", $4) . "$1"/ge;

    # Convert signal names to C++.
    # Don't accept underscore in gtk-doc-formatted signal names.
    # Converted property names would be found and converted to ClassName::signal_property_name().
    s/(^|\s)::([a-z\d-]+)(\(\))*([^:\w]|$)/my $name = "$1signal_$2()$4"; $name =~ s"-"_"g; "$name";/ge;
    s/(#[A-Z]\w+)::([a-z\d-]+)(\(\))*([^:\w]|$)/my $name = "$1::signal_$2()$4"; $name =~ s"-"_"g; "$name";/ge;
    s/\[(`?)signal@(?:([A-Z]\w*)\.)?([A-Z]\w+)::([a-z\d_-]+)\1]/"$1" . &DocsParser::substitute_property_or_signal_name($doc_func, $2, $3, "signal", $4) . "$1"/ge;
    # Type names
    s/[#%]([A-Z][a-z]*)([A-Z][A-Za-z]+)\b/&DocsParser::substitute_type_name($doc_func, $1, $2)/eg;
    s/`([A-Z][a-z]*)([A-Z][A-Za-z]*[a-z])`/"`" . &DocsParser::substitute_type_name($doc_func, $1, $2) . "`"/eg;
    s/\[(`?)(?:class|enum|error|flags|iface|struct|type)@(?:([A-Z]\w*)\.)?([A-Z]\w+)\1]/"$1" . &DocsParser::substitute_type_name($doc_func, $2, $3) . "$1"/eg;

    # Enumerator names
    s/[#%]([A-Z]+)_([A-Z\d_]+)\b/&DocsParser::substitute_enumerator_name($1, $2)/eg;
    s/`([A-Z]+)_([A-Z\d_]+)`/"`" . &DocsParser::substitute_enumerator_name($1, $2) . "`"/eg;
    s/\[(`?)enum@([A-Z]\w*)\.([A-Z]\w*)\.([A-Z\d_]+)\1]/"$1" . &DocsParser::substitute_enumerator_name3($2, $3, $4) . "$1"/eg;

    s/\bG:://g; #Rename G::Something to Something.

    # Substitute callback types to slot types.
    s/(\b\w+)Callback/Slot$1/g;

    # Replace C function names with C++ counterparts.
    s/\b([a-z]+_[a-z][a-z\d_]+) ?\(\)/&DocsParser::substitute_function($doc_func, $1)/eg;
    s/\[(`?)id@([a-z\d_]+)\1]/"$1" . &DocsParser::substitute_function($doc_func, $2) . "$1"/eg;
    s/\[(`?)(?:ctor|method)@(?:([A-Z]\w*)\.)?([A-Z]\w+)\.([a-z\d_]+)\1]/"$1" . &DocsParser::substitute_split_function($doc_func, $2, $3, $4) . "$1"/eg;
    s/\[(`?)vfunc@(?:([A-Z]\w*)\.)?([A-Z]\w+)\.([a-z\d_]+)\1]/"$1" . &DocsParser::substitute_split_function($doc_func, $2, $3, $4 . "_vfunc") . "$1"/eg;
    s/\[(`?)func@([\w.]+)\1]/"$1" . &DocsParser::substitute_func_function($doc_func, $2) . "$1"/eg;
  }
}

sub substitute_type_name($$$)
{
  my ($doc_func, $module, $name) = @_;
  $module = get_module_from_doc_func($doc_func) if !$module;

  my $c_name = $module . $name;

  if (exists $DocsParser::type_names{$c_name})
  {
    return $DocsParser::type_names{$c_name};
  }
  $module = "Glib" if $module eq "GLib";
  #print "DocsParser.pm: Assuming the type $c_name shall become " . (($module eq "G") ? "" : "${module}::") . "$name.\n";
  return $module . "::" . $name;
}

sub substitute_enumerator_name3($$$)
{
  # For instance Gtk, FontRendering, MANUAL.
  # Convert to GTK, FONT_RENDERING_MANUAL before calling substitute_enumerator_name().
  my ($module, $type_name, $enumerator) = @_;

  $type_name =~ s/([a-z])([A-Z])/$1_$2/g;
  return substitute_enumerator_name(uc($module), uc($type_name) . "_" . $enumerator);
}

sub substitute_enumerator_name($$)
{
  state $first_call = 1;
  state @sorted_keys;

  my ($module, $name) = @_;
  my $c_name = $module . "_" . $name;

  if (exists $DocsParser::enumerator_names{$c_name})
  {
    return $DocsParser::enumerator_names{$c_name};
  }

  if ($first_call)
  {
    # Sort only once, on the first call.
    # "state @sorted_keys = ...;" is not possible. Only a scalar variable
    # can have a one-time assignment in its defining "state" statement.
    $first_call = 0;
    @sorted_keys = reverse sort keys(%DocsParser::enumerator_name_prefixes);
  }

  # This is a linear search through the keys of %DocsParser::enumerator_name_prefixes.
  # It's inefficient if %DocsParser::enumerator_name_prefixes contains many values.
  #
  # If one key is part of another key (e.g. G_REGEX_MATCH_ and G_REGEX_),
  # search for a match against the longer key before the shorter key.
  foreach my $key (@sorted_keys)
  {
    if ($c_name =~ m/^$key/)
    {
      # $c_name begins with $key. Replace that part of $c_name with the C++ analogue.
      $c_name =~ s/^$key/$DocsParser::enumerator_name_prefixes{$key}/;
      return $c_name; # Now it's the C++ name.
    }
  }

  # Don't apply the default substitution to these module names.
  # They are not really modules.
  if (grep {$module eq $_} qw(HAS NO O SO AF XDG))
  {
    return $c_name;
  }

  my $cxx_name = (($module eq "G") ? "" : (ucfirst(lc($module)) . "::")) . $name;

  print "DocsParser.pm: Assuming the enumerator $c_name shall become $cxx_name.\n";

  return $cxx_name;
}

sub substitute_property_or_signal_name($$$$$)
{
  # $doc_func can be the name of a property (ModuleClass:property_name),
  # signal (ModuleClass::signal_name), function/method (module_class_method_name)
  # or class/enum/etc. (ModuleClass).
  my ($doc_func, $module, $class, $prop_or_sig, $name) = @_;
  $module = get_module_from_doc_func($doc_func) if !$module;

  my $prefix = $module . $class;
  $name =~ s"-"_"g;
  $name = $prop_or_sig . "_" . $name . "()";
  if (index($doc_func, $prefix . ":") == 0)
  {
    # Documentation of property or signal in the same class as the referred
    # property or signal.
    return $name;
  }
  if (index($doc_func, ":") == -1)
  {
    # Documentation of a function or method.
    if (my $defs_method = GtkDefs::lookup_method_dont_mark($doc_func))
    {
      if ($$defs_method{class} eq $prefix)
      {
        # Documentation of function/method in the same class as the referred
        # property or signal.
        return $name;
      }
    }
  }
  return $module . "::" . $class . "::" . $name;
}

sub substitute_split_function($$$$)
{
  my ($doc_func, $module, $class, $name) = @_;
  $module = get_module_from_doc_func($doc_func) if !$module;

  my $prefix = build_method_prefix($module, $class);

  if ($doc_func =~ m/^$prefix/)
  {
    return $name . "()";
  }
  else
  {
    $module = "Glib" if $module eq "GLib";
    return $module . "::" . $class . "::" . $name . "()";
  }
}

sub substitute_func_function($$)
{
  # $name == Gtk.WidgetPaintable.func or Gtk.func or func.
  my ($doc_func, $name) = @_;
  $name =~ s/\./_/g;
  $name =~ s/([a-z])([A-Z])/$1_$2/g;
  return DocsParser::substitute_function($doc_func, lc($name));
}

sub get_module_from_doc_func($)
{
  my ($doc_func) = @_;

  if ($doc_func =~ /^([a-z]+)_/)
  {
    # Function name. gtk_foo_bar -> Gtk
    return "\u$1";
  }
  # Class name. GtkFooBar -> Gtk
  $doc_func =~ /^([A-Z][a-z]*?)[A-Z]/;
  return $1;
}

sub substitute_function($$)
{
  my ($doc_func, $name) = @_;

  if(my $defs_method = GtkDefs::lookup_method_dont_mark($name))
  {
    if(my $defs_object = DocsParser::lookup_object_of_method($$defs_method{class}, $name))
    {
      my $module = $$defs_object{module};
      my $class  = $$defs_object{name};

      DocsParser::build_method_name($doc_func, $module, $class, \$name);
    }
    else
    {
      print STDERR "Documentation: Class/Namespace for $name not found\n";
    }
  }
  else
  {
    # Not perfect, but better than nothing.
    $name =~ s/^g_/Glib::/;
  }

  return $name . "()";
}

sub lookup_object_of_method($$)
{
  my ($object, $name) = @_;

  if($object ne "")
  {
    my $result = GtkDefs::lookup_object($object);

    # We already know the C object name, because $name is a non-static method.
    if(defined($result) and ($result ne ""))
    {
      return $result;
    }
    else
    {
      print "DocsParser.pm: lookup_object_of_method(): Warning: GtkDefs::lookup_object() failed for object name=" . $object . ", function name=" . $name . "\n";
      print "  This may be a missing define-object in a *.defs file.\n"
    }
  }

  my @parts = split(/_/, $name);
  pop(@parts);

  # (gtk, foo, bar) -> (Gtk, Foo, Bar)
  foreach(@parts) { $_ = (length > 2) ? ucfirst : uc; }

  # Do a bit of try'n'error.
  while($#parts >= 1)
  {
    my $try = join("", @parts);

    if(my $defs_object = GtkDefs::lookup_object($try))
      { return $defs_object; }

    pop(@parts);
  }

  return undef;
}

sub build_method_name($$$$)
{
  my ($doc_func, $module, $class, $name) = @_;

  my $prefix = build_method_prefix($module, $class);

  if($$name =~ m/^\Q$prefix\E/)
  {
    my $scope = "";
    $scope = "${module}::${class}::" unless($doc_func =~ m/^\Q$prefix\E/);

    substr($$name, 0, length($prefix)) = $scope;
  }
}

sub build_method_prefix($$)
{
  my ($module, $class) = @_;

  my $prefix = $module . $class;

  $prefix =~ s/([a-z])([A-Z])/$1_$2/g;
  $prefix =~ s/^(Gdk|Gtk)_GL([A-Z][a-z])/$1_GL_$2/; # Special cases, add an underline
  return lc($prefix) . '_';
}

1; # indicate proper module load.
