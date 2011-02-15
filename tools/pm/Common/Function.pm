package Common::Function;

use strict;
use warnings;
use Common::Util;
use parent qw (Base::Function);

my $gi_p_t = 'internal_param_types';
my $gi_p_n = 'internal_param_names';
my $gi_p_d_v = 'internal_param_default_values';

# parses C++ parameter lists.
# forms a list of types, names, and initial values
#  (we don't currently use values)
sub parse_params($$)
{
  my $line = shift;
  my $type = '';
  my $name = '';
  my $value = '';
  my $id = 0;
  my $has_value = 0;
  my $param_types = [];
  my $param_names = [];
  my $param_default_values = [];
  my $params_h_r =
  {
    $gi_p_t = $param_types,
    $gi_p_n = $param_names,
    $gi_p_d_v = $param_default_values
  };

  # clean up space and handle empty case
  $line = Util::string_simplify ($line);
  return $params_h_r if (not $line);

  # parse through argument list
  my @str = ();
  my $par = 0;
  for my $part (split(/(const )|([,=&*()])|(<[^,]*>)|(\s+)/, $line)) #special characters OR <something> OR whitespace.
  {
    next if (not defined ($part) or not $part);

    if ($part eq '(') #Detect the opening bracket.
    {
       push (@str, $part);
       ++$par; #Increment the number of parameters.
       next;
    }
    elsif ($part eq ')')
    {
       push (@str, $part);
       --$par; #Decrement the number of parameters.
       next;
    }
    # const std::vector<std::string>& (or const std::vector<int>*))
    elsif ($par or $part =~ /^(const )|(<[^,]*>)|([*&])|(\s+)/)
    {
      push (@str, $part); #This looks like part of the type, so we store it.
      next;
    }
    elsif ($part eq '=') #Default value
    {
      $type = join ('', @str); #The type is everything before the = character.
      @str = (); #Wipe it so that it will only contain the default value, which comes next.
      $has_value = 1;
      next;
    }
    elsif ($part eq ',') #The end of one parameter:
    {
      if ($has_value)
      {
        $value = join ('', @str); # If there's a default value, then it's the part before the next ",".
      }
      else
      {
        $type = join ('', @str);
      }

      unless ($name)
      {
        $name = sprintf ('p%s', @{$param_types} + 1)
      }

      $type = Util::string_trim ($type);

      push (@{$param_types}, $type);
      push (@{$param_names}, $name);
      push (@{$param_default_values}, $value);

      #Clear variables, ready for the next parameter.
      @str = ();
      $type= '';
      $value = '';
      $has_value = 0;
      $name = '';
      $id = 0;

      next;
    }

    if ($has_value)
    {
      push(@str, $_);
      next;
    }

    ++$id;
    $name = $part if ($id == 2);
    push (@str, $part) if ($id == 1);

    if ($id > 2)
    {
      print STDERR "Can't parse $line.\n";
      print STDERR "  arg type so far: $type\n";
      print STDERR "  arg name so far: $name\n";
      print STDERR "  arg default value so far: $value\n";
    }
  }

  # handle last argument  (There's no , at the end.)
  if ($has_value)
  {
    $value = join ('', @str);
  }
  else
  {
    $type = join ('', @str);
  }

  unless ($name)
  {
    $name = sprintf ('p%s', @{$param_types} + 1)
  }

  $type = Util::string_trim ($type);

  push (@{$param_types}, $type);
  push (@{$param_names}, $name);
  push (@{$param_default_values}, $value);

  return $params_h_r;
}


##################################################
### Function
# Commonly used algorithm for parsing a function declaration into
# its component pieces
#
#  class Function : FunctionBase
#    {
#       string ret_type;
#       bool ret_type_needs_ref;
#       bool const;
#       bool static;
#       string name; e.g. gtk_accelerator_valid
#       string c_name;
#       string array param_type;
#       string array param_name;
#       string array param_default_value;
#       string in_module; e.g. Gtk
#       string signal_when. e.g. first, last, or both.
#       string class e.g. GtkButton ( == of-object. Useful for signal because their names are not unique.
#       string entity_type. e.g. method or signal
#    }

my $g_r_t_n_r = 'ret_type_needs_ref';
my $g_c = 'const';
my $g_s = 'static';
my $g_p_d_v = 'param_default_values';
my $g_i_m = 'in_module';
my $g_s_w = 'signal_when'; # TODO: check if this is needed.
my $g_cl = 'class'; # TODO: check if this is needed.
my $g_e_t = 'entity_type' # TODO: check if this is needed. If so, move to new base class.

sub new ($)
{
  my $type = shift;
  my $class = ref ($type) or $type or "Function";
  my $self = $class->SUPER->new ();

  $self->{$g_r_t_n_r} = 0;
  $self->{$g_c} = 0;
  $self->{$g_s} = 0;
  $self->{$g_p_d_v} = [];
  $self->{$g_i_m} = '';
  $self->{$g_s_w} = '';
  $self->{$g_cl} = '';
  $self->{$g_e_t} = 'method';

  bless ($self, $class);
  return $self;
}

#sub new_empty()
#{
#  my $self = {};
#  bless $self;

#  return $self;
#}

# bool parse ($self, $declaration)
sub parse ($$)
{
  #Parse a function/method declaration.
  #e.g. guint gtk_something_set_thing(guint a, const gchar* something)

  my $self = shift;
  my $line = shift;

  $line Util::string_simplify ($line);

  my $ret_type = '';
  my $name = '';
  my $params = '';
  my $static = 0;
  my $const = 0;

  # static method
  if ($line =~ /^static\s+([^()]+)\s+(\S+)\s*\((.*)\)\s*$/)
  {
    $ret_type = $1;
    $name = $2;
    $params = $3;
    $static = 1;
  }
  # function, method or const method
  elsif ($line =~ /^([^()]+)\s+(\S+)\s*\((.*)\)\s*(const)*$/)
  {
    $ret_type = $1;
    $name = $2;
    $params = $3;
    $const = ((defined ($4) and $4 eq 'const') ? 1 : 0);
  }
  # constructor
  elsif ($line =~ /^(\S+)\s*\((.*)\)\s*/)
  {
    $name = $1;
    $params = $2;
  }
  else
  {
    return 0;
  }

  my $params_h_r = parse_params ($params);

  unless (keys (%{$params_h_r}))
  {
    return 0;
  }

  $self->set_ret_type ($ret_type);
  $self->set_name ($name);
  $self->set_c_name ($name);
  $self->set_param_types ($params_h_r->{$gi_p_t});
  $self->set_param_names ($params_h_r->{$gi_p_n});
  $self->{$g_p_d_v} = $params_h_r->{$gi_p_d_v};
  $self->{$g_s} = $static;
  $self->{$g_c} = $const;

  return 1;
}


## $objFunction new_ctor($function_declaration, $objWrapParser)
## Like new(), but the function_declaration doesn't need a return type.
#sub new_ctor($$)
#{
#  #Parse a function/method declaration.
#  #e.g. guint gtk_something_set_thing(guint a, const gchar* something)

#  my ($line, $objWrapParser) = @_;

#  my $self = {};
#  bless $self;

#  #Initialize member data:
#  $$self{rettype} = "";
#  $$self{rettype_needs_ref} = 0;
#  $$self{const} = 0;
#  $$self{name} = "";
#  $$self{param_types} = [];
#  $$self{param_names} = [];
#  $$self{param_default_values} = [];
#  $$self{in_module} = "";
#  $$self{class} = "";
#  $$self{entity_type} = "method";

#  $line =~ s/^\s+//;  # Remove leading whitespace.
#  $line =~ s/\s+/ /g; # Compress white space.

#  if ($line =~ /^(\S+)\s*\((.*)\)\s*/)
#  {
#    $$self{name} = $1;
#    $$self{c_name} = $2;
#    $self->parse_param($2);
#  }
#  else
#  {
#    $objWrapParser->error("fail to parse $line\n");
#  }

#  return $self;
#}

# $num num_args()
#sub num_args #($)
#{
#  my ($self) = @_;
#  my $param_types = $$self{param_types};
#  return $#$param_types+1;
#}

# add_parameter_autoname($, $type, $name)
# Adds e.g "sometype somename"
sub add_parameter_autoname ($$)
{
  my $self = shift;
  my $type = shift;

  $self->add_parameter ($type, '');
}

# add_parameter($, $type, $name)
# Adds e.g GtkSomething* p1"
sub add_parameter($$$)
{
  my $self = shift;
  my $type = shift;
  my $name = shift;

  $type = Util::string_unquote ($type);
  #const-char -> const char
  $type =~ s/-/ /g;

  my $param_names = $self->get_param_names ();

  unless ($name)
  {
    $name = sprintf ('p%s', @{$param_names} + 1);
  }

  push (@{$param_names}, $name);

  my $param_types = $self->get_param_types ();

  push(@{$param_types}, $type);
}

# $string get_refdoc_comment()
# Generate a readable prototype for signals.
sub get_refdoc_comment($)
{
  my $self = shift;
  my $str .= "  /**\n   * \@par Prototype:\n";

  $str .= join ('', '   * <tt>', $self->get_ret_type (), ' on_my_', $self->get_name (), '(');

  my $param_names = $self->get_param_names ();
  my $param_types = $self->get_param_types ();
  my $num_params  = @{$param_types};

  # List the parameters:
  for (my $i = 0; $i < @{$param_types}; ++$i)
  {
    $str .= $param_types->[$i] . ' ' . $param_names->[$i];
    $str .= ", " if ($i < $num_params - 1);
  }

  $str .= ")</tt>\n   */";

  return $str;
}

sub get_is_const($)
{
  my $self = shift;

  return $self->{$g_c};
}

1; # indicate proper module load.
