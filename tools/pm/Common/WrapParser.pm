# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::WrapParser module
#
# Copyright 2011 glibmm development team
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

use Common::Util;
use Common::SectionManager;
use Common::Output::Shared;
use Common::Output::Gobject;
use constant
{
  'STAGE_HG' => 0,
  'STAGE_CCG' => 1,
  'STAGE_INVALID' => 2
};

############################################################################

sub nl
{
  return (shift or '') . "\n";
}

# public
sub new ($$$)
{
  my ($type, $repositories, $gir_namespace) = @_;
  my $class = (ref ($type) or $type or 'Common::WrapParser');
  my $self =
  {
    # TODO: check if all those fields are really needed.
    'filename' => '(none)',
    'line_num' => 0,
    'level' => 0,
    'class' => '',
    'c_class' => '',
    'in_class' => 0,
    'first_namespace' => 1,
    'namespace' => [],
    'in_namespace' => [],
    'defsdir' => ".",
    'module' => $gir_namespace,
    'type' => "GTKOBJECT", # or "BOXEDTYPE", or "GOBJECT" - wrapped differently.
    'already_read' => {},
    'repositories' => $repositories,
    'tokens_hg' => [],
    'tokens_ccg' => [],
    'tokens_null' => [],
    'tokens' => [],
    'parsing_stage' => STAGE_INVALID,
    'main_section' => Common::SectionManager::SECTION_DEV_NULL,
    'section_manager' => Common::SectionManager->new,
    'stage_section_pairs' =>
    {
      STAGE_HG() => [Common::SectionManager::SECTION_H, 'tokens_hg'],
      STAGE_CCG() => [Common::SectionManager::SECTION_CC, 'tokens_ccg'],
      STAGE_INVALID() => [Common::SectionManager::SECTION_DEV_NULL, 'tokens_null']
    },
    'source_dir' => undef,
    'destination_dir' => undef,
    'base' => undef
  };

  $self = bless ($self, $class);
  $self->{'handlers'} =
  {
    '{' => [$self, \&on_open_brace],
    '}' => [$self, \&on_close_brace],
    '`' => [$self, \&on_backtick], # probably won't be needed anymore
    '\'' => [$self, \&on_apostrophe], # probably won't be needed anymore
    '"' => [$self, \&on_string_literal],
    '//' => [$self, \&on_comment_cpp],
    '/*' => [$self, \&on_comment_c],
    '/**' => [$self, \&on_comment_doxygen],
    '#m4begin' => [$self, \&on_m4_section], # probably won't be needed anymore
    '#m4' => [$self, \&on_m4_line], # probably won't be needed anymore
    '_DEFS' => [$self, \&on_defs], # probably won't be needed anymore
    '_IGNORE' => [$self, \&on_ignore],
    '_IGNORE_SIGNAL' => [$self, \&on_ignore_signal],
    '_WRAP_METHOD' => [$self, \&on_wrap_method],
    '_WRAP_METHOD_DOCS_ONLY' => [$self, \&on_wrap_method_docs_only],
    '_WRAP_CORBA_METHOD'=> [$self, \&on_wrap_corba_method],
    '_WRAP_SIGNAL' => [$self, \&on_wrap_signal],
    '_WRAP_PROPERTY' => [$self, \&on_wrap_property],
    '_WRAP_VFUNC' => [$self, \&on_wrap_vfunc],
    '_WRAP_CTOR' => [$self, \&on_wrap_ctor],
    '_WRAP_CREATE' => [$self, \&on_wrap_create],
    '_WRAP_ENUM' => [$self, \&on_wrap_enum],
    '_WRAP_GERROR' => [$self, \&on_wrap_gerror],
    '_IMPLEMENTS_INTERFACE' => [$self, \&on_implements_interface],
    # TODO: these should be handled by different handlers.
    '_CLASS_GENERIC' => [$self, \&on_class_generic],
    '_CLASS_GOBJECT' => [$self, \&on_class_gobject],
    '_CLASS_GTKOBJECT' => [$self, \&on_class],
    '_CLASS_BOXEDTYPE' => [$self, \&on_class],
    '_CLASS_BOXEDTYPE_STATIC' => [$self, \&on_class],
    '_CLASS_INTERFACE' => [$self, \&on_class],
    '_CLASS_OPAQUE_COPYABLE' => [$self, \&on_class],
    '_CLASS_OPAQUE_REFCOUNTED' => [$self, \&on_class],
    'namespace' => [$self, \&on_namespace],
    '_INSERT_SECTION' => [$self, \&on_insert_section]
  };



  return bless ($self, $class);
}

# public
sub set_source_dir ($$)
{
  my ($self, $source_dir) = @_;

  $self->{'source_dir'} = $source_dir;
}

# public
sub set_destination_dir ($$)
{
  my ($self, $destination_dir) = @_;

  $self->{'destination_dir'} = $destination_dir;
}

# public
sub set_base ($$)
{
  my ($self, $base) = @_;

  $self->{'base'} = $base;
}

# public
sub get_namespaces ($)
{
  my ($self) = @_;

  return $self->{'namespace'};
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

sub switch_to_stage ($$)
{
  my ($self, $stage) = @_;
  my $pairs = $self->{'stage_section_pairs'};

  if (exists $pairs->{$stage})
  {
    $self->{'parsing_stage'} = $stage;
    $self->{'main_section'} = $pairs->{$stage}[0];
    $self->{'tokens'} = $self->{$pairs->{$stage}[1]};
  }
  else
  {
    # TODO: internal error.
  }
}

# public
sub parse ($)
{
  my ($self) = @_;

  $self->read_file;
  $self->parse_and_build_output;
}

# void parse_and_build_output()
sub parse_and_build_output ($)
{
  my ($self) = @_;
  my $handlers = $self->{'handlers'};
  my $section_manager = $self->{'section_manager'};
  my @stages = (STAGE_HG, STAGE_CCG);

  for my $stage (@stages)
  {
    $self->switch_to_stage ($stage);

    my $tokens = $self->{'tokens'};

    while (@{$tokens})
    {
      my $token = $self->extract_token;

      if (exists $handlers->{$token})
      {
        my $pair = $handlers->{$token};
        my $object = $pair->[0];
        my $handler = $pair->[1];

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
        my $main_section = $self->{'main_section'};
        # no handler found - just paste the token to main section
        $section_manager->append_string_to_section ($token, $main_section);
      }
    }
  }

  my $destination_dir = $self->{'destination_dir'};
  my $base = $self->{'base'};
  my $h_file = File::Spec->catfile ($destination_dir, $base . '.h');
  my $cc_file = File::Spec->catfile ($destination_dir, $base . '.cc');
  my $p_h_file = File::Spec->catfile ($destination_dir, 'private', $base . '_p.h');

  $section_manager->write_main_section_to_file (Common::SectionManager::SECTION_H, $h_file);
  $section_manager->write_main_section_to_file (Common::SectionManager::SECTION_CC, $cc_file);
  $section_manager->write_main_section_to_file (Common::SectionManager::SECTION_P_H, $p_h_file);
}

sub error_with_loc ($$$)
{
  my ($self, $line_num, $message) = @_;

  print STDERR $self->{'filename'} . ':' . $line_num . ' - ERROR: ' . $message . "\n";
  exit 1;
}

sub error ($$)
{
  my ($self, $message) = @_;

  $self->error_with_loc ($self->{'line_num'}, $message);
}

sub warning_with_loc ($$$)
{
  my ($self, $line_num, $message) = @_;

  print STDERR $self->{'filename'} . ':' . $line_num . ' - WARNING: ' . $message;
}

sub warning ($$)
{
  my ($self, $message) = @_;

  $self->warning_with_loc ($self->{'line_num'}, $message);
}

######################################################################
##### 1.1 parser subroutines

########################################
###  returns the next token, ignoring some stuff.
# $string extract_token()
sub extract_token ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};

  while (@{$tokens})
  {
    my $token = shift @{$tokens};

    # skip empty tokens
    next if (not defined ($token) or $token eq '');

    if ($token =~ /\n/)
    {
      ++$self->{'line_num'};
    }

    return $token;
  }

  return '';
}

### Returns the next token, but does not remove it from the queue, so that
# extract_token will return it again.
# $string peek_token()
sub peek_token ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};

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

sub on_string_with_delimiters ($$$$)
{
  my ($self, $start, $end, $what) = @_;
  my $tokens = $self->{'tokens'};
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};
  my @out = ($start);
  my $line_num = $self->{'line_num'};

  while (@{$tokens})
  {
    my $token = $self->extract_token;

    push @out, $token;
    if ($token eq $end)
    {
      $section_manager->append_string_to_section (join ('', @out), $main_section);
      return;
    }
  }
  $self->error_with_loc ($line_num, 'Hit eof while in ' . $what . '.');
}

########################################
###  we pass strings literally with quote substitution
# void on_string_literal()
sub on_string_literal ($)
{
  my ($self) = @_;

  $self->on_string_with_delimiters ('"', '"', 'string');
}


########################################
###  we pass comments literally
# void on_comment_cpp()
sub on_comment_cpp ($)
{
  my ($self) = @_;

  $self->on_string_with_delimiters ('//', "\n", 'C++ comment');
}


########################################
###  we pass C comments literally
# void on_comment_c()
sub on_comment_c ($)
{
  my ($self) = @_;

  $self->on_string_with_delimiters ('/*', '*/', 'C comment');
}

sub on_comment_doxygen ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};
  my @out =  ('/**');
  my $line_num = $self->{'line_num'};

  while (@{$tokens})
  {
    my $token = $self->extract_token;

    if ($token eq '*/')
    {
      push @out, '*';
      # Find next non-whitespace token, but remember whitespace so that we
      # can print it if the next real token is not _WRAP_SIGNAL
      my @whitespace = ();
      my $next_token = $self->peek_token;
      while ($next_token !~ /\S/)
      {
        push @whitespace, $self->extract_token;
        $next_token = $self->peek_token;
      }

      # If the next token is a signal, do not close this comment, to merge
      # this doxygen comment with the one from the signal.
      if ($next_token eq '_WRAP_SIGNAL')
      {
        # Extract token and process
        $self->extract_token();
        # Tell wrap_signal to merge automatically generated comment with
        # already existing comment. This is why we do not close the comment
        # here.
        return $self->on_wrap_signal_after_comment(\@out);
      }
      else
      {
        # Something other than signal follows, so close comment normally
        # and append whitespace we ignored so far.
        push @out, '/', @whitespace;
        return join '', @out;
      }

      last;
    }

    push @out, $token;
  }
  $self->error_with_loc ($line_num, 'Hit eof while in doxygen comment.');
}

#TODO: get rid of it?
########################################
###  handle #m4begin ... #m4end
# we don't substitute ` or ' in #m4begin
# void on_m4_section()
sub on_m4_section($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};
  my $line_num = $self->{'line_num'};

  $self->warning ('#m4begin and #m4end are deprecated.');

  while (@{$tokens})
  {
    return if ($self->extract_token eq '#m4end');
  }

  $self->error_with_loc ($line_num, 'Hit eof when looking for #m4end.');
}

# TODO: get rid of it?
########################################
###  handle #m4 ... /n
# we don't substitute ` or ' in #m4
# void on_m4_line()
sub on_m4_line ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};
  my $line_num = $self->{'line_num'};

  $self->warning ('#m4 is deprecated.');

  while (@{$tokens})
  {
    return if ($self->extract_token eq "\n");
  }

  $self->error_with_loc ($line_num, 'Hit eof when looking for newline');
}

########################################
# m4 needs to know when we entered a namespace
# void on_namespace()
sub on_namespace ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};
  my $name = '';
  my $done = 0;
  my $in_s_comment = 0;
  my $in_m_comment = 0;
  my $line_num = $self->{'line_num'};

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
      $name = Util::string_trim ($name);

      if ($self->{'first_namespace'})
      {
        $self->{'first_namespace'} = 0;
        $section_manager->append_section_to_section ('SECTION_BEFORE_FIRST_NAMESPACE', $main_section);
      }

#      this is probably not needed - m4 needed that to know what namespaces
#      were opened, so it could close them and reopen in order
#      $objOutputter->append("_NAMESPACE($arg)");
      unshift @{$self->{'namespace'}}, $name;
      unshift @{$self->{'in_namespace'}}, $self->{'level'} + 1;
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
        $self->error ('Unexpected `' . $token . '\' after namespace name.');
      }
      $name = $token;
    }

    if ($done)
    {
      $section_manager->append_string_to_section ('namespace', $main_section);
      return;
    }
  }
  $self->error_with_loc ($line_num, 'Hit eof while processing `namespace\'.');
}


# TODO: implement it.
########################################
###  we don't want to report every petty function as unwrapped
# void on_ignore($)
sub on_ignore($)
{
  my ($self) = @_;

  $self->warning ('_IGNORE is not yet implemented.');
  $self->extract_bracketed_text;
#  my @args = split(/\s+|,/,$str);
#  foreach (@args)
#  {
#    next if ($_ eq "");
#    GtkDefs::lookup_function($_); #Pretend that we've used it.
#  }
}

# TODO: implement it.
sub on_ignore_signal($)
{
  my ($self) = @_;

  $self->warning ('_IGNORE_SIGNAL is not yet implemented.');
  $self->extract_bracketed_text;
#  $str = Util::string_trim($str);
#  $str = Util::string_unquote($str);
#  my @args = split(/\s+|,/,$str);
#  foreach (@args)
#  {
#    next if ($_ eq "");
#    GtkDefs::lookup_signal($$self{c_class}, $_); #Pretend that we've used it.
#  }
}

# TODO: make it a common handler of _CLASS macros. And actually implement it.
########################################
###  we have certain macros we need to insert at end of statements
# void on_class($, $strClassCommand)
#sub on_class($$)
sub on_class ($)
{
#  my ($self, $class_command) = @_;
  my ($self) = @_;

  $self->warning ('on_class is not implemented.');
  $self->extract_bracketed_text;

  # my $objOutputter = $$self{objOutputter};

  # $$self{in_class} = $$self{level};

  # #Remember the type of wrapper required, so that we can append the correct _END_CLASS_* macro later.
  # {
  #   my $str = $class_command;
  #   $str =~ s/^_CLASS_//;
  #   $$self{type} = $str;
  # }

  # my ($class, $c_class) = split(',',$str);
  # $class = Util::string_trim($class);
  # $c_class = Util::string_trim($c_class);

  # $$self{class} = $class;
  # $$self{c_class} = $c_class;

  # my @back;
  # push(@back, $class_command);
  # push(@back, "($str)");

  # TODO: do we really need it?
  # When we hit _CLASS, we walk backwards through the output to find "class"
  # my $token;
  # while ( scalar(@{$$objOutputter{out}}))
  # {
  #   $token = pop @{$$objOutputter{out}};
  #   unshift(@back, $token);
  #   if ($token eq "class")
  #   {
  #     $objOutputter->append("_CLASS_START()");

  #     my $strBack = join("", @back);

  #     $objOutputter->append($strBack);
  #     return;
  #   }
  # }

#  $self->error($class_command . 'outside of class.');
#  exit 1;
}

# order to read the defs file
# void on_defs()
sub on_defs ($)
{
  my ($self) = @_;

  $self->warning ('_DEFS macro is deprecated.');
  $self->extract_bracketed_text;
}

# void on_open_brace()
sub on_open_brace($)
{
  my ($self) = @_;
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};

  ++$self->{'level'};
  $section_manager->append_string_to_section ('{', $main_section);
}

# void on_close_brace($)
sub on_close_brace($)
{
  my ($self) = @_;
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};

  if ($self->{'in_class'} and $self->{'in_class'} == $self->{'level'})
  {
    $self->on_end_class();
  }

  $section_manager->append_string_to_section ('}', $main_section);

  if (@{$self->{'in_namespace'}} and $self->{'in_namespace'}[0] == $self->{'level'})
  {
    $self->on_end_namespace();
  }

  --$self->{'level'};
}


# TODO: check if we really need it. That was probably only for m4. We can do it in simpler way.
########################################
###  denote the end of a class
# void on_end_class($)
sub on_end_class ($)
{
  my ($self) = @_;
  # my $objOutputter = $$self{objOutputter};

  # # Examine $$self{type}, which was set in on_class()
  # # And append the _END_CLASS_* macro, which will, in turn, output the m4 code.
  # {
  #   my $str = $$self{type};
  #   $objOutputter->append("`'_END_CLASS_$str()\n");
  # }

  # $$self{class} = "";
  # $$self{c_class} = "";
  # $$self{in_class} = 0;
}

########################################
###
# void on_end_namespace($)
sub on_end_namespace ($)
{
  my ($self) = @_;
  my $namespaces = $self->{'namespace'};
#  my $objOutputter = $$self{objOutputter};

#  $objOutputter->append("`'_END_NAMESPACE()");
  shift @{$namespaces};
  shift @{$self->{'in_namespace'}};

  unless (@{$namespaces})
  {
    my $section_manager = $self->{'section_manager'};
    my $main_section = $self->{'main_section'};
    my $tokens = $self->{'tokens'};
    my @strs = ();

    # TODO: make it multiline comments aware?
    while (@{$tokens})
    {
      my $token = $self->extract_token;

      push @strs, $token;
      last if ($token eq "\n");
    }
    $section_manager->append_string_to_section (join ('', @strs), $main_section);
    $section_manager->append_section_to_section ('SECTION_AFTER_FIRST_NAMESPACE', $main_section);
  }
}


######################################################################
##### some utility subroutines

########################################
###  takes (\S+) from the tokens (smart)
# $string extract_bracketed_text()
sub extract_bracketed_text ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};
  my $level = 1;
  my $str = '';
  my $line_num = $self->{'line_num'};

  # Move to the first "(":
  while (@{$tokens})
  {
    my $token = $self->extract_token;

    last if ($token eq '(');
  }

  # Concatenate until the corresponding ")":
  while (@{$tokens})
  {
    my $token = $self->extract_token;
    ++$level if ($token eq '(');
    --$level if ($token eq ')');

    return $str unless $level;
    $str .= $token;
  }

  $self->error_with_loc ($line_num, 'Hit eof when extracting bracketed text.');
}

# TODO: Handle case when some string is passed?
########################################
###  breaks up a string by commas (smart)
# @strings string_split_commas($string)
sub string_split_commas ($)
{
  my ($in) = @_;
  my @out = ();
  my $level = 0;
  my $str = '';
  my @tokens = split(/([,()]"')/, $in);
  my $sq = 0;
  my $dq = 0;

  while (@tokens)
  {
    my $token = shift @tokens;

    next if ($token eq '');

    if ($sq)
    {
      if ($token eq '\'')
      {
        $sq = 0;
      }
    }
    elsif ($dq)
    {
      if ($token eq '"')
      {
        $dq = 0;
      }
    }
    elsif ($token eq '\'')
    {
      $sq = 1;
    }
    elsif ($token eq '"')
    {
      $dq = 1;
    }
    elsif ($token eq '(')
    {
      ++$level;
    }
    elsif ($token eq ')')
    {
      --$level;
    }
    elsif ($token eq ',' and not $level)
    {
      push @out, $str;
      $str = '';
      next;
    }

    $str .= $token;
  }

  push @out, $str;
  return @out;
}

sub tokenize_contents ($$)
{
  my ($self, $contents) = @_;
  # Break the file into tokens.  Token is:
  # - any group of #, A to z, 0 to 9, _
  # - /**
  # - /*
  # - *.
  # - //
  # - any char proceeded by \
  # - symbols ;{}"`'()
  # - newline
  my @tokens = split(/([#A-Za-z0-9_]+)|(\/\*\*)|(\/\*)|(\*\/)|(\/\/)|(\\.)|([;{}"'`()])|(\n)/,
                     $contents);

  return \@tokens;
}

########################################
###  reads in the preprocessor files
# we insert line and file directives for later stages
# void read_file()
sub read_file ($)
{
  my ($self) = @_;
  my $source_dir = $self->{'source_dir'};
  my $base = $self->{'base'};
  my $source = File::Spec->catfile ($source_dir, $base);
  my $hg = $source . '.hg';
  my $ccg = $source . '.ccg';
  my $fd = IO::File->new ($hg, 'r');

  unless (defined $fd)
  {
    print 'Could not open file `' . $hg . '\' for reading.' . "\n";
    exit 1;
  }

  $self->{'tokens_hg'} = $self->tokenize_contents (join '', $fd->getlines);
  $fd->close;

  # Source file is optional.
  $fd = IO::File->new ($ccg, 'r');
  if (defined $fd)
  {
    my $str = join ('',
                    '_INSERT_SECTION(SECTION_CCG_BEGIN)',
                    "\n",
                    $fd->getlines,
                    "\n",
                    '_INSERT_SECTION(SECTION_CCG_END)',
                    "\n");
    $self->{'tokens_ccg'} = $self->tokenize_contents ($str);
    $fd->close;
  }
}

######################################################################
##### 2.1 subroutines for _WRAP

########################################

# $bool check_for_eof()
sub check_for_eof ($)
{
  my ($self) = @_;
  my $tokens = $self->{'tokens'};

  unless (@{$tokens})
  {
    $self->error ('Hit eof in _WRAP.');
  }
  return 1;
}

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

# TODO: implement it.
# void on_wrap_method()
sub on_wrap_method($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $commentblock = $self->extract_preceding_documentation();
  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # my $entity_type = "method";

  # unless ($$self{in_class})
  # {
  #   print STDERR "$filename:$line_num:_WRAP macro encountered outside class\n";
  #   return;
  # }

  # my $objCfunc;
  # my $objCppfunc;

  # # handle first argument
  # my $argCppMethodDecl = $args[0];
  # if ($argCppMethodDecl !~ m/\S/s)
  # {
  #   print STDERR "$filename:$line_num:_WRAP_METHOD: missing prototype\n";
  #   return;
  # }

  # #Parse the method decaration and build an object that holds the details:
  # $objCppfunc = &Function::new($argCppMethodDecl, $self);

  # # handle second argument:

  # my $argCFunctionName = $args[1];
  # $argCFunctionName = Util::string_trim($argCFunctionName);

  # #Get the c function's details:

  # # Checks that it's not empty and that it contains no whitespace.
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

  # # Extra stuff needed?
  # $$objCfunc{rettype_needs_ref} = 0;
  # $$objCfunc{throw_any_errors} = 0;
  # $$objCfunc{constversion} = 0;
  # $$objCfunc{deprecated} = "";
  # my $deprecation_docs = "";
  # my $ifdef;
  # while($#args >= 2) # If the optional ref/err/deprecated arguments are there.
  # {
  #   my $argRef = Util::string_trim(pop @args);
  #   #print "debug arg=$argRef\n";
  #   if($argRef eq "refreturn")
  #   {
  #     $$objCfunc{rettype_needs_ref} = 1;
  #   }
  #   elsif($argRef eq "errthrow")
  #   {
  #     $$objCfunc{throw_any_errors} = 1;
  #   }
  #   elsif($argRef eq "constversion")
  #   {
  #     $$objCfunc{constversion} = 1;
  #   }
  #   elsif($argRef =~ /^deprecated(.*)/) #If deprecated is at the start.
  #   {
  #     $$objCfunc{deprecated} = "deprecated";

  #     if($1 ne "")
  #     {
  #       $deprecation_docs = Util::string_unquote(Util::string_trim($1));
  #     }
  #   }
  #   elsif($argRef =~ /^ifdef(.*)/) #If ifdef is at the start.
  #   {
  #     $ifdef = $1;
  #   }
  # }

  # if ($commentblock ne '')
  # {
  #   $commentblock = '  /**' . $commentblock . "\n   */\n";
  # }
  # else
  # {
  #   $commentblock = DocsParser::lookup_documentation($argCFunctionName, $deprecation_docs);
  # }

  # $objOutputter->output_wrap_meth($filename, $line_num, $objCppfunc, $objCfunc, $argCppMethodDecl, $commentblock, $ifdef);
}

# TODO: implement it.
# void on_wrap_method_docs_only()
sub on_wrap_method_docs_only($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->extract_bracketed_text();
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
  # $argCFunctionName = Util::string_trim($argCFunctionName);

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
  #   my $argRef = Util::string_trim(pop @args);
  #   if($argRef eq "errthrow")
  #   {
  #     $$objCfunc{throw_any_errors} = 1;
  #   }
  # }

  # my $commentblock = "";
  # $commentblock = DocsParser::lookup_documentation($argCFunctionName, "");

  # $objOutputter->output_wrap_meth_docs_only($filename, $line_num, $commentblock);
}

# TODO: implement it.
sub on_wrap_ctor($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # if( !($self->check_for_eof()) )
  # {
  #  return;
  # }

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # my $entity_type = "method";

  # if (!$$self{in_class})
  #   {
  #     print STDERR "$filename:$line_num:_WRAP_CTOR macro encountered outside class\n";
  #     return;
  #   }

  # my $objCfunc;
  # my $objCppfunc;

  # # handle first argument
  # my $argCppMethodDecl = $args[0];
  # if ($argCppMethodDecl !~ m/\S/s)
  #   {
  #     print STDERR "$filename:$line_num:_WRAP_CTOR: missing prototype\n";
  #     return;
  #   }

  # #Parse the method decaration and build an object that holds the details:
  # $objCppfunc = &Function::new_ctor($argCppMethodDecl, $self);

  # # handle second argument:

  # my $argCFunctionName = $args[1];
  # $argCFunctionName = Util::string_trim($argCFunctionName);

  # #Get the C function's details:
  # if ($argCFunctionName =~ m/^\S+$/s)
  # {
  #   $objCfunc = GtkDefs::lookup_function($argCFunctionName); #c-name. e.g. gtk_clist_set_column_title
  #   if(!$objCfunc) #If the lookup failed:
  #   {
  #     $objOutputter->output_wrap_failed($argCFunctionName, "ctor defs lookup failed (2)");
  #     return;
  #   }
  # }

  # $objOutputter->output_wrap_ctor($filename, $line_num, $objCppfunc, $objCfunc, $argCppMethodDecl);
}

# TODO: implement it.
sub on_implements_interface ($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # if( !($self->check_for_eof()) )
  # {
  #  return;
  # }

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # # handle first argument
  # my $interface = $args[0];

  # # Extra stuff needed?
  # my $ifdef;
  # while($#args >= 1) # If the optional ref/err/deprecated arguments are there.
  # {
  #   my $argRef = Util::string_trim(pop @args);
  #   if($argRef =~ /^ifdef(.*)/) #If ifdef is at the start.
  #   {
  #     $ifdef = $1;
  #   }
  # }
  # my $objOutputter = $$self{objOutputter};
  # $objOutputter->output_implements_interface($interface, $ifdef);
}

# TODO: implement it.
sub on_wrap_create($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;

  # if( !($self->check_for_eof()) )
  # {
  #   return;
  # }

  # my $str = $self->extract_bracketed_text();

  # my $objOutputter = $$self{objOutputter};
  # $objOutputter->output_wrap_create($str, $self);
}

# TODO: split the common part from it and make two methods with merging doxycomment and without it. Implement it actually.
sub on_wrap_signal($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my ($self, $merge_doxycomment_with_previous) = @_;

  # if( !($self->check_for_eof()) )
  # {
  #   return;
  # }

  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # #Get the arguments:
  # my $argCppDecl = $args[0];
  # my $argCName = $args[1];
  # $argCName = Util::string_trim($argCName);
  # $argCName = Util::string_unquote($argCName);

  # my $bCustomDefaultHandler = 0;
  # my $bNoDefaultHandler = 0;
  # my $bCustomCCallback = 0;
  # my $bRefreturn = 0;
  # my $ifdef;

  # while($#args >= 2) # If optional arguments are there.
  # {
  #   my $argRef = Util::string_trim(pop @args);
  #   if($argRef eq "custom_default_handler")
  #   {
  #     $bCustomDefaultHandler = 1;
  #   }

  #   if($argRef eq "no_default_handler")
  #   {
  #     $bNoDefaultHandler = 1;
  #   }

  #   if($argRef eq "custom_c_callback")
  #   {
  #     $bCustomCCallback = 1;
  #   }

  #   if($argRef eq "refreturn")
  #   {
  #     $bRefreturn = 1;
  #   }

  #   elsif($argRef =~ /^ifdef(.*)/) #If ifdef is at the start.
  #   {
  #     $ifdef = $1;
  #   }
  # }

  # $self->output_wrap_signal($argCppDecl, $argCName, $$self{filename}, $$self{line_num},
  #                           $bCustomDefaultHandler, $bNoDefaultHandler, $bCustomCCallback,
  #                           $bRefreturn, $ifdef, $merge_doxycomment_with_previous);
}

# TODO: implement it.
# void on_wrap_vfunc()
sub on_wrap_vfunc($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;

  # if( !($self->check_for_eof()) )
  # {
  #   return;
  # }

  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # #Get the arguments:
  # my $argCppDecl = $args[0];
  # my $argCName = $args[1];
  # $argCName = Util::string_trim($argCName);
  # $argCName = Util::string_unquote($argCName);

  # my $refreturn = 0;
  # my $refreturn_ctype = 0;
  # my $custom_vfunc = 0;
  # my $custom_vfunc_callback = 0;
  # my $ifdef = "";

  # while($#args >= 2) # If optional arguments are there.
  # {
  #   my $argRef = Util::string_trim(pop @args);

  #   # Extra ref needed?
  #   if($argRef eq "refreturn")
  #   {
  #     $refreturn = 1;
  #   }
  #   elsif($argRef eq "refreturn_ctype")
  #   {
  #     $refreturn_ctype = 1;
  #   }
  #   elsif($argRef eq "custom_vfunc")
  #   {
  #     $custom_vfunc = 1;
  #   }
  #   elsif($argRef eq "custom_vfunc_callback")
  #   {
  #     $custom_vfunc_callback = 1;
  #   }
  #   elsif($argRef =~ /^ifdef(.*)/) #If ifdef is at the start.
  #   {
  #     $ifdef = $1;
  #   }
  # }

  # $self->output_wrap_vfunc($argCppDecl, $argCName, $$self{filename}, $$self{line_num},
  #                          $refreturn, $refreturn_ctype, $custom_vfunc,
  #                          $custom_vfunc_callback, $ifdef);
}

sub extract_members ($$)
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

#TODO: implement beautifying if I am really bored.
sub convert_members_to_strings($)
{
  my ($members) = @_;
  my @strings = ();

  foreach my $pair (@{$members})
  {
    my $name = $pair->[0];
    my $value = $pair->[1];

    push @strings, '    ' . $name . ' = ' . $value;
  }
  return \@strings;
}

sub on_wrap_enum($)
{
  my ($self) = @_;
  my $repositories = $self->{'repositories'};
  my $module = $self->{'module'};
  my $repository = $repositories->get_repository ($module);
  my $namespace = $repository->get_g_namespace_by_name ($module);

  return unless $self->check_for_eof;

  # get the arguments
  my @args = string_split_commas ($self->extract_bracketed_text);
  my $cpp_type = Util::string_trim(shift @args);
  my $c_enum = Util::string_trim(shift @args);
  my $flags = 0;
  my $enum = $namespace->get_g_enumeration_by_name ($c_enum);

  unless (defined $enum)
  {
    $enum = $namespace->get_g_bitfield_by_name ($c_enum);
    $flags = 1;
    unless (defined $enum)
    {
      $self->error ('No enum or flags `' . $c_enum . '\' found.');
    }
  }

  my @substs = ();

  if (@args)
  {
    foreach my $arg (@args)
    {
      if ($arg eq 'NO_GTYPE')
      {
        $self->warning ('NO_GTYPE parameter is deprecated.');
      }
      elsif ($arg =~ /^\s*s#([^#]+)#([^#]*)#\s*$/)
      {
        push @substs, [$1, $2];
      }
      elsif (/^\s*get_type_func=.*$/)
      {
        $self->warning ('get-type-func parameter is deprecated.');
      }
      else
      {
        $self->warning ('Unknown parameter passed to _WRAP_GERROR: `' . $arg . '\'.');
      }
    }
  }

  unless (defined $enum)
  {
    $self->error ('No enum `' . $c_enum . '\' found.');
  }

  my $gir_gtype = $enum->get_a_glib_get_type;
  my $members = extract_members ($enum, \@substs);
  my $string_members = convert_members_to_strings ($members);
  my $code_string = nl ('enum ' . $cpp_type) .
                    nl ('{') .
                    nl (join (nl (','), $string_members)) .
                    nl ('};') .
                    nl ();

  if ($flags)
  {
    $code_string .= nl ('inline ' . $cpp_type . ' operator|(' . $cpp_type . ' lhs, ' . $cpp_type . ' rhs)') .
                    nl ('  { return static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs)); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . ' operator&(' . $cpp_type . ' lhs, ' . $cpp_type . ' rhs)') .
                    nl ('  { return static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs)); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . ' operator^(' . $cpp_type . ' lhs, ' . $cpp_type . ' rhs)') .
                    nl ('{ return static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs)); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . ' operator~(' . $cpp_type . ' flags)') .
                    nl ('  { return static_cast<' . $cpp_type . '>(~static_cast<unsigned>(flags)); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . '& operator|=(' . $cpp_type . '& lhs, ' . $cpp_type . ' rhs)') .
                    nl ('  { return (lhs = static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) | static_cast<unsigned>(rhs))); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . '& operator&=(' . $cpp_type . '& lhs, ' . $cpp_type . ' rhs)') .
                    nl ('  { return (lhs = static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) & static_cast<unsigned>(rhs))); }') .
                    nl () .
                    nl ('inline ' . $cpp_type . '& operator^=(' . $cpp_type . '& lhs, ' . $cpp_type . ' rhs)') .
                    nl ('  { return (lhs = static_cast<' . $cpp_type . '>(static_cast<unsigned>(lhs) ^ static_cast<unsigned>(rhs))); }') .
                    nl ();

  }

  my $namespaces = $self->{'namespace'};
  my $error_namespaces = $self->join_namespaces;
  my $full_cpp_type = join ('::', $error_namespaces, $cpp_type);

  if (defined $gir_gtype)
  {
    my $close = 1;

    if (@{$namespaces} == 1 and $namespaces->[0] eq 'Glib')
    {
      $close = 0;
    }

    if ($close)
    {
      $code_string .= Common::Output::Shared::close_namespaces $self->get_namespaces;
    }

    my $value_base = 'Glib::Value_';

    if ($flags)
    {
      $value_base .= 'Flags';
    }
    else
    {
      $value_base .= 'Enum';
    }
    $code_string .= nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('template <>') .
                    nl ('class Value< ' . $full_cpp_type . ' > : public ' . $value_base . '< ' . $full_cpp_type . '> ') .
                    nl ('{') .
                    nl ('public:') .
                    nl ('  static GType value_type() G_GNUC_CONST;') .
                    nl ('};') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();

    if ($close)
    {
      $code_string .= Common::Output::Shared::open_namespaces $self->get_namespaces;
    }
  }

  my $section_manager = $self->{'section_manager'};

  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_H);

  if (defined $gir_gtype)
  {
    $code_string = nl ('// static') .
                   nl ('GType Glib::Value< ' . $full_cpp_type . ' >::value_type()') .
                   nl ('{') .
                   nl ('  return ' . $gir_gtype . '();') .
                   nl ('}') .
                   nl ();
    $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
  }
}

sub on_wrap_gerror ($)
{
  my ($self) = @_;
  my $repositories = $self->{'repositories'};
  my $module = $self->{'module'};
  my $repository = $repositories->get_repository ($module);
  my $namespace = $repository->get_g_namespace_by_name ($module);

  return unless $self->check_for_eof;

  # get the arguments
  my @args = string_split_commas ($self->extract_bracketed_text);
  my $cpp_type = Util::string_trim(shift @args);
  my $c_enum = Util::string_trim(shift @args);
  my $enum = $namespace->get_g_enumeration_by_name ($c_enum);
  my @substs = ();

  if (@args)
  {
    my $first_iteration = 1;

    foreach my $arg (@args)
    {
      if ($arg eq 'NO_GTYPE')
      {
        $self->warning ('NO_GTYPE parameter is deprecated.');
      }
      elsif ($arg =~ /^\s*s#([^#]+)#([^#]*)#\s*$/)
      {
        push @substs, [$1, $2];
      }
      elsif (/^\s*get_type_func=.*$/)
      {
        $self->warning ('get-type-func parameter is deprecated.');
      }
      elsif ($first_iteration)
      {
        $self->warning ('Domain parameter is deprecated.');
      }
      else
      {
        $self->warning ('Unknown parameter passed to _WRAP_GERROR: `' . $arg . '\'.');
      }
      $first_iteration = 0;
    }
  }

  unless (defined $enum)
  {
    $self->error ('No enum `' . $c_enum . '\' found.');
  }

  my $gir_gtype = $enum->get_a_glib_get_type;
  my $gir_domain = $enum->get_a_glib_error_domain;
  my $members = extract_members ($enum, \@substs);
  my $string_members = convert_members_to_strings ($members);
  my $code_string = nl ('class ' . $cpp_type . ' : public Glib:error') .
                    nl ('{') .
                    nl ('public:') .
                    nl ('  enum Code') .
                    nl ('  {') .
                    nl (join nl (','), @{$string_members}) .
                    nl ('  };') .
                    nl () .
                    nl ('  ' . $cpp_type . '(Code error_code, const Glib::ustring& error_message);') .
                    nl ('  explicit ' . $cpp_type . '(GError* gobject);') .
                    nl ('  Code code() const;') .
                    nl () .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('private:') .
                    nl () .
                    nl ('  static void throw_func(GError* gobject);') .
                    nl () .
                    nl ('  friend void wrap_init(); // uses throw_func()') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ('};') .
                    nl ();

  my $error_namespaces = $self->join_namespaces;
  my $full_cpp_type = join ('::', $error_namespaces, $cpp_type);

  if (defined $gir_gtype)
  {
    my $namespaces = $self->{'namespace'};
    my $close = 1;
    if (@{$namespaces} == 1 and $namespaces->[0] eq 'Glib')
    {
      $close = 0;
    }

    if ($close)
    {
      $code_string .= Common::Output::Shared::close_namespaces $self->get_namespaces;
    }

    $code_string .= nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('namespace Glib') .
                    nl ('{') .
                    nl () .
                    nl ('template <>') .
                    nl ('class Value< ' . $full_cpp_type . '::Code > : public Glib::Value_Enum< ' . $full_cpp_type . '::Code >') .
                    nl ('{') .
                    nl ('public:') .
                    nl ('  static GType value_type() G_GNUC_CONST;') .
                    nl ('};') .
                    nl () .
                    nl ('} // namespace Glib') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl ();

    if ($close)
    {
      $code_string .= Common::Output::Shared::open_namespaces $self->get_namespaces;
    }
  }

  my $section_manager = $self->{'section_manager'};

  $section_manager->append_string_to_section ($code_string, Common::SectionManager::SECTION_H);
  $code_string = nl ($full_cpp_type . '::' . $cpp_type . '(' . $full_cpp_type . '::Code error_code, const Glib::ustring& error_message)') .
                 nl (':') .
                 nl ('  Glib::Error(g_quark_from_static_string ("' . $gir_domain . '"), error_code, error_message)') .
                 nl ('{}') .
                 nl () .
                 nl ($full_cpp_type . '::' . $cpp_type . '(GError* gobject)') .
                 nl (':') .
                 nl ('  Glib::Error(gobject)') .
                 nl ('{}') .
                 nl () .
                 nl ($full_cpp_type . '::Code ' . $full_cpp_type . '::code() const') .
                 nl ('{') .
                 nl ('  return static_cast<Code>(Glib::Error::code());') .
                 nl ('}') .
                 nl () .
                 nl ('// static') .
                 nl ('void ' . $full_cpp_type . '::throw_func(GError* gobject)') .
                 nl ('{') .
                 nl ('  throw ' . $full_cpp_type . '(gobject);') .
                 nl ('}') .
                 nl ();

  if (defined $gir_gtype)
  {
    $code_string .= nl ('// static') .
                    nl ('GType Glib::Value< ' . $full_cpp_type . '::Code >::value_type()') .
                    nl ('{') .
                    nl ('  return ' . $gir_gtype . '();') .
                    nl ('}') .
                    nl ();
  }

  $section_manager->append_string_to_section ($code_string, 'SECTION_CCG_END');
}

# TODO: implement it.
sub on_wrap_property($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $str = $self->extract_bracketed_text();
  # my @args = string_split_commas($str);

  # #Get the arguments:
  # my $argPropertyName = $args[0];
  # $argPropertyName = Util::string_trim($argPropertyName);
  # $argPropertyName = Util::string_unquote($argPropertyName);

  # #Convert the property name to a canonical form, as it is inside gobject.
  # #Otherwise, gobject might not recognise the name,
  # #and we will not recognise the property name when we get notification that the value changes.
  # $argPropertyName =~ tr/_/-/;

  # my $argCppType = $args[1];
  # $argCppType = Util::string_trim($argCppType);
  # $argCppType = Util::string_unquote($argCppType);

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # $objOutputter->output_wrap_property($filename, $line_num, $argPropertyName, $argCppType, $$self{c_class});
}

# TODO: either remove it or make use of it in every _WRAP macro specific for class.
sub output_wrap_check($$$$$$)
{
  my ($self, $CppDecl, $signal_name, $filename, $line_num, $macro_name) = @_;

  #Some checks:

  unless ($self->{'in_class'})
  {
    $self->error ($macro_name . 'macro encountered outside class');
  }
  if ($CppDecl !~ m/\S/s)
  {
    $self->error ($macro_name . ': missing prototype');
  }
  return 0;
}

# TODO: we probably won't need this.
# void output_wrap($CppDecl, $signal_name, $filename, $line_num, $bCustomDefaultHandler, $bNoDefaultHandler, $bCustomCCallback, $bRefreturn)
# sub output_wrap_signal($$$$$$$$$)
# {
#   my ($self, $CppDecl, $signal_name, $filename, $line_num, $bCustomDefaultHandler, $bNoDefaultHandler, $bCustomCCallback, $bRefreturn, $ifdef, $merge_doxycomment_with_previous) = @_;

#   #Some checks:
#   return if ($self->output_wrap_check($CppDecl, $signal_name,
#                                       $filename, $line_num, "_WRAP_SIGNAL"));
#   # handle first argument

#   #Parse the method declaration and build an object that holds the details:
#   my $objCppSignal = &Function::new($CppDecl, $self);
#   $$objCppSignal{class} = $$self{class}; #Remember the class name for use in Outputter::output_wrap_signal().


#   # handle second argument:
#   my $objCSignal = undef;

#   my $objOutputter = $$self{objOutputter};

#   #Get the c function's details:
#   if ($signal_name ne '')
#   {
#     $objCSignal = GtkDefs::lookup_signal($$self{c_class}, $signal_name);

#     # Check for failed lookup.
#     if($objCSignal eq 0)
#     {
#     print STDERR "$signal_name\n";
#       $objOutputter->output_wrap_failed($signal_name,
#         " signal defs lookup failed");
#       return;
#     }
#   }

#   $objOutputter->output_wrap_sig_decl($filename, $line_num, $objCSignal, $objCppSignal, $signal_name, $bCustomCCallback, $ifdef, $merge_doxycomment_with_previous);

#   if($bNoDefaultHandler eq 0)
#   {
#     $objOutputter->output_wrap_default_signal_handler_h($filename, $line_num, $objCppSignal, $objCSignal, $ifdef);

#     my $bImplement = 1;
#     if($bCustomDefaultHandler) { $bImplement = 0; }
#     $objOutputter->output_wrap_default_signal_handler_cc($filename, $line_num, $objCppSignal, $objCSignal, $bImplement, $bCustomCCallback, $bRefreturn, $ifdef);
#   }
# }

# TODO: we probably won't need this.
# void output_wrap($CppDecl, $vfunc_name, $filename, $line_num, $refreturn, $refreturn_ctype,
#                  $custom_vfunc, $custom_vfunc_callback, $ifdef)
# sub output_wrap_vfunc($$$$$$$$)
# {
#   my ($self, $CppDecl, $vfunc_name, $filename, $line_num, $refreturn, $refreturn_ctype,
#       $custom_vfunc, $custom_vfunc_callback, $ifdef) = @_;

#   #Some checks:
#   return if ($self->output_wrap_check($CppDecl, $vfunc_name, $filename, $line_num, '_WRAP_VFUNC'));

#   # handle first argument

#   #Parse the method declaration and build an object that holds the details:
#   my $objCppVfunc = &Function::new($CppDecl, $self);


#   # handle second argument:
#   my $objCVfunc = undef;

#   my $objOutputter = $$self{objOutputter};

#   #Get the c function's details:
#   if ($vfunc_name =~ m/^\S+$/s) # if it's not empty and contains no whitespace
#   {
#     $objCVfunc = GtkDefs::lookup_signal($$self{c_class},$vfunc_name);
#     if(!$objCVfunc) #If the lookup failed:
#     {
#       $objOutputter->output_wrap_failed($vfunc_name, " vfunc defs lookup failed");
#       return;
#     }
#   }

#   # Write out the appropriate macros.
#   # These macros are defined in vfunc.m4:

#   $$objCppVfunc{rettype_needs_ref} = $refreturn;
#   $$objCppVfunc{name} .= "_vfunc"; #All vfuncs should have the "_vfunc" suffix, and a separate easily-named invoker method.

#   $$objCVfunc{rettype_needs_ref} = $refreturn_ctype;

#   $objOutputter->output_wrap_vfunc_h($filename, $line_num, $objCppVfunc, $objCVfunc, $ifdef);
#   $objOutputter->output_wrap_vfunc_cc($filename, $line_num, $objCppVfunc, $objCVfunc,
#                                       $custom_vfunc, $custom_vfunc_callback, $ifdef);
# }

# TODO: what it is for? Remove it.
# give some sort of weights to sorting attibutes
# sub byattrib()
# {
#   my %attrib_value = (
#      "virtual_impl" ,1,
#      "virtual_decl" ,2,
#      # "sig_impl"     ,3,
#      "sig_decl"     ,4,
#      "meth"         ,5
#   );

#   # $a and $b are hidden parameters to a sorting function
#   return $attrib_value{$b} <=> $attrib_value{$a};
# }


# TODO: probably implement this. I am not sure.
# void on_wrap_corba_method()
sub on_wrap_corba_method($)
{
  my ($self) = @_;

  $self->extract_bracketed_text;
  # my $objOutputter = $$self{objOutputter};

  # return unless ($self->check_for_eof());

  # my $filename = $$self{filename};
  # my $line_num = $$self{line_num};

  # my $str = $self->extract_bracketed_text();
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

sub on_insert_section ($)
{
  my ($self) = @_;
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};
  my $str = Util::string_trim $self->extract_bracketed_text;

  $section_manager->append_section_to_section ($str, $main_section);
}

sub on_class_generic ($)
{
  my ($self) = @_;
  my @args = string_split_commas $self->extract_bracketed_text;

  if (@args < 2)
  {
    $self->error ('Too few parameters for _CLASS_GENERIC');
  }
  elsif (@args > 2)
  {
    $self->warning ('Superfluous parameters in _CLASS_GENERIC will be ignored.');
  }

  my ($cpp_type, $c_type) = @args;
  my $code_string = nl ('public:') .
                    nl (Common::Output::Shared::doxy_skip_begin) .
                    nl ('  typedef ' . $cpp_type . ' CppObjectType;') .
                    nl ('  typedef ' . $c_type . ' BaseObjectType;') .
                    nl (Common::Output::Shared::doxy_skip_end) .
                    nl () .
                    nl ('private:') .
                    nl ();
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};

  $section_manager->append_string_to_section ($code_string, $main_section);
}

sub on_class_gobject ($)
{
  my ($self) = @_;
  my $section_manager = $self->{'section_manager'};
  my $main_section = $self->{'main_section'};
  my $line_num = $self->{'line_num'};
  my @args = string_split_commas $self->extract_bracketed_text;

  if (@args > 2)
  {
    $self->warning_with_loc ($line_num, 'Last ' . @args - 2 . ' parameters are deprecated.');
  }

  my $repositories = $self->{'repositories'};
  my $module = $self->{'module'};
  my $repository = $repositories->get_repository ($module);

  unless (defined $repository)
  {
    $self->error_with_loc ($line_num, 'No such repository: ' . $module);
  }

  my $namespace = $repository->get_g_namespace_by_name ($module);

  unless (defined $namespace)
  {
    $self->error_with_loc ($line_num, 'No such namespace: ' . $module);
  }

  my $gir_prefix = $namespace->get_a_c_identifier_prefixes;
  my ($cpp_type, $c_type) = @_;
  my $gir_class = $namespace->get_g_class_by_name ($c_type);

  unless (defined $gir_class)
  {
    $self->error_with_loc ($line_num, 'No such class: ' . $c_type);
  }

  my $get_type_func = $gir_class->get_a_glib_get_type;

  unless (defined $get_type_func)
  {
    $self->error_with_loc ($line_num, 'Class `' . $c_type . '\' has no get-type function.');
  }

  my $gir_parent = $gir_class->get_a_parent;

  unless (defined $gir_parent)
  {
    $self->error_with_loc ($line_num, 'Class `' . $c_type . '\' has no parent (you are not wrapping GObject, are you?).');
  }

  my $gir_type_struct = $gir_class->get_a_glib_type_struct;

  unless (defined $gir_type_struct)
  {
    $self->error_with_loc ($line_num, 'Class `' . $c_type . '\' has no Class struct.');
  }

  my $c_type_class = $gir_prefix . $gir_type_struct;
  my $c_type_parent;
  my $c_type_parent_class;

  # if parent is for example Gtk.Widget
  if ($gir_parent =~ /^([^.]+)\.(.*)/)
  {
    my $gir_parent_module = $1;
    my $gir_parent_name = $2;
    my $parent_repository = $repositories=>get_repository ($gir_parent_module);

    unless (defined $parent_repository)
    {
      $self->error ('No such repository for parent: `' . $gir_parent_module . '\'.');
    }

    my $parent_namespace = $parent_repository->get_g_namespace_by_name ($gir_parent_module);

    unless (defined $parent_namespace)
    {
      $self->error ('No such namespace for parent: `' . $gir_parent_module . '\'.');
    }

    my $gir_parent_c_prefix = $parent_namespace->get_a_c_identifier_prefixes;

    $c_type_parent = $gir_parent_c_prefix . $gir_parent_name;

    my $gir_parent_class = $parent_namespace->get_g_class_by_name ($c_type_parent);

    unless (defined $gir_parent_class)
    {
      $self->error_with_loc ($line_num, 'No such parent class in namespace: `' . $c_type_parent . '\.');
    }

    my $gir_parent_type_struct = $gir_parent_class->get_a_glib_type_struct;

    unless (defined $gir_parent_type_struct)
    {
      $self->error_with_loc ($line_num, 'Parent of `' . $c_type . '\', `' . $c_type_parent . '\' has not Class struct.');
    }

    $c_type_parent_class = $gir_parent_c_prefix . $gir_parent_type_struct;
  }
  else
  {
    $c_type_parent = $gir_prefix . $gir_parent;

    my $gir_parent_class = $namespace->get_g_class_by_name ($c_type_parent);

    unless (defined $gir_parent_class)
    {
      $self->error_with_loc ($line_num, 'No such parent class in namespace: `' . $c_type_parent . '\.');
    }

    my $gir_parent_type_struct = $gir_parent_class->get_a_glib_type_struct;

    unless (defined $gir_parent_type_struct)
    {
      $self->error_with_loc ($line_num, 'Parent of `' . $c_type . '\', `' . $c_type_parent . '\' has not Class struct.');
    }

    $c_type_parent_class = $gir_prefix . $gir_parent_type_struct;
  }

  # TODO: write C <-> C++ name store.
  my $c_cpp_converter = $self->get_c_cpp_converter;
  my $cpp_type_parent = $c_cpp_converter->from_c_to_cpp ($c_type_parent);

  Common::Output::Gobject::output ($self,
                                   $c_type,
                                   $c_type_class,
                                   $c_type_parent,
                                   $c_type_parent_class,
                                   $get_type_func,
                                   $cpp_type,
                                   $cpp_type_parent);
}

1; # indicate proper module load.
