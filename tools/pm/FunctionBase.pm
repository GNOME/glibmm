package FunctionBase;

use strict;
use warnings;
use Util;

BEGIN {
     use Exporter   ();
     our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

     # set the version for version checking
     $VERSION     = 1.00;
     @ISA         = qw(Exporter);
     @EXPORT      = qw(&func1 &func2 &func4);
     %EXPORT_TAGS = ( );
     # your exported package globals go here,
     # as well as any optionally exported functions
     @EXPORT_OK   = qw($Var1 %Hashit &func3);
     }
our @EXPORT_OK;

##################################################
### FunctionBase
# Contains data and methods used by both Function (C++ declarations) and GtkDefs::Function (C defs descriptions)
# Note that GtkDefs::Signal inherits from GtkDefs::Function so it get these methods too.
#
#  class Function : FunctionBase
#    {
#       string array param_types;
#       string array param_names;
#       string array param_documentation;
#       string return_documention;
#    }


# $string args_types_only($)
# comma-delimited argument types.
sub args_types_only($)
{
  my ($self) = @_;

  my $param_types = $$self{param_types};
  return join(", ", @$param_types);
}

# $string args_names_only(int index = 0)
# Gets the args names.  The optional index specifies which argument
# list should be used out of the possible combination of arguments based on
# whether any arguments are optional.  index = 0 ==> all the names.
sub args_names_only($)
{
  my ($self, $index) = @_;

  $index = 0 unless defined($index);

  my $param_names = $$self{param_names};
  my $possible_args_list = $$self{possible_args_list};
  my @out;

  my @arg_indices;

  if(defined($possible_args_list))
  {
    @arg_indices = split(" ", @$possible_args_list[$index]);
  }
  else
  {
    @arg_indices = (0..@$param_names - 1);
  }

  for (my $i = 0; $i < @arg_indices; $i++)
  {
    push(@out, $$param_names[$arg_indices[$i]]);
  }
  return join(", ", @out);
}

# $string args_types_and_names(int index = 0)
# Gets the args types and names.  The optional index specifies which argument
# list should be used out of the possible combination of arguments based on
# whether any arguments are optional.  index = 0 ==> all the types and names.
sub args_types_and_names($)
{
  my ($self, $index) = @_;

  $index = 0 unless defined($index);

  my $i;

  my $param_names = $$self{param_names};
  my $param_types = $$self{param_types};
  my $possible_args_list = $$self{possible_args_list};
  my @out;

  #debugging:
  #if($#$param_types)
  #{
  #  return "NOARGS";
  #}

  my @arg_indices;

  if(defined($possible_args_list))
  {
    @arg_indices = split(" ", @$possible_args_list[$index]);
  }
  else
  {
    @arg_indices = (0..@$param_names - 1);
  }

  for ($i = 0; $i < @arg_indices; $i++)
  {
    my $str = sprintf("%s %s", $$param_types[$arg_indices[$i]],
      $$param_names[$arg_indices[$i]]);
    push(@out, $str);
  }

  my $result =  join(", ", @out);
  return $result;
}

# $string args_names_only_without_object($)
sub args_names_only_without_object2($)
{
  my ($self) = @_;

  my $param_names = $$self{param_names};

  my $result = "";
  my $bInclude = 0; #Ignore the first (object) arg.
  foreach (@{$param_names})
  {
    # Add comma if there was an arg before this one:
    if( $result ne "")
    {
      $result .= ", ";
    }

    # Append this arg if it's not the first one:
    if($bInclude)
    {
      $result .= $_;
    }

    $bInclude = 1;
  }

  return $result;
}

# $string args_types_and_names_without_object($)
sub args_types_and_names_without_object($)
{
  my ($self) = @_;

  my $param_names = $$self{param_names};
  my $param_types = $$self{param_types};
  my $i = 0;
  my @out;

  for ($i = 1; $i < $#$param_types + 1; $i++) #Ignore the first arg.
  {
    my $str = sprintf("%s %s", $$param_types[$i], $$param_names[$i]);
    push(@out, $str);
  }

  return join(", ", @out);
}

# $string args_names_only_without_object($)
sub args_names_only_without_object($)
{
  my ($self) = @_;

  my $param_names = $$self{param_names};

  my $result = "";
  my $bInclude = 0; #Ignore the first (object) arg.
  foreach (@{$param_names})
  {
    # Add comma if there was an arg before this one:
    if( $result ne "")
    {
      $result .= ", ";
    }

    # Append this arg if it's not the first one:
    if($bInclude)
    {
      $result .= $_;
    }

    $bInclude = 1;
  }

  return $result;
}

sub dump($)
{
  my ($self) = @_;

  my $param_types = $$self{param_types};
  my $param_names = $$self{param_names};

  print "<function>\n";
  foreach (keys %$self)
  {
    print "  <$_ value=\"$$self{$_}\"/>\n" if (!ref $$self{$_} && $$self{$_} ne "");
  }

  if (scalar(@$param_types)>0)
  {
    print "  <parameters>\n";

    for (my $i = 0; $i < scalar(@$param_types); $i++)
    {
      print "    \"$$param_types[$i]\" \"$$param_names[$i]\" \n";
    }

    print "  </parameters>\n";
  }

  print "</function>\n\n";
}

# $string args_types_and_names_with_default_values(int index = 0)
# Gets the args types and names with default values.  The optional index
# specifies which argument list should be used out of the possible
# combination of arguments based on whether any arguments are optional.
# index = 0 ==> all the types and names.
sub args_types_and_names_with_default_values($)
{
  my ($self, $index) = @_;

  $index = 0 unless defined $index;

  my $i;

  my $param_names = $$self{param_names};
  my $param_types = $$self{param_types};
  my $param_default_values = $$self{param_default_values};
  my $possible_args_list = $$self{possible_args_list};
  my @out;

  my @arg_indices;

  if(defined($possible_args_list))
  {
    @arg_indices = split(" ", @$possible_args_list[$index]);
  }
  else
  {
    @arg_indices = (0..@$param_names - 1);
  }

  for ($i = 0; $i < @arg_indices; $i++)
  {
    my $str = sprintf("%s %s", $$param_types[$arg_indices[$i]],
      $$param_names[$arg_indices[$i]]);


    if(defined($$param_default_values[$arg_indices[$i]]))
    {
      my $default_value = $$param_default_values[$arg_indices[$i]];

      if($default_value ne "")
      {
        $str .= " = " . $default_value;
      }
    }

    push(@out, $str);
  }

  return join(", ", @out);
}

# $string get_declaration(int index = 0)
# Gets the function declaration (this includes the default values of the
# args).  The optional index specifies which argument list should be used out
# of the possible combination of arguments based on whether any arguments are
# optional.  index = 0 ==> all the types and names.
sub get_declaration($)
{
  my ($self, $index) = @_;

  $index = 0 unless defined $index;
  my $out = "";

  $out = "static " if($$self{static});
  $out = $out . "$$self{rettype} " if($$self{rettype});
  $out = $out . $$self{name} . "(" .
    $self->args_types_and_names_with_default_values($index) . ")";
  $out = $out . " const" if $$self{const};
  $out = $out . ";";

  return $out;
}

# int get_num_possible_args_list();
# Returns the number of possible argument list based on whether some args are
# optional.
sub get_num_possible_args_list()
{
  my ($self) = @_;

  my $possible_args_list = $$self{possible_args_list};

  if(defined($possible_args_list))
  {
    return @$possible_args_list;
  }
  else
  {
    return 1;
  }
}

1; # indicate proper module load.

