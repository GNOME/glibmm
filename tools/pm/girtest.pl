#!/usr/bin/env perl

use strict;
use warnings;

push (@INC, '.');

require Gir::Parser;

my $parser = Gir::Parser->new ();

$parser->parse_file ('GtkSource-3.0.gir');
