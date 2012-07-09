# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Scanner module
#
# Copyright 2012 glibmm development team
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

package Common::Scanner;

use strict;
use warnings;

use Common::Shared;
use constant
{
  'STAGE_HG' => 0,
  'STAGE_CCG' => 1,
  'STAGE_INVALID' => 2
};

sub _get_stages ($)
{
  my ($self) = @_;

  return $self->{'stages'};
}

sub _set_tokens ($$)
{
  my ($self, $tokens) = @_;

  $self->{'tokens'} = $tokens;
}

sub _get_tokens ($)
{
  my ($self) = @_;

  return $self->{'tokens'};
}

sub _get_namespaces ($)
{
  my ($self) = @_;

  return $self->{'namespaces'};
}

sub _get_classes ($)
{
  my ($self) = @_;

  return $self->{'classes'};
}

sub _inc_level ($)
{
  my ($self) = @_;

  ++$self->{'level'};
}

sub _dec_level ($)
{
  my ($self) = @_;

  --$self->{'level'};
}

sub _get_level ($)
{
  my ($self) = @_;

  return $self->{'level'};
}

sub _get_class_levels ($)
{
  my ($self) = @_;

  return $self->{'class_levels'};
}

sub _get_namespace_levels ($)
{
  my ($self) = @_;

  return $self->{'namespace_levels'};
}

sub _get_handlers ($)
{
  my ($self) = @_;

  return $self->{'handlers'};
}

sub _switch_to_stage ($$)
{
  my ($self, $stage) = @_;
  my $stages = $self->_get_stages;

  if (exists $stages->{$stage})
  {
    $self->_set_tokens ($stages->{$stage});
  }
  else
  {
# TODO: throw an internal error
    die 'Internal error in Scanner - unknown stage: ' . $stage . "\n";
  }
}

sub _extract_token ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $results = Common::Shared::extract_token $tokens;

  return $results->[0];
}

sub _on_string_with_end ($$)
{
  my ($self, $end) = @_;
  my $tokens = $self->_get_tokens;

  while (@{$tokens})
  {
    my $token = $self->_extract_token;

    if ($token eq $end)
    {
      last;
    }
  }
}

sub _extract_bracketed_text ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $result = Common::Shared::extract_bracketed_text $tokens;

  if (defined $result)
  {
    my $string = $result->[0];
    my $add_to_line = $result->[1];

    return $string;
  }
}

sub _make_full_type ($$)
{
  my ($self, $cxx_type) = @_;
  my $namespaces = $self->_get_namespaces;
  my $classes = $self->_get_classes;

  if (defined $cxx_type)
  {
    return join '::', reverse (@{$namespaces}), reverse (@{$classes}), $cxx_type;
  }
  else
  {
    return join '::', reverse (@{$namespaces}), (reverse @{$classes});
  }
}

sub _append ($$$$)
{
  my ($self, $c_stuff, $cxx_stuff, $macro_type) = @_;
  my $tuples = $self->get_tuples;

  push @{$tuples}, [$c_stuff, $cxx_stuff, $macro_type];
}

sub _get_params ($)
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas $self->_extract_bracketed_text;

  if (@args < 2)
  {
    return undef;
  }

  return [$args[0], $args[1]];
}

sub _on_wrap_func_generic ($$)
{
  my ($self, $args) = @_;
  my $cxx_function = Common::Shared::parse_function_declaration ($args->[0])->[2];
  my $c_function = $args->[1];

  $self->_append ($c_function, $self->_make_full_type ($cxx_function), 'FUNC');
}

sub _on_wrap_enum_generic ($$)
{
  my ($self, $args) = @_;
  my $cxx_enum = $args->[0];
  my $c_enum = $args->[1];

  $self->_append ($c_enum, $self->_make_full_type ($cxx_enum), 'ENUM');
}

sub _on_wrap_class_generic ($$$)
{
  my ($self, $args, $macro_type) = @_;
  my $classes = $self->_get_classes;
  my $cxx_class = $args->[0];
  my $c_class = $args->[1];

  if (@{$classes} > 0 and $classes->[-1] eq $cxx_class)
  {
    my $cxx_full_type = $self->_make_full_type (undef);

    $self->_append ($c_class, $self->_make_full_type (undef), $macro_type);
  }
}

###
###
###

sub _on_open_brace ($)
{
  my ($self) = @_;

  $self->_inc_level;
}

sub _on_close_brace ($)
{
  my ($self) = @_;
  my $level = $self->_get_level;
  my $classes = $self->_get_classes;
  my $class_levels = $self->_get_class_levels;
  my $namespaces = $self->_get_namespaces;
  my $namespace_levels = $self->_get_namespace_levels;

  if (@{$class_levels} and $class_levels->[-1] == $level)
  {
    pop @{$classes};
    pop @{$class_levels};
  }
  elsif (@{$namespace_levels} and $namespace_levels->[-1] == $level)
  {
    pop @{$namespaces};
    pop @{$namespace_levels};
  }
  $self->_dec_level;
}

sub _on_string_literal ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('"');
}

sub _on_comment_cxx ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ("\n");
}

sub _on_comment_c ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('*/');
}

sub _on_comment_doxygen ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('*/');
}

sub _on_m4_section ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ('#m4end');
}

sub _on_m4_line ($)
{
  my ($self) = @_;

  $self->_on_string_with_end ("\n");
}

sub _on_wrap_method ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_func_generic ($args);
  }
}

sub _on_wrap_ctor ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_func_generic ($args);
  }
}

sub _on_wrap_enum ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_enum_generic ($args);
  }
}

sub _on_wrap_gerror ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_enum_generic ($args);
  }
}

sub _on_class_generic ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    # no conversion generation possible - it have to be provided manually.
    $self->_on_wrap_class_generic ($args, 'MANUAL');
  }
}

sub _on_class_g_object ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'REFFED');
  }
}

sub _on_class_gtk_object ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'NORMAL');
  }
}

sub _on_class_boxed_type ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'NORMAL');
  }
}

sub _on_class_boxed_type_static ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'NORMAL');
  }
}

sub _on_class_interface ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
# TODO: which convert? reffed or not? probably both. probably manual.
    $self->_on_wrap_class_generic ($args, 'MANUAL');
  }
}

sub _on_class_opaque_copyable ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'NORMAL');
  }
}

sub _on_class_opaque_refcounted ($)
{
  my ($self) = @_;
  my $args = $self->_get_params;

  if (defined $args)
  {
    $self->_on_wrap_class_generic ($args, 'REFFED');
  }
}

sub _on_module
{
  my ($self) = @_;
  my @args = Common::Shared::string_split_commas ($self->_extract_bracketed_text ());

  if (@args != 1)
  {
# TODO: warning.
    return;
  }

  $self->{'modules'}{$args[0] . '.gir'} = undef;
}

sub _on_namespace_keyword ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
  my $name = '';
  my $in_s_comment = 0;
  my $in_m_comment = 0;

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
    elsif ($token =~ m#^//[/!]?$#)
    {
      $in_s_comment = 1;
    }
    elsif ($token =~ m#^/\*[*!]?$#)
    {
      $in_m_comment = 1;
    }
    elsif ($token eq '{')
    {

      my $namespaces = $self->_get_namespaces;
      my $namespace_levels = $self->_get_namespace_levels;

      $name = Common::Util::string_trim ($name);
      push @{$namespaces}, $name;
      push @{$namespace_levels}, $self->_get_level + 1;

      return;
    }
    elsif ($token eq ';')
    {
      return;
    }
    elsif ($token !~ /\s/)
    {
      $name = $token;
    }
  }
}

sub _on_class_keyword ($)
{
  my ($self) = @_;
  my $tokens = $self->_get_tokens;
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
      my $classes = $self->_get_classes;
      my $class_levels = $self->_get_class_levels;

      $name =~ s/\s+//g;
      push @{$classes}, $name;
      push @{$class_levels}, $self->_get_level + 1;
      return;
    }
    elsif ($token eq ';')
    {
      return;
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
  }
}

sub new ($$$)
{
  my ($type, $tokens_hg, $tokens_ccg) = @_;
  my $class = (ref $type or $type or 'Common::Scanner');
  my @tokens_hg_copy = (@{$tokens_hg});
  my @tokens_ccg_copy = (@{$tokens_ccg});
  my $self =
  {
    'tokens' => undef,
    'tuples' => [],
    'stages' =>
    {
      STAGE_HG () => \@tokens_hg_copy,
      STAGE_CCG () => \@tokens_ccg_copy,
      STAGE_INVALID () => []
    },
    'namespace_levels' => [],
    'namespaces' => [],
    'class_levels' => [],
    'classes' => [],
    'level' => 0,
    'modules' => {}
  };

  $self = bless $self, $class;

  $self->{'handlers'} =
  {
    '{' => sub { $self->_on_open_brace (@_); },
    '}' => sub { $self->_on_close_brace (@_); },
    '"' => sub { $self->_on_string_literal (@_); },
    '//' => sub { $self->_on_comment_cxx (@_); },
    '///' => sub { $self->_on_comment_cxx (@_); },
    '//!' => sub { $self->_on_comment_cxx (@_); },
    '/*' => sub { $self->_on_comment_c (@_); },
    '/**' => sub { $self->_on_comment_doxygen (@_); },
    '/*!' => sub { $self->_on_comment_doxygen (@_); },
    '#m4begin' => sub { $self->_on_m4_section (@_); },
    '#m4' => sub { $self->_on_m4_line (@_); },
    '_WRAP_METHOD' => sub { $self->_on_wrap_method (@_); },
    '_WRAP_CTOR' => sub { $self->_on_wrap_ctor (@_); },
    '_WRAP_ENUM' => sub { $self->_on_wrap_enum (@_); },
    '_WRAP_GERROR' => sub { $self->_on_wrap_gerror (@_); },
    '_CLASS_GENERIC' => sub { $self->_on_class_generic (@_); },
    '_CLASS_GOBJECT' => sub { $self->_on_class_g_object (@_); },
    '_CLASS_GTKOBJECT' => sub { $self->_on_class_gtk_object (@_); },
    '_CLASS_BOXEDTYPE' => sub { $self->_on_class_boxed_type (@_); },
    '_CLASS_BOXEDTYPE_STATIC' => sub { $self->_on_class_boxed_type_static (@_); },
    '_CLASS_INTERFACE' => sub { $self->_on_class_interface (@_); },
    '_CLASS_OPAQUE_COPYABLE' => sub { $self->_on_class_opaque_copyable (@_); },
    '_CLASS_OPAQUE_REFCOUNTED' => sub { $self->_on_class_opaque_refcounted (@_); },
    '_MODULE' => sub { $self->_on_module (@_); },
    'namespace' => sub { $self->_on_namespace_keyword (@_); },
    'class' => sub { $self->_on_class_keyword (@_); }
  };

  return $self;
}

sub scan ($)
{
  my ($self) = @_;
  my $handlers = $self->_get_handlers;
  my @stages = (STAGE_HG, STAGE_CCG);

  for my $stage (@stages)
  {
    $self->_switch_to_stage ($stage);

    my $tokens = $self->_get_tokens;

    while (@{$tokens})
    {
      my $token = $self->_extract_token;

      if (exists $handlers->{$token})
      {
        my $handler = $handlers->{$token};

        &{$handler};
      }
    }
  }
}

sub get_tuples ($)
{
  my ($self) = @_;

  return $self->{'tuples'};
}

sub get_modules ($)
{
  my ($self) = @_;
  my @modules = keys (%{$self->{'modules'}});

  return \@modules;
}

1; # indicate proper module load.
