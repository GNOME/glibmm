# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::TypeDetails::Value module
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

package Common::TypeDetails::Value;

use strict;
use warnings;

use parent qw(Common::TypeDetails::Base);

sub _get_split_values ($)
{
  my ($self) = @_;

  return join ('', $self->SUPER::_get_split_values (), '<>,!#');
}

sub new ($$$$$$)
{
  my ($type, $const, $volatile, $base, $templates, $imbue_type) = @_;
  my $class = (ref $type or $type or 'Common::TypeDetails::Value');
  my $self = $class->SUPER::new ($const, $volatile, '');

  $self->{'base'} = $base;
  $self->{'templates'} = $templates;
  $self->{'imbue_type'} = $imbue_type;

  return bless $self, $class;
}

sub get_base ($)
{
  my ($self) = @_;

  return $self->{'base'};
}

sub get_templates ($)
{
  my ($self) = @_;

  return $self->{'templates'};
}

sub get_imbue_type ($)
{
  my ($self) = @_;

  return $self->{'imbue_type'};
}

sub get_value_details ($)
{
  my ($self) = @_;

  return $self;
}

sub match_sigil ($$$)
{
  my ($self, $matches, $flags) = @_;

  unless (ref ($matches))
  {
    $matches = [$matches];
  }
  unless (defined ($flags))
  {
    $flags = Common::TypeDetails::Base::NONE;
  }

  foreach my $match (@{$matches})
  {
    $match = $self->match_basic_sigil ($match, $flags);
    next unless (defined $match);

    my $tokens = $self->_tokenize ($match);
    my @templates = reverse @{$self->get_templates ()};

    if (not @{$tokens} and not @templates)
    {
      return 1;
    }
    elsif ((@{$tokens} xor @templates) or shift @{$tokens} ne '>')
    {
      next;
    }

    my $do_not_care_all = 0;
    my $do_not_care_single = 0;
    my $template_param = '';
    my $template_level = 0;
    my $done = 0;

    foreach my $token (@${tokens})
    {
      if ($done)
      {
        # too many tokens.
        $done = 0;
        last;
      }
      elsif ($template_level > 0)
      {
        $template_param = join ('', $token, $template_param);

        ++$template_level if ($token eq '>');
        --$template_level if ($token eq '<');
      }
      elsif ($do_not_care_all eq 1)
      {
        if ($token eq '<')
        {
          $done = 1;
        }
        last;
      }
      elsif ($do_not_care_single)
      {
        if ($token eq '<')
        {
          if (@templates == 1)
          {
            $done = 1;
          }
          last;
        }
        elsif ($token eq ',')
        {
          last unless (@templates);
          shift (@templates);
          $do_not_care_single = 0;
        }
      }
      elsif ($token eq '!')
      {
        $do_not_care_all = 1;
      }
      elsif ($token eq '#')
      {
        $do_not_care_single = 1;
      }
      elsif ($token eq ',' or $token eq '<')
      {
        last unless (@templates);

        my $template_details = shift (@templates);

        last unless ($template_details->match_sigil ($template_param, $flags));
        $template_param = '';
        if ($token eq '<')
        {
          $done = 1;
        }
      }
      else
      {
        ++$template_level if ($token eq '>');
        $template_param = join ('', $token, $template_param);
      }
    }
    if ($done)
    {
      return 1;
    }
  }
  return 0;
}

sub get_string ($)
{
  my ($self) = @_;
  my $basic_string = $self->get_basic_string ();
  my $result = ($basic_string ? $basic_string . ' ' : '')  . $self->get_base ();
  my $templates = $self->get_templates ();

  if (@{$templates})
  {
    $result .= '< ';
    foreach my $template_details (@{$templates})
    {
      $result .= $template_details->get_string ();
    }
    $result .= ' >';
  }

  return $result;
}

sub equal ($$$)
{
  my ($self, $other, $flags) = @_;

  unless ($self->SUPER::equal ($other, $flags))
  {
    return 0;
  }

  if (($flags & Common::TypeDetails::Base::BASE) == Common::TypeDetails::Base::BASE)
  {
    my $self_base = $self->get_base ();
    my $other_base = $other->get_base ();

    if ($self_base ne $other_base)
    {
      return 0;
    }

    if (($flags & Common::TypeDetails::Base::RECURSIVE) == Common::TypeDetails::Base::RECURSIVE)
    {
      my $self_template = $self->_get_template;
      my $other_template = $other->_get_template;
      my $self_template_count = @{$self_template};
      my $other_template_count = @{$other_template};

      if ($self_template_count != $other_template_count)
      {
        return 0;
      }

      my %check = map { ($self_template->[$_]->equal ($other_template->[$_], $flags)) => undef; } 0 .. $self_template_count - 1;

      if (exists $check{'0'})
      {
        return 0;
      }
    }

  }

  return 1;
}

1; # indicate proper module load.
