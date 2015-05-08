package Enum;

use strict;
use warnings;
use DocsParser;

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

# class Enum
#    {
#       bool flags;
#       string type;
#       string module;
#       string c_type;
#
#       string array elem_names;
#       string array elem_values;
#       string c_prefix;
#
#       bool mark;
#    }

#
# private functions:
#

sub split_enum_tokens($)
{
  my ($token_string) = @_;
  my @tokens = ();
  # index of first opening double quotes between parens - beginning of a new
  # token.
  my $begin_token = 0;
  # index of last closing double quotes between parens - end of a token.
  my $end_token = 0;
  # whether we are inside double quotes.
  my $inside_dquotes = 0;
  # whether we are inside double and then single quotes (for situations like
  # "'"'").
  my $inside_squotes = 0;
  my $len = length($token_string);
  # whether we found opening paren and we are expecting an opening double
  # quotes.
  my $near_begin = 0;
  # count of double quotes pairs between parens.
  my $dq_count = 0;
  # whether previous char was a backslash - important only when being between
  # double quotes.
  my $backslash = 0;
  for (my $index = 0; $index < $len; $index++)
  {
    my $char = substr($token_string, $index, 1);
    if ($inside_dquotes)
    {
      # if prevous char was backslash, then current char is not important -
      # we are still inside double or double/single quotes anyway.
      if ($backslash)
      {
        $backslash = 0;
      }
      # if current char is backslash.
      elsif ($char eq '\\')
      {
        $backslash = 1;
      }
      # if current char is unescaped double quotes and we are not inside single
      # ones - means, we are going outside string. We mark this place as an end
      # of the token in case we find a closing paren after this.
      elsif ($char eq '"' and not $inside_squotes)
      {
        $inside_dquotes = 0;
        $end_token = $index;
      }
      # if current char is single quote then switch being inside single quotes
      # state.
      elsif ($char eq '\'')
      {
        $inside_squotes = not $inside_squotes;
      }
    }
    # current char is opening paren - this means we are near the beginning of
    # a token (first double quotes after this paren).
    elsif ($char eq '(')
    {
      $near_begin = 1;
    }
    # current char is closing paren - this means we reached end of a token at
    # last closing double quotes.
    elsif ($char eq ')')
    {
      my $token_len = $end_token + 1 - $begin_token;
      my $token = substr($token_string, $begin_token, $token_len);
      # there should be three pairs of double quotes.
      if ($dq_count == 3)
      {
        push(@tokens, $token);
      }
      else
      {
        print STDERR "Wrong value statement while parsing ($token)\n";
      }
      $dq_count = 0;
    }
    # current char is opening double quotes - this can be a beginning of
    # a token.
    elsif ($char eq '"')
    {
      if ($near_begin)
      {
        $begin_token = $index;
        $near_begin = 0;
      }
      $inside_dquotes = 1;
      $dq_count++;
    }
  }
  return @tokens;
}

#
# end of private functions.
#

sub new
{
  my ($def) = @_;
  my $self = {};
  bless $self;

  $def =~ s/^\(//;
  $def =~ s/\)$//;

  $$self{mark}  = 0;
  $$self{flags} = 0;
  $$self{c_prefix} = "";

  $$self{elem_names}  = [];
  $$self{elem_values} = [];

  # snarf down the fields

  if($def =~ s/^define-(enum|flags)-extended (\S+)//)
  {
    $$self{type} = $2;
    $$self{flags} = 1 if($1 eq "flags");
  }

  $$self{module} = $1 if($def =~ s/\(in-module "(\S+)"\)//);
  $$self{c_type} = $1 if($def =~ s/\(c-name "(\S+)"\)//);

  # values are compound lisp statement
  if($def =~ s/\(values((?: '\("\S+" "\S+" "[^"]+"\))*) \)//)
  {
    $self->parse_values($1);
  }

  if($def !~ /^\s*$/)
  {
    GtkDefs::error("Unhandled enum def ($def) in $$self{module}\::$$self{type}\n")
  }

  # this should never happen
  warn if(scalar(@{$$self{elem_names}}) != scalar(@{$$self{elem_values}}));

  return $self;
}

sub parse_values($$)
{
  my ($self, $value) = @_;

  my $elem_names  = [];
  my $elem_values = [];
  my $common_prefix = undef;
  # break up the value statements - it works with parens inside double quotes
  # and handles triples like '("dq-token", "MY_SCANNER_DQ_TOKEN", "'"'").
  foreach (split_enum_tokens($value))
  {
    if (/^"\S+" "(\S+)" "(.+)"$/)
    {
      my ($name, $value) = ($1, $2);

      # detect whether there is module prefix common to all names, e.g. GTK_
      my $prefix = $1 if ($name =~ /^([^_]+_)/);

      if (not defined($common_prefix))
      {
        $common_prefix = $prefix;
      }
      elsif ($prefix ne $common_prefix)
      {
        $common_prefix = "";
      }

      push(@$elem_names, $name);
      push(@$elem_values, $value);
    }
    else
    {
      GtkDefs::error("Unknown value statement ($_) in $$self{c_type}\n");
    }
  }

  if ($common_prefix)
  {
    # cut off the module prefix, e.g. GTK_
    s/^$common_prefix// foreach (@$elem_names);

    # Save the common prefix.
    $$self{c_prefix}  = $common_prefix;
  }

  $$self{elem_names}  = $elem_names;
  $$self{elem_values} = $elem_values;
}

sub beautify_values($)
{
  my ($self) = @_;

  return if($$self{flags});

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  my $num_elements = scalar(@$elem_values);
  return if($num_elements == 0);

  my $first = $$elem_values[0];
  return if($first !~ /^-?[0-9]+$/);

  my $prev = $first;

  # Continuous?  (Aliases to prior enum values are allowed.)
  foreach my $value (@$elem_values)
  {
    return if ($value =~ /[G-WY-Zg-wy-z_]/);
    return if(($value < $first) || ($value > $prev + 1));
    $prev = $value;
  }

  # This point is reached only if the values are a continuous range.
  # 1) Let's kill all the superfluous values, for better readability.
  # 2) Substitute aliases to prior enum values.

  my %aliases = ();

  for(my $i = 0; $i < $num_elements; ++$i)
  {
    my $value = \$$elem_values[$i];
    my $alias = \$aliases{$$value};

    if(defined($$alias))
    {
      $$value = $$alias;
    }
    else
    {
      $$alias = $$elem_names[$i];
      $$value = "" unless($first != 0 && $$value == $first);
    }
  }
}

sub build_element_list($$$$)
{
  my ($self, $ref_flags, $ref_no_gtype, $indent) = @_;

  my @subst_in  = [];
  my @subst_out = [];

  # Build a list of custom substitutions, and recognize some flags too.

  foreach(@$ref_flags)
  {
    if(/^\s*(NO_GTYPE)\s*$/)
    {
      $$ref_no_gtype = $1;
    }
    elsif(/^\s*(get_type_func=)(\s*)\s*$/)
    {
      my $part1 = $1;
      my $part2 = $2;
    }
    elsif(/^\s*s#([^#]+)#([^#]*)#\s*$/)
    {
      push(@subst_in,  $1);
      push(@subst_out, $2);
    }
    elsif($_ !~ /^\s*(?:newin.*)?$/) # newin or only white space
    {
      return undef;
    }
  }

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  my $num_elements = scalar(@$elem_names);
  my $elements = "";

  for(my $i = 0; $i < $num_elements; ++$i)
  {
    my $name  = $$elem_names[$i];
    my $value = $$elem_values[$i];

    for(my $ii = 0; $ii < scalar(@subst_in); ++$ii)
    {
      $name  =~ s/${subst_in[$ii]}/${subst_out[$ii]}/;
      $value =~ s/${subst_in[$ii]}/${subst_out[$ii]}/;
    }

    # Skip this element, if its name has been deleted.
    next if($name eq "");

    $elements .= ",\n" if($elements ne "");
    $elements .= "${indent}${name}";
    $elements .= " = ${value}" if($value ne "");
  }

  return $elements;
}

sub dump($)
{
  my ($self) = @_;

  print "<enum module=\"$$self{module}\" type=\"$$self{type}\" flags=$$self{flags}>\n";

  my $elem_names  = $$self{elem_names};
  my $elem_values = $$self{elem_values};

  for(my $i = 0; $i < scalar(@$elem_names); ++$i)
  {
    print "  <element name=\"$$elem_names[$i]\"  value=\"$$elem_values[$i]\"/>\n";
  }

  print "</enum>\n\n";
}

1; # indicate proper module load.
