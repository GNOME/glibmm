# Gtkmmproc Output module
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
package Output;
use strict;
use open IO => ":utf8";
use Function qw(FLAG_PARAM_OPTIONAL FLAG_PARAM_OUTPUT FLAG_PARAM_NULLPTR
                FLAG_PARAM_EMPTY_STRING);

use DocsParser;

BEGIN { @Namespace::ISA=qw(main); }

# $objOutputter new()
sub new
{
  my ($m4path, $macrodirs) = @_;
  my $self = {};
  bless $self;

  $$self{out} = [];

  $$self{source} = "";
  $$self{tmpdir} = File::Spec->tmpdir();
  $$self{destdir} = "";
  $$self{objDefsParser} = undef; # It will be set in set_defsparser()

  $$self{m4path} = $m4path;
  $$self{m4args} = "-I";
  $$self{m4args} .= join(" -I", @$macrodirs);

  return $self;
}

sub set_defsparser($$)
{
  my ($self, $objDefsParser) = @_;

  $$self{objDefsParser} = $objDefsParser; #Remember it so that we can use it in our output methods.
}

sub m4args_append($$)
{
  my ($self, $str) = @_;
  $$self{m4args} .= $str;
}

sub append($$)
{
  my ($self, $str) = @_;

  push(@{$$self{out}}, $str);
}

# void output_wrap_failed($cname, $error)
# Puts a comment in the header about the error during code-generation.
sub output_wrap_failed($$$)
{
  my ($self, $cname, $error) = @_;

  # See "MS Visual Studio" comment in gmmproc.in.
  my $str = sprintf("//gtkmmproc error: %s : %s", $cname, $error);
  print STDERR "Output.pm, $main::source, $cname : $error\n";
  $self->append($str);
}

sub error
{
  my $format=shift @_;
  printf STDERR "Output.pm, $main::source: $format",@_;
}

# void check_deprecation($file_deprecated, $defs_deprecated, $wrap_deprecated,
#   $entity_name, $entity_type, $wrapper)
sub check_deprecation($$$$$$)
{
  my ($file_deprecated, $defs_deprecated, $wrap_deprecated,
      $entity_name, $entity_type, $wrapper) = @_;

  # Don't print a warning if the whole .hg file is deprecated.
  return if ($file_deprecated);

  if ($defs_deprecated && !$wrap_deprecated)
  {
    print STDERR "Warning, $main::source: The $entity_name $entity_type" .
      " is deprecated in the .defs file, but not in _WRAP_$wrapper.\n";
  }
  # Uncomment the following lines some time in the future, when most
  # signal.defs files have been updated with deprecation information.
  # generate_extra_defs.cc was updated to generate this info soon after
  # glibmm 2.47.6.
  #elsif (!$defs_deprecated && $wrap_deprecated)
  #{
  #  print STDERR "Warning, $main::source: The $entity_name $entity_type" .
  #    " is deprecated in _WRAP_$wrapper, but not in the .defs file.\n";
  #}
}

sub ifdef($$)
{
	my ($self, $ifdef) = @_;
	if ($ifdef)
	{
		$self->append("\n#ifdef $ifdef\n");
	}
}

sub endif($$)
{
	my ($self, $ifdef) = @_;
	if ($ifdef)
	{
		$self->append("\n#endif // $ifdef\n");
	}
}

### Convert _WRAP to a virtual
# _VFUNC_H(signame,rettype,`<cppargs>')
# _VFUNC_PH(gtkname,crettype,cargs and names)
# void output_wrap_vfunc_h($filename, $line_num, $objCppfunc, $objCDefsFunc)
sub output_wrap_vfunc_h($$$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objCDefsFunc, $ifdef) = @_;

#Old code. We removed _VFUNC_H from the .m4 file
#  my $str = sprintf("_VFUNC_H(%s,%s,\`%s\',%s)dnl\n",
#    $$objCppfunc{name},
#    $$objCppfunc{rettype},
#    $objCppfunc->args_types_and_names(),
#    $objCppfunc->get_is_const()
#   );
#  $self->append($str);

  $self->ifdef($ifdef);

  # Prepend a Doxygen @throws directive to the declaration if the virtual
  # function throws an error.
  if($$objCDefsFunc{throw_any_errors})
  {
    $self->append('/// @throws Glib::Error.' . "\n");
  }

  my $cppVfuncDecl = "virtual " . $$objCppfunc{rettype} . " " . $$objCppfunc{name} . "(" . $objCppfunc->args_types_and_names() . ")";
  if($objCppfunc->get_is_const())
  {
    $cppVfuncDecl .= " const";
  }

  $self->append("  $cppVfuncDecl;\n");
  $self->endif($ifdef);

  #The default callback, which will call *_vfunc, which will then call the base default callback.
  #Declares the callback in the private *Class class and sets it in the class_init function.

  my $str = sprintf("_VFUNC_PH(%s,%s,\`%s\',%s)dnl\n",
    $$objCDefsFunc{name},
    $$objCDefsFunc{rettype},
    $objCDefsFunc->args_types_and_names(),
    $ifdef
   );
  $self->append($str);
}

# _VFUNC_CC(signame,gtkname,rettype,crettype,`<cppargs>',`<cargs>')
sub output_wrap_vfunc_cc($$$$$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objCFunc,
      $custom_vfunc, $custom_vfunc_callback, $ifdef) = @_;

  my $cname = $$objCFunc{name};

  my $errthrow = "";
  if($$objCFunc{throw_any_errors})
  {
    $errthrow = "errthrow"
  }

  # e.g. Gtk::Button::draw_indicator:

  #Use a different macro for Interfaces, to generate an extra convenience method.

  if (!$custom_vfunc)
  {
    my $refreturn = "";
    $refreturn = "refreturn" if($$objCppfunc{rettype_needs_ref});
    my $returnValue = $$objCppfunc{return_value};

    my ($conversions, $declarations, $initializations) =
      convert_args_cpp_to_c($objCppfunc, $objCFunc, 0, $line_num, $errthrow);

    my $no_slot_copy = "";
    $no_slot_copy = "no_slot_copy" if ($$objCppfunc{no_slot_copy});

    my $str = sprintf("_VFUNC_CC(%s,%s,%s,%s,\`%s\',\`%s\',%s,%s,%s,%s,%s,%s,%s,%s)dnl\n",
      $$objCppfunc{name},
      $cname,
      $$objCppfunc{rettype},
      $$objCFunc{rettype},
      $objCppfunc->args_types_and_names(),
      $conversions,
      $objCppfunc->get_is_const(),
      $refreturn,
      $ifdef,
      $errthrow,
      $$objCppfunc{slot_type},
      $$objCppfunc{slot_name},
      $no_slot_copy,
      $returnValue);

    $self->append($str);
  }

  # e.g. Gtk::ButtonClass::draw_indicator():

  if (!$custom_vfunc_callback)
  {
    my $refreturn_ctype = "";
    $refreturn_ctype = "refreturn_ctype" if($$objCFunc{rettype_needs_ref});

    my $keep_return = "";
    $keep_return = "keep_return" if($$objCppfunc{keep_return});

    # Get the conversions.
    my $conversions =
     convert_args_c_to_cpp($objCFunc, $objCppfunc, $line_num);

    my $returnValue = $$objCppfunc{return_value};
    my $exceptionHandler = $$objCppfunc{exception_handler};

    my $str = sprintf("_VFUNC_PCC(%s,%s,%s,%s,\`%s\',\`%s\',\`%s\',%s,%s,%s,%s,%s,%s,%s,%s,%s)dnl\n",
      $$objCppfunc{name},
      $cname,
      $$objCppfunc{rettype},
      $$objCFunc{rettype},
      $objCFunc->args_types_and_names(),
      $objCFunc->args_names_only(),
      $conversions,
      ${$objCFunc->get_param_names()}[0],
      $refreturn_ctype,
      $keep_return,
      $ifdef,
      $errthrow,
      $$objCppfunc{slot_type},
      $$objCppfunc{c_data_param_name},
      $returnValue,
      $exceptionHandler);

    $self->append($str);
  }
}

### Convert _WRAP to a signal
# _SIGNAL_H(signame,rettype, `<cppargs>', ifdef)
# _SIGNAL_PH(gtkname,crettype, cargs and names, ifdef, deprecated)
# void output_wrap_default_signal_handler_h($filename, $line_num, $objCppfunc,
#      $objCDefsFunc, $ifdef, $deprecated, $exceptionHandler)
sub output_wrap_default_signal_handler_h($$$$$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objCDefsFunc, $ifdef, $deprecated, $exceptionHandler) = @_;

  # The default signal handler is a virtual function.
  # It's not hidden by deprecation, since that would break ABI.
  my $str = sprintf("_SIGNAL_H(%s,%s,\`%s\',%s)dnl\n",
    $$objCppfunc{name},
    $$objCppfunc{rettype},
    $objCppfunc->args_types_and_names(),
    $ifdef
   );
  $self->append($str);


  #The default callback, which will call on_* or the base default callback.
  #Declares the callback in the private *Class class and sets it in the class_init function.
  #This is hidden by deprecation.
  $str = sprintf("_SIGNAL_PH(%s,%s,\`%s\',%s,%s,%s)dnl\n",
    $$objCDefsFunc{name},
    $$objCDefsFunc{rettype},
    $objCDefsFunc->args_types_and_names(),
    $ifdef,
    $deprecated,
    $exceptionHandler
   );
  $self->append($str);
}

# _SIGNAL_CC(signame, gtkname, rettype, crettype,`<cppargs>',`<cargs>', const, refreturn, ifdef, exceptionHandler)
sub output_wrap_default_signal_handler_cc($$$$$$$$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objDefsSignal, $bImplement,
      $bCustomCCallback, $bRefreturn, $ifdef, $deprecated, $exceptionHandler) = @_;

  my $cname = $$objDefsSignal{name};
  # $cname = $1 if ($args[3] =~ /"(.*)"/); #TODO: What's this about?

  # e.g. Gtk::Button::on_clicked:
  if($bImplement eq 1)
  {
    my $refreturn = "";
    $refreturn = "refreturn" if($bRefreturn eq 1);

    my ($conversions, $declarations, $initializations) =
      convert_args_cpp_to_c($objCppfunc, $objDefsSignal, 0, $line_num);

    # The default signal handler is a virtual function.
    # It's not hidden by deprecation, since that would break ABI.
    my $str = sprintf("_SIGNAL_CC(%s,%s,%s,%s,\`%s\',\`%s\',%s,%s,%s)dnl\n",
      $$objCppfunc{name},
      $cname,
      $$objCppfunc{rettype},
      $$objDefsSignal{rettype},
      $objCppfunc->args_types_and_names(),
      $conversions,
      $$objCppfunc{const},
      $refreturn,
      $ifdef
      );
    $self->append($str);
  }


  # e.g. Gtk::ButtonClass::on_clicked():

  #Callbacks always take the object instance as the first argument:
#  my $arglist_names = "object";
#  my $arglist_names_extra = $objDefsSignal->args_names_only();
#  if ($arglist_names_extra)
#  {
#    $arglist_names .= ", ";
#    $arglist_names .= $arglist_names_extra;
#  }

  if($bCustomCCallback ne 1)
  {
    my $conversions =
      convert_args_c_to_cpp($objDefsSignal, $objCppfunc, $line_num);

    #This is hidden by deprecation.
    my $str = sprintf("_SIGNAL_PCC(%s,%s,%s,%s,\`%s\',\`%s\',\`%s\',\`%s\',%s,%s,%s)dnl\n",
      $$objCppfunc{name},
      $cname,
      $$objCppfunc{rettype},
      $$objDefsSignal{rettype},
      $objDefsSignal->args_types_and_names(),
      $objDefsSignal->args_names_only(),
      $conversions,
      ${$objDefsSignal->get_param_names()}[0],
      $ifdef,
      $deprecated,
      $exceptionHandler);
    $self->append($str);
  }
}

### Convert _WRAP to a method
#  _METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,const)
#  void output_wrap_meth($filename, $line_num, $objCppFunc, $objCDefsFunc, $cppMethodDecl, $documentation, $ifdef)
sub output_wrap_meth($$$$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objCDefsFunc, $cppMethodDecl, $documentation, $ifdef) = @_;
  my $objDefsParser = $$self{objDefsParser};

  my $cpp_param_names = $$objCppfunc{param_names};
  my $cpp_param_types = $$objCppfunc{param_types};
  my $c_param_name_mappings = $$objCppfunc{param_mappings};

  my $num_args_list = $objCppfunc->get_num_possible_args_list();

  my $output_var_name;
  my $output_var_type;

  if(defined($$c_param_name_mappings{"OUT"}))
  {
    $output_var_name = $$cpp_param_names[$$c_param_name_mappings{"OUT"}];
    $output_var_type = $$cpp_param_types[$$c_param_name_mappings{"OUT"}];
  }

  for(my $arg_list = 0; $arg_list < $num_args_list; $arg_list++)
  {
    # Allow the generated .h/.cc code to have an #ifndef around it, and add
    # deprecation docs to the generated documentation.
    my $deprecated = "";
    if($$objCDefsFunc{deprecated})
    {
      $deprecated = "deprecated";
    }

    #Declaration:
    if($deprecated ne "")
    {
      $self->append("\n_DEPRECATE_IFDEF_START");
    }

    $self->ifdef($ifdef);

    if($arg_list == 0)
    {
      # Doxygen documentation before the method declaration:
      $self->output_wrap_meth_docs_only($filename, $line_num, $documentation);
    }
    else
    {
      $self->append("\n\n  /// A $$objCppfunc{name}() convenience overload.\n");
    }

    $self->append("  " . $objCppfunc->get_declaration($arg_list));

    $self->endif($ifdef);

    if($deprecated ne "")
    {
      $self->append("\n_DEPRECATE_IFDEF_END\n");
    }

    my $refneeded = "";
    if($$objCDefsFunc{rettype_needs_ref})
    {
      $refneeded = "refreturn"
    }

    my $errthrow = "";
    if($$objCDefsFunc{throw_any_errors})
    {
      $errthrow = "errthrow"
    }

    my $constversion = ""; #Whether it is just a const overload (so it can reuse code)
    if($$objCDefsFunc{constversion})
    {
      $constversion = "constversion"
    }

    #Implementation:
    my $str;
    if ($$objCppfunc{static}) {
      my ($conversions, $declarations, $initializations) =
        convert_args_cpp_to_c($objCppfunc, $objCDefsFunc, 1, $line_num,
        $errthrow, $arg_list); #1 means it's static, so it has 'object'.

      my $no_slot_copy = "";
      my $slot_type = "";
      my $slot_name = "";

      # A slot may be optional so if it is signaled by
      # convert_args_cpp_to_c() to not be included, then don't.
      if ($$objCppfunc{include_slot})
      {
        $slot_type = $$objCppfunc{slot_type};
        $slot_name = $$objCppfunc{slot_name};
        $no_slot_copy = "no_slot_copy" if ($$objCppfunc{no_slot_copy});
      }

      $str = sprintf("_STATIC_METHOD(%s,%s,\`%s\',%s,\`%s\',\`%s\',\`%s\',\`%s\',%s,%s,%s,%s,%s,%s,`%s',`%s',`%s',%s)dnl\n",
        $$objCppfunc{name},
        $$objCDefsFunc{c_name},
        $$objCppfunc{rettype},
        $objCDefsFunc->get_return_type_for_methods(),
        $objCppfunc->args_types_and_names($arg_list),
        $declarations,
        $conversions,
        $initializations,
        $refneeded,
        $errthrow,
        $deprecated,
        $ifdef,
        $output_var_name,
        $output_var_type,
        $slot_type,
        $slot_name,
        $no_slot_copy,
        $line_num
        );
    } else {
      my ($conversions, $declarations, $initializations) =
        convert_args_cpp_to_c($objCppfunc, $objCDefsFunc, 0, $line_num,
        $errthrow, $arg_list);

      my $no_slot_copy = "";
      my $slot_type = "";
      my $slot_name = "";

      # A slot may be optional so if it is signaled by
      # convert_args_cpp_to_c() to not be included, then don't.
      if ($$objCppfunc{include_slot})
      {
        $slot_type = $$objCppfunc{slot_type};
        $slot_name = $$objCppfunc{slot_name};
        $no_slot_copy = "no_slot_copy" if ($$objCppfunc{no_slot_copy});
      }

      $str = sprintf("_METHOD(%s,%s,\`%s\',%s,\`%s\',\`%s\',\`%s\',\`%s\',%s,%s,%s,%s,%s,\`%s\',%s,%s,%s,`%s',`%s',`%s',%s)dnl\n",
        $$objCppfunc{name},
        $$objCDefsFunc{c_name},
        $$objCppfunc{rettype},
        $objCDefsFunc->get_return_type_for_methods(),
        $objCppfunc->args_types_and_names($arg_list),
        $declarations,
        $conversions,
        $initializations,
        $$objCppfunc{const},
        $refneeded,
        $errthrow,
        $deprecated,
        $constversion,
        $objCppfunc->args_names_only($arg_list),
        $ifdef,
        $output_var_name,
        $output_var_type,
        $slot_type,
        $slot_name,
        $no_slot_copy,
        $line_num
        );
    }
    $self->append($str);
  }
}

### Convert _WRAP to a method
#  _METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,const)
#  void output_wrap_meth($filename, $line_num, $documentation)
sub output_wrap_meth_docs_only($$$$)
{
  my ($self, $filename, $line_num, $documentation) = @_;
  my $objDefsParser = $$self{objDefsParser};

  # Doxygen documentation before the method declaration:
  $self->append("\n${documentation}");
}

### Convert _WRAP_CTOR to a ctor
#  _METHOD(cppname,cname,cpprettype,crettype,arglist,cargs,const)
#  void output_wrap_ctor($filename, $line_num, $objCppFunc, $objCDefsFunc, $cppMethodDecl)
sub output_wrap_ctor($$$$$)
{
  my ($self, $filename, $line_num, $objCppfunc, $objCDefsFunc, $cppMethodDecl) = @_;
  my $objDefsParser = $$self{objDefsParser};

  my $num_args_list = $objCppfunc->get_num_possible_args_list();

  for(my $arg_list = 0; $arg_list < $num_args_list; $arg_list++)
  {
    if ($arg_list > 0)
    {
      $self->append("\n\n  /// A $$objCppfunc{name}() convenience overload.\n");
    }

    #Ctor Declaration:
    #TODO: Add explicit.
    $self->append("  explicit " . $objCppfunc->get_declaration($arg_list) . "\n");

    my $errthrow = "";
    if($$objCDefsFunc{throw_any_errors})
    {
      $errthrow = "errthrow";
    }

    #Implementation:
    my $str = sprintf("_CTOR_IMPL(%s,%s,\`%s\',\`%s\')dnl\n",
      $$objCppfunc{name},
      $$objCDefsFunc{c_name},
      $objCppfunc->args_types_and_names($arg_list),
      get_ctor_properties($objCppfunc, $objCDefsFunc, $line_num, $errthrow, $arg_list)
    );

    $self->append($str);
  }
}

sub output_wrap_create($$$)
{
  my ($self, $args_type_and_name_with_default_values, $objWrapParser) = @_;

  #Re-use Function in a very hacky way, to separate the argument types_and_names.
  my $fake_decl = "void fake_func(" . $args_type_and_name_with_default_values . ")";

  my $objFunction = &Function::new($fake_decl, $objWrapParser);

  my $num_args_list = $objFunction->get_num_possible_args_list();

  for(my $arg_list = 0; $arg_list < $num_args_list; $arg_list++)
  {
    my $args_names_only = $objFunction->args_names_only($arg_list);
    my $args_type_and_name_hpp =
      $objFunction->args_types_and_names_with_default_values($arg_list);
    my $args_type_and_name_cpp = $objFunction->args_types_and_names($arg_list);

    if ($arg_list > 0) {
      $self->append("\n  /// A create() convenience overload.");
    }

    my $str = sprintf("_CREATE_METHOD(\`%s\',\`%s\',\`%s\')dnl\n",
                $args_type_and_name_hpp, , $args_type_and_name_cpp, $args_names_only);

    $self->append($str)
  }
}

# void output_wrap_sig_decl($filename, $line_num, $objCSignal, $objCppfunc, $signal_name,
#   $bCustomCCallback, $ifdef, $commentblock, $deprecated, $deprecation_docs,
#   $newin, $exceptionHandler, $detail_name, $bTwoSignalMethods)
sub output_wrap_sig_decl($$$$$$$$$$$$$$)
{
  my ($self, $filename, $line_num, $objCSignal, $objCppfunc, $signal_name,
      $bCustomCCallback, $ifdef, $commentblock, $deprecated, $deprecation_docs,
      $newin, $exceptionHandler, $detail_name, $bTwoSignalMethods) = @_;

# _SIGNAL_PROXY(c_signal_name, c_return_type, `<c_arg_types_and_names>',
#               cpp_signal_name, cpp_return_type, `<cpp_arg_types>',`<c_args_to_cpp>',
#               refdoc_comment, exceptionHandler)

  # Get the signal name with underscores only (to look up docs -- they are
  # stored that way).
  my $underscored_signal_name = $signal_name;
  $underscored_signal_name =~ s/-/_/g;

  # Get the existing signal documentation from the parsed docs.
  my $documentation = DocsParser::lookup_documentation(
    "$$objCSignal{class}::$underscored_signal_name", $deprecation_docs, $newin, $objCppfunc);

  # Create a merged Doxygen comment block for the signal from the looked up
  # docs (the block will also contain a prototype of the slot as an example).
  my $doxycomment = $objCppfunc->get_refdoc_comment($documentation);

  # If there was already a previous doxygen comment, we want to merge this
  # one with the previous so it is one big comment. If
  # $commentblock is not emtpy, it contains the previous doxygen comment without
  # opening and closing tokens (/** and */).
  if($commentblock ne "")
  {
    # Strip leading whitespace
    $doxycomment =~ s/^\s+//;
    # Add a level of m4 quotes. Necessary if $commentblock contains __FT__ or __BT__.
    # DocsParser::lookup_documentation() adds it in $documentation.
    $commentblock = "`" . $commentblock . "'";

    # We don't have something to add, so just use $commentblock with
    # opening and closing tokens added.
    if($doxycomment eq "")
    {
      $doxycomment = '  /**' . $commentblock . "\n   */";
    }
    else
    {
      # Merge the two comments, but remove the first three characters from the
      # second comment (/**) that mark the beginning of the comment.
      $doxycomment = substr($doxycomment, 3);
      $doxycomment =~ s/^\s+//;
      $doxycomment = '  /**' . $commentblock . "\n   *\n   " . $doxycomment;
    }
  }

  my $conversions =
    convert_args_c_to_cpp($objCSignal, $objCppfunc, $line_num);

  my $str = sprintf("_SIGNAL_PROXY(%s,%s,\`%s\',%s,%s,\`%s\',\`%s\',\`%s\',%s,\`%s\',%s,%s,%s,%s)dnl\n",
    $signal_name,
    $$objCSignal{rettype},
    $objCSignal->args_types_and_names_without_object(),
    $$objCppfunc{name},
    $$objCppfunc{rettype},
    $objCppfunc->args_types_only(),
    $conversions,
    $bCustomCCallback, #When this is true, it will not write the *_callback implementation for you.
    $deprecated,
    $doxycomment,
    $ifdef,
    $exceptionHandler,
    $detail_name, # If a detailed name is supported (signal_name::detail_name)
    $bTwoSignalMethods # If separate signal_xxx() methods for detailed and general name.
  );

  $self->append($str);
}

# void output_wrap_enum($filename, $line_num, $cpp_type, $c_type, $comment, @flags)
sub output_wrap_enum($$$$$$$)
{
  my ($self, $filename, $line_num, $cpp_type, $c_type, $comment, @flags) = @_;

  my $objEnum = GtkDefs::lookup_enum($c_type);
  if(!$objEnum)
  {
    $self->output_wrap_failed($c_type, "enum defs lookup failed.");
    return;
  }

  $objEnum->beautify_values();

  my $no_gtype = "";
  my $elements = $objEnum->build_element_list(\@flags, \$no_gtype, "  ");

  if(!$elements)
  {
    $self->output_wrap_failed($c_type, "unknown _WRAP_ENUM() flag");
    return;
  }

  my $value_suffix = "Enum";
  $value_suffix = "Flags" if($$objEnum{flags});

  # Get the enum documentation from the parsed docs.
  my $enum_docs =
    DocsParser::lookup_enum_documentation("$c_type", "$cpp_type", " ", \@flags);

  # Merge the passed in comment to the existing enum documentation.
  $comment .= "\n * " . $enum_docs if $enum_docs ne "";

  my $str = sprintf("_ENUM(%s,%s,%s,\`%s\',\`%s\',\`%s\')dnl\n",
    $cpp_type,
    $c_type,
    $value_suffix,
    $elements,
    $no_gtype,
    $comment
  );

  $self->append($str);
}

sub output_wrap_enum_docs_only($$$$$$$)
{
  my ($self, $filename, $line_num, $module_canonical, $cpp_type, $c_type,
      $comment, @flags) = @_;
 
  # Get the existing enum description from the parsed docs.
  my $enum_docs =
    DocsParser::lookup_enum_documentation("$c_type", "$cpp_type", " ", \@flags);

  if($enum_docs eq "")
  {
    $self->output_wrap_failed($c_type, "failed to find documentation.");
    return;
  }

  # Include the enum docs in the module's enum docs group.
  $enum_docs .= "\n *\n * \@ingroup ${module_canonical}Enums";

  # Merge the passed in comment to the existing enum documentation.
  $comment = "/** " . $comment . "\n * " . $enum_docs . "\n */\n";

  $self->append($comment);
}

# void output_wrap_gerror($filename, $line_num, $cpp_type, $c_enum, $domain, @flags)
sub output_wrap_gerror($$$$$$$)
{
  my ($self, $filename, $line_num, $cpp_type, $c_enum, $domain, @flags) = @_;

  my $objDefsParser = $$self{objDefsParser};

  my $objEnum = GtkDefs::lookup_enum($c_enum);
  if(!$objEnum)
  {
    $self->output_wrap_failed($c_enum, "enum defs lookup failed.");
    return;
  }

  # Shouldn't happen, and if it does, I'd like to know that.
  warn if($$objEnum{flags});

  $objEnum->beautify_values();

  # cut off the module prefix, e.g. GDK_
  my $prefix = $domain;
  $prefix =~ s/^[^_]+_//;

  # Chop off the domain prefix, because we put the enum into the class.
  unshift(@flags, "s#^${prefix}_##");

  my $no_gtype = "";
  my $elements = $objEnum->build_element_list(\@flags, \$no_gtype, "    ");

  # Get the enum documentation from the parsed docs.
  my $enum_docs =
    DocsParser::lookup_enum_documentation("$c_enum", "Code", "   ", \@flags);

  # Prevent Doxygen from auto-linking to a class called Error.
  $enum_docs =~ s/([^%])(Error code)/$1%$2/g;

  my $str = sprintf("_GERROR(%s,%s,%s,\`%s\',%s,\`%s\')dnl\n",
    $cpp_type,
    $c_enum,
    $domain,
    $elements,
    $no_gtype,
    $enum_docs
  );

  $self->append($str);
}

# _PROPERTY_PROXY(name, cpp_type) and _CHILD_PROPERTY_PROXY(name, cpp_type)
# void output_wrap_any_property($filename, $line_num, $name, $cpp_type, $c_class, $deprecated, $deprecation_docs, $objProperty, $proxy_macro)
sub output_wrap_any_property($$$$$$$$$$)
{
  my ($self, $filename, $line_num, $name, $cpp_type, $c_class, $deprecated,
      $deprecation_docs, $newin, $objProperty, $proxy_macro) = @_;

  my $objDefsParser = $$self{objDefsParser};

  # We use a suffix to specify a particular Glib::PropertyProxy* class.
  my $proxy_suffix = "";

  # Read/Write:
  if($objProperty->get_construct_only() eq 1)
  {
    # construct-only functions can be read, but not written.
    $proxy_suffix = "_ReadOnly";

    if($objProperty->get_readable() ne 1)
    {
      $self->output_wrap_failed($name, "attempt to wrap write-only and construct-only property.");
      return;
    }
  }
  elsif($objProperty->get_readable() ne 1)
  {
    $proxy_suffix = "_WriteOnly";
  }
  elsif($objProperty->get_writable() ne 1)
  {
    $proxy_suffix = "_ReadOnly";
  }

  # Convert - to _ so we can use it in C++ method and variable names:
  my $name_underscored = $name;
  $name_underscored =~ tr/-/_/;

  # Get the existing property documentation, if any, from the parsed docs.
  my $documentation = DocsParser::lookup_documentation(
    "$$objProperty{class}:$name_underscored", $deprecation_docs, $newin);

  if ($documentation ne "")
  {
    # Remove leading "/**" and trailing "*/". They will be added by the m4 macro.
    $documentation =~ s/^\s*\/\*\*\s*//;
    $documentation =~ s/\s*\*\/\s*$//;
  }

  if ($documentation =~ /^`?[*\s]*
      (?:
        \@newin\{[\d,]+\}
        |[Ss]ince[:\h]+\d+\.\d+
        |\@deprecated\s
        |[Dd]eprecated[:\s]
      )/x)
  {
    # The documentation begins with a "@newin", "Since", "@deprecated" or
    # "Deprecated" line. Get documentation also from the Property object,
    # but don't add another @newin or @deprecated.
    my $objdoc = $objProperty->get_docs("", "");
    if ($objdoc ne "")
    {
      add_m4_quotes(\$objdoc);
      $documentation = "$objdoc\n   *\n   * $documentation";
    }
  }
  elsif ($documentation eq "")
  {
    # Try to get the (usually short) documentation from the Property object.
    $documentation = $objProperty->get_docs($deprecation_docs, $newin);
    if ($documentation ne "")
    {
      add_m4_quotes(\$documentation);
    }
  }

  #Declaration:
  if($deprecated ne "")
  {
    $self->append("\n_DEPRECATE_IFDEF_START\n");
  }

  my $str = sprintf("$proxy_macro(%s,%s,%s,%s,%s,`%s')dnl\n",
    $name,
    $name_underscored,
    $cpp_type,
    $proxy_suffix,
    $deprecated,
    $documentation
  );
  $self->append($str);
  $self->append("\n");

  # If the property is not already read-only, and the property can be read,
  # then add a second const accessor for a read-only propertyproxy:
  if( ($proxy_suffix ne "_ReadOnly") && ($objProperty->get_readable()) )
  {
    my $str = sprintf("$proxy_macro(%s,%s,%s,%s,%s,`%s')dnl\n",
      $name,
      $name_underscored,
      $cpp_type,
      "_ReadOnly",
      $deprecated,
      $documentation
    );
    $self->append($str);
  }

  if($deprecated ne "")
  {
    $self->append("\n_DEPRECATE_IFDEF_END");
  }
}

# _PROPERTY_PROXY(name, cpp_type)
# void output_wrap_property($filename, $line_num, $name, $cpp_type, $file_deprecated,
#   $deprecated, $deprecation_docs)
sub output_wrap_property($$$$$$$$$$)
{
  my ($self, $filename, $line_num, $name, $cpp_type, $c_class, $file_deprecated,
      $deprecated, $deprecation_docs, $newin) = @_;

  my $objProperty = GtkDefs::lookup_property($c_class, $name);
  if($objProperty eq 0) #If the lookup failed:
  {
    $self->output_wrap_failed($name, "property defs lookup failed.");
  }
  else
  {
    Output::check_deprecation($file_deprecated, $objProperty->get_deprecated(),
      $deprecated, $name, "property", "PROPERTY");

    $self->output_wrap_any_property($filename, $line_num, $name, $cpp_type, $c_class,
      $deprecated, $deprecation_docs, $newin, $objProperty, "_PROPERTY_PROXY");
  }
}

# _CHILD_PROPERTY_PROXY(name, cpp_type)
# void output_wrap_child_property($filename, $line_num, $name, $cpp_type, $file_deprecated,
#   $deprecated, $deprecation_docs)
sub output_wrap_child_property($$$$$$$$$$)
{
  my ($self, $filename, $line_num, $name, $cpp_type, $c_class, $file_deprecated,
      $deprecated, $deprecation_docs, $newin) = @_;

  my $objChildProperty = GtkDefs::lookup_child_property($c_class, $name);
  if($objChildProperty eq 0) #If the lookup failed:
  {
    $self->output_wrap_failed($name, "child property defs lookup failed.");
  }
  else
  {
    Output::check_deprecation($file_deprecated, $objChildProperty->get_deprecated(),
      $deprecated, $name, "child property", "CHILD_PROPERTY");

    $self->output_wrap_any_property($filename, $line_num, $name, $cpp_type, $c_class,
      $deprecated, $deprecation_docs, $newin, $objChildProperty, "_CHILD_PROPERTY_PROXY");
  }
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

# void output_temp_g1($module, $glibmm_version) e.g. output_temp_g1(gtkmm, 2.38.0)
sub output_temp_g1($$$)
{
  my ($self, $module, $glibmm_version) = @_;

  # Write out *.g1 temporary file
  open(FILE, '>', "$$self{tmpdir}/gtkmmproc_$$.g1");  # $$ is the Process ID

  print FILE "include(base.m4)dnl\n";

  my $module_canonical = Util::string_canonical($module); #In case there is a / character in the module.
  print FILE "_START($$self{source},$module,$module_canonical,$glibmm_version)dnl\n";
  print FILE join("", @{$$self{out}});
  print FILE "_END()\n";
  close(FILE);
}

sub make_g2_from_g1($)
{
  my ($self) = @_;

  # Execute m4 to get *.g2 file:
  system("$$self{m4path} $$self{m4args} \"$$self{tmpdir}/gtkmmproc_$$.g1\" > \"$$self{tmpdir}/gtkmmproc_$$.g2\"");
  return ($? >> 8);
}

# void write_sections_to_files()
# This is where we snip the /tmp/gtkmmproc*.g2 file into sections (,h, .cc, _private.h)
sub write_sections_to_files()
{
  my ($self) = @_;

  my $fname_h  = "$$self{destdir}/$$self{source}.h";
  my $fname_ph = "$$self{destdir}/private/$$self{source}_p.h";
  my $fname_cc = "$$self{destdir}/$$self{source}.cc";

  open(INPUT, '<', "$$self{tmpdir}/gtkmmproc_$$.g2"); # $$ is the process ID.

  # open temporary file for each section
  open(OUTPUT_H,  '>', "$fname_h.tmp");
  open(OUTPUT_PH, '>', "$fname_ph.tmp");
  open(OUTPUT_CC, '>', "$fname_cc.tmp");

  my $oldfh = select(OUTPUT_H);
  my $blank = 0;

  while(<INPUT>)
  {
    # section switching
    if(/^#S 0/) { select(OUTPUT_H);  next; }
    if(/^#S 1/) { select(OUTPUT_PH); next; }
    if(/^#S 2/) { select(OUTPUT_CC); next; }

    # get rid of bogus blank lines
    if(/^\s*$/) { ++$blank; } else { $blank = 0; }
    next if($blank > 2);

    print $_;
  }

  select($oldfh);
  close(INPUT);
  close(OUTPUT_H);
  close(OUTPUT_PH);
  close(OUTPUT_CC);

  foreach($fname_h, $fname_ph, $fname_cc)
  {
    # overwrite the source file only if it has actually changed

    # Win32 does fail at this, so we do the two steps separately:
    #system("cmp -s '$_.tmp' '$_' || cp '$_.tmp' '$_'" ; rm -f '$_.tmp');

    system("cmp -s '$_.tmp' '$_' || cp '$_.tmp' '$_'");
    system("rm -f '$_.tmp'");
  }
}


sub remove_temp_files($)
{
  my ($self) = @_;

  system("rm -f \"$$self{tmpdir}/gtkmmproc_$$.g1\"");
  system("rm -f \"$$self{tmpdir}/gtkmmproc_$$.g2\"");
}



# procedure for generating CONVERT macros, C declarations (for C output
# variables), and INITIALIZE macros (to set the corresponding C++ parameters
# from the C output parameters) for the specified argument list
# (string, string, string) convert_args_cpp_to_c($objCppfunc, $objCDefsFunc, $static, $wrap_line_number,$automatic_error, $index = 0)
# The return is an array of 3 strings: The _CONVERT macros, the C declarations
# and the _INITIALIZE macros.
# The optional index specifies which arg list out of the possible combination
# of arguments based on whether any arguments are optional. index = 0 ==> all
# the arguments.
sub convert_args_cpp_to_c($$$$$)
{
  my ($objCppfunc, $objCDefsFunc, $static, $wrap_line_number, $automatic_error, $index) = @_;

  $automatic_error = "" unless defined $automatic_error;
  $index = 0 unless defined $index;

  my $cpp_param_names = $$objCppfunc{param_names};
  my $cpp_param_types = $$objCppfunc{param_types};
  my $cpp_param_flags = $$objCppfunc{param_flags};
  my $c_param_name_mappings = $$objCppfunc{param_mappings};
  my $c_param_types = $$objCDefsFunc{param_types};
  my $c_param_names = $$objCDefsFunc{param_names};

  my @conversions = ();
  my @declarations = ();
  my @initializations = ();

  my $num_c_args_expected = scalar(@{$c_param_types});
  if( !($static) ) { $num_c_args_expected--; } #The cpp method will need an Object* paramater at the start.

  my $num_cpp_args = scalar(@{$cpp_param_types});

  my $has_output_param = 0;
  my $output_param_index;

  # See if there is an output parameter.  If so, temporarily decrement the
  # number of C++ arguments so that the possible GError addition works and
  # note the existence.
  if(defined($$c_param_name_mappings{"OUT"}))
  {
    $num_cpp_args--;
    $has_output_param = 1;
    $output_param_index = $$c_param_name_mappings{"OUT"};
  }
  else
  {
    # Check for possible void return mismatch (warn if the option was
    # specified to gmmproc at the command line).
    if($main::return_mismatches &&
      $$objCppfunc{rettype} eq "void" && $$objCDefsFunc{rettype} ne "void")
    {
      Output::error(
        "void return of $$objCppfunc{name}() does not match the "
        . "$$objCDefsFunc{rettype} return type.\n");
    }
  }

  # add implicit last error parameter;
  if ( $automatic_error ne "" &&
       $num_cpp_args == ($num_c_args_expected - 1) &&
       ${$c_param_types}[-1] eq "GError**" )
  {
    $num_cpp_args++;
    $cpp_param_names = [@{$cpp_param_names},"gerror"];
    $cpp_param_types = [@{$cpp_param_types},"GError*&"];
    $cpp_param_flags = [@{$cpp_param_flags}, 0];

    # Map from the C gerror param name to the newly added C++ param index.
    # The correct C++ index to map to (from the C name) depends on if there
    # is an output parameter since it will be readded.
    my $cpp_index = $num_cpp_args - 1;
    $cpp_index++ if($has_output_param);
    $$c_param_name_mappings{$$c_param_names[$num_c_args_expected]} = $cpp_index;
  }

  # If the method has a slot temporarily decrement the C arg count when
  # comparing the C++ and C argument count because the C function would
  # have a final 'gpointer data' parameter.
  $num_c_args_expected-- if ($$objCppfunc{slot_name});

  if ( $num_cpp_args != $num_c_args_expected )
  {
    Output::error( "convert_args_cpp_to_c(): Incorrect number of arguments. (%d != %d)\n",
             $num_cpp_args,
             $num_c_args_expected );
    $objCppfunc->dump();
    $objCDefsFunc->dump();

    return ("", "", "");
  }

  # Reincrement the expected C argument count if there is a slot.
  $num_c_args_expected++ if ($$objCppfunc{slot_name});

  # If there is an output parameter it must be processed so re-increment (now)
  # the number of C++ arguments.
  $num_cpp_args++ if($has_output_param);

  if ($index == 0)
  {
    # Check if the C param names in %$c_param_name_mappings exist.
    foreach my $mapped_c_param_name (keys %$c_param_name_mappings)
    {
      next if $mapped_c_param_name eq "" || $mapped_c_param_name eq "OUT";

      if (!grep($_ eq $mapped_c_param_name, @$c_param_names))
      {
        Output::error("convert_args_cpp_to_c(): There is no C argument called \"$mapped_c_param_name\"\n");
        $objCDefsFunc->dump();
        return ("", "", "");
      }
    }
  }

  # Get the desired argument list combination.
  my $possible_arg_list = $$objCppfunc{possible_args_list}[$index];

  # Tells if slot code should be included or not based on if a slot
  # parameter is optional.
  $$objCppfunc{include_slot} = 0;

  # Loop through the parameters:
  my $i;
  my $cpp_param_max = $num_cpp_args;
  # if( !($static) ) { $cpp_param_max++; }

  for ($i = 0; $i < $cpp_param_max; $i++)
  {
    # Skip the output parameter because it is handled in output_wrap_meth().
    next if($has_output_param && $i == $output_param_index);

    #index of C parameter:
    my $iCParam = $i;
    if( !($static) ) { $iCParam++; }

    # Account for a possible C++ output param in the C++ arg list.
    $iCParam-- if($has_output_param && $i > $output_param_index);

    my $c_param_name = $$c_param_names[$iCParam];
    my $cpp_param_index = $i;
    $cpp_param_index = $$c_param_name_mappings{$c_param_name} if(defined($$c_param_name_mappings{$c_param_name}));

    my $cppParamType = $$cpp_param_types[$cpp_param_index];
    $cppParamType =~ s/ &/&/g; #Remove space between type and &
    $cppParamType =~ s/ \*/*/g; #Remove space between type and *

    my $cppParamName = $$cpp_param_names[$cpp_param_index];
    my $cParamType = $$c_param_types[$iCParam];

    if(!($possible_arg_list =~ /\b$cpp_param_index\b/))
    {
      # If the C++ index is not found in the list of desired parameters, pass
      # nullptr to the C func unless the param is not optional (applies to a
      # possibly added GError parameter).
      if ($$cpp_param_flags[$cpp_param_index] & FLAG_PARAM_OPTIONAL)
      {
        push(@conversions, "nullptr");
        next;
      }
    }

    if ($$cpp_param_flags[$cpp_param_index] & FLAG_PARAM_OUTPUT)
    {
      # Get a generic name for the C output parameter name.
      my $cOutputParamName = "g_" . $$c_param_names[$iCParam];
      my $cOutputParamType = $cParamType;
      # Remove a possible final '*' from the output parameter type because it
      # will be passed by C reference (&name).
      $cOutputParamType =~ s/\*$//;

      # Only initialize pointers to nullptr.  Otherwise, use the default
      # constructor of the type.
      my $initialization = "";
      if($cOutputParamType =~ /\*$/)
      {
        $initialization = " = nullptr"; 
      }
      else
      {
        $initialization = " = $cOutputParamType()"; 
      }

      push(@declarations, "  $cOutputParamType $cOutputParamName$initialization;");

      push(@conversions, "&" . $cOutputParamName);

      push(@initializations, sprintf("_INITIALIZE(\`%s\',%s,%s,%s,%s);",
                    $cppParamType,
                    $cOutputParamType,
                    $cppParamName,
                    $cOutputParamName,
                    $wrap_line_number));
      next;
    }

    # If dealing with a slot.
    if ($$objCppfunc{slot_name} eq $cppParamName)
    {
      if ($$objCppfunc{slot_callback})
      {
        # The conversion for the slot is the address of the callback.
        push(@conversions, "&" . $$objCppfunc{slot_callback});
      }
      else
      {
        Output::error(
          "convert_args_cpp_to_c(): Missing a slot callback.  " .
          "Specify it with the 'slot_callback' option.\n",);
        $objCppfunc->dump();
        $objCDefsFunc->dump();
        return ("", "", "");
      }

      # Get the slot type without the const and the & and store it so
      # it can be passed to the m4 _*METHOD macros.
      $cppParamType =~ /^const\s+(.*)&/;
      $$objCppfunc{slot_type} = $1;

      # Signal that the slot code should be included.
      $$objCppfunc{include_slot} = 1;

      next;
    }

    if ($cppParamType ne $cParamType) #If a type conversion is needed.
    {
      my $std_conversion = sprintf("_CONVERT(%s,%s,%s,%s)",
            $cppParamType,
            $cParamType,
            $cppParamName,
            $wrap_line_number);

      # Shall an empty string be translated to a nullptr or to a pointer to
      # an empty string? The default is "pointer to an empty string" for
      # mandatory parameters, nullptr for optional parameters.
      if (($$cpp_param_flags[$cpp_param_index] & FLAG_PARAM_NULLPTR) ||
        (($$cpp_param_flags[$cpp_param_index] &
         (FLAG_PARAM_OPTIONAL | FLAG_PARAM_EMPTY_STRING)) == FLAG_PARAM_OPTIONAL && # OPTIONAL and not EMPTY_STRING
        $cppParamType =~ /^(const\s+)?(std::string|Glib::ustring)&?/))
      {
        push(@conversions, "$cppParamName.empty() ? nullptr : " . $std_conversion);
      }
      else
      {
        push(@conversions, $std_conversion);
      }
    }
    else
    {
      push(@conversions, $cppParamName);
    }
  }

  # Append the final slot copy parameter to the C function if the method
  # has a slot.  The m4 macros assume that that parameter name is
  # "slot_copy".  The m4 macros will either copy the slot to the
  # "slot_copy" variable or set it to the address of the slot itself if
  # the slot should not be copied.
  if ($$objCppfunc{slot_name})
  {
    if ($$objCppfunc{include_slot})
    {
      push(@conversions, "slot_copy");
    }
    else
    {
      push(@conversions, "nullptr")
    }
  }

  return ( join(", ", @conversions), join("\n", @declarations),
    join("\n  ", @initializations) );
}

# procedure for generating CONVERT macros
# Ignores the first C 'self' argument.
# $string convert_args_c_to_cpp($objCDefsFunc, $objCppFunc, $wrap_line_number)
sub convert_args_c_to_cpp($$$)
{
  my ($objCDefsFunc, $objCppfunc, $wrap_line_number) = @_;

  my $cpp_param_names = $$objCppfunc{param_names};
  my $cpp_param_types = $$objCppfunc{param_types};
  my $c_param_types = $$objCDefsFunc{param_types};
  my $c_param_names = $$objCDefsFunc{param_names};

  # This variable stores the C++ parameter mappings from the C++
  # index to the C param name if the mappings exist.
  my %cpp_index_param_mappings;

  # Fill the index to param names mappings from the c param names to index
  # mappings variable above.
  @cpp_index_param_mappings{values %{$$objCppfunc{param_mappings}}}
    = keys %{$$objCppfunc{param_mappings}};

  my @result;

  my $num_c_args = scalar(@{$c_param_types});

  # If the the function has been marked as a function that throws errors
  # (Glib::Error) don't count the last GError** argument.
  $num_c_args-- if($$objCDefsFunc{throw_any_errors});

  my $num_cpp_args = scalar(@{$cpp_param_types});

  # If the method has a slot temporarily increment the C++ arg count when
  # comparing the C++ and C argument count because the C function would
  # have a final 'gpointer data' parameter and the C++ method would not.
  $num_cpp_args++ if ($$objCppfunc{slot_name});

  if ( ($num_cpp_args + 1) !=  $num_c_args )
  {
    Output::error( "convert_args_c_to_cpp(): Incorrect number of arguments. (%d != %d)\n",
             $num_cpp_args + 1,
             $num_c_args);
    $objCppfunc->dump();
    $objCDefsFunc->dump();

    return "";
  }

  # Re-decrement the expected C++ argument count if there is a slot.
  $num_cpp_args-- if ($$objCppfunc{slot_name});

  # Loop through the C++ parameters:
  my $i;
  my $cpp_param_max = $num_cpp_args;
  my $num_c_args = scalar(@{$c_param_names});

  for ($i = 0; $i < $cpp_param_max; $i++)
  {
    my $cParamName = "";
    my $c_index = 0;

    if (defined $cpp_index_param_mappings{$i})
    {
      # If a mapping exists from the current index to a C param name,
      # use that C param for the conversion.
      $cParamName = $cpp_index_param_mappings{$i};

      # Get the C index based on the C param name.
      ++$c_index until $c_index >= $num_c_args || $$c_param_names[$c_index] eq $cParamName;
      if ($c_index >= $num_c_args)
      {
        Output::error("convert_args_c_to_cpp(): There is no C argument called \"$cParamName\"\n");
        $objCDefsFunc->dump();
        return "";
      }
    }
    else
    {
      # If no mapping exists, the C index is the C++ index + 1 (to skip
      # The 'self' argument of the C function).
      $c_index = $i + 1;
      $cParamName = $$c_param_names[$c_index];
    }

    my $cParamType = $$c_param_types[$c_index];

    my $cppParamName = $$cpp_param_names[$i];
    my $cppParamType = $$cpp_param_types[$i];
    $cppParamType =~ s/ &/&/g; #Remove space between type and &.
    $cppParamType =~ s/ \*/*/g; #Remove space between type and *

    if ($$objCppfunc{slot_name})
    {
      # If the current parameter is the slot parameter insert the
      # derefenced name of the variable containing the slot which is
      # assumed to be '*slot'.  The m4 macro is responsible for ensuring
      # that the variable is declared and the slot in the 'user_data' C
      # param is placed in the variable.
      if ($$objCppfunc{slot_name} eq $cppParamName)
      {
        push(@result, "*slot");

        # Get the slot type without the const and the '&' and store it so
        # it can be passed to the m4 macro.
        $cppParamType =~ /^const\s+(.*)&/;

        # If the type does not contain
        # any '::' then assume that it is in the library standard namespace
        # by prepending '__NAMESPACE__::' to it which the m4 macros will
        # translate to the library namespace.
        my $plainCppParamType = $1;
        $plainCppParamType = "__NAMESPACE__::" . $plainCppParamType
          if (!($plainCppParamType =~ /::/));

        $$objCppfunc{slot_type} = $plainCppParamType;

        # Store the name of the C data parameter so it can be passed
        # to the m4 macro so it can extract the slot.
        $$objCppfunc{c_data_param_name} = $$c_param_names[$num_c_args - 1];

        next;
      }
    }

    if ($cParamType ne $cppParamType) #If a type conversion is needed.
    {
      push(@result, sprintf("_CONVERT(%s,%s,%s,%s)\n",
                   $cParamType,
                   $cppParamType,
                   $cParamName,
                   $wrap_line_number) );
    }
    else
    {
      push(@result, $cParamName);
    }
  }

  return join(", ",@result);
}


# generates the XXX in g_object_new(get_type(), XXX): A list of property names
# and values.  Uses the cpp arg name as the property name.
#
# - The optional index specifies which arg list out of the possible combination
#   of arguments based on whether any arguments are optional. index = 0 ==> all
#   the arguments.
#
# - The errthrow parameter tells if the C new function has a final GError**
#   parameter.  That parameter is ignored since it will not form part of the
#   property list.
#
# $string get_ctor_properties($objCppfunc, $objCDefsFunc, $wrap_line_number, $errthrow, $index = 0)
sub get_ctor_properties($$$$$$)
{
  my ($objCppfunc, $objCDefsFunc, $wrap_line_number, $errthrow, $index) = @_;

  $index = 0 unless defined $index;

  my $cpp_param_names = $$objCppfunc{param_names};
  my $cpp_param_types = $$objCppfunc{param_types};
  my $cpp_param_flags = $$objCppfunc{param_flags};
  my $c_param_name_mappings = $$objCppfunc{param_mappings};
  my $c_param_types = $$objCDefsFunc{param_types};
  my $c_param_names = $$objCDefsFunc{param_names};

  my @result;

  my $num_args = scalar(@{$c_param_types});

  # If the C function has a final GError** parameter, ignore it.
  $num_args-- if ($errthrow eq "errthrow");

  my $num_cpp_args = scalar(@{$cpp_param_types});
  if ( $num_cpp_args != $num_args )
  {
    Output::error("get_ctor_properties(): Incorrect number of arguments. (%d != %d)\n",
             $num_cpp_args,
             $num_args );
    return "";
  }

  if ($index == 0)
  {
    # Check if the C param names in %$c_param_name_mappings exist.
    foreach my $mapped_c_param_name (keys %$c_param_name_mappings)
    {
      next if $mapped_c_param_name eq "";

      if (!grep($_ eq $mapped_c_param_name, @$c_param_names))
      {
        Output::error("get_ctor_properties(): There is no C argument called \"$mapped_c_param_name\"\n");
        $objCDefsFunc->dump();
        return ("", "", "");
      }
    }
  }

  # Get the desired argument list combination.
  my $possible_arg_list = $$objCppfunc{possible_args_list}[$index];

  # Loop through the parameters:
  my $i = 0;

  for ($i = 0; $i < $num_args; $i++)
  {
    my $c_param_name = $$c_param_names[$i];
    my $cpp_param_index = $i;
    $cpp_param_index = $$c_param_name_mappings{$c_param_name} if(defined($$c_param_name_mappings{$c_param_name}));

    my $cppParamType = $$cpp_param_types[$cpp_param_index];
    $cppParamType =~ s/ &/&/g; #Remove space between type and &
    $cppParamType =~ s/ \*/*/g; #Remove space between type and *

    my $cppParamName = $$cpp_param_names[$cpp_param_index];
    my $cParamType = $$c_param_types[$i];

    # Property name:
    push(@result, "\"" . $cppParamName . "\"");

    if(!($possible_arg_list =~ /\b$cpp_param_index\b/))
    {
      # If the C++ index is not found in the list of desired parameters, pass
      # nullptr to the C func unless the param is not optional.
      if ($$cpp_param_flags[$cpp_param_index] & FLAG_PARAM_OPTIONAL)
      {
        push(@result, "nullptr");
        next;
      }
    }

   # C property value:
    if ($cppParamType ne $cParamType) #If a type conversion is needed.
    {
      push(@result, sprintf("_CONVERT(%s,%s,%s,%s)",
                  $cppParamType,
                  $cParamType,
                  $cppParamName,
                  $wrap_line_number) );
    }
    else
    {
      push(@result, $cppParamName);
    }
  }

  return join(", ", @result);
}

### Convert _WRAP to a corba method
# _CORBA_METHOD(retype, method_name,args, arg_names_only) - implemented in libbonobomm.
#  void output_wrap_corba_method($filename, $line_num, $objCppFunc)
sub output_wrap_corba_method($$$$)
{
  my ($self, $filename, $line_num, $objCppfunc) = @_;

  my $str = sprintf("_CORBA_METHOD(%s,%s,\`%s\',\`%s\')dnl\n",
      $$objCppfunc{rettype},
      $$objCppfunc{name},
      $objCppfunc->args_types_and_names(),
      $objCppfunc->args_names_only()
   );

  $self->append($str);
}

sub output_implements_interface($$)
{
  my ($self, $interface, $ifdef) = @_;

  my $str = sprintf("_IMPLEMENTS_INTERFACE_CC(%s, %s)dnl\n",
  	$interface,
  	$ifdef);

  $self->append($str);
}

1; # indicate proper module load.
