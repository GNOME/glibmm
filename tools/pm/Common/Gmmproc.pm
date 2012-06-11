# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# gmmproc - Common::Gmmproc module
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

package Common::Gmmproc;

use strict;
use warnings;

use IO::File;

use Common::Scanner;
use Common::Sections;
use Common::SectionManager;
use Common::TokensStore;
use Common::TypeInfo::Global;
use Common::WrapParser;
use Common::Variables;

use Gir::Repositories;

sub _tokenize_contents_ ($)
{
  my ($contents) = @_;
  # Break the file into tokens.  Token is:
  # - any group of #, A to z, 0 to 9, _
  # - /**
  # - /*!
  # - /*
  # - */
  # - ///
  # - //!
  # - //
  # - any char proceeded by \
  # - symbols ;{}"`'():
  # - newline
  my @tokens = Common::Shared::cleanup_tokens (split(/([#A-Za-z0-9_]+)|(\/\*[*!]?)|(\*\/)|(\/\/[\/!]?)|(\\.)|([:;{}"'`()])|(\n)/,
                     $contents));

  return \@tokens;
}

sub _prepare ($)
{
  my ($self) = @_;
  my $type_info_global = $self->get_type_info_global;

  $type_info_global->add_infos_from_file ('type_infos');
}

sub _read_all_bases ($)
{
  my ($self) = @_;
  my $source_dir = $self->get_source_dir;
  my $bases = $self->get_bases;

  # parallelize
  foreach my $base (sort keys %{$bases})
  {
    my $tokens_store = $bases->{$base};
    my $source = File::Spec->catfile ($source_dir, $base);
    my $hg = $source . '.hg';
    my $ccg = $source . '.ccg';
    my $fd = IO::File->new ($hg, 'r');

    unless (defined $fd)
    {
# TODO: do proper logging.
      print 'Could not open file `' . $hg . '\' for reading.' . "\n";
      exit 1;
    }

    $tokens_store->set_hg_tokens (_tokenize_contents_ (join '', $fd->getlines));
    $fd->close;

    # Source file is optional.
    $fd = IO::File->new ($ccg, 'r');
    if (defined $fd)
    {
      my $str = join '',
                     '_INSERT_SECTION(SECTION_CCG_BEGIN)',
                     "\n",
                     $fd->getlines,
                     "\n",
                     '_INSERT_SECTION(SECTION_CCG_END)',
                     "\n";
      $tokens_store->set_ccg_tokens (_tokenize_contents_ ($str));
      $fd->close;
    }
  }
}

sub _scan_all_bases ($)
{
  my ($self) = @_;
  my $bases = $self->get_bases;
  my @bases_keys = sort keys %{$bases};

  # parallelize
  foreach my $base (@bases_keys)
  {
    my $tokens_store = $bases->{$base};
    my $tokens_hg = $tokens_store->get_hg_tokens;
    my $tokens_ccg = $tokens_store->get_ccg_tokens;
    my $scanner = Common::Scanner->new ($tokens_hg, $tokens_ccg);

    $scanner->scan;
    $tokens_store->set_tuples ($scanner->get_tuples);
  }

  my $type_info_global = $self->get_type_info_global;

  foreach my $base (@bases_keys)
  {
    my $tokens_store = $bases->{$base};
    my $tuples = $tokens_store->get_tuples;

    foreach my $tuple (@{$tuples})
    {
      my $c_stuff = $tuple->[0];
      my $cxx_stuff = $tuple->[1];
      my $macro_type = $tuple->[2];

      $type_info_global->add_generated_info ($c_stuff, $cxx_stuff, $macro_type);
    }
  }
}

sub _parse_all_bases ($)
{
  my ($self) = @_;
  my $bases = $self->get_bases;
  my $type_info_global = $self->get_type_info_global ();
  my $repositories = $self->get_repositories;
  my $mm_module = $self->get_mm_module;

  # parallelize
  foreach my $base (sort keys %{$bases})
  {
    my $tokens_store = $bases->{$base};
    my $tokens_hg = $tokens_store->get_hg_tokens;
    my $tokens_ccg = $tokens_store->get_ccg_tokens;
    my $wrap_parser = Common::WrapParser->new ($tokens_hg,
                                               $tokens_ccg,
                                               $type_info_global,
                                               $repositories,
                                               $mm_module,
                                               $base);

    $wrap_parser->parse;
    $tokens_store->set_section_manager ($wrap_parser->get_section_manager);
  }
}

sub _generate_all_bases ($)
{
  my ($self) = @_;
  my $bases = $self->get_bases;
  my $destination_dir = $self->get_destination_dir;

  # parallelize
  foreach my $base (sort keys %{$bases})
  {
    my $tokens_store = $bases->{$base};
    my $section_manager = $tokens_store->get_section_manager;
    my $h_file = File::Spec->catfile ($destination_dir, $base . '.h');
    my $cc_file = File::Spec->catfile ($destination_dir, $base . '.cc');
    my $p_h_file = File::Spec->catfile ($destination_dir, 'private', $base . '_p.h');

    $section_manager->write_main_section_to_file (Common::Sections::H, $h_file);
    $section_manager->write_main_section_to_file (Common::Sections::CC, $cc_file);
    $section_manager->write_main_section_to_file (Common::Sections::P_H, $p_h_file);
  }
}

sub _finish ($)
{
  my ($self) = @_;
  my $type_info_global = $self->get_type_info_global ();

  $type_info_global->write_generated_infos_to_file ();
}

sub new ($$$$)
{
  my ($type, $repositories, $mm_module, $include_paths) = @_;
  my $class = (ref $type or $type or 'Common::Gmmproc');
  my $self =
  {
    'repositories' => $repositories,
    'bases' => {},
    'source_dir' => '.',
    'destination_dir' => '.',
    'type_info_global' => Common::TypeInfo::Global->new ($mm_module, $include_paths),
    'mm_module' => $mm_module,
    'include_paths' => $include_paths
  };

  return bless $self, $class;
}

sub set_source_dir ($$)
{
  my ($self, $source_dir) = @_;

  $self->{'source_dir'} = $source_dir;
}

sub get_source_dir ($)
{
  my ($self) = @_;

  return $self->{'source_dir'};
}

sub set_destination_dir ($$)
{
  my ($self, $destination_dir) = @_;

  $self->{'destination_dir'} = $destination_dir;
}

sub get_destination_dir ($)
{
  my ($self) = @_;

  return $self->{'destination_dir'};
}

sub set_include_paths ($$)
{
  my ($self, $includes) = @_;

  $self->{'includes'} = $includes;
}

sub get_include_paths ($)
{
  my ($self) = @_;

  return $self->{'includes'};
}

sub add_base ($$)
{
  my ($self, $base) = @_;
  my $bases = $self->get_bases;

  if (exists $bases->{$base})
  {
# TODO: is proper logging needed at this stage?
    print STDERR 'Base `' . $base . ' was already added.' . "\n";
    return;
  }

  $bases->{$base} = Common::TokensStore->new;
}

sub get_bases ($)
{
  my ($self) = @_;

  return $self->{'bases'};
}

sub get_repositories ($)
{
  my ($self) = @_;

  return $self->{'repositories'};
}

sub get_type_info_global ($)
{
  my ($self) = @_;

  return $self->{'type_info_global'};
}

sub get_mm_module ($)
{
  my ($self) = @_;

  return $self->{'mm_module'};
}

sub parse_and_generate ($)
{
  my ($self) = @_;

  $self->_prepare;
  $self->_read_all_bases;
  $self->_scan_all_bases;
  $self->_parse_all_bases;
  $self->_generate_all_bases;
  $self->_finish;
}

1; # indicate proper module load.
