#! /usr/bin/perl

# Read the gtk-doc comment blocks in the *.{c,h} source files converting them
# to xml which gmmproc can use for the documentation of methods, signals,
# properties and enums.
# usage: ./docextract_to_xml.pl file.c [--help | -h] [--with-signals | -s] [--with-properties | -p] [--with-enums | -e ] file.[c|h| ... > output-file.xml

use strict;
use warnings;

# Prototypes.
sub print_usage();
sub parse_command_line_options();
sub process_file($);
sub find_gtk_doc_comment_block($$$);
sub get_param_section($$$);
sub get_description($$$);
sub get_return($$$);
sub append_final_lines($$$);
sub translate_text($);

# Global variables.
$main::with_signals = 0;        # Don't print signal xml by default.
$main::with_properties = 0;     # Don't print property xml by default.
$main::with_enums = 0;          # Don't print enum xml by default.
$main::is_enum = 0;             # Tells whether current block is an enum block.

# Begin by parsing command line.
parse_command_line_options();

# Print initial <root> tag.
print "<root>\n";

while (@ARGV)
{
  # Open each file in the argument list and convert the gtk-doc comment blocks
  # to xml outputing to stdout.
  if (open(my $in_file, "<", $ARGV[0]))
  {
    print STDERR "Processing '$ARGV[0]'.\n";
    process_file($in_file);
    close $in_file;
  }
  else
  {
    # If file opening is not successful, print an error message but continue
    # processing the remaining files.
    print STDERR "Error trying to open file \"$ARGV[0]\"; skipping it.\n";
  }

  shift @ARGV;
}

# Print final <root> tag.
print "</root>\n";

exit;

# Print usage information on error.  Exits.
sub print_usage()
{
  print STDERR "usage: $0 [--help | -h] [--with-signals | -s] [--with-properties | -p] [--with-enums | -e ] file.[c|h] ...\n";
  exit 1;
}

# Parse command line arguments, if any.
sub parse_command_line_options()
{
  print_usage() if (@ARGV == 0);

  while ($ARGV[0] =~ /^-/)
  {
    $_ = shift @ARGV;

    # Print help message for --help option.
    print_usage() if (/^-h$/ || /^--help$/);

    if (/^-s$/ || /^--with-signals$/)
    {
      $main::with_signals = 1;
    }
    elsif (/^-p$/ || /^--with-properties$/)
    {
      $main::with_properties = 1;
    }
    elsif (/^-e$/ || /^--with-enums$/)
    {
      $main::with_enums = 1;
    }
    else
    {
      print STDERR "$0: Unrecognized parameter: $_\n";
      exit 1;
    }
  }
}

# Read through source file looking for gtk-doc comment blocks, testing if the
# comment blocks are function, signal or property comment blocks and
# converting the ones that are to xml for gmmproc to use to get documentation
# for wrapped C functions or signals.
sub process_file($)
{
  my ($in_file, $line) = @_;

  # Read through file by lines.
  while ($line = <$in_file>)
  {
    my $identifier = "";        # The identifier of the current comment block.
    my $parameters = "";        # The parameters.
    my $description = "";       # The description.
    my $return = "";            # The return

    # Always assume that current block is not an enum block.  The parameter
    # parsing will determine whether it is or not based on whether the
    # parameters of the block are all caps (this is only true generally for
    # enums).
    $main::is_enum = 0;

    # Find the next comment block.
    $line = find_gtk_doc_comment_block($in_file, $line, $identifier);

    # Get the several sections of the comment block.
    $line = get_param_section($in_file, $line, $parameters) if $line;
    $line = get_description($in_file, $line, $description) if $line;
    $line = get_return($in_file, $line, $return) if $line;

    # Append the final lines of the comment block to the main description.
    # These lines could be "Since:" or "Deprecated:" lines.
    $line = append_final_lines($in_file, $line, $description) if $line;

    # Surround the description with the xml tags.
    $description = "<description>\n" . $description . "</description>\n";

    # Test to see if dealing with a function.  If so print xml for it.
    if ($identifier =~ /^[a-z0-9_]+/)
    {
      print "<function name=\"$identifier\">\n";
      print "$description";
      print "$parameters";
      print "$return";
      print "</function>\n\n";
    }
    # Test to see if dealing with a signal.  If so print xml for it if the
    # --with-signal option has been specified.
    elsif ($main::with_signals && $identifier =~ /^[A-Z]\w*::[a-z0-9-]+/)
    {
      print "<signal name=\"$identifier\">\n";
      print "$description";
      print "$parameters";
      print "$return";
      print "</signal>\n\n";
    }
    # Test to see if dealing with a property.  If so print xml for it if the
    # --with-property option has been specified.  Ignore possible
    # "SECTION:name" which is gtk-doc specific syntax.  Properties don't have
    # parameters or returns so those are not printed.
    elsif ($main::with_properties && $identifier =~ /^[A-Z]\w*:[a-z0-9-]+/ &&
      !($identifier =~ /^SECTION/))
    {
      print "<property name=\"$identifier\">\n";
      print "$description";
      print "</property>\n\n";
    }
    # Test to see if dealing with an enum and print it out if it has been
    # specified.  An enum has no return so it is not printed.
    elsif ($main::with_enums && $main::is_enum && $identifier =~ /^[A-Z]\w*/)
    {
      print "<enum name=\"$identifier\">\n";
      print "$description";
      print "$parameters";
      print "</enum>\n\n";
    }
  }
}

# Searches for the next gtk-doc comment block.  If a comment block is found,
# returns the first line of the comment block (the line that contains the
# identifier).  Also returns the identifier in the third parameter.
sub find_gtk_doc_comment_block($$$)
{
  my ($in_file, $line) = @_;

  # Find the beginning of a gtk-doc comment block.  Also stop if end of file
  # is reached.
  $line = <$in_file> until (!$line || $line =~ /([ \t]*)\/\*\*([ \t]*)$/);

  # Try to read the line below the beginning of the comment block to attempt
  # to get the identifier if the end of file has not been reached.
  $line = <$in_file> if ($line);

  # If end of file is not reached.
  if ($line)
  {
    # Test for a function comment block and extract its identifier.
    if ($line =~ /^([ \t]*)\**+([ \t]*)([a-z0-9_]+)([ \t]*)(\(\))*:*([ \t]*)$/)
    {
      $_[2] = "$3";
    }
    # Test for a signal comment block and extract its identifier.
    elsif ($line =~
      /^([ \t]*)\**+([ \t]*)([A-Z]\w*::[a-z0-9-]+)([ \t]*)(\(\))*:*([ \t]*)$/)
    {
      $_[2] = "$3";
    }
    # Test for a property comment block and extract its identifier.
    elsif ($line =~
      /^([ \t]*)\**+([ \t]*)([A-Z]\w*:[a-z0-9-]+)([ \t]*):*([ \t]*)$/)
    {
      $_[2] = "$3";
    }
    # Anything else, just try to get an identifier.
    elsif ($line =~ /^([ \t]*)\**+([ \t]*)(\w+)([ \t]*):*/)
    {
      $_[2] = "$3";
    }
  }

  return $line;
}

# Given an opened file and the line where the identifier of a gtk-doc comment
# block is specified, store xml of the parameter descriptions (if there are
# any) in the third parameter (as a string), and return the line in which the
# parameter description section ends.
sub get_param_section($$$)
{
  my ($in_file, $line) = @_;

  # Begin by reading the line below the identifier.
  $line = <$in_file>;

  # Assume this is an enum and disprove it in the processing.  This is done if
  # any of the parameters have lowercase letters.
  $main::is_enum = 1;

  # Loop through all the parameter descriptions storing the xml for each one.
  while ($line && $line =~
    /^([ \t]*)\**+([ \t]*)@(\w+)([ \t]*):([ \t]*)(.*)$/)
  {
    $_[2] .= "<parameter name=\"$3\">\n";
    $_[2] .= "<parameter_description> " . translate_text($6) . "\n";

    # If a lowercase letter is found in the parameter name, it is not an enum.
    $main::is_enum = 0 if ($3 =~ /[a-z]/);

    # Continue reading lines and storing them as part of the current parameter
    # description as long the end of the file or end of the parameter
    # description section or a new parameter description or the end of the
    # comment block are not encountered.
    while (defined($line = <$in_file>) && !($line =~ /^([ \t]*)\**+([ \t]*)$/)
      && !($line =~ /^([ \t]*)\**+([ \t]*)@\w+([ \t]*):/) &&
      !($line =~ /\*\//))
    {
      $line =~ /^([ \t]*)\**+([ \t]*)(.*)$/;
      $_[2] .= translate_text($3) . "\n";
    }

    $_[2] .= "</parameter_description>\n";
    $_[2] .= "</parameter>\n";
  }

  # Assume that this was not an enum if there were no parameters.
  $main::is_enum = 0 if (!$_[2]);

  # Add the xml tags to the paramter list.
  $_[2] = "<parameters>\n" . $_[2] . "</parameters>\n";

  return $line;
}

# Given an input file and the line just after the last parameter description
# in a gtk-doc comment block, store all the non-empty lines up until
# a return description in the third parameter as a string.  If a "Since:"
# line is encountered before a return description or the end of the comment
# block, it is appended to the description.  Likewise, if a "Deprecated:"
# description is encountered.  Returns the line that terminates the storing.
sub get_description($$$)
{
  my ($in_file, $line) = @_;

  # If the end of the block has been encountered before processing the
  # description (in the paramter processing), return because there is no
  # description.
  return $line if ($line && $line =~ /\*\//);

  # Skip blank lines in the comment block as long as the end of file or the
  # end of the comment block are not reached.
  do
  {
    $line = <$in_file>;

    # Skip the line (by going to the next iteration) if the line only has an
    # asterisk.
    next if ($line && $line =~ /^([ \t]*)\*([ \t]*)$/);
  }
  until (!$line || $line =~ /^([ \t]*)\**+([ \t]*)(.+)$/ || $line =~ /\*\//);

  # Concatenate each line to the third parameter as long as the end of file or
  # the return description or the end of the comment block are not reached.
  until (!$line || $line =~ /^([ \t]*)\**+([ \t]*)Returns[ \t]*:/ ||
    $line =~ /\*\//)
  {
    $line =~ /^([ \t]*)\**+([ \t]*)(.*)$/;
    $_[2] .= translate_text($3) . "\n";
    $line = <$in_file>;
  }

  return $line;
}

# Given an input file and the line ending the description in a gtk-doc
# comment block, store all the non-empty lines as a return xml block up until
# a "Since:" line or a "Deprecated:" description (if there are any) in the
# third parameter.  Returns the line that terminates the storing.
sub get_return($$$)
{
  my ($in_file, $line) = @_;

  if ($line && $line =~ /^([ \t]*)\**+([ \t]*)Returns[ \t]*:([ \t]*)(.*)$/)
  {
    $_[2] .= translate_text($4) . "\n";

    # Concatenate each line to the third parameter as long as the end of file
    # or a "Since:" line or a "Deprecated:" section or the end of the comment
    # block are not reached.
    while (defined($line = <$in_file>) &&
      !($line =~ /^([ \t]*)\**+([ \t]*)Since[ \t]*:/) &&
      !($line =~ /^([ \t]*)\**+([ \t]*)@*Deprecated[ \t]*:/) &&
      !($line =~ /\*\//))
    {
      $line =~ /^([ \t]*)\**+([ \t]*)(.*)$/;
      $_[2] .= translate_text($3) . "\n";
    }
  }

  # Add the return tags.
  $_[2] = "<return>\n" . $_[2] . "</return>\n";

  return $line;
}

# Given an input file and the line which stopped a return description
# processing in a gtk-doc comment block, store all the remaining lines of the
# gtk-doc comment block in the third parameter as a string.  This subroutine
# assumes that everything up until the return description in the current
# gtk-doc comment block has already been processed.  The only possible lines
# remaining would be "Since:" or "Deprecated:" lines.  Those lines should be
# stored in the description.  If this isn't so, appending the remaining lines
# to the description still seems the sensible thing to do.  Returns the line
# that terminates the storing.
sub append_final_lines($$$)
{
  my ($in_file, $line) = @_;

  # Concatenate each line to the third parameter as long as the end of file or
  # the end of the comment block are not reached.
  until (!$line || $line =~ /\*\//)
  {
    $line =~ /^([ \t]*)\**+([ \t]*)(.*)$/;
    $_[2] .= translate_text($3) . "\n";
    $line = <$in_file>;
  }

  return $line;
}

# Takes given text and returns translated text that is Doxygen and xml
# friendly.
sub translate_text($)
{
  my $text = shift;

  if ($text)
  {
    $text =~ s/<note>/\@note\n/g; # Use Doxygen note directive.
    $text =~ s/<\/note>//g;       # No need to close the Doxygen directive.
    $text =~ s/"/&quot;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/'/&apos;/g;
  }

  return $text;
}
