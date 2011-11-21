#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

push (@INC, '.');

require Gir::Parser;

my $gir_parser = Gir::Parser->new ();

$gir_parser->parse_file ('GtkSource-3.0.gir');

my $repositories = $gir_parser->get_repositories;

foreach my $repository (sort keys %{$repositories->{'repositories'}})
{
  print STDOUT $repository . "\n";
}
