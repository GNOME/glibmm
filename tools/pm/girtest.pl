#!/usr/bin/env perl

use strict;
use warnings;

push (@INC, '.');

require Gir::Parser;

my $gir_parser = Gir::Parser->new ();

$gir_parser->parse_file ('GtkSource-3.0.gir');
