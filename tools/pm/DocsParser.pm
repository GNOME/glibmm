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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#

# Based on XML::Parser tutorial found at http://www.devshed.com/Server_Side/Perl/PerlXML/PerlXML1/page1.html
# This module isn't properly Object Orientated because the XML Parser needs global callbacks.

package DocsParser;
use XML::Parser;
use strict;
use warnings;

# use Util;
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
#~ $DocsParser::bOverride = 0; #First we parse the C docs, then we parse the C++ override docs.

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

  # C++ overide documentation:
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

  if($tag eq "function" or $tag eq "signal" or $tag eq "enum")
  {
    if(defined $DocsParser::objCurrentFunction)
    {
      $objParser->xpcroak(
        "\nClose a function, signal or enum tag before you open another one.");
    }

    my $functionName = $attr{name};

    # Change signal name from Class::a-signal-name to Class::a_signal_name.
    $functionName =~ s/-/_/g if($tag eq "signal");

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
      # We don't need this any more, the only reference to this field is commented
      # $$DocsParser::objCurrentFunction{description_overridden} = $DocsParser::bOverride;
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

  if($tag eq "function" or $tag eq "signal" or $tag eq "enum")
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

sub lookup_enum_documentation($$$)
{
  my ($c_enum_name, $cpp_enum_name, $ref_flags) = @_;
  
  my @subst_in  = [];
  my @subst_out = [];
 
 # Get the substitutions.
  foreach(@$ref_flags)
  {
    if(/^\s*s#([^#]+)#([^#]*)#\s*$/)
    {
      push(@subst_in,  $1);
      push(@subst_out, $2);
    }
  }

  my $objFunction = $DocsParser::hasharrayFunctions{$c_enum_name};
  if(!$objFunction)
  {
    #print "DocsParser.pm: Warning: enum not found: $enum_name\n";
    return ""
  }

  my $docs = "";

  my @param_names = @{$$objFunction{param_names}};
  my $param_descriptions = \$$objFunction{param_descriptions};

  # Append the param docs first so that the enum description can come last and
  # the possible flag docs that the m4 _ENUM() macro appends goes in the right
  # place.
  foreach my $param (@param_names)
  {
    my $desc = $$param_descriptions->{$param};

    # Remove the initial prefix in the name of the enum constant. Would be something like GTK_.
    $param =~ s/\b[A-Z]+_//;

    # Now apply custom substitutions.
    for(my $i = 0; $i < scalar(@subst_in); ++$i)
    {
      $param =~ s/${subst_in[$i]}/${subst_out[$i]}/;
      $desc  =~ s/${subst_in[$i]}/${subst_out[$i]}/;
    }

    # Skip this element, if its name has been deleted.
    next if($param eq "");

    $param =~ s/([a-zA-Z0-9]*(_[a-zA-Z0-9]+)*)_?/$1/g;
    if(length($desc) > 0)
    {
      $desc =~ s/\n/ /g;
      $desc =~ s/ $//;
      $desc =~ s/^\s+//; # Chop off leading whitespace
      $desc .= '.' unless($desc =~ /(?:^|\.)$/);
      $docs .= "\@var $cpp_enum_name ${param}\n \u${desc}\n\n"; # \u = Convert next char to uppercase
    }
  }

  # Append the enum description docs.
  $docs .= "\@enum $cpp_enum_name\n"; 
  $docs .= $$objFunction{description};

  DocsParser::convert_docs_to_cpp($objFunction, \$docs);
  DocsParser::add_m4_quotes(\$docs);

  # Escape the space after "i.e." or "e.g." in the brief description.
  $docs =~ s/^([^.]*\b(?:i\.e\.|e\.g\.))\s/$1\\ /;
  
  remove_example_code($c_enum_name, \$docs);

  # Convert to Doxygen-style comment.
  $docs =~ s/\n/\n \* /g;
  $docs =  "\/\*\* " . $docs;

  return $docs;
}

# $strCommentBlock lookup_documentation($strFunctionName, $deprecation_docs, $objCppfunc)
# The final objCppfunc parameter is optional.  If passed, it is used to
# decide if the final C parameter should be omitted if the C++ method
# has a slot parameter.
sub lookup_documentation($$;$)
{
  my ($functionName, $deprecation_docs, $objCppfunc) = @_;

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

  DocsParser::convert_docs_to_cpp($objFunction, \$text);
  # A blank line, marking the end of a paragraph, is needed after @newin.
  # Most @newins are at the end of a function description.
  $text .= "\n";

  #Add note about deprecation if we have specified that in our _WRAP_METHOD() call:
  if($deprecation_docs ne "")
  {
    $text .= "\n\@deprecated $deprecation_docs\n";
  }

  DocsParser::append_parameter_docs($objFunction, \$text, $objCppfunc);
  DocsParser::append_return_docs($objFunction, \$text);
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

  print STDERR "gmmproc: $main::source: $obj_name: Example code discarded.\n"
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
# slot parameter.
sub append_parameter_docs($$;$)
{
  my ($obj_function, $text, $objCppfunc) = @_;

  my @param_names = @{$$obj_function{param_names}};
  my $param_descriptions = \$$obj_function{param_descriptions};

  # Strip first parameter if this is a method.
  my $defs_method = GtkDefs::lookup_method_dont_mark($$obj_function{name});
  # the second alternative is for use with method-mappings meaning:
  # this function is mapped into this Gtk::class
  shift(@param_names) if(($defs_method && $$defs_method{class} ne "") ||
                         ($$obj_function{mapped_class} ne ""));

  # Also skip first param if this is a signal.
  shift(@param_names) if ($$obj_function{name} =~ /\w+::/);

  # Skip the last param if there is a slot because it would be a
  # gpointer user_data parameter.
  pop(@param_names) if (defined($objCppfunc) && $$objCppfunc{slot_name});

  foreach my $param (@param_names)
  {
    if ($param ne "error" ) #We wrap GErrors as exceptions, so ignore these.
    {
      my $desc = $$param_descriptions->{$param};

      # Deal with callback parameters converting the docs to a slot
      # compatible format.
      if ($param eq "callback")
      {
        $param = "slot";
        $$text =~ s/\@a callback/\@a slot/g;
      }

      $param =~ s/([a-zA-Z0-9]*(_[a-zA-Z0-9]+)*)_?/$1/g;
      DocsParser::convert_docs_to_cpp($obj_function, \$desc);
      if(length($desc) > 0)
      {
        $desc  .= '.' unless($desc =~ /(?:^|\.)$/);
        $$text .= "\n\@param ${param} \u${desc}";
      }
    }
  }
}


sub append_return_docs($$)
{
  my ($obj_function, $text) = @_;

  my $desc = $$obj_function{return_description};
  DocsParser::convert_docs_to_cpp($obj_function, \$desc);

  $desc  =~ s/\.$//;
  $$text .= "\n\@return \u${desc}." unless($desc eq "");
}


sub convert_docs_to_cpp($$)
{
  my ($obj_function, $text) = @_;

  # Chop off leading and trailing whitespace.
  $$text =~ s/^\s+//;
  $$text =~ s/\s+$//;
# HagenM: this is the only reference to $$obj_function{description_overridden}
# and it seems not to be in use.
#  if(!$$obj_function{description_overridden})
#  {
    # Convert C documentation to C++.
    DocsParser::convert_tags_to_doxygen($text);
    DocsParser::substitute_identifiers($$obj_function{name}, $text);

    $$text =~ s/\bX\s+Window\b/X&nbsp;\%Window/g;
    $$text =~ s/\bWindow\s+manager/\%Window manager/g;
#  }
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

    # Don't convert Doxygen's $throw, @throws and @param, so these can be used
    # in the docs_override.xml.
    # Also don't convert @enum and @var which are used for enum documentation.
    s" \@a (throws?|param|enum|var)\b" \@$1"g;

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
    # If Since is not followed by a colon, substitute @newin only if it's
    # in a sentence of its own at the end of the string. 
    s/\bSince:\s*(\d+)\.(\d+)\.(\d+)\b\.?/\@newin{$1,$2,$3}/g;
    s/\bSince:\s*(\d+)\.(\d+)\b\.?/\@newin{$1,$2}/g;
    s/(\.\s+)Since\s+(\d+)\.(\d+)\.(\d+)\.?$/$1\@newin{$2,$3,$4}/;
    s/(\.\s+)Since\s+(\d+)\.(\d+)\.?$/$1\@newin{$2,$3}/;

    s"\b->\b"->"g;

    # Doxygen is too dumb to handle &mdash;
    s"&mdash;" \@htmlonly&mdash;\@endhtmlonly "g;

    s"\%?\bFALSE\b"<tt>false</tt>"g;
    s"\%?\bTRUE\b"<tt>true</tt>"g;
    s"\%?\bNULL\b"<tt>0</tt>"g;

    s"#?\bgboolean\b"<tt>bool</tt>"g;
    s"#?\bg(int|short|long)\b"<tt>$1</tt>"g;
    s"#?\bgu(int|short|long)\b"<tt>unsigned $1</tt>"g;

    # Escape all backslashes, except in \throw, \throws and \param, which can
    # be Doxygen commands in the docs_override.xml.
    s"\\"\\\\"g;
    s"\\\\(throws?|param)\b"\\$1"g
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

    # Convert property names to C++.
    # The standard (and correct) gtk-doc way of referring to properties.
    s/(#[A-Z]\w+):([a-z\d-]+)/my $name = "$1::property_$2()"; $name =~ s"-"_"g; "$name";/ge;
    # This is an incorrect format but widely used so correctly treat as a
    # property.
    s/(\s)::([a-z\d-]+)(\s+property)/my $name = "$1property_$2()$3"; $name =~ s"-"_"g; "$name";/ge;
    # This one catches properties written in the gtk-doc block as for example
    # '#GtkActivatable::related-action property'.  The correct way to write it
    # would be 'GtkActivatable:related-action' (with a single colon and not
    # two because the double colons are specifically for signals -- see the
    # gtk-doc docs:
    # http://developer.gnome.org/gtk-doc-manual/unstable/documenting_symbols.html.en)
    # but a few are written with the double colon in the gtk+ docs so this
    # protects against those errors.
    s/([A-Z]\w+)::([a-z\d-]+)(\s+property)/my $name = "$1::property_$2()$3"; $name =~ s"-"_"g; "$name";/ge;

    # Convert signal names to C++.
    s/(^|\s)::([a-z\d-]+)(\(\))*([^:\w]|$)/my $name = "$1signal_$2()$4"; $name =~ s"-"_"g; "$name";/ge;
    s/(#[A-Z]\w+)::([a-z\d-]+)(\(\))*([^:\w]|$)/my $name = "$1::signal_$2()$4"; $name =~ s"-"_"g; "$name";/ge;

    s/[#%]([A-Z][a-z]*)([A-Z][A-Za-z]+)\b/$1::$2/g; # type names

    s/[#%]([A-Z])([A-Z]*)_([A-Z\d_]+)\b/$1\L$2\E::$3/g; # enum values

    # Undo wrong substitutions.
    s/\bHas::/HAS_/g;
    s/\bNo::/NO_/g;
    s/\bO::/O_/g;
    s/\bG:://g; #Rename G::Something to Something.

    # Substitute callback types to slot types.
    s/(\b\w+)Callback/Slot$1/g;

    # Replace C function names with C++ counterparts.
    s/\b([a-z]+_[a-z][a-z\d_]+) ?\(\)/&DocsParser::substitute_function($doc_func, $1)/eg;
  }
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
      print "Documentation: Transformed C name $name into ";
      non_object_method_name($doc_func, \$name);
      print "C++ name $name\n";
    }
  }
  else
  {
    # Not perfect, but better than nothing.
    $name =~ s/^g_/Glib::/;
  }

  return $name . "()";
}

sub non_object_method_name($$)
{
  my ($doc_func, $name) = @_;
  if ($$name =~ m/^gtk_/)
  {
    my %gtk_objects = ("gtk_accel_map" => "AccelMap",
                       "gtk_clipboard" => "Clipboard",
                       "gtk_file_filter" => "FileFilter",
                       "gtk_icon_set" => "IconSet",
                       "gtk_icon_source" => "IconSource",
                       "gtk_icon_info" => "IconInfo",
                       "gtk_page_setup" => "PageSetup",
                       "gtk_recent_info" => "RecentInfo",
                       "gtk_tooltip" => "Tooltip",
                       "gtk_target_list" => "TargetList",
                       "gtk_drag_source" => "DragSource",
                       "gtk_print_settings" => "PrintSettings",
                       "gtk_recent_filter" => "RecentFilter");
    foreach my $key (keys(%gtk_objects))
    {
      if ($$name =~ m/^\Q$key\E/)
      {
        DocsParser::build_method_name($doc_func, "Gtk", $gtk_objects{$key}, $name);
        return;
      }
    }
  }

  print STDERR "Documentation: Class/Namespace for $$name not found\n";
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
      print "DocsParser.pm:lookup_object_of_method(): Warning: GtkDefs::lookup_object() failed for object name=" . $object . ", function name=" . $name . "\n";
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

  my $prefix = $module . $class;

  $prefix =~ s/([a-z])([A-Z])/$1_$2/g;
  $prefix = lc($prefix) . '_';

  if($$name =~ m/^\Q$prefix\E/)
  {
    my $scope = "";
    $scope = "${module}::${class}::" unless($doc_func =~ m/^\Q$prefix\E/);

    substr($$name, 0, length($prefix)) = $scope;
  }
}


1; # indicate proper module load.
