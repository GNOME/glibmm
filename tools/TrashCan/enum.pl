#! /usr/bin/perl

# The lisp definitions for flags does not include order.
# thus we must extract it ourselves.
# Usage: ./enum.pl /gnome/head/cvs/gconf/gconf/*.h > gconf_enums.defs
use warnings;
use strict;
use File::Spec;
use Getopt::Long;
use IO::File;
#
# globals.
#
# keeps enum values.
my %tokens = ();
# module name.
my $module = "none";
# if user used --help option.
my $help = 0;
# if user wants to omit deprecated stuff.
my $omit = 0;
#
# prototypes.
#
sub parse($);
sub process($$);
sub form_names($$);
#
# main.
#
GetOptions('module=s' => \$module, 'help' => \$help, 'omit-deprecated'=> \$omit);
if ($help or not @ARGV)
{
  print "enum.pl [--module modname][--omit-deprecated] header_files ...\n";
  exit 0;
}
foreach my $file (@ARGV)
{
  parse($file);
}
exit;
#
# parse enums from C.
#
sub parse($)
{
  my ($file) = @_;
  my $fd = IO::File->new($file, "r");
  unless (defined $fd)
  {
    print STDERR "WARNING: Unable to open file: '" . $file . "'.\n";
    return;
  }
  # 1, if we are inside enum.
  my $enum = 0;
  # 1 or more, if we are inside deprecated lines.
  my $deprecated = 0;
  # 1, if we are inside multiline comment.
  my $comment = 0;
  # line containing whole enum preprocessed definition to be processed.
  my $line = "";
  # line containing whole enum raw definition.
  my $raw_line = "";
  # 1, if we already printed comment about basename of header file containing
  # enums.
  my $from = 0;
  # 1, if only right bracket was found, not name.
  my $rbracket_only = 0;
  while(<$fd>)
  {
    my $tmp_rawline = $_;
    if ($enum)
    {
      $raw_line .= ";; " . $tmp_rawline;
    }
    if($comment)
    {
      # end of multiline comment.
      if (m!\*/(.*)!) # / just to fix frigging highlighting in gedit
      {
        $comment = 0;
        if ($enum)
        {
          $line .= $1;
        }
      }
      next;
    }
    # omit deprecated stuff.
    if ($omit and /^\s*#.*(if\s*!\s*defined)|(ifndef)\s*\(?\s*[A-Z_]+_DISABLE_DEPRECATED\s*\)?/)
    {
      ++$deprecated;
      next;
    }
    ++$deprecated if ($deprecated > 0 and /^#\s*if/);
    if ($deprecated > 0 and /^#\s*endif/)
    {
      --$deprecated;
      next;
    }
    next if ($deprecated > 0);
    # discard any preprocessor directives inside enums.
    next if ($enum and /^\s*#/);
    # filter single-line comments.
    s!/\*.*?\*/!!g;
    s!//.*$!!;
    # beginning of multiline comment.
    if (m!^(.*)/\*!)
    {
      $comment = 1;
      if ($enum)
      {
        $line .= $1 . "\n";
      }
      next;
    }
    # XXX: what does it do?
    s/','/\%\%COMMA\%\%/;
    s/'}'/\%\%RBRACE\%\%/;
    # we have found an enum.
    if (/^\s*typedef enum/ )
    {
      my $basename = File::Spec->splitpath($file);
      print(';; From ', $basename, "\n\n") unless ($from);
      $from = 1;
      $enum = 1;
      $raw_line .= ";; " . $tmp_rawline;
      next;
    }
    # we have found end of an enum.
    if ($enum and /\}/ or $rbracket_only)
    {
       # if the same line also consists ';' - that means there is a typedef name
       # between '}' and ';'.
       if (/;/)
       {
         my $def = ($rbracket_only ? ("} " . $_) : ($_));
         $enum = 0;
         print ";; Original typedef:\n";
         print $raw_line . "\n";
         process($line, $def);
         $line = "";
         $raw_line = "";
         $rbracket_only = 0;
       }
       # we assume there is no such definition formed like this:
       # typedef enum
       # {
       # ...
       # } MyTypedef
       # ;
       # that would be stupid.
       else
       {
         $rbracket_only = 1;
         # don't append useless lines to $line.
         next;
       }
    }
    $line .= $_ if ($enum);
  }
  $fd->close();
}

#
# convert enums to lisp.
#
sub process($$)
{
  my ($line,$def) = @_;
  # strip whitespace and closing bracket before the name and whitespace and
  # colon after the name.
  $def =~ s/\s*\}\s*//g;
  $def =~ s/\s*;\s*$//;
  my $c_name = $def;
  # replace all excessive whitespaces with one space.
  $line =~ s/\s+/ /g;
  # get rid of any comments.
  $line =~ s!/\*.*\*/!!g;
  # get rid of opening bracket.
  $line =~ s/\s*{\s*//;
  # lets employ some heuristics. :)
  my %e_h = ("enum" => 0, "flags" => 0);
  # c_name = module + def.
  $c_name =~ /^([A-Z][a-z]*)/;
  $module = $1 if ($module eq "none");
  $def =~ s/\Q$module\E//;
  # names and their values.
  my @c_names = ();
  my @numbers = ();
  # val - default value for enum, gets incremented after every value processed.
  my $val = 0;
  # these are just for case when enum value is equal to a some sort of unknown
  # value - preprocessor define or other enum.
  my $unknown_flag = 0;
  my $unknown_val = "";
  my $unknown_base = "";
  my $unknown_increment = 0;
  foreach my $i (split(/,/, $line))
  {
    # remove leading and trailing spaces.
    $i =~ s/^\s+//;
    $i =~ s/\s+$//;
    # also remove backslashes as some people like to add them before newlines...
    $i =~ s/\\//g;
    # if only name exists [like MY_ENUM_VALUE].
    if ($i =~ /^\S+$/)
    {
      push(@c_names, $i);
      if ($unknown_flag)
      {
        push(@numbers, $unknown_val);
        $tokens{$i} = $unknown_val;
      }
      else
      {
        push(@numbers, sprintf("%d", $val));
        $tokens{$i} = $val;
      }
      $e_h{"enum"}++;
    }
    # if name with value exists [like MY_FLAG_VALUE = 0x2 or 0x5 << 22
    # or 42 or -13 (in this case entity is still enum, not flags)
    # or 1 << 2 or (1 << 4) or (1 << 5) - 1].
    elsif ($i =~ /^(\S+)\s*=?\s*(0x[0-9a-fA-F]+[\s0-9a-fx<-]*)$/ or
           $i =~ /^(\S+)\s*=?\s*(-?\s*[0-9]+)$/ or
           $i =~ /^(\S+)\s*=?\s*(\(?1\s*<<\s*[0-9]+\s*\)?[\s0-9a-fx<-]*)$/
          )
    {
      my ($tmp1, $tmp2) = ($1, $2);
      push(@c_names, $tmp1);
      # i do not know who thought that writing '- 1' as enum value is grrreat
      # idea - strip whitespaces between unary minus and a digit.
      if ($tmp2 =~ /^-\s+/)
      {
        $tmp2 =~ s/\s+//;
      }
      eval("\$val = $tmp2;");
      if ($tmp2 =~ /^\(?1\s*<</)
      {
        $e_h{"flags"} += 10;
      }
      elsif ($tmp2 =~ /^0x/)
      {
        $e_h{"flags"}++;
      }
      else
      {
        $e_h{"enum"}++;
      }
      push(@numbers, $tmp2);
      $tokens{$tmp1} = $val;
      $unknown_flag = 0;
    }
    # if name with other name exists [like MY_FLAG_VALUE = MY_PREV_FLAG_VALUE
    # or ~(MY_PREV_FLAG_VALUE | MY_EARLIER_VALUE | (1 << 5) - 1 | 0x200)].
    # [MY_FLAG MY_OTHER_FLAG is also supported - note lack of equal char.]
    elsif ($i =~ /^(\S+)\s*=?\s*([ _x0-9a-fA-Z|()<~]+)$/)
    {
      my ($tmp1, $tmp2) = ($1, $2);
      push(@c_names, $tmp1);
      # split r-values on "logical or" and for each splitted r-value check its
      # numeric value and replace a name with it if possible.
      my @tmps = split(/\|/, $tmp2);
      # dont_eval is 1 if unknown token is found, so whole value is copied
      # verbatim, without evaling.
      my $dont_eval = 0;
      if (@tmps > 1)
      {
        $e_h{"flags"}++;
      }
      else
      {
        $e_h{"enum"}++;
      }
      foreach my $tmpval (@tmps)
      {
        # if r-value is something like MY_FLAG or MY_DEFINE_VALUE3.
        if ($tmpval =~ /([_A-Z0-9]+)/)
        {
          my $tmp3 = $1;
          unless (defined($tokens{$tmp3}))
          {
            $dont_eval = 1;
            print STDERR "WARNING: " . $tmp3 . " value of " . $tmp1 . " element in '" . $c_name . "' enum is an unknown token.\n" .
                  "It probably is one of below:\n" .
                  "         - preprocessor value - make sure that header defining this value is included in sources wrapping " . $c_name . ".\n" .
                  "         - enum value from other header or module - see 'preprocessor value'.\n" .
                  "         - typo (happens rarely) - send a patch fixing this to maintainer of this module.\n";
            # unknown value often makes a flag.
            $e_h{"flags"}++;
          }
          else
          {
            $tmp2 =~ s/$tmp3/$tokens{$tmp3}/;
          }
        }
        # else is a numeric value, so we do not do anything.
      }
      # check if there are still same non-numerical values.
      if ($tmp2 =~ /[_A-Z]+/)
      {
        $dont_eval = 1;
      }
      unless ($dont_eval)
      {
        eval("\$val = $tmp2;");
        # TODO: "0x%X" format should not be used if, in the end, parsed typedef
        # is an enum.
#        $val = sprintf("0x%X", $val);
        push(@numbers, $val);
        $tokens{$tmp1} = $val;
        $unknown_flag = 0;
      }
      else
      {
        push(@numbers, $tmp2);
        $unknown_flag = 1;
        # wrapping in safety parens.
        $unknown_base = "(" . $tmp2 . ")";
        $unknown_increment = 0;
        $tokens{$tmp1} = $unknown_base;
      }
    }
    # if name with char exists (like MY_ENUM_VALUE = 'a').
    elsif ($i =~ /^(\S+)\s*=\s*'(.)'$/)
    {
      push(@c_names, $1);
      push(@numbers, "\'$2\'");
      $val = ord($2);
      $tokens{$1} = $val;
      $unknown_flag = 0;
      $e_h{"enum"}++;
    }
    # if... XXX: I do not know what is matched here.
    elsif ($i =~ /^(\S+)\s*=\s*(\%\%[A-Z]+\%\%)$/)
    {
      my $tmp = $1;
      $_ = $2;
      s/\%\%COMMA\%\%/,/;
      s/\%\%RBRACE\%\%/]/;
      push(@c_names, $tmp);
      push(@numbers, "\'$_\'");
      $val = ord($_);
      $tokens{$tmp} = $val;
      $unknown_flag = 0;
      $e_h{"enum"}++;
    }
    # it should not get here.
    else
    {
      print STDERR "WARNING: I do not know how to parse it: '" . $i . "' in '" . $c_name . "'.\n";
    }
    if ($unknown_flag)
    {
      $unknown_increment++;
      $unknown_val = $unknown_base . " + " . $unknown_increment;
    }
    else
    {
      $val++;
    }
  }
  my $entity;
  # if there are 'Flags' at the end of C name, they are flags. if not, let
  # heuristics decide.
  if ($c_name =~ /Flags$/ or $e_h{"flags"} >= $e_h{"enum"})
  {
    $entity = "flags";
  }
  else
  {
    $entity = "enum";
  }
  # get nicks.
  my $ref_names = form_names($c_name, \@c_names);
  # set format - decimal for enums, hexadecimal for flags.
  my $format = "%d";
  $format = "0x%X" if ($entity eq "flags");
  # evaluate any unevaluated values and format them properly, if applicable.
  for (my $j = 0; $j < @numbers; $j++)
  {
    if ($numbers[$j] =~ /\$/)
    {
      $numbers[$j] = eval($numbers[$j]);
    }
    if ($numbers[$j] =~ /[0-9a-fA-F]+/ and $numbers[$j] !~ /[_G-Zg-z<]/)
    {
      $numbers[$j] = sprintf($format, $numbers[$j]);
    }
  }
  # print the defs.
  print "(define-$entity-extended $def\n";
  print "  (in-module \"$module\")\n";
  print "  (c-name \"$c_name\")\n";

  print "  (values\n";
  for (my $j = 0; $j < @c_names; $j++)
  {
    print "    \'(\"$ref_names->[$j]\" \"$c_names[$j]\"";
    print " \"$numbers[$j]\"" if ($numbers[$j] ne "");
    print ")\n";
  }
  print "  )\n";
  print ")\n\n";
}

#
# form nicks from C names.
#
sub form_names($$)
{
  my ($c_name, $c_names) = @_;
  my @names = ();
  # search for length of a prefix.
  my $len = length($c_names->[0]) - 1;
  # if there is more than one value in enum, just search for a common part.
  if (@{$c_names} > 1)
  {
    NAME: for (my $j = 0; $j < @{$c_names} - 1; $j++)
    {
      while (substr($c_names->[$j], $len - 1, 1) ne "_" or
             substr($c_names->[$j], 0, $len) ne substr($c_names->[$j + 1], 0, $len))
      {
        $len--;
        last NAME if ($len <= 0);
      }
    }
  }
  # if there is only one value in enum, we have to use name of the enum.
  elsif (@{$c_names} == 1)
  {
    my @subvals = split(/_/, lc($c_names->[0]));
    foreach my $subval (@subvals)
    {
      $subval = ucfirst($subval);
    }
    my $false_c_name = join("", @subvals);
    while (substr($c_name, 0, $len) ne substr($false_c_name, 0, $len))
    {
      $len--;
      last if ($len <= 0);
    }
    my $tmplen = $len;
    foreach my $subval (@subvals)
    {
      $len++;
      my $l = length($subval);
      last if ($tmplen <= $l);
      $tmplen -= $l;
    }
  }
  # no values in enum means no names.
  else
  {
    return \@names;
  }
  # get prefix with given length.
  my $prefix = substr($c_names->[0], 0, $len);
  # generate names.
  for (my $j = 0; $j < @{$c_names}; $j++)
  {
    $_ = $c_names->[$j];
    s/^$prefix//;
    tr/A-Z_/a-z-/;
    push(@names, $_);
  }
  return \@names;
}
