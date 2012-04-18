# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapParser module
#
# Copyright 2011, 2012 glibmm development team
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

package Common::WrapParser;

use strict;
use warnings;

use IO::File;

use Common::CxxFunctionInfo;
use Common::CFunctionInfo;
use Common::SignalInfo;
use Common::Util;
use Common::SectionManager;
use Common::Shared;
use Common::Output;
use Common::ConversionsStore;
use constant
{
  'STAGE_HG' => 0,
  'STAGE_CCG' => 1,
  'STAGE_INVALID' => 2,
  'GIR_RECORD' => 0,
  'GIR_CLASS' => 1,
  'GIR_ANY' => 2
};

###
### NOT SURE ABOUT THE CODE BELOW
###

# TODO: check if we can avoid using it.
# Look back for a Doxygen comment.  If there is one,
# remove it from the output and return it as a string.
sub extract_preceding_documentation ($)
{
  my ($self) = @_;
  my $outputter = $$self{objOutputter};
  my $out = \@{$$outputter{out}};

  my $comment = '';

  if ($#$out >= 2)
  {
    # steal the last three tokens
    my @back = splice(@$out, -3);
    local $_ = join('', @back);

    # Check for /*[*!] ... */ or //[/!] comments.  The closing */ _must_
    # be the last token of the previous line.  Apart from this restriction,
    # anything else should work, including multi-line comments.

    if (m#\A/\s*\*(?:\*`|`!)(.+)'\*/\s*\z#s or m#\A\s*//`[/!](.+)'\s*\z#s)
    {
      $comment = '`' . $1;
      $comment =~ s/\s*$/'/;
    }
    else
    {
      # restore stolen tokens
      push(@$out, @back);
    }
  }

  return $comment;
}

# TODO: probably implement this. I am not sure.
# void _on_wrap_corba_method()
sub _on_wrap_corba_method ($)
{
  my ($self) = @_;

  $self->_extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->_extract_bracketed_text();
  # my @args = string_split_commas($str);

  # my $entity_type = "method";

  # if (!$$self{in_class})
  #   {
  #     print STDERR "$filename:$line_num:_WRAP macro encountered outside class\n";
  #     return;
  #   }

  # my $objCppfunc;

  # # handle first argument
  # my $argCppMethodDecl = $args[0];
  # if ($argCppMethodDecl !~ m/\S/s)
  # {
  #   print STDERR "$filename:$line_num:_WRAP_CORBA_METHOD: missing prototype\n";
  #   return;
  # }

  # # Parse the method decaration and build an object that holds the details:
  # $objCppfunc = &Function::new($argCppMethodDecl, $self);
  # $objOutputter->output_wrap_corba_method($filename, $line_num, $objCppfunc);
}

###
### NOT SURE ABOUT THE CODE ABOVE
###

sub _handle_get_args_results ($$)
{
  my ($self, $results) = @_;

  if (defined $results)
  {
    my $errors = $results->[0];
    my $warnings = $results->[1];
    my $fatal = 0;

    if (defined $errors)
    {
      foreach my $error (@{$errors})
      {
        my $param = $error->[0];
        my $message = $error->[1];

        $self->fixed_error_non_fatal (join ':', $param, $message);
      }
      $fatal = 1;
    }
    if (defined $warnings)
    {
      foreach my $warning (@{$warnings})
      {
        my $param = $warning->[0];
        my $message = $warning->[1];

        $self->fixed_warning (join ':', $param, $message);
      }
    }

    if ($fatal)
    {
# TODO: throw an exception or something.
      exit 1;
    }
  }
}

sub _extract_token ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;
  my $results = Common::Shared::extract_token $tokens;
  my $token = $results->[0];
  my $add_lines = $results->[1];

  $self->inc_line_num ($add_lines);
  return $token;
}

sub _peek_token ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;

  while (@{$tokens})
  {
    my $token = $tokens->[0];

    # skip empty tokens
    if (not defined $token or $token eq '')
    {
      shift @{$tokens};
    }
    else
    {
      return $token;
    }
  }

  return '';
}

sub _extract_bracketed_text ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;
  my $result = Common::Shared::extract_bracketed_text $tokens;

  if (defined $result)
  {
    my $string = $result->[0];
    my $add_lines = $result->[1];

    $self->inc_line_num ($add_lines);
    return $string;
  }

  $self->fixed_error ('Hit eof when extracting bracketed text.');
}

sub _extract_members ($$)
{
  my ($object, $substs) = @_;
  my $member_count = $object->get_g_member_count;
  my @all_members = ();

  for (my $iter = 0; $iter < $member_count; ++$iter)
  {
    my $member = $object->get_g_member_by_index ($iter);
    my $name = uc $member->get_a_name;
    my $value = $member->get_a_value;

    foreach my $pair (@{$substs})
    {
      $name =~ s#$pair->[0]#$pair->[1]#;
      $value =~ s#$pair->[0]#$pair->[1]#;
    }
    push @all_members, [$name, $value];
  }

  return \@all_members;
}

sub _on_string_with_delimiters ($$$$)
{
  my ($self, $start, $end, $what) = @_;
  my $tokens = $self->get_tokens;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my @out = ($start);

  while (@{$tokens})
  {
    my $token = $self->_extract_token;

    push @out, $token;
    if ($token eq $end)
    {
      $section_manager->append_string_to_section ((join '', @out), $main_section);
      return;
    }
  }
  $self->fixed_error ('Hit eof while in ' . $what . '.');
}

sub _on_ending_brace ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my @strings = ();
  my $slc = 0;
  my $mlc = 0;

  while (@{$tokens})
  {
    my $token = $self->_extract_token;

    push @strings, $token;
    if ($slc)
    {
      if ($token eq "\n")
      {
        last;
      }
    }
    elsif ($mlc)
    {
      if ($token eq "*/")
      {
        last;
      }
    }
    elsif ($token eq '//')
    {
      # usual case: } // namespace Foo
      $slc = 1;
    }
    elsif ($token eq '/*')
    {
      # usual case: } /* namespace Foo */
      $mlc = 1;
    }
    elsif ($token eq "\n")
    {
      last;
    }
    elsif ($token =~ /^\s+$/)
    {
      # got nonwhitespace, non plain comment token
      # removing it from strings and putting it back to tokens, so it will be processed later.
      pop @strings;
      unshift @{$tokens}, $token;
      last;
    }
  }
  $section_manager->append_string_to_section ((join '', @strings, "\n"), $main_section);
}

sub _get_gir_stack ($)
{
  my ($self) = @_;

  return $self->{'gir_stack'};
}

sub _push_gir_generic ($$$)
{
  my ($self, $gir_stuff, $gir_type) = @_;
  my $gir_stack = $self->_get_gir_stack;

  push @{$gir_stack}, [$gir_type, $gir_stuff];
}

sub _push_gir_record ($$)
{
  my ($self, $gir_record) = @_;

  $self->_push_gir_generic ($gir_record, GIR_RECORD);
}

sub _push_gir_class ($$)
{
  my ($self, $gir_class) = @_;

  $self->_push_gir_generic  ($gir_class, GIR_CLASS);
}

sub _get_gir_generic ($$)
{
  my ($self, $gir_type) = @_;
  my $gir_stack = $self->_get_gir_stack;

  if (@{$gir_stack})
  {
    my $gir_desc = $gir_stack->[-1];

    if ($gir_desc->[0] == $gir_type or $gir_type == GIR_ANY)
    {
      return $gir_desc->[1];
    }
  }

  return undef;
}

sub _get_gir_record ($)
{
  my ($self) = @_;

  return $self->_get_gir_generic (GIR_RECORD);
}

sub _get_gir_class ($)
{
  my ($self) = @_;

  return $self->_get_gir_generic (GIR_CLASS);
}

sub _get_gir_entity ($)
{
  my ($self) = @_;

  return $self->_get_gir_generic (GIR_ANY);
}

sub _pop_gir_entity ($)
{
  my ($self) = @_;
  my $gir_stack = $self->_get_gir_stack;

  pop @{$gir_stack};
}

sub _get_c_stack ($)
{
  my ($self) = @_;

  return $self->{'c_stack'};
}

sub _push_c_class ($$)
{
  my ($self, $c_class) = @_;
  my $c_stack = $self->_get_c_stack;

  push @{$c_stack}, $c_class;
}

sub _pop_c_class ($)
{
  my ($self) = @_;
  my $c_stack = $self->_get_c_stack;

  pop @{$c_stack};
}

# TODO: public
sub get_c_class ($)
{
  my ($self) = @_;
  my $c_stack = $self->_get_c_stack;

  if (@{$c_stack})
  {
    return $c_stack->[-1];
  }
  return undef;
}

sub _get_prop_name ($$$$)
{
  my ($self, $gir_class, $c_param_name, $cxx_param_name) = @_;
  my $c_prop_name = $c_param_name;

  $c_prop_name =~ s/_/-/g;

  my $gir_property = $gir_class->get_g_property_by_name ($c_prop_name);

  unless (defined $gir_property)
  {
    my $cxx_prop_name = $cxx_param_name;

    $cxx_prop_name =~ s/_/-/g;
    $gir_property = $gir_class->get_g_property_by_name ($cxx_prop_name);

    unless (defined $gir_property)
    {
# TODO: error in proper, fixed line.
      die;
    }
  }

  return $gir_property->get_a_name;
}

###
### HANDLERS BELOW
###

sub _on_open_brace ($)
{
  my ($self) = @_;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;

  $self->inc_level;
  $section_manager->append_string_to_section ('{', $main_section);
}

sub _on_close_brace ($)
{
  my ($self) = @_;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my $namespace_levels = $self->get_namespace_levels;
  my $namespaces = $self->get_namespaces;
  my $level = $self->get_level;
  my $class_levels = $self->get_class_levels;
  my $classes = $self->get_classes;

  $section_manager->append_string_to_section ('}', $main_section);

  # check if we are closing the class brace
  if (@{$class_levels} and $class_levels->[-1] == $level)
  {
    if (@{$classes} == 1)
    {
      my $section = Common::Output::Shared::get_section $self, Common::Sections::H_AFTER_FIRST_CLASS;

      $self->_on_ending_brace;
      $section_manager->append_section_to_section ($section, $main_section);
    }

    pop @{$class_levels};
    pop @{$classes};
    $self->_pop_gir_entity;
  }
  # check if we are closing the namespace brace
  elsif (@{$namespace_levels} and $namespace_levels->[-1] == $level)
  {
    if (@{$namespaces} == 1)
    {
      my $section = Common::Output::Shared::get_section $self, Common::Sections::H_AFTER_FIRST_NAMESPACE;

      $self->_on_ending_brace;
      $section_manager->append_section_to_section ($section, $main_section);
    }

    pop @{$namespaces};
    pop @{$namespace_levels};
  }

  $self->dec_level;
}

sub _on_string_literal ($)
{
  my ($self) = @_;

  $self->_on_string_with_delimiters ('"', '"', 'string');
}

sub _on_comment_cpp ($)
{
  my ($self) = @_;

  $self->_on_string_with_delimiters ('//', "\n", 'C++ comment');
}

# TODO: look at _on_comment_doxygen - something similar has to
# TODO continued: be done here.
sub _on_comment_doxygen_single ($)
{
  my ($self) = @_;

  $self->_on_string_with_delimiters ('///', "\n", 'Doxygen single line comment');
}

sub _on_comment_c ($)
{
  my ($self) = @_;

  $self->_on_string_with_delimiters ('/*', '*/', 'C comment');
}

# TODO: use the commented code.
sub _on_comment_doxygen ($)
{
  my ($self) = @_;

  $self->_on_string_with_delimiters ('/**', '*/', 'Doxygen multiline comment');

#  my $tokens = $self->get_tokens;
#  my @out =  ('/**');
#
#  while (@{$tokens})
#  {
#    my $token = $self->_extract_token;
#
#    if ($token eq '*/')
#    {
#      push @out, '*';
#      # Find next non-whitespace token, but remember whitespace so that we
#      # can print it if the next real token is not _WRAP_SIGNAL
#      my @whitespace = ();
#      my $next_token = $self->_peek_token;
#      while ($next_token !~ /\S/)
#      {
#        push @whitespace, $self->_extract_token;
#        $next_token = $self->_peek_token;
#      }
#
#      # If the next token is a signal, do not close this comment, to merge
#      # this doxygen comment with the one from the signal.
#      if ($next_token eq '_WRAP_SIGNAL')
#      {
#        # Extract token and process
#        $self->_extract_token;
#        # Tell wrap_signal to merge automatically generated comment with
#        # already existing comment. This is why we do not close the comment
#        # here.
#        return $self->_on_wrap_signal_after_comment(\@out);
#      }
#      else
#      {
#        # Something other than signal follows, so close comment normally
#        # and append whitespace we ignored so far.
#        push @out, '/', @whitespace;
#        return join '', @out;
#      }
#
#      last;
#    }
#
#    push @out, $token;
#  }
#  $self->fixed_error ('Hit eof while in doxygen comment.');
}

# TODO: We have to just ignore #m4{begin,end}, and check for
# TODO continued: _CONVERSION macros inside.
sub _on_m4_section ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;

  $self->fixed_warning ('Deprecated.');

  while (@{$tokens})
  {
    return if ($self->_extract_token eq '#m4end');
  }

  $self->fixed_error ('Hit eof when looking for #m4end.');
}

# TODO: We have to just ignore #m4, and check for _CONVERSION
# TODO continued: macros inside.
sub _on_m4_line ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;

  $self->fixed_warning ('Deprecated.');

  while (@{$tokens})
  {
    return if ($self->_extract_token eq "\n");
  }

  $self->fixed_error ('Hit eof when looking for newline');
}

sub _on_defs ($)
{
  my ($self) = @_;

  $self->fixed_warning ('Deprecated.');
  $self->_extract_bracketed_text;
}

# TODO: implement it.
sub _on_ignore ($)
{
  my ($self) = @_;

  $self->fixed_warning ('Not yet implemented.');
  $self->_extract_bracketed_text;
#  my @args = split(/\s+|,/,$str);
#  foreach (@args)
#  {
#    next if ($_ eq "");
#    GtkDefs::lookup_function($_); #Pretend that we've used it.
#  }
}

# TODO: implement it.
sub _on_ignore_signal ($)
{
  my ($self) = @_;

  $self->fixed_warning ('Not yet implemented.');
  $self->_extract_bracketed_text;
#  $str = Common::Util::string_trim($str);
#  $str = Common::Util::string_unquote($str);
#  my @args = split(/\s+|,/,$str);
#  foreach (@args)
#  {
#    next if ($_ eq "");
#    GtkDefs::lookup_signal($$self{c_class}, $_); #Pretend that we've used it.
#  }
}

sub _on_wrap_method ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cxx_method_decl = shift @args;
  my $c_function_name = shift @args;
  my $deprecated = 0;
  my $refreturn = 0;
  my $constversion = 0;
  my $errthrow = 0;
  my $ifdef = undef;
  my $setup =
  {
    'b(deprecated)' => \$deprecated,
# TODO: probably obsolete, maybe inform that some annotation
# TODO continued: could be added to C sources.
    'ob(refreturn)' => \$refreturn,
    'b(constversion)' => \$constversion,
    'ob(errthrow)' => \$errthrow,
    's(ifdef)' => \$ifdef
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  my $cxx_function = Common::CxxFunctionInfo->new_from_string ($cxx_method_decl);
  my $gir_entity = $self->_get_gir_entity;

  unless (defined $gir_entity)
  {
    $self->fixed_error ('Macro outside class.');
  }

# TODO: Check if we have any function outside C class wrapped
# TODO continued: in C++ class. If not then getting the
# TODO continued: namespace is not needed.
  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $gir_namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $gir_namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my $gir_func = $gir_entity->get_g_method_by_name ($c_function_name);

  unless (defined $gir_func)
  {
    $gir_func = $gir_entity->get_g_function_by_name ($c_function_name);

    unless (defined $gir_func)
    {
# TODO: Check if we have any function outside C class wrapped
# TODO continued: in C++ class.
      $gir_func = $gir_namespace->get_g_function_by_name ($c_function_name);

      unless (defined $gir_func)
      {
        $self->fixed_error ('No such method: ' . $c_function_name);
      }
      else
      {
        $self->fixed_warning ('Found a function, but it is outside class.');
      }
    }
  }

  my $c_function = Common::CFunctionInfo->new_from_gir ($gir_func);
  my $ret_transfer = $c_function->get_return_transfer;
  my $throws = $c_function->get_throws;

# TODO: remove the ifs below after possible bugs in
# TODO continued: wrappers/annotations are fixed.
  if ($ret_transfer == Common::ConversionsStore::TRANSFER_FULL and $refreturn)
  {
    $self->fixed_warning ('refreturn given but annotation says that transfer is already full - which is wrong? (refreturn is ignored anyway.)');
  }
  elsif ($ret_transfer == Common::ConversionsStore::TRANSFER_NONE and not $refreturn)
  {
    $self->fixed_warning ('There is no refreturn, but annotation says that transfer is none - which is wrong? (refreturn would be ignored anyway.)');
  }
  if (not $throws and $errthrow)
  {
    $self->fixed_warning ('errthrow given but annotation says that no error here is thrown - which is wrong? (errthrow is ignored anyway.)');
  }
  elsif ($throws and not $errthrow)
  {
    $self->fixed_warning ('There is no errthrow but annotation says that an error can be thrown here - which is wrong? (errthrow would be ignored anyway.)');
  }

  Common::Output::Method::output ($self,
                                  $cxx_function->get_static,
                                  $cxx_function->get_return_type,
                                  $cxx_function->get_name,
                                  $cxx_function->get_param_types,
                                  $cxx_function->get_param_names,
                                  $cxx_function->get_const,
                                  $constversion,
                                  $deprecated,
                                  $ifdef,
                                  $c_function->get_return_type,
                                  $ret_transfer,
                                  $c_function->get_name,
                                  $c_function->get_param_types,
                                  $c_function->get_param_transfers,
                                  $throws);
}

# TODO: implement it.
sub _on_wrap_method_docs_only ($)
{
  my ($self) = @_;

  $self->_extract_bracketed_text;
  $self->fixed_warning ('Not yet implemented.');
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->_extract_bracketed_text();
  # my @args = string_split_commas($str);

  # my $entity_type = "method";

  # if (!$$self{in_class})
  #   {
  #     print STDERR "$filename:$line_num:_WRAP macro encountered outside class\n";
  #     return;
  #   }

  # my $objCfunc;

  # # handle first argument
  # my $argCFunctionName = $args[0];
  # $argCFunctionName = Common::Util::string_trim($argCFunctionName);

  # # Get the C function's details:

  # # Checks that it's not empty or contains whitespace
  # if ($argCFunctionName =~ m/^\S+$/s)
  # {
  #   #c-name. e.g. gtk_clist_set_column_title
  #   $objCfunc = GtkDefs::lookup_function($argCFunctionName);

  #   if(!$objCfunc) #If the lookup failed:
  #   {
  #     $objOutputter->output_wrap_failed($argCFunctionName, "method defs lookup failed (1)");
  #     return;
  #   }
  # }

  # # Extra ref needed?
  # $$objCfunc{throw_any_errors} = 0;
  # while($#args >= 1) # If the optional ref/err arguments are there.
  # {
  #   my $argRef = Common::Util::string_trim(pop @args);
  #   if($argRef eq "errthrow")
  #   {
  #     $$objCfunc{throw_any_errors} = 1;
  #   }
  # }

  # my $commentblock = "";
  # $commentblock = DocsParser::lookup_documentation($argCFunctionName, "");

  # $objOutputter->output_wrap_meth_docs_only($filename, $line_num, $commentblock);
}

# TODO: Split the common part from it and make two methods
# TODO continued: with merging doxycomment and without it.
# TODO: Implement it actually.
sub _on_wrap_signal ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cxx_method_decl = shift @args;
  my $c_signal_str = shift @args;
  my $deprecated = 0;
  my $refreturn = 0;
  my $ifdef = undef;
  my $dhs_disabled = 0;
  my $custom_c_callback = 0;
  my $custom_signal_handler = 0;
  my $setup =
  {
    'b(deprecated)' => \$deprecated,
# TODO: probably obsolete, maybe inform that some annotation
# TODO continued: could be added to C sources.
    'ob(refreturn)' => \$refreturn,
    's(ifdef)' => \$ifdef,
    'b(no_default_handler)' => \$dhs_disabled,
    'b(custom_c_callback)' => \$custom_c_callback,
    'b(custom_signal_handler)' => \$custom_signal_handler
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  if ($c_signal_str =~ /_/ or $c_signal_str !~ /$".*"^/)
  {
    $self->fixed_warning ('Second parameter should be like C string (in double quotes) with dashes instead of underlines - e.g. "activate-link".');
  }

  $c_signal_str =~ s/_/-/g;
  $c_signal_str =~ s/"//g;

  my $c_signal_name = $c_signal_str;

  $c_signal_name =~ s/-/_/g;

  my $cxx_function = Common::CxxFunctionInfo->new_from_string ($cxx_method_decl);
  my $gir_class = $self->_get_gir_class;

  unless (defined $gir_class)
  {
    $self->fixed_error ('Macro outside class.');
  }

  my $gir_signal = $gir_class->get_g_glib_signal_by_name ($c_signal_str);

  unless (defined $gir_signal)
  {
    $self->fixed_error ('No such signal: ' . $c_signal_str);
  }

  my $c_signal = Common::SignalInfo->new_from_gir ($gir_signal);
  my $ret_transfer = $c_signal->get_return_transfer;

# TODO: remove the ifs below after possible bugs in
# TODO continued: wrappers/annotations are fixed.
  if ($ret_transfer == Common::ConversionsStore::TRANSFER_FULL and $refreturn)
  {
    $self->fixed_warning ('refreturn given but annotation says that transfer is already full - which is wrong? (refreturn is ignored anyway.)');
  }
  elsif ($ret_transfer == Common::ConversionsStore::TRANSFER_NONE and not $refreturn)
  {
    $self->fixed_warning ('There is no refreturn, but annotation says that transfer is none - which is wrong? (refreturn would be ignored anyway.)');
  }

# TODO: Add custom_signal_handler.
  Common::Output::Signal::output $self,
                                 $ifdef,
                                 $c_signal->get_return_type,
                                 $ret_transfer,
                                 $c_signal_name,
                                 $c_signal->get_name,
                                 $c_signal->get_param_types,
                                 $c_signal->get_param_names,
                                 $c_signal->get_param_transfers,
                                 $cxx_function->get_return_type,
                                 $cxx_function->get_name,
                                 $cxx_function->get_param_types,
                                 $cxx_function->get_param_names,
                                 $custom_c_callback,
                                 !$dhs_disabled;
}

sub _on_wrap_property ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $prop_c_name = shift @args;
  my $prop_cpp_type = shift @args;

  # Catch useless parameters.
  $self->_handle_get_args_results (Common::Shared::get_args \@args, {});

  if ($prop_c_name =~ /_/ or $prop_c_name !~ /^"\w+"$/)
  {
    $self->fixed_warning ('First parameter should be like C string (in double quotes) with dashes instead of underlines - e.g. "g-name-owner".');
  }

  $prop_c_name =~ s/_/-/g;
  $prop_c_name =~ s/"//g;

  my $prop_cpp_name = $prop_c_name;

  $prop_c_name =~ s/-/_/g;

  my $gir_class = $self->_get_gir_class;

  unless ($gir_class)
  {
    $self->fixed_error ('Outside Glib::Object subclass.');
  }

  my $gir_property = $gir_class->get_g_property_by_name ($prop_c_name);

  unless ($gir_property)
  {
    $self->fixed_error ('No such property in gir: "' . $prop_c_name . '".');
  }

  my $construct_only = $gir_property->get_a_construct_only;
  my $readable = $gir_property->get_a_readable;
  my $writable = $gir_property->get_a_writable;
# TODO: probably not needed.
  my $transfer = $gir_property->get_a_transfer_ownership;
  my $read_only = 0;
  my $write_only = 0;

  if ($construct_only and not $readable)
  {
    $self->fixed_error ('Tried to wrap write-only and construct-only property');
  }

  Common::Output::Property::output $self,
                                   $construct_only,
                                   $readable,
                                   $writable,
                                   $prop_cpp_type,
                                   $prop_cpp_name,
                                   $prop_c_name;
}

sub _on_wrap_vfunc ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cxx_method_decl = shift @args;
  my $c_vfunc_name = shift @args;

  if ($c_vfunc_name !~ /^\w+$/)
  {
    $self->fixed_warning ('Second parameter should be like a name of C vfunc. No dashes, no double quotes.');
  }

  $c_vfunc_name =~ s/-/_/g;
  $c_vfunc_name =~ s/"//g;

  my $deprecated = 0;
  my $refreturn = 0;
  my $errthrow = 0;
  my $ifdef = undef;
  my $custom_vfunc = 0;
  my $custom_vfunc_callback = 0;
  my $setup =
  {
    'b(deprecated)' => \$deprecated,
# TODO: probably obsolete, maybe inform that some annotation
# TODO continued: could be added to C sources.
    'ob(refreturn)' => \$refreturn,
    'ob(refreturn_ctype)' => undef,
    'ob(errthrow)' => $errthrow,
    's(ifdef)' => \$ifdef,
    'b(custom_vfunc)' => \$custom_vfunc,
    'b(custom_vfunc_callback)' => \$custom_vfunc_callback
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  my $cxx_function = Common::CxxFunctionInfo->new_from_string ($cxx_method_decl);
  my $gir_class = $self->_get_gir_class;

  unless (defined $gir_class)
  {
    $self->fixed_error ('Macro outside Glib::Object subclass.');
  }

  my $gir_vfunc = $gir_class->get_g_virtual_method_by_name ($c_vfunc_name);

  unless (defined $gir_vfunc)
  {
    $self->fixed_error ('No such virtual method: ' . $c_vfunc_name);
  }

  my $c_vfunc = Common::CFunctionInfo->new_from_gir ($gir_vfunc);
  my $ret_transfer = $c_vfunc->get_return_transfer;
  my $throws = $c_vfunc->get_throws;

# TODO: remove the ifs below after possible bugs in
# TODO continued: wrappers/annotations are fixed.
  if ($ret_transfer == Common::ConversionsStore::TRANSFER_FULL and $refreturn)
  {
    $self->fixed_warning ('refreturn given but annotation says that transfer is already full - which is wrong? (refreturn is ignored anyway.)');
  }
  elsif ($ret_transfer == Common::ConversionsStore::TRANSFER_NONE and not $refreturn)
  {
    $self->fixed_warning ('There is no refreturn, but annotation says that transfer is none - which is wrong? (refreturn would be ignored anyway.)');
  }
  if (not $throws and $errthrow)
  {
    $self->fixed_warning ('errthrow given but annotation says that no error here is thrown - which is wrong? (errthrow is ignored anyway.)');
  }
  elsif ($throws and not $errthrow)
  {
    $self->fixed_warning ('There is no errthrow but annotation says that an error can be thrown here - which is wrong? (errthrow would be ignored anyway.)');
  }

  Common::Output::VFunc::output $self,
                                $ifdef,
                                $c_vfunc->get_return_type,
                                $ret_transfer,
                                $c_vfunc->get_name,
                                $c_vfunc->get_param_types,
                                $c_vfunc->get_param_names,
                                $c_vfunc->get_param_transfers,
                                $cxx_function->get_return_type,
                                $cxx_function->get_name,
                                $cxx_function->get_param_types,
                                $cxx_function->get_param_names,
                                $cxx_function->get_const,
                                $custom_vfunc,
                                $custom_vfunc_callback,
                                $throws;
}

sub _on_wrap_ctor ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cxx_method_decl = shift @args;
  my $c_constructor_name = shift @args;

  # Catch useless parameters.
  $self->_handle_get_args_results (Common::Shared::get_args \@args, {});

  my $cxx_function = Common::CxxFunctionInfo->new_from_string ($cxx_method_decl);
  my $gir_class = $self->_get_gir_class;

  unless (defined $gir_class)
  {
    $self->fixed_error ('Macro outside Glib::Object subclass.');
  }

  my $gir_constructor = $gir_class->get_g_constructor_by_name ($c_constructor_name);

  unless (defined $gir_constructor)
  {
    $self->fixed_error ('No such constructor: ' . $c_constructor_name);
  }

  my $c_constructor = Common::CFunctionInfo->new_from_gir ($gir_constructor);
  my $c_param_names = $c_constructor->get_param_names;
  my $cxx_param_names = $cxx_function->get_param_names;
  my $c_params_count = @{$c_param_names};
  my $cxx_params_count = @{$cxx_param_names};

  die if $c_params_count != $cxx_params_count;

  my @c_prop_names = map { $self->_get_prop_name ($gir_class, $c_param_names->[$_], $cxx_param_names->[$_]) } 0 .. ($c_params_count - 1);

  Common::Output::Ctor::wrap_ctor $self,
                                  $c_constructor->get_param_types,
                                  $c_constructor->get_param_transfers,
                                  \@c_prop_names,
                                  $cxx_function->get_param_types,
                                  $cxx_function->get_param_names;
}

sub _on_wrap_create ($)
{
  my ($self) = @_;
  my $params = Common::Shared::parse_params $self->_extract_bracketed_text;
  my $types = [];
  my $names = [];

  foreach my $param (@{$params})
  {
    push @{$types}, $param->{'type'};
    push @{$names}, $param->{'name'};
  }

  Common::Output::Ctor::wrap_create $self, $types, $names;
}

sub _on_wrap_enum ($)
{
  my ($self) = @_;
  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);
  my $namespace = $repository->get_g_namespace_by_name ($module);
  my @args = Common::Shared::string_split_commas ($self->_extract_bracketed_text);

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cpp_type = Common::Util::string_trim(shift @args);
  my $c_type = Common::Util::string_trim(shift @args);
  my @sed = ();
  my $setup =
  {
    'ob(NO_GTYPE)' => undef,
    'a(sed)' => \@sed,
    'os(get_type_func)' => undef,
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  my @substs = ();

  for my $subst (@sed)
  {
    if ($subst =~ /^\s*s#([^#]+)#([^#]*)#\s*$/)
    {
      push @substs, $subst;
    }
    else
    {
      $self->fixed_warning ('sed:Badly formed value - delimiters have to be hashes (#).');
    }
  }

  my $flags = 0;
  my $enum = $namespace->get_g_enumeration_by_name ($c_type);

  unless (defined $enum)
  {
    $enum = $namespace->get_g_bitfield_by_name ($c_type);
    $flags = 1;
    unless (defined $enum)
    {
      $self->fixed_error ('No such enumeration or bitfield: `' . $c_type . '\'.');
    }
  }

  my $gir_gtype = $enum->get_a_glib_get_type;
  my $members = _extract_members $enum, \@substs;

  Common::Output::Enum::output ($self, $cpp_type, $members, $flags, $gir_gtype);
}

sub _on_wrap_gerror ($)
{
  my ($self) = @_;
  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);
  my $namespace = $repository->get_g_namespace_by_name ($module);
  my @args = Common::Shared::string_split_commas ($self->_extract_bracketed_text);

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cpp_type = Common::Util::string_trim (shift @args);
  my $c_type = Common::Util::string_trim (shift @args);
  my $enum = $namespace->get_g_enumeration_by_name ($c_type);

  if (@args)
  {
    my $arg = $args[0];

    if ($arg ne 'NO_GTYPE' and $arg !~ /^\s*s#[^#]+#[^#]*#\s*$/ and $arg !~ /^\s*get_type_func=.*$/)
    {
      $self->fixed_warning ('Domain parameter is deprecated.');
      shift @args;
    }
  }

  my @sed = ();
  my $setup =
  {
    'ob(NO_GTYPE)' => undef,
    'a(sed)' => \@sed,
    'os(get_type_func)' => undef,
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  my @substs = ();

  for my $subst (@sed)
  {
    if ($subst =~ /^\s*s#([^#]+)#([^#]*)#\s*$/)
    {
      push @substs, $subst;
    }
    else
    {
      $self->fixed_warning ('sed:Badly formed value - delimiters have to be hashes (#).');
    }
  }

  unless (defined $enum)
  {
    $self->fixed_error ('No such enumeration: `' . $c_type . '\'.');
  }

  my $gir_gtype = $enum->get_a_glib_get_type;
  my $gir_domain = $enum->get_a_glib_error_domain;
  my $members = _extract_members $enum, \@substs;

  Common::Output::GError::output $self, $cpp_type, $members, $gir_domain, $gir_gtype;
}

sub _on_implements_interface ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $interface = shift @args;
  my $ifdef = undef;
  my $setup =
  {
    's(ifdef)' => \$ifdef
  };

  $self->_handle_get_args_results (Common::Shared::get_args \@args, $setup);

  Common::Output::GObject::implements_interface $self, $interface, $ifdef;
}

sub _on_class_generic ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    $self->fixed_error ('Too few parameters.');
  }

  my $cpp_type = shift @args;
  my $c_type = shift @args;

  # Catch useless parameters.
  $self->_handle_get_args_results (Common::Shared::get_args \@args, {});

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my $gir_record = $namespace->get_g_record_by_name ($c_type);

  unless (defined $gir_record)
  {
    $self->fixed_error ('No such record: ' . $c_type);
# TODO: should we check also other things? like Union or Glib::Boxed?
  }

  $self->push_gir_record ($gir_record);

  Common::Output::Generic::output ($self, $c_type, $cpp_type);
}

sub _on_class_g_object ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 2)
  {
    $self->fixed_warning ('Last ' . @args - 2 . ' parameters are deprecated.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my $cpp_type = shift @args;
  my $c_type = shift @args;
  my $gir_class = $namespace->get_g_class_by_name ($c_type);

  unless (defined $gir_class)
  {
    $self->fixed_error ('No such class: ' . $c_type);
  }

  my $get_type_func = $gir_class->get_a_glib_get_type;

  unless (defined $get_type_func)
  {
    $self->fixed_error ('Class `' . $c_type . '\' has no get type function.');
  }

  my $gir_parent = $gir_class->get_a_parent;

  unless (defined $gir_parent)
  {
    $self->fixed_error ('Class `' . $c_type . '\' has no parent. (you are not wrapping GObject, are you?)');
  }

  my $gir_type_struct = $gir_class->get_a_glib_type_struct;

  unless (defined $gir_type_struct)
  {
    $self->fixed_error ('Class `' . $c_type . '\' has no Class struct.');
  }

  my @gir_prefixes = $namespace->get_a_c_identifier_prefixes;
  my $c_class_type = undef;

  foreach my $gir_prefix (@gir_prefixes)
  {
    my $temp_type = $gir_prefix . $gir_type_struct;

    if (defined $namespace->get_g_record_by_name ($temp_type))
    {
      $c_class_type = $temp_type;
      last;
    }
  }

  unless (defined $c_class_type)
  {
    $self->fixed_error ('Could not find any type struct (' . $gir_type_struct . ').');
  }

  my $c_parent_type = undef;
  my $c_parent_class_type = undef;

  # if parent is for example Gtk.Widget
  if ($gir_parent =~ /^([^.]+)\.(.*)/)
  {
    my $gir_parent_module = $1;
    my $gir_parent_type = $2;
    my $parent_repository = $repositories->get_repository ($gir_parent_module);

    unless (defined $parent_repository)
    {
      $self->fixed_error ('No such repository for parent: `' . $gir_parent_module . '\'.');
    }

    my $parent_namespace = $parent_repository->get_g_namespace_by_name ($gir_parent_module);

    unless (defined $parent_namespace)
    {
      $self->fixed_error ('No such namespace for parent: `' . $gir_parent_module . '\'.');
    }

    my @gir_parent_prefixes = split ',', $parent_namespace->get_a_c_identifier_prefixes;
    my $gir_parent_class = undef;

    foreach my $gir_parent_prefix (@gir_parent_prefixes)
    {
      my $temp_parent_type = $gir_parent_prefix . $gir_parent_type;

      $gir_parent_class = $parent_namespace->get_g_class_by_name ($temp_parent_type);

      if (defined $gir_parent_class)
      {
        $c_parent_type = $temp_parent_type;
        last;
      }
    }

    unless (defined $c_parent_type)
    {
      $self->fixed_error ('No such parent class in namespace: `' . $c_parent_type . '\.');
    }

    my $gir_parent_type_struct = $gir_parent_class->get_a_glib_type_struct;

    unless (defined $gir_parent_type_struct)
    {
      $self->fixed_error ('Parent of `' . $c_type . '\', `' . $c_parent_type . '\' has not Class struct.');
    }

    for my $gir_parent_prefix (@gir_parent_prefixes)
    {
      my $temp_parent_class_type = $gir_parent_prefix . $gir_parent_type_struct;
      my $gir_parent_class_struct = $parent_namespace->get_g_record_by_name ($temp_parent_class_type);

      if (defined $gir_parent_class_struct)
      {
        $c_parent_class_type = $temp_parent_class_type;
      }
    }

    unless (defined $c_parent_class_type)
    {
      $self->fixed_error ('Could not find type struct (' . $gir_parent_type_struct . ').');
    }
  }
  else
  {
    my $gir_parent_class = undef;

    foreach my $gir_prefix (@gir_prefixes)
    {
      my $temp_parent_type = $gir_prefix . $gir_parent;

      $gir_parent_class = $namespace->get_g_class_by_name ($temp_parent_type);

      if (defined $gir_parent_class)
      {
        $c_parent_type = $temp_parent_type;
        last;
      }
    }

    unless (defined $c_parent_type)
    {
      $self->fixed_error ('No such parent class in namespace: `' . $gir_parent . '\.');
    }

    my $gir_parent_type_struct = $gir_parent_class->get_a_glib_type_struct;

    unless (defined $gir_parent_type_struct)
    {
      $self->fixed_error ('Parent of `' . $c_type . '\', `' . $c_parent_type . '\' has not Class struct.');
    }

    for my $gir_prefix (@gir_prefixes)
    {
      my $temp_parent_class_type = $gir_prefix . $gir_parent_type_struct;
      my $gir_parent_class_struct = $namespace->get_g_record_by_name ($temp_parent_class_type);

      if (defined $gir_parent_class_struct)
      {
        $c_parent_class_type = $temp_parent_class_type;
      }
    }

    unless (defined $c_parent_class_type)
    {
      $self->fixed_error ('Could not find type struct (' . $gir_parent_type_struct . ').');
    }
  }

  my $type_info_store = $self->get_type_info_store;
# TODO: write an info about adding mapping when returned value
# TODO continued: is undefined.
  my $cpp_parent_type = $type_info_store->c_to_cpp ($c_parent_type);

  $self->_push_gir_class ($gir_class);
  $self->_push_c_class ($c_type);

  Common::Output::GObject::output $self,
                                  $c_type,
                                  $c_class_type,
                                  $c_parent_type,
                                  $c_parent_class_type,
                                  $get_type_func,
                                  $cpp_type,
                                  $cpp_parent_type;
}

# TODO: set current gir_class.
sub _on_class_gtk_object ($)
{

}

sub _on_class_boxed_type ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 5)
  {
    $self->fixed_warning ('Last ' . @args - 5 . ' parameters are deprecated.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my ($cpp_type, $c_type, $new_func, $copy_func, $free_func) = @args;
  my $gir_record = $namespace->get_g_record_by_name ($c_type);

  unless (defined $gir_record)
  {
    $self->fixed_error ('No such record: ' . $c_type);
  }

  my $get_type_func = $gir_record->get_a_glib_get_type;

  unless (defined $get_type_func)
  {
    $self->fixed_error ('Record `' . $c_type . '\' has no get type function.');
  }

# TODO: Check if we can support generating constructors with
# TODO continued: several parameters also.
  if (not defined $new_func or $new_func eq 'GUESS')
  {
    my $constructor_count = $gir_record->get_g_constructor_count;

    $new_func = undef;
    for (my $iter = 0; $iter < $constructor_count; ++$iter)
    {
      my $constructor = $gir_record->get_g_constructor_by_index ($iter);

      unless ($constructor->get_g_parameters_count)
      {
        $new_func = $constructor->get_a_c_identifier;
        last;
      }
    }
  }

  my @gir_prefixes = split ',', $namespace->get_a_c_symbol_prefixes;
  my $record_prefix = $gir_record->get_a_c_symbol_prefix;

  if (not defined $copy_func or $copy_func eq 'GUESS')
  {
    my $found_any = 0;

    $copy_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $ctor_suffix ('copy', 'ref')
      {
        my $copy_ctor_name = join '_', $prefix, $record_prefix, $ctor_suffix;
        my $copy_ctor = $gir_record->get_g_method_by_name ($copy_ctor_name);

        if (defined $copy_ctor)
        {
          $found_any = 1;
          unless ($copy_ctor->get_g_parameters_count)
          {
            $copy_func = $copy_ctor_name;
          }
        }
      }
    }

    unless (defined $copy_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a copy/ref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any copy/ref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($copy_func ne 'NONE')
  {
    my $copy_ctor = $gir_record->get_g_method_by_name ($copy_func);

    unless (defined $copy_ctor)
    {
      $self->fixed_error ('Could not find such copy/ref function in Gir file: `' . $copy_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Copy/ref function can not be NONE.');
  }

  if (not defined $free_func or $free_func eq 'GUESS')
  {
    my $found_any = 0;

    $free_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $dtor_suffix ('free', 'unref')
      {
        my $dtor_name = join '_', $prefix, $record_prefix, $dtor_suffix;
        my $dtor = $gir_record->get_g_method_by_name ($dtor_name);

        if (defined $dtor)
        {
          $found_any = 1;
          unless ($dtor->get_g_parameters_count)
          {
            $free_func = $dtor_name;
          }
        }
      }
    }

    unless (defined $free_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a free/unref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any free/unref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($free_func ne 'NONE')
  {
    my $dtor = $gir_record->get_g_method_by_name ($free_func);

    unless (defined $dtor)
    {
      $self->fixed_error ('Could not find such free/unref in Gir file: `' . $free_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Free/unref function can not be NONE.');
  }

  $self->push_gir_record ($gir_record);

  Common::Output::BoxedType::output $self,
                                    $c_type,
                                    $cpp_type,
                                    $get_type_func,
                                    $new_func,
                                    $copy_func,
                                    $free_func;
}

sub _on_class_boxed_type_static ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 2)
  {
    $self->fixed_warning ('Last ' . @args - 2 . ' parameters are useless.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my ($cpp_type, $c_type) = @args;
  my $gir_record = $namespace->get_g_record_by_name ($c_type);

  unless (defined $gir_record)
  {
    $self->fixed_error ('No such record: ' . $c_type);
  }

  my $get_type_func = $gir_record->get_a_glib_get_type;

  unless (defined $get_type_func)
  {
    $self->fixed_error ('Record `' . $c_type . '\' has no get type function.');
  }

  $self->push_gir_record ($gir_record);

  Common::Output::BoxedTypeStatic::output $self,
                                          $c_type,
                                          $cpp_type,
                                          $get_type_func;
}

sub _on_class_interface ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 2)
  {
    $self->fixed_warning ('Last ' . @args - 2 . ' parameters are deprecated.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my ($cpp_name, $c_name) = @args;
  my $gir_class = $namespace->get_g_class_by_name ($c_name);

  unless (defined $gir_class)
  {
    $self->fixed_error ('No such class: ' . $c_name);
  }

  my $get_type_func = $gir_class->get_a_glib_get_type;

  unless (defined $get_type_func)
  {
    $self->fixed_error ('Class `' . $c_name . '\' has no get type function.');
  }

  my $prerequisite_count = $gir_class->get_g_prerequisite_count;
  my $gir_parent = undef;

  for (my $iter = 0; $iter < $prerequisite_count; ++$iter)
  {
    my $prerequisite = $gir_class->get_g_prerequisite_by_index ($iter);

    if (defined $prerequisite)
    {
      my $prereq_name = $prerequisite->get_a_name;

      if ($prereq_name ne "GObject.Object")
      {
        $gir_parent = $prereq_name;
      }
    }
  }

  unless (defined $gir_parent)
  {
    $gir_parent = 'GObject.Object';
  }

  my $gir_type_struct = $gir_class->get_a_glib_type_struct;

  unless (defined $gir_type_struct)
  {
    $self->fixed_error ('Class `' . $c_name . '\' has no Iface struct.');
  }

  my @gir_prefixes = $namespace->get_a_c_identifier_prefixes;
  my $c_class_name = undef;

  foreach my $gir_prefix (@gir_prefixes)
  {
    my $temp_name = $gir_prefix . $gir_type_struct;

    if (defined $namespace->get_g_record_by_name ($temp_name))
    {
      $c_class_name = $temp_name;
      last;
    }
  }

  unless (defined $c_class_name)
  {
    $self->fixed_error ('Could not find any type struct (' . $gir_type_struct . ').');
  }

  my $c_parent_name = undef;

  # if parent is for example Gtk.Widget
  if ($gir_parent =~ /^([^.]+)\.(.*)/)
  {
    my $gir_parent_module = $1;
    my $gir_parent_name = $2;
    my $parent_repository = $repositories=>get_repository ($gir_parent_module);

    unless (defined $parent_repository)
    {
      $self->fixed_error ('No such repository for parent: `' . $gir_parent_module . '\'.');
    }

    my $parent_namespace = $parent_repository->get_g_namespace_by_name ($gir_parent_module);

    unless (defined $parent_namespace)
    {
      $self->fixed_error ('No such namespace for parent: `' . $gir_parent_module . '\'.');
    }

    my @gir_parent_prefixes = $parent_namespace->get_a_c_identifier_prefixes;

    foreach my $gir_parent_prefix (@gir_parent_prefixes)
    {
      my $temp_parent_name = $gir_parent_prefix . $gir_parent_name;
      my $gir_parent_class = $parent_namespace->get_g_class_by_name ($temp_parent_name);

      if (defined $gir_parent_class)
      {
        $c_parent_name = $temp_parent_name;
        last;
      }
    }

    unless (defined $c_parent_name)
    {
      $self->fixed_error ('No such parent class in namespace: `' . $c_parent_name . '\.');
    }
  }
  else
  {
    for my $gir_prefix (@gir_prefixes)
    {
      my $temp_parent_name = $gir_prefix . $gir_parent;
      my $gir_parent_class = $namespace->get_g_class_by_name ($temp_parent_name);

      if (defined $gir_parent_class)
      {
        $c_parent_name = $temp_parent_name;
        last;
      }
    }

    unless (defined $c_parent_name)
    {
      $self->fixed_error ('No such parent class in namespace: `' . $c_parent_name . '\.');
    }
  }

  my $type_info_store = $self->get_type_info_store;
  my $cpp_parent_name = $type_info_store->c_to_cpp ($c_parent_name);

  $self->_push_gir_class ($gir_class);

  Common::Output::Interface::output $self,
                                    $c_name,
                                    $c_class_name,
                                    $c_parent_name,
                                    $cpp_name,
                                    $cpp_parent_name,
                                    $get_type_func;
}

# TODO: some of the code here duplicates the code in next
# TODO continued: method.
sub _on_class_opaque_copyable ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 5)
  {
    $self->fixed_warning ('Last ' . @args - 2 . ' parameters are useless.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my ($cpp_type, $c_type, $new_func, $copy_func, $free_func) = @args;
  my $gir_record = $namespace->get_g_record_by_name ($c_type);

  unless (defined $gir_record)
  {
    $self->fixed_error ('No such record: ' . $c_type);
  }

# TODO: Check if we can support generating constructors with
# TODO continued: several parameters also.
  if (not defined $new_func or $new_func eq 'GUESS')
  {
    my $constructor_count = $gir_record->get_g_constructor_count;

    $new_func = undef;
    for (my $iter = 0; $iter < $constructor_count; ++$iter)
    {
      my $constructor = $gir_record->get_g_constructor_by_index ($iter);

      unless ($constructor->get_g_parameters_count)
      {
        $new_func = $constructor->get_a_c_identifier;
        last;
      }
    }
  }

  my @gir_prefixes = split ',', $namespace->get_a_c_symbol_prefixes;
  my $record_prefix = $gir_record->get_a_c_symbol_prefix;

  if (not defined $copy_func or $copy_func eq 'GUESS')
  {
    my $found_any = 0;

    $copy_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $ctor_suffix ('copy', 'ref')
      {
        my $copy_ctor_name = join '_', $prefix, $record_prefix, $ctor_suffix;
        my $copy_ctor = $gir_record->get_g_method_by_name ($copy_ctor_name);

        if (defined $copy_ctor)
        {
          $found_any = 1;
          unless ($copy_ctor->get_g_parameters_count)
          {
            $copy_func = $copy_ctor_name;
          }
        }
      }
    }

    unless (defined $copy_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a copy/ref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any copy/ref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($copy_func ne 'NONE')
  {
    my $copy_ctor = $gir_record->get_g_method_by_name ($copy_func);

    unless (defined $copy_ctor)
    {
      $self->fixed_error ('Could not find such copy/ref function in Gir file: `' . $copy_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Copy/ref function can not be NONE.');
  }

  if (not defined $free_func or $free_func eq 'GUESS')
  {
    my $found_any = 0;

    $free_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $dtor_suffix ('free', 'unref')
      {
        my $dtor_name = join '_', $prefix, $record_prefix, $dtor_suffix;
        my $dtor = $gir_record->get_g_method_by_name ($dtor_name);

        if (defined $dtor)
        {
          $found_any = 1;
          unless ($dtor->get_g_parameters_count)
          {
            $free_func = $dtor_name;
          }
        }
      }
    }

    unless (defined $free_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a free/unref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any free/unref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($free_func ne 'NONE')
  {
    my $dtor = $gir_record->get_g_method_by_name ($free_func);

    unless (defined $dtor)
    {
      $self->fixed_error ('Could not find such free/unref in Gir file: `' . $free_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Free/unref function can not be NONE.');
  }

  $self->push_gir_record ($gir_record);

  Common::Output::OpaqueCopyable::output $self,
                                         $c_type,
                                         $cpp_type,
                                         $new_func,
                                         $copy_func,
                                         $free_func;
}

# TODO: some of the code below duplicates the code in method
# TODO continued: above.
sub _on_class_opaque_refcounted ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args > 5)
  {
    $self->fixed_warning ('Last ' . @args - 2 . ' parameters are useless.');
  }

  my $repositories = $self->get_repositories;
  my $module = $self->get_module;
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->fixed_error ('No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->fixed_error ('No such namespace: ' . $module);
  }

  my ($cpp_type, $c_type, $new_func, $copy_func, $free_func) = @args;
  my $gir_record = $namespace->get_g_record_by_name ($c_type);

  unless (defined $gir_record)
  {
    $self->fixed_error ('No such record: ' . $c_type);
  }

# TODO: Check if we can support generating constructors with
# TODO continued: with several parameters also.
  if (not defined $new_func or $new_func eq 'GUESS')
  {
    my $constructor_count = $gir_record->get_g_constructor_count;

    $new_func = undef;
    for (my $iter = 0; $iter < $constructor_count; ++$iter)
    {
      my $constructor = $gir_record->get_g_constructor_by_index ($iter);

      unless ($constructor->get_g_parameters_count)
      {
        $new_func = $constructor->get_a_c_identifier;
        last;
      }
    }
  }

  my @gir_prefixes = split ',', $namespace->get_a_c_symbol_prefixes;
  my $record_prefix = $gir_record->get_a_c_symbol_prefix;

  if (not defined $copy_func or $copy_func eq 'GUESS')
  {
    my $found_any = 0;

    $copy_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $ctor_suffix ('ref', 'copy')
      {
        my $copy_ctor_name = join '_', $prefix, $record_prefix, $ctor_suffix;
        my $copy_ctor = $gir_record->get_g_method_by_name ($copy_ctor_name);

        if (defined $copy_ctor)
        {
          $found_any = 1;
          unless ($copy_ctor->get_g_parameters_count)
          {
            $copy_func = $copy_ctor_name;
          }
        }
      }
    }

    unless (defined $copy_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a copy/ref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any copy/ref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($copy_func ne 'NONE')
  {
    my $copy_ctor = $gir_record->get_g_method_by_name ($copy_func);

    unless (defined $copy_ctor)
    {
      $self->fixed_error ('Could not find such copy/ref function in Gir file: `' . $copy_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Copy/ref function can not be NONE.');
  }

  if (not defined $free_func or $free_func eq 'GUESS')
  {
    my $found_any = 0;

    $free_func = undef;
    for my $prefix (@gir_prefixes)
    {
      for my $dtor_suffix ('unref', 'free')
      {
        my $dtor_name = join '_', $prefix, $record_prefix, $dtor_suffix;
        my $dtor = $gir_record->get_g_method_by_name ($dtor_name);

        if (defined $dtor)
        {
          $found_any = 1;
          unless ($dtor->get_g_parameters_count)
          {
            $free_func = $dtor_name;
          }
        }
      }
    }

    unless (defined $free_func)
    {
      if ($found_any)
      {
        $self->fixed_error ('Found a free/unref function, but its prototype was not the expected one. Please specify its name explicitly. Note that NONE is not allowed.');
      }
      else
      {
        $self->fixed_error ('Could not find any free/unref function. Please specify its name explicitly. Note that NONE is not allowed.');
      }
    }
  }
  elsif ($free_func ne 'NONE')
  {
    my $dtor = $gir_record->get_g_method_by_name ($free_func);

    unless (defined $dtor)
    {
      $self->fixed_error ('Could not find such free/unref in Gir file: `' . $free_func . '\'.');
    }
  }
  else
  {
    $self->fixed_error ('Free/unref function can not be NONE.');
  }

  $self->push_gir_record ($gir_record);

  Common::Output::OpaqueRefcounted::output $self,
                                           $c_type,
                                           $cpp_type,
                                           $new_func,
                                           $copy_func,
                                           $free_func;
}

sub _on_namespace_keyword ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my $name = '';
  my $done = 0;
  my $in_s_comment = 0;
  my $in_m_comment = 0;

# TODO: why _extract_token is not used here?
  # we need to peek ahead to figure out what type of namespace
  # declaration this is.
  foreach my $token (@{$tokens})
  {
    next if (not defined $token or $token eq '');

    if ($in_s_comment)
    {
      if ($token eq "\n")
      {
        $in_s_comment = 0;
      }
    }
    elsif ($in_m_comment)
    {
      if ($token eq '*/')
      {
        $in_m_comment = 0;
      }
    }
    elsif ($token eq '//')
    {
      $in_s_comment = 1;
    }
    elsif ($token eq '/*' or $token eq '/**')
    {
      $in_m_comment = 1;
    }
    elsif ($token eq '{')
    {
      my $level = $self->get_level;
      my $namespaces = $self->get_namespaces;
      my $namespace_levels = $self->get_namespace_levels;

      $name = Common::Util::string_trim ($name);
      push @{$namespaces}, $name;
      push @{$namespace_levels}, $level + 1;

      if (@{$namespaces} == 1)
      {
        $self->generate_first_namespace_number;

        my $section = Common::Output::Shared::get_section $self, Common::Sections::H_BEFORE_FIRST_NAMESPACE;

        $section_manager->append_section_to_section ($section, $main_section);
      }

      $done = 1;
    }
    elsif ($token eq ';')
    {
      $done = 1;
    }
    elsif ($token !~ /\s/)
    {
      if ($name ne '')
      {
        $self->fixed_error ('Unexpected `' . $token . '\' after namespace name.');
      }
      $name = $token;
    }

    if ($done)
    {
      $section_manager->append_string_to_section ('namespace', $main_section);
      return;
    }
  }
  $self->fixed_error ('Hit eof while processing `namespace\'.');
}

sub _on_insert_section ($)
{
  my ($self) = @_;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my $str = Common::Util::string_trim $self->_extract_bracketed_text;

  $section_manager->append_section_to_section ($str, $main_section);
}

sub _on_class_keyword ($)
{
  my ($self) = @_;
  my $tokens = $self->get_tokens;
  my $section_manager = $self->get_section_manager;
  my $main_section = $self->get_main_section;
  my $name = '';
  my $done = 0;
  my $in_s_comment = 0;
  my $in_m_comment = 0;
  my $colon_met = 0;

  # we need to peek ahead to figure out what type of class
  # declaration this is.
  foreach my $token (@{$tokens})
  {
    next if (not defined $token or $token eq '');

    if ($in_s_comment)
    {
      if ($token eq "\n")
      {
        $in_s_comment = 0;
      }
    }
    elsif ($in_m_comment)
    {
      if ($token eq '*/')
      {
        $in_m_comment = 0;
      }
    }
    elsif ($token eq '//' or $token eq '///' or $token eq '//!')
    {
      $in_s_comment = 1;
    }
    elsif ($token eq '/*' or $token eq '/**' or $token eq '/*!')
    {
      $in_m_comment = 1;
    }
    elsif ($token eq '{')
    {
      my $level = $self->get_level;
      my $classes = $self->get_classes;
      my $class_levels = $self->get_class_levels;

      $name =~ s/\s+//g;
      push @{$classes}, $name;
      push @{$class_levels}, $level + 1;

      if (@{$classes} == 1)
      {
        $self->generate_first_class_number;

        my $section = Common::Output::Shared::get_section $self, Common::Sections::H_BEFORE_FIRST_CLASS;

        $section_manager->append_section_to_section ($section, $main_section);
      }

      $done = 1;
    }
    elsif ($token eq ';')
    {
      $done = 1;
    }
    elsif ($token eq ':')
    {
      $colon_met = 1;
    }
    elsif ($token !~ /\s/)
    {
      unless ($colon_met)
      {
        $name .= $token;
      }
    }

    if ($done)
    {
      $section_manager->append_string_to_section ('class', $main_section);
      return;
    }
  }
  $self->fixed_error ('Hit eof while processing `class\'.');
}

sub _on_module ($)
{
  my ($self) = @_;
  my $str = Common::Util::string_trim $self->_extract_bracketed_text;

  $self->{'module'} = $str;
}

sub _on_pinclude ($)
{
  my ($self) = @_;
  my $str = Common::Util::string_trim $self->_extract_bracketed_text;

  Common::Output::Misc::p_include $self, $str;
}

###
### HANDLERS ABOVE
###

sub get_stage_section_tuples ($)
{
  my ($self) = @_;

  return $self->{'stage_section_tuples'}
}

sub set_filename ($$)
{
  my ($self, $filename) = @_;

  $self->{'filename'} = $filename;
}

sub get_filename ($)
{
  my ($self) = @_;

  return $self->{'filename'};
}

sub get_base ($)
{
  my ($self) = @_;

  return $self->{'base'};
}

# TODO: private
sub _switch_to_stage ($$)
{
  my ($self, $stage) = @_;
  my $pairs = $self->get_stage_section_tuples;

  if (exists $pairs->{$stage})
  {
    my $tuple = $pairs->{$stage};
    my $main_section = $tuple->[0][0];
    my $tokens = $tuple->[1];
    my $ext = $tuple->[2];
    my $filename = join '.', $self->get_base, $ext;

    $self->set_parsing_stage ($stage);
    $self->set_main_section ($pairs->{$stage}[0][0]);
    $self->set_tokens ($self->{$pairs->{$stage}[1]});
    $self->set_filename ($filename);
  }
  else
  {
# TODO: internal error.
    die;
  }
}

sub get_repositories ($)
{
  my ($self) = @_;

  return $self->{'repositories'};
}

# public
sub new ($$$$$$$)
{
  my ($type, $tokens_hg, $tokens_ccg, $type_info_store, $repositories, $conversions_store, $mm_module, $base) = @_;
  my $class = (ref $type or $type or 'Common::WrapParser');
  my $self =
  {
# TODO: check if all those fields are really needed.
    'line_num' => 0,
    'fixed_line_num' => 0,
    'level' => 0,
    'classes' => [],
    'class_levels' => [],
    'namespaces' => [],
    'namespace_levels' => [],
    'module' => '',
    'repositories' => $repositories,
    'tokens_hg' => [@{$tokens_hg}],
    'tokens_ccg' => [@{$tokens_ccg}],
    'tokens_null' => [],
    'tokens' => [],
    'parsing_stage' => STAGE_INVALID,
    'main_section' => Common::Sections::DEV_NULL->[0],
    'section_manager' => Common::SectionManager->new ($base, $mm_module),
    'stage_section_tuples' =>
    {
      STAGE_HG() => [Common::Sections::H, 'tokens_hg', 'hg'],
      STAGE_CCG() => [Common::Sections::CC, 'tokens_ccg', 'ccg'],
      STAGE_INVALID() => [Common::Sections::DEV_NULL, 'tokens_null', 'BAD']
    },
    'type_info_store' => $type_info_store,
    'counter' => 0,
    'conversions_store' => Common::ConversionsStore->new_local ($conversions_store),
    'gir_stack' => [],
    'c_stack' => [],
    'mm_module' => $mm_module,
    'base' => $base,
    'filename' => undef
  };

  $self = bless $self, $class;
  $self->{'handlers'} =
  {
    '{' => [$self, \&_on_open_brace],
    '}' => [$self, \&_on_close_brace],
#    '`' => [$self, \&_on_backtick], # probably won't be needed anymore
#    '\'' => [$self, \&_on_apostrophe], # probably won't be needed anymore
    '"' => [$self, \&_on_string_literal],
    '//' => [$self, \&_on_comment_cpp],
    '///' => [$self, \&_on_comment_doxygen_single],
    '//!' => [$self, \&_on_comment_doxygen_single],
    '/*' => [$self, \&_on_comment_c],
    '/**' => [$self, \&_on_comment_doxygen],
    '/*!' => [$self, \&_on_comment_doxygen],
    '#m4begin' => [$self, \&_on_m4_section], # probably won't be needed anymore
    '#m4' => [$self, \&_on_m4_line], # probably won't be needed anymore
    '_DEFS' => [$self, \&_on_defs], # probably won't be needed anymore
    '_IGNORE' => [$self, \&_on_ignore],
    '_IGNORE_SIGNAL' => [$self, \&_on_ignore_signal],
    '_WRAP_METHOD' => [$self, \&_on_wrap_method],
    '_WRAP_METHOD_DOCS_ONLY' => [$self, \&_on_wrap_method_docs_only],
#    '_WRAP_CORBA_METHOD'=> [$self, \&_on_wrap_corba_method],
    '_WRAP_SIGNAL' => [$self, \&_on_wrap_signal],
    '_WRAP_PROPERTY' => [$self, \&_on_wrap_property],
    '_WRAP_VFUNC' => [$self, \&_on_wrap_vfunc],
    '_WRAP_CTOR' => [$self, \&_on_wrap_ctor],
    '_WRAP_CREATE' => [$self, \&_on_wrap_create],
    '_WRAP_ENUM' => [$self, \&_on_wrap_enum],
    '_WRAP_GERROR' => [$self, \&_on_wrap_gerror],
    '_IMPLEMENTS_INTERFACE' => [$self, \&_on_implements_interface],
    '_CLASS_GENERIC' => [$self, \&_on_class_generic],
    '_CLASS_GOBJECT' => [$self, \&_on_class_g_object],
    '_CLASS_GTKOBJECT' => [$self, \&_on_class_gtk_object],
    '_CLASS_BOXEDTYPE' => [$self, \&_on_class_boxed_type],
    '_CLASS_BOXEDTYPE_STATIC' => [$self, \&_on_class_boxed_type_static],
    '_CLASS_INTERFACE' => [$self, \&_on_class_interface],
    '_CLASS_OPAQUE_COPYABLE' => [$self, \&_on_class_opaque_copyable],
    '_CLASS_OPAQUE_REFCOUNTED' => [$self, \&_on_class_opaque_refcounted],
    'namespace' => [$self, \&_on_namespace_keyword],
    '_INSERT_SECTION' => [$self, \&_on_insert_section],
    'class' => [$self, \&_on_class_keyword],
    '_MODULE' => [$self, \&_on_module],
    '_PINCLUDE' => [$self, \&_on_pinclude]
  };

  return $self;
}

sub get_type_info_store ($)
{
  my ($self) = @_;

  return $self->{'type_info_store'};
}

sub get_number ($)
{
  my ($self) = @_;
  my $c = 'counter';
  my $number = $self->{$c};

  ++$self->{$c};
  return $number;
}

sub get_conversions_store ($)
{
  my ($self) = @_;

  return $self->{'conversions_store'};
}

sub generate_first_class_number ($)
{
  my ($self) = @_;

  $self->{'first_class_number'} = $self->get_number;
}

sub get_first_class_number ($)
{
  my ($self) = @_;

  return $self->{'first_class_number'};
}

sub generate_first_namespace_number ($)
{
  my ($self) = @_;

  $self->{'first_namespace_number'} = $self->get_number;
}

sub get_first_namespace_number ($)
{
  my ($self) = @_;

  $self->{'first_namespace_number'};
}

# public
sub get_namespaces ($)
{
  my ($self) = @_;

  return $self->{'namespaces'};
}

sub get_namespace_levels ($)
{
  my ($self) = @_;

  return $self->{'namespace_levels'};
}

sub get_classes ($)
{
  my ($self) = @_;

  return $self->{'classes'};
}

sub get_class_levels ($)
{
  my ($self) = @_;

  return $self->{'class_levels'};
}

# public
sub get_section_manager ($)
{
  my ($self) = @_;

  return $self->{'section_manager'};
}

# public
sub get_main_section ($)
{
  my ($self) = @_;

  return $self->{'main_section'};
}

sub set_main_section ($$)
{
  my ($self, $main_section) = @_;

  $self->{'main_section'} = $main_section;
}

sub set_parsing_stage ($$)
{
  my ($self, $parsing_stage) = @_;

  $self->{'parsing_stage'} = $parsing_stage;
}

sub set_tokens ($$)
{
  my ($self, $tokens) = @_;

  $self->{'tokens'} = $tokens;
}

sub get_tokens ($)
{
  my ($self) = @_;

  return $self->{'tokens'};
}

sub get_line_num ($)
{
  my ($self) = @_;

  return $self->{'line_num'};
}

sub inc_line_num ($$)
{
  my ($self, $inc) = @_;

  $self->{'line_num'} += $inc;
}

sub _set_fixed_line_num ($)
{
  my ($self) = @_;

  $self->{'fixed_line_num'} = $self->get_line_num;
}

sub _get_fixed_line_num ($)
{
  my ($self) = @_;

  return $self->{'fixed_line_num'};
}

sub get_current_macro ($)
{
  my ($self) = @_;

  return $self->{'current_macro'};
}

sub _set_current_macro ($$)
{
  my ($self, $macro) = @_;

  $self->{'current_macro'} = $macro;
}

sub get_level ($)
{
  my ($self) = @_;

  return $self->{'level'};
}

sub dec_level ($)
{
  my ($self) = @_;

  --$self->{'level'};
}

sub inc_level ($)
{
  my ($self) = @_;

  ++$self->{'level'};
}

sub get_module ($)
{
  my ($self) = @_;

  return $self->{'module'};
}

sub get_mm_module ($)
{
  my ($self) = @_;

  return $self->{'mm_module'};
}

sub parse ($)
{
  my ($self) = @_;
  my $handlers = $self->{'handlers'};
  my $section_manager = $self->get_section_manager;
  my @stages = (STAGE_HG, STAGE_CCG);

  for my $stage (@stages)
  {
    $self->_switch_to_stage ($stage);

    my $tokens = $self->get_tokens;

    while (@{$tokens})
    {
      my $token = $self->_extract_token;

      if (exists $handlers->{$token})
      {
        print 'Currently parsing: ' . $token . "\n";

        my $pair = $handlers->{$token};
        my $object = $pair->[0];
        my $handler = $pair->[1];

        $self->_set_current_macro ($token);
        $self->_set_fixed_line_num;

        if (defined $object)
        {
          $object->$handler;
        }
        else
        {
          &{$handler};
        }
      }
      else
      {
        my $main_section = $self->get_main_section;
        # no handler found - just paste the token to main section
        $section_manager->append_string_to_section ($token, $main_section);
# TODO: remove it later.
        if ($token =~ /^[A-Z_]+$/)
        {
          print STDERR $token . ": Possible not implemented token!\n";
        }
      }
    }
  }
}

# TODO: warning and error functions should not print messages
# TODO continued: immediately - they should just put messages
# TODO continued: into an array and that would be printed by
# TODO continued: Gmmproc.

sub _print_with_loc ($$$$$)
{
  my ($self, $line_num, $type, $message, $fatal) = @_;
  my $full_message = join '', (join ':', $self->{'filename'}, $self->get_current_macro, $line_num, $type, $message), "\n";

  print STDERR $full_message;

  if ($fatal)
  {
# TODO: throw an exception or something.
    exit 1;
  }
}

sub error_with_loc ($$$)
{
  my ($self, $line_num, $message) = @_;
  my $type = 'ERROR';
  my $fatal = 1;

  $self->_print_with_loc ($line_num, $type, $message, $fatal);
}

sub error ($$)
{
  my ($self, $message) = @_;

  $self->error_with_loc ($self->get_line_num, $message);
}

sub fixed_error ($$)
{
  my ($self, $message) = @_;
  my $line_num = $self->_get_fixed_line_num;

  $self->error_with_loc ($line_num, $message);
}

sub fixed_error_non_fatal ($$)
{
  my ($self, $message) = @_;
  my $line_num = $self->_get_fixed_line_num;
  my $type = 'ERROR';
  my $fatal = 0;

  $self->_print_with_loc ($line_num, $type, $message, $fatal);
}

sub warning_with_loc ($$$)
{
  my ($self, $line_num, $message) = @_;
  my $type = 'WARNING';
  my $fatal = 0;

  $self->_print_with_loc ($line_num, $type, $message, $fatal);
}

sub warning ($$)
{
  my ($self, $message) = @_;

  $self->warning_with_loc ($self->get_line_num, $message);
}

sub fixed_warning ($$)
{
  my ($self, $message) = @_;
  my $line_num = $self->_get_fixed_line_num;

  $self->warning_with_loc ($line_num, $message);
}

1; # indicate proper module load.
